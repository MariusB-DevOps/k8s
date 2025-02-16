resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.jenkins_namespace
  }
}

resource "helm_release" "jenkins" {
  name       = var.jenkins_release_name
  repository = "https://charts.jenkins.io"
  chart      = "jenkins"
  namespace  = kubernetes_namespace.jenkins.metadata[0].name

  set {
    name  = "controller.ingress.enabled"
    value = "true"
  }

  set {
    name  = "controller.ingress.hostName"
    value = var.jenkins_ingress_host
  }

  set {
    name  = "controller.ingress.annotations.nginx.ingress.kubernetes.io/force-ssl-redirect"
    value = "true"
  }

  set {
    name  = "controller.ingress.annotations.nginx.ingress.kubernetes.io/ssl-redirect"
    value = "true"
  }

  set {
    name  = "persistence.enabled"
    value = "true"
  }

  set {
    name  = "persistence.size"
    value = var.jenkins_persistence_size
  }

  set {
    name  = "controller.javaOpts"
    value = var.jenkins_java_opts
  }

  set {
    name  = "controller.resources.requests.cpu"
    value = var.jenkins_resources_requests_cpu
  }

  set {
    name  = "controller.resources.requests.memory"
    value = var.jenkins_resources_requests_memory
  }

  set {
    name  = "controller.resources.limits.cpu"
    value = var.jenkins_resources_limits_cpu
  }

  set {
    name  = "controller.resources.limits.memory"
    value = var.jenkins_resources_limits_memory
  }
}
