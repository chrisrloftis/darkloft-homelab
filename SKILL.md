---
name: homelab
description: Operational conventions for the HomeLab repository. Activates for any task that interacts with this repo's OKD or MicroShift clusters, applies manifests, runs Ansible against the fleet, or modifies cluster state. Also indexes other project-local skills.
---

# HomeLab Skill

Operational conventions for this HomeLab repository. Read this in full before
acting on cluster, manifest, or Ansible changes. The companion file
[AGENTS.md](AGENTS.md) expands on directory layout and common tasks.

## Related Skills

- [Kubernetes (KubeShark)](.agents/skills/kubernetes-skill/SKILL.md) —
  production-grade Kubernetes manifest, Helm, and Kustomize guidance with a
  failure-mode workflow and Conditional Reference Retrieval. Required for any
  Kubernetes resource design, review, or refactor. OKD-specific patterns
  (SCCs, Routes, arbitrary UID images) live in its `openshift-patterns` CRR
  reference.

## Cluster Inventory

| Cluster    | Distribution        | Nodes                                                | Storage   | KUBECONFIG               |
| ---------- | ------------------- | ---------------------------------------------------- | --------- | ------------------------ |
| OCP        | OCP 4.22.8 | 3 control-plane (`master-0/1/2`) + workers (`worker-1/2`) | ODF | `$HOME/.kube/config`        |

GitOps: ArgoCD reconciles [k8s/](k8s/) into both clusters via
per-app overlays (`overlays/okd`, `overlays/microshift`). Other active
overlays across the repo: `okd-sandbox`, `okd-unas`, `sandbox`, `sno`,
`microshift-unas`, `old`, `operator` (all OpenShift/OKD-based) and `k3s`
(legacy, the only non-OpenShift target).

## Cluster Authentication

Select the target cluster by exporting `KUBECONFIG` before any `kubectl`,
`oc`, `helm`, `kustomize`, or `argocd` call:

- OKD: `export KUBECONFIG=$HOME/.kube/okd`
- MicroShift: `export KUBECONFIG=$HOME/.kube/microshift`

Both kubeconfigs grant **cluster-admin**. Caution rules:

- Prefer read-only commands (`get`, `describe`, `--dry-run=client`,
  `kustomize build`) when exploring.
- Confirm with the user before any mutating action: `apply`, `delete`,
  `patch`, `scale`, `drain`, `cordon`, `rollout restart`, `evict`.
- Never `oc adm` or `kubectl exec` into a production workload without
  explicit user confirmation.
- Mutations to ArgoCD-managed resources will be reverted on next sync — the
  correct fix is almost always a PR to [k8s/](k8s/), not a
  live `kubectl` change.

## Repository Workflow

### Adding or editing a Kubernetes app

1. Place manifests under `k8s/<app>/base/` and per-cluster overlays under `k8s/<app>/overlays/{ocp}/`.
1. Register the app in [k8s/openshift-gitops-operator/applications/](k8s/argocd/applications/) as `<app>.yaml` and add it to the local `kustomization.yaml`.
1. Validate with `./main.bash test_overlays` (requires `VAULT_ADDR` and `VAULT_TOKEN`; runs `argocd-vault-plugin` + `kubeconform -strict` against a sibling `../kubernetes-json-schema/` checkout).
1. Follow the [Kubernetes (KubeShark) skill](.agents/skills/kubernetes-skill/SKILL.md) for resource design (security context, probes, resources, RBAC NetworkPolicy, rollout strategy).

### Secrets

- Never commit plaintext secrets, kubeconfigs, tokens, or `.env` files.
  `gitleaks` runs in pre-commit and CI.

### OKD provisioning

- [ocp/](ocp/) holds `agent-config.yaml` and `install-config.yaml` for the
  OKD agent-based installer.
- Treat as bootstrap inputs; changes are rare and high-risk — require
  explicit user confirmation.

### Lint and formatting

- Commit messages must satisfy `conventional-pre-commit`
  (`feat:`, `fix:`, `chore:`, `build(deps):`, `docs:`, ...).

YAML rules: 2-space indent, `---` document marker at top, no line-length
limit. Shell scripts: `set -o errexit -o nounset -o pipefail` and
`shopt -s failglob`; see [main.bash](main.bash).

## Out of Scope

- [notes/](notes/) and [sandbox/](sandbox/) are scratch. Read for context;
  do not deploy from them and do not treat their YAML as authoritative.
- `CHANGELOG.md` is auto-maintained; do not hand-edit.
- `img/` holds documentation assets only.
