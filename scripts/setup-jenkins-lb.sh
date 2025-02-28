#!/bin/bash

set -e

DOMAIN_NAME="jenkins.k8s.it.com"
HOSTED_ZONE_ID="Z05844171BN27HQQ98YZ8"  # Replace with your Route 53 hosted zone ID
ARGOCD_LB_DNS=$(kubectl get svc -n argocd argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

if [[ -z "$ARGOCD_LB_DNS" ]]; then
  echo "Error: Could not retrieve ArgoCD Load Balancer DNS!"
  exit 1
fi

echo "Found ArgoCD Load Balancer DNS: $ARGOCD_LB_DNS"

LOAD_BALANCER_ARN=$(aws elbv2 describe-load-balancers \
  --query "LoadBalancers[?DNSName=='$ARGOCD_LB_DNS'].LoadBalancerArn" \
  --output text)

if [[ -z "$LOAD_BALANCER_ARN" ]]; then
  echo "Error: Load Balancer ARN could not be retrieved!"
  exit 1
fi

echo "Found Load Balancer ARN: $LOAD_BALANCER_ARN"

REGION="eu-west-1"

echo "Creating ACM certificate for $DOMAIN_NAME..."

# 1️⃣ Retrieve the existing ACM Certificate ARN (if exists)
CERT_ARN=$(aws acm list-certificates --query "CertificateSummaryList[?DomainName=='$DOMAIN_NAME'].CertificateArn" --output text)

if [[ -n "$CERT_ARN" ]]; then
  echo "✅ Certificate for $DOMAIN_NAME already exists: $CERT_ARN"
else
  echo "🚀 Requesting a new ACM certificate for $DOMAIN_NAME..."
  CERT_ARN=$(aws acm request-certificate \
    --domain-name "$DOMAIN_NAME" \
    --validation-method DNS \
    --query "CertificateArn" --output text)
  
  echo "✅ Requested new certificate: $CERT_ARN"
fi

# 2️⃣ Retrieve the validation CNAME record
VALIDATION_RECORD=$(aws acm describe-certificate --certificate-arn "$CERT_ARN" \
  --query "Certificate.DomainValidationOptions[0].ResourceRecord" --output json)

if [[ "$VALIDATION_RECORD" == "null" ]]; then
  echo "⚠️ No validation record found for the certificate."
  exit 1
fi

RECORD_NAME=$(echo "$VALIDATION_RECORD" | jq -r .Name)
RECORD_VALUE=$(echo "$VALIDATION_RECORD" | jq -r .Value)

# 3️⃣ Check if the DNS record already exists in Route 53
EXISTING_RECORD=$(aws route53 list-resource-record-sets --hosted-zone-id '$HOSTED_ZONE_ID' \
  --query "ResourceRecordSets[?Name=='$RECORD_NAME']" --output json)

if [[ "$EXISTING_RECORD" == "[]" ]]; then
  echo "📝 Adding Route 53 CNAME record for validation..."
  cat > change-batch.json <<EOF
{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$RECORD_NAME",
      "Type": "CNAME",
      "TTL": 300,
      "ResourceRecords": [{ "Value": "$RECORD_VALUE" }]
    }
  }]
}
EOF
  aws route53 change-resource-record-sets --hosted-zone-id ZONE_ID --change-batch file://change-batch.json
  echo "✅ DNS validation record added."
else
  echo "✅ DNS validation record already exists."
fi

# 4️⃣ Wait for certificate validation
echo "⏳ Waiting for ACM certificate validation..."
while true; do
  STATUS=$(aws acm describe-certificate --certificate-arn "$CERT_ARN" --query "Certificate.Status" --output text)
  echo "  - Current status: $STATUS"
  if [[ "$STATUS" == "ISSUED" ]]; then
    echo "✅ Certificate issued!"
    break
  fi
  sleep 30
done

# 5️⃣ Attach the certificate to the Load Balancer
echo "🔍 Retrieving Load Balancer ARN..."
LB_ARN=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?DNSName=='ARGOCD_LB_DNS'].LoadBalancerArn" --output text)

if [[ -z "$LB_ARN" ]]; then
  echo "❌ Failed to retrieve Load Balancer ARN."
  exit 1
fi

# 6️⃣ Retrieve the Listener ARN for HTTPS (Port 443)
LISTENER_ARN=$(aws elbv2 describe-listeners --load-balancer-arn "$LB_ARN" \
  --query "Listeners[?Port==\`443\`].ListenerArn" --output text)

if [[ -z "$LISTENER_ARN" ]]; then
  echo "❌ No existing HTTPS listener found on Load Balancer."
  exit 1
fi

# 7️⃣ Check if the certificate is already attached
EXISTING_CERTS=$(aws elbv2 describe-listener-certificates --listener-arn "$LISTENER_ARN" --query "Certificates[].CertificateArn" --output json)

if echo "$EXISTING_CERTS" | grep -q "$CERT_ARN"; then
  echo "✅ Certificate is already attached to Load Balancer."
else
  echo "🔗 Attaching certificate to Load Balancer..."
  aws elbv2 add-listener-certificates --listener-arn "$LISTENER_ARN" --certificates CertificateArn="$CERT_ARN"
  echo "✅ Certificate attached successfully!"
fi

echo "Jenkins setup complete!"

