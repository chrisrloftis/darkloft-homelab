# HashiCorp Vault on OpenShift (Homelab)

Kustomize overlay for deploying HashiCorp Vault into an OpenShift cluster.

## Structure

```
vault/
├── base/                    # Core Vault resources
│   ├── kustomization.yaml   # Base kustomization
│   ├── namespace.yaml       # Namespace + LimitRange (combined)
│   ├── service-account.yaml # Service account for Vault pods
│   ├── rbac.yaml            # ClusterRoleBindings for Vault API access
│   ├── network-policy.yaml  # Network policies (deny-all + exceptions)
│   └── service.yaml         # External + internal headless services
├── components/
│   ├── ha/                  # High Availability component
│   │   ├── kustomization.yaml
│   │   ├── vault.hcl        # Vault config (Raft storage)
│   │   ├── statefulset.yaml # 3-replica StatefulSet
│   │   ├── pdb.yaml         # PodDisruptionBudget (minAvailable: 2)
│   │   ├── vpa.yaml         # VerticalPodAutoscaler
│   │   └── probes.yaml      # Readiness/liveness probe scripts
│   └── tls/                 # TLS/certificate management component
│       ├── kustomization.yaml
│       ├── certificate.yaml # cert-manager Certificate + Issuers
│       └── ingress-route.yaml  # OpenShift Routes
└── overlays/
    └── homelab/             # Homelab-specific overlay
        └── kustomization.yaml
```

## Components

### HA Component
Enables high availability with:
- 3-replica StatefulSet using Raft storage
- PodDisruptionBudget ensuring 2 pods always available
- VerticalPodAutoscaler for automatic resource adjustment
- Pod anti-affinity to spread across nodes

### TLS Component
Enables TLS with:
- cert-manager Certificate resources
- OpenShift Route resources (passthrough TLS recommended)

## Usage

### Generate and apply manifests
```bash
# View the rendered manifest
kubectl kustomize overlays/homelab

# Apply directly
kubectl kustomize overlays/homelab | kubectl apply -f -

# Preview with dry run
kubectl kustomize overlays/homelab | kubectl apply -f - --dry-run=client
```

### Initialize Vault
```bash
# Get the first pod name
VAULT_POD=$(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o name | head -1)

# Initialize Vault (outputs root token and unseal keys)
kubectl exec -it $VAULT_POD -n vault -- vault operator init

# Save these keys securely!
```

### Unseal Vault
```bash
# Unseal with 3 of 5 keys (majority of 3 replicas)
kubectl exec -it vault-0.vault-internal -n vault -- vault operator unseal <key1>
kubectl exec -it vault-1.vault-internal -n vault -- vault operator unseal <key2>
kubectl exec -it vault-2.vault-internal -n vault -- vault operator unseal <key3>
```

### Join additional Raft peers
```bash
# After initializing vault-0, join vault-1 and vault-2
kubectl exec -it vault-1.vault-internal -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -it vault-1.vault-internal -n vault -- vault operator unseal <key>

kubectl exec -it vault-2.vault-internal -n vault -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -it vault-2.vault-internal -n vault -- vault operator unseal <key>
```

### Configure Kubernetes Auth
```bash
# Enable Kubernetes auth method
vault auth enable kubernetes

# Configure Vault to talk to Kubernetes API
vault write auth/kubernetes/config \
  kubernetes_host="https://kubernetes.default.svc:443"

# Create a role for service accounts
vault write auth/kubernetes/role/my-app \
  bound_service_account_names=my-app-sa \
  bound_service_account_namespaces=my-namespace \
  policies=default \
  ttl=1h
```

## Configuration

### Customize the overlay

Edit `overlays/homelab/kustomization.yaml` to:

1. **Change the hostname**: Update `spec.host` values for both Routes
2. **Change the Vault image version**: Update the image path
3. **Add storage class**: Add a patch to override `volumeClaimTemplates[0].spec.storageClassName`
4. **Adjust replica count**: Modify the `replicas` field in the StatefulSet

### Storage

By default, the StatefulSet uses a 10Gi PVC with the default storage class. To use a specific storage class:

```yaml
# Add to overlays/homelab/kustomization.yaml patches:
- target:
    kind: StatefulSet
    name: vault
  patch: |
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: vault
    spec:
      volumeClaimTemplates:
        - metadata:
            name: data
          spec:
            storageClassName: rook-ceph-block  # Your storage class
```

### TLS Mode

The default Route uses `passthrough` TLS termination, which means:
- OpenShift does NOT decrypt traffic
- Vault handles TLS directly (end-to-end encryption)
- You need to provide your own certificates

Alternative modes:
- **reencrypt**: OpenShift terminates TLS and validates backend certificates
- **edge**: OpenShift terminates TLS and sends unencrypted to backend

For Vault, `passthrough` is recommended for security.

## OpenShift Notes

1. **SecurityContextConstraints**: Vault runs as root internally for binding to ports. You may need to create an SCC:
   ```bash
   oc create -f - <<EOF
   apiVersion: security.openshift.io/v1
   kind: SecurityContextConstraints
   metadata:
     name: vault-scc
   allowPrivilegedContainer: true
   runAsUser:
     type: RunAsAny
   seLinuxContext:
     type: RunAsAny
   users:
     - system:serviceaccount:vault:vault-sa
   volumes:
     - persistentVolumeClaim
   EOF
   oc adm policy add-scc-to-user vault-scs -n vault -z vault-sa
   ```

2. **Image Pull Secrets**: If using a private registry, add imagePullSecrets to the ServiceAccount.

3. **Route Hostname**: Make sure your DNS is configured for the hostname you set in the overlay.

4. **cert-manager**: The TLS component assumes cert-manager is installed. For OpenShift, you can use the built-in certificate management or install cert-manager.