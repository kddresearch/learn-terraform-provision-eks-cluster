# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0
 
# nginx runs from bjw-s's app-template chart (Apache-2.0) with the official
# nginx image (BSD-2-Clause). app-template is a generic chart: you describe the
# Deployment, Service and ConfigMaps in values and it renders them.
#
# Port 80 is not used for the Service because k3s's built-in load balancer
# (ServiceLB) already gives it to Traefik on every node. A second LoadBalancer
# service on 80 would never get an address. The container still listens on 80,
# and the Service maps 8080 to it.
locals {
  nginx_release_name = "nginx"
 
  nginx_values = {
    global = {
      # app-template names resources "<release>-app-template" by default. This
      # makes the Service "nginx" so the data source below can find it.
      fullnameOverride = local.nginx_release_name
    }
 
    controllers = {
      main = {
        replicas = 1
 
        containers = {
          main = {
            image = {
              repository = "docker.io/library/nginx"
              tag        = "stable-alpine"
            }
          }
        }
      }
    }
 
    service = {
      main = {
        controller = "main"
        type       = "LoadBalancer"
 
        ports = {
          http = {
            port       = 8080
            targetPort = 80
          }
        }
      }
    }
  }
}
 
resource "helm_release" "nginx" {
  name       = local.nginx_release_name
  namespace  = kubernetes_namespace_v1.education.metadata[0].name
  repository = "https://bjw-s-labs.github.io/helm-charts"
  chart      = "app-template"
  version    = "5.2.1"
 
  values = [yamlencode(local.nginx_values)]
}
 
data "kubernetes_service_v1" "nginx" {
  depends_on = [helm_release.nginx]
 
  metadata {
    name      = helm_release.nginx.name
    namespace = helm_release.nginx.namespace
  }
}
