variable "jenkins_namespace" {
  description = "Namespace for Jenkins"
  type        = string
}

variable "jenkins_release_name" {
  description = "Helm release name for Jenkins"
  type        = string
}

variable "jenkins_ingress_host" {
  description = "Ingress host for Jenkins"
  type        = string
}

variable "jenkins_persistence_size" {
  description = "Persistent storage size for Jenkins"
  type        = string
}

variable "jenkins_java_opts" {
  description = "Java options for Jenkins"
  type        = string
}

variable "jenkins_resources_requests_cpu" {
  description = "CPU request for Jenkins"
  type        = string
}

variable "jenkins_resources_requests_memory" {
  description = "Memory request for Jenkins"
  type        = string
}

variable "jenkins_resources_limits_cpu" {
  description = "CPU limit for Jenkins"
  type        = string
}

variable "jenkins_resources_limits_memory" {
  description = "Memory limit for Jenkins"
  type        = string
}
