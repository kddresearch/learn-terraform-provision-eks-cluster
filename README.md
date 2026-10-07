# Learn OpenTofu - Use a self-hosted k3s cluster

This started as HashiCorp's [Provision an EKS Cluster tutorial](https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks) repo. It now targets a k3s cluster you already run. It does not create the cluster or any cloud resources.

## What changed from the EKS version

| EKS version | k3s version |
| --- | --- |
| `aws` provider, VPC module, EKS module, node groups | Removed. The cluster already exists. |
| EBS CSI driver add-on and its IAM role | Whatever StorageClass the cluster marks as default |
| `aws eks update-kubeconfig` | Copy `/etc/rancher/k3s/k3s.yaml` from the server |
| Outputs: endpoint, security group, region, name | Outputs: endpoint, name, version, nodes, default storage class, namespace, nginx endpoint |

The config connects with your kubeconfig, reads the nodes, finds the default StorageClass, and creates one namespace (`education` by default). `helm_release.tf` then deploys nginx into that namespace (see below).

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

## Deploy nginx with Helm

`helm_release.tf` follows HashiCorp's [Helm provider tutorial](https://developer.hashicorp.com/terraform/tutorials/kubernetes/helm-provider) ([learn-terraform-helm](https://github.com/hashicorp-education/learn-terraform-helm)). It installs the Bitnami `nginx` chart into the `education` namespace. It differs from the tutorial in a few ways:

- It sits in the same workspace as the cluster config. The tutorial reads the EKS state with `terraform_remote_state`, but there's no cluster state to read here.
- The helm provider uses your kubeconfig instead of `aws eks get-token`.
- Values are an HCL map passed through `yamlencode()` instead of `nginx-values.yaml`.
- The service listens on 8080. On k3s, Traefik already holds port 80 on every node through ServiceLB, so a second LoadBalancer on 80 never gets an address.
- `nginx_endpoint` reads the load balancer's IP. EKS hands out a hostname.

After `tofu apply`:

```sh
curl $(tofu output -raw nginx_endpoint)
```

You should get the "Welcome to nginx!" page.

### Change the nginx config

This is the tutorial's "Modify Nginx" step. Add a `serverBlock` to `local.nginx_values` in `helm_release.tf`:

```hcl
locals {
  nginx_values = {
    replicaCount = 1

    service = {
      ports = {
        http = 8080
      }
    }

    serverBlock = <<-EOT
      server {
        listen 0.0.0.0:8080;
        location / {
          default_type text/plain;
          return 200 "hello! from k3s\n";
        }
      }
    EOT
  }
}
```

The `listen 8080` here is the port inside the container, which Bitnami's image uses by default. It isn't the service port above, even though both are 8080.

Run `tofu apply` again. It should report one resource changed. `curl` the endpoint again to see the new response.

### Bitnami images

Bitnami moved versioned images to `docker.io/bitnamilegacy` in August 2025. Only `latest` tags of a smaller set remain free under `docker.io/bitnami`. This config doesn't pin a chart version, so it gets the newest chart, which should point at images that still pull. If you pin an older chart version and the pod hangs in `ImagePullBackOff`, that move is the reason.

## Clean up

This removes the nginx release and the namespace. It leaves the cluster alone.

```sh
tofu destroy
```

## Requirements

- OpenTofu 1.6 or newer
- A LoadBalancer implementation. k3s's ServiceLB is on by default. MetalLB also works.
- A k3s cluster with a default StorageClass. Stock k3s has one (`local-path`). If you started the server with `--disable local-storage`, mark another class as default.
