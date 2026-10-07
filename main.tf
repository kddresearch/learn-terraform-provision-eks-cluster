# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

# The cluster already exists. Read its endpoint out of the same kubeconfig
# the provider uses so it can be reported as an output.
locals {
  kubeconfig   = yamldecode(file(pathexpand(var.kubeconfig_path)))
  context_name = coalesce(var.kubeconfig_context, local.kubeconfig["current-context"])
  context      = one([for c in local.kubeconfig.contexts : c.context if c.name == local.context_name])
  cluster      = one([for c in local.kubeconfig.clusters : c.cluster if c.name == local.context.cluster])

  default_storage_classes = [
    for sc in data.kubernetes_resources.storage_classes.objects : sc.metadata.name
    if try(sc.metadata.annotations["storageclass.kubernetes.io/is-default-class"], "false") == "true"
  ]
}

data "kubernetes_nodes" "all" {}

# Use whatever StorageClass the cluster marks as default (local-path on stock
# k3s, Longhorn or anything else if you've changed it). PVCs that leave out
# storageClassName get this class, so nothing here names one.
data "kubernetes_resources" "storage_classes" {
  api_version = "storage.k8s.io/v1"
  kind        = "StorageClass"
}

check "default_storage_class" {
  assert {
    condition     = length(local.default_storage_classes) == 1
    error_message = "Expected exactly one default StorageClass, found ${length(local.default_storage_classes)}: ${jsonencode(local.default_storage_classes)}. PVCs without a storageClassName will fail to bind if there is none."
  }
}

resource "kubernetes_namespace_v1" "education" {
  metadata {
    name = var.namespace
  }
}
