#!/bin/bash

set -e

DOMAIN_NAME="jenkins.k8s.it.com"
HOSTED_ZONE_ID="Z05844171BN27HQQ98YZ8"  # Replace with your Route 53 hosted zone ID
LB_ARN=$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(DNSName, 'elb')].LoadBalancerArn" --output text)
REGION="eu-west-1"

echo "Creating ACM certificate for $DOMAIN_NAME..."
CERT_ARN=$(aws acm request-certificate --domain-name $DOMAIN_NAME --validation-method DNS --query "CertificateArn" --output text --region $REGION)

echo "Fetching DNS validation record..."
VALIDATION_RECORD=$(aws acm describe-certificate --certificate-arn $CERT_ARN --query "Certificate.DomainValidationOptions[0].ResourceRecord" --output json)

RECORD_NAME=$(echo $VALIDATION_RECORD | jq -r '.Name')
RECORD_VALUE=$(echo $VALIDATION_RECORD | jq -r '.Value')

echo "HOSTED_ZONE_ID=$HOSTED_ZONE_ID"
echo "CERT_ARN=$CERT_ARN"
echo "DOMAIN_NAME=$DOMAIN_NAME"
echo "LOAD_BALANCER_HOSTNAME=$LOAD_BALANCER_HOSTNAME"

echo "Adding Route 53 record for validation..."
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch '{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "'"$RECORD_NAME"'",
      "Type": "CNAME",
      "TTL": 60,
      "ResourceRecords": [{ "Value": "'"$RECORD_VALUE"'" }]
    }
  }]
}'

echo "Waiting for certificate validation..."
aws acm wait certificate-validated --certificate-arn $CERT_ARN --region $REGION

echo "Associating ACM certificate with Load Balancer..."
aws elbv2 add-listener-certificates --listener-arn $LB_ARN --certificates CertificateArn=$CERT_ARN

echo "Adding Route 53 record for Jenkins..."
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE_ID --change-batch '{
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "'"$DOMAIN_NAME"'",
      "Type": "A",
      "AliasTarget": {
        "HostedZoneId": "Z05844171BN27HQQ98YZ8",
        "DNSName": "'"$(aws elbv2 describe-load-balancers --query "LoadBalancers[?contains(DNSName, 'elb')].DNSName" --output text)"'",
        "EvaluateTargetHealth": false
      }
    }
  }]
}'

echo "Jenkins setup complete!"

