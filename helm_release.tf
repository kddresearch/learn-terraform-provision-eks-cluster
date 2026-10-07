# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# Port 80 is not used here because k3s's built-in load balancer (ServiceLB)
# already gives it to Traefik on every node. A second LoadBalancer service on
# 80 would never get an address.
locals {
  nginx_values = {
    replicaCount = 1

    service = {
      ports = {
        http = 8080
      }
    }
  }
}

resource "helm_release" "nginx" {
  name       = "nginx"
  namespace  = kubernetes_namespace_v1.education.metadata[0].name
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx"

  values = [yamlencode(local.nginx_values)]
}

data "kubernetes_service_v1" "nginx" {
  depends_on = [helm_release.nginx]

  metadata {
    name      = helm_release.nginx.name
    namespace = helm_release.nginx.namespace
  }
}
