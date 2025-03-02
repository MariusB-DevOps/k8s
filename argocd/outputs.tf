#output "argocd_initial_admin_secret" {
#  value = "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
#}

output "argocd_alb_hostname" {
  value = data.terraform_remote_state.eks.outputs.argocd_alb_hostname
}

output "argocd_initial_admin_secret" {
  value     = kubernetes_secret.argocd_admin.data["password"]
  sensitive = true
}
