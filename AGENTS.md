# Agent Instructions

This file is the entry point for AI agents working in this repository. It
mirrors the HomeLab skill at [SKILL.md](SKILL.md). Read both before acting.

## TL;DR

- This repo manages a bare-metal **OCP** cluster (3 control-plane + 2 workers).
- Applications are deployed via **ArgoCD GitOps** from [k8s/](k8s/).
- OpenShift cluster is Bare-metal and provisioned via the **OCP agent-based installer** ([okd/](okd/)).
- Kubernetes manifest, Helm, and Kustomize tasks must follow the
  [Kubernetes (KubeShark) skill](.agents/skills/kubernetes-skill/SKILL.md).

## Repository Map

| Path                                                                                  | Purpose                                                                 |
| ------------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| [containers/](containers/)                                                            | Custom container images (`toolbox`, `gpu-toolbox`, `udi`, `apache-php`) |
| [k8s/](k8s/)                                                                          | All cluster apps; GitOps source for ArgoCD                              |
| [kubernetes/openshift-gitops-operator/applications/](kubernetes/argocd/applications/) | ArgoCD `Application` registrations (one YAML per app)                   |
| [ocp/](ocp/)                                                                          | OKD agent-based installer configs (`agent-config`, `install-config`)    |

## Cluster Authentication

Always set `KUBECONFIG` explicitly before any `kubectl`, `oc`, `helm`, or
`kustomize` invocation:

- OCP: `export KUBECONFIG=$HOME/.kube/config`

Both kubeconfigs grant **cluster-admin**. Default to read-only commands
(`get`, `describe`, `--dry-run=client`, `kustomize build`) when exploring.
Confirm with the user before any `apply`, `delete`, `patch`, `scale`,
`drain`, or `cordon`.

## Conventions

### Kubernetes manifests

- Layout per app: `kubernetes/<app>/{base,overlays/<cluster>}` with a
  `kustomization.yaml` at each level. Some apps add `components/` for
  reusable patches.
- Active overlays: `ocp` Pick the one matching the target cluster.
- Register new apps in [k8s/argocd/applications/](kubernetes/argocd/applications/)
  as `<app>.yaml` and include them in the local `kustomization.yaml`.

- Secrets: prefer **External Secrets Operator** (`ExternalSecret` pulling
  from Vault via the cluster `ClusterSecretStore` — see
  [kubernetes/external-secrets-operator/](kubernetes/external-secrets-operator/)).
  Fall back to **argocd-vault-plugin** placeholders (`<path:...#key>`) only
  when ESO cannot express the requirement. Never commit plaintext secrets.
  Overlay validation still requires `VAULT_ADDR` and `VAULT_TOKEN` for AVP
  placeholders that remain.
- Validation: run `kubectl kustomize` to ensure overlay successfully builds out

### Manifest authoring rules

When writing or reviewing Kubernetes resources, follow the
[Kubernetes (KubeShark) skill](.agents/skills/kubernetes-skill/SKILL.md).
Its failure-mode workflow and Conditional Reference Retrieval take
precedence over generic Kubernetes guidance. OKD-specific patterns
(SecurityContextConstraints, `Route`, arbitrary UID images) apply here —
load the `openshift-patterns` CRR reference when touching them.

### Shell, YAML, Markdown

- Shell scripts use `set -o errexit -o nounset -o pipefail` and
  `shopt -s failglob` (see [main.bash](main.bash) for the template).
- YAML indent is 2 spaces; `---` document marker required at top of files
  (enforced by `kustomize_fix`).
- Commit messages must follow Conventional Commits (`feat:`, `fix:`,
  `chore:`, `build(deps):`, `docs:`, ...).

## Common Tasks

- Add a Kubernetes app — see [README.md](README.md#deploying-a-new-app).
- Drain a node — `oc adm drain <node> --delete-emptydir-data --ignore-daemonsets --force`
  (confirm with the user first).

## Related Skills

- [Kubernetes (KubeShark)](.agents/skills/kubernetes-skill/SKILL.md) —
  production-grade Kubernetes manifest, Helm, and Kustomize guidance with a
  failure-mode workflow and Conditional Reference Retrieval. Activate for any
  Kubernetes resource design or review.
- [HomeLab SKILL](SKILL.md) — canonical version of this document, also
  surfaced under [.agents/skills/homelab/SKILL.md](.agents/skills/homelab/SKILL.md).

## Out of Scope

- `.git/`, `img/`, `CHANGELOG.md` (auto-maintained) — do not edit unless
  explicitly requested.
