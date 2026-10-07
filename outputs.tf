# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

output "cluster_endpoint" {
  description = "Kubernetes API server URL from the kubeconfig"
  value       = local.cluster.server
}

output "cluster_name" {
  description = "Cluster name from the kubeconfig (k3s calls it \"default\")"
  value       = local.context.cluster
}

output "kubernetes_version" {
  description = "Kubelet version reported by the first node"
  value       = data.kubernetes_nodes.all.nodes[0].status[0].node_info[0].kubelet_version
}

output "nodes" {
  description = "Names of all nodes in the cluster"
  value       = [for n in data.kubernetes_nodes.all.nodes : n.metadata[0].name]
}

output "default_storage_class" {
  description = "The cluster's default StorageClass, or null if none is set"
  value       = try(local.default_storage_classes[0], null)
}

output "nginx_endpoint" {
  description = "URL of the nginx LoadBalancer service"
  value = format("http://%s:%d",
    coalesce(
      try(data.kubernetes_service_v1.nginx.status[0].load_balancer[0].ingress[0].ip, ""),
      try(data.kubernetes_service_v1.nginx.status[0].load_balancer[0].ingress[0].hostname, ""),
    ),
    data.kubernetes_service_v1.nginx.spec[0].port[0].port,
  )
}

output "namespace" {
  description = "Namespace created for workloads"
  value       = kubernetes_namespace_v1.education.metadata[0].name
}
