# Homelab GitOps

GitOps configuration for a Kubernetes homelab cluster. Argo CD is the control plane for cluster reconciliation, with a root application that manages infrastructure controllers, platform services, and user workloads from this repository.

## Repository Layout

```text
.
├── bootstrap/          # One-time Argo CD root Application
├── argocd/             # App-of-apps entry point managed by the root app
│   ├── infrastructure/ # Cluster infrastructure Argo CD Applications
│   ├── platform/       # Shared platform Argo CD Applications
│   └── applications/   # User workload Argo CD Applications
├── infrastructure/     # Helm values and manifests for core controllers
├── platform/           # Shared cluster services and routing primitives
├── applications/       # Workload manifests
├── secrets/            # Encrypted secret manifests
└── talos/              # Talos image customization helpers
```

## What This Deploys

### Infrastructure

- Argo CD, including repo-server support for KSOPS/SOPS decryption.
- cert-manager with CRDs enabled.
- Envoy Gateway.
- External Secrets Operator.
- MetalLB.
- Longhorn.
- Terraform controller manifests are present but currently disabled in `argocd/infrastructure/kustomization.yaml`.

### Platform

- Public Gateway API `GatewayClass` and `Gateway` for `*.k8s.749rmw.com`.
- cert-manager `ClusterIssuer` using Route53 DNS-01 challenges.
- Wildcard certificate for `*.k8s.749rmw.com`.
- authentik, deployed from the upstream Helm chart with encrypted configuration secrets.

### Applications

- `whoami`, exposed through Gateway API at `whoami.k8s.749rmw.com`.
- `sops-test`, a small KSOPS-backed secret decryption test.
- Grafana and VictoriaMetrics Argo CD application placeholders exist but are currently empty and not included in `argocd/applications/kustomization.yaml`.

## Bootstrap

This repo uses an Argo CD app-of-apps pattern.

1. Install Argo CD into the cluster.
2. Create the SOPS age key secret in the `argocd` namespace.
3. Apply the root application:

```sh
kubectl apply -f bootstrap/root-app.yaml
```

The root app is named `homelab-root` and points Argo CD at the `argocd/` directory on the `main` branch. From there, Argo CD reconciles the grouped infrastructure, platform, and application manifests.

## Secret Management

Secrets are encrypted with SOPS using age. The repo SOPS policy is in `.sops.yaml`:

- Files matching `*.sops.yaml` or `*.sops.yml` are encrypted.
- Only `data` and `stringData` fields are encrypted.
- Argo CD repo-server is configured to run KSOPS through Kustomize.

Before Argo CD can decrypt KSOPS resources, create the age key secret:

```sh
kubectl create secret generic sops-age \
  --namespace argocd \
  --from-file=keys.txt=/path/to/age/keys.txt
```

To edit an encrypted secret locally:

```sh
sops applications/sops-test/test-secret.sops.yaml
```

To create a new KSOPS-backed secret, add the encrypted `*.sops.yaml` file and reference it from a `secret-generator.yaml` file similar to the existing examples in `applications/sops-test/` and `platform/authentik/secrets/`.

## Local Validation

Render Kustomize entry points before pushing changes:

```sh
kubectl kustomize argocd
kubectl kustomize argocd/infrastructure
kubectl kustomize argocd/platform
kubectl kustomize argocd/applications
```

For KSOPS directories, local rendering requires `ksops`, `sops`, and the corresponding age private key:

```sh
kubectl kustomize --enable-alpha-plugins --enable-exec applications/sops-test
kubectl kustomize --enable-alpha-plugins --enable-exec platform/authentik
```

## Talos Image

The `talos/image/` directory contains a Talos Image Factory schematic. It currently enables the official `siderolabs/iscsi-tools` system extension for Longhorn support.

Generate a schematic ID and installer image:

```sh
./talos/image/generate.sh
```

The Talos version defaults to the value in `talos/image/version.env`.

## Operating Notes

- Most Argo CD applications enable automated self-heal.
- Pruning is enabled for some workloads and disabled for several platform and infrastructure resources. Check each `Application` manifest before assuming deletion behavior.
- Gateway routes rely on the `public` Gateway in `envoy-gateway-system`.
- Route53 DNS-01 certificate issuance requires the `route53-credentials` secret in the `cert-manager` namespace.
- This repository contains cluster-specific domains, hosted zone IDs, and application names. Review those values before reusing it for another cluster.
