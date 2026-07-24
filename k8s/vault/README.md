# HashiCorp Vault on OpenShift (Homelab)

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