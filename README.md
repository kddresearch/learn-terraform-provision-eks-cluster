# Learn OpenTofu - Use a self-hosted k3s cluster

This started as HashiCorp's [Provision an EKS Cluster tutorial](https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks) repo. It now targets a k3s cluster you already run. It does not create the cluster or any cloud resources.

## What changed from the EKS version

| EKS version | k3s version |
| --- | --- |
| `aws` provider, VPC module, EKS module, node groups | Removed. The cluster already exists. |
| EBS CSI driver add-on and its IAM role | Whatever StorageClass the cluster marks as default |
| `aws eks update-kubeconfig` | Copy `/etc/rancher/k3s/k3s.yaml` from the server |
| Outputs: endpoint, security group, region, name | Outputs: endpoint, name, version, nodes, default storage class, namespace |

The config connects with your kubeconfig, reads the nodes, finds the default StorageClass, and creates one namespace (`education` by default).

On stock k3s the default is `local-path`. Those volumes live on a single node's disk, so a pod using one is pinned to that node. If you install something like Longhorn and make it the default, this config picks it up with no changes. `tofu plan` warns if the cluster has zero or more than one default.

## Get a kubeconfig

On the k3s server:

```sh
sudo cat /etc/rancher/k3s/k3s.yaml
```

Save that to `~/.kube/config` on the machine running OpenTofu. Change `server: https://127.0.0.1:6443` to the server's real IP or hostname. If you reach it by a name that isn't in the API certificate, add that name to the server with `--tls-san` first.

## Run it

```sh
tofu init
tofu plan
tofu apply
```

To use a different kubeconfig or context, create `terraform.tfvars`:

```hcl
kubeconfig_path    = "~/.kube/k3s.yaml"
kubeconfig_context = "default"
namespace          = "education"
```

To remove the namespace:

```sh
tofu destroy
```

## Requirements

- OpenTofu 1.6 or newer
- A k3s cluster with a default StorageClass. Stock k3s has one (`local-path`). If you started the server with `--disable local-storage`, mark another class as default.
