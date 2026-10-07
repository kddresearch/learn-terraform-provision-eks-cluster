# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

variable "kubeconfig_path" {
  description = "Path to a kubeconfig for the k3s cluster (a copy of /etc/rancher/k3s/k3s.yaml with the server address fixed up)"
  type        = string
  default     = "~/.kube/config"
}

variable "kubeconfig_context" {
  description = "Kubeconfig context to use. Null uses the file's current-context."
  type        = string
  default     = null
}

variable "namespace" {
  description = "Namespace to create for workloads"
  type        = string
  default     = "education"
}
