# Vault HA configuration using Raft storage
# Top-level configurations
disable_mlock = true
ui            = true

listener "tcp" {
  address       = "0.0.0.0:8200"
  cluster_address = ":8201"
  tls_disable   = true
}

storage "raft" {
  path = "/vault/data"
}

# Service discovery and auto-unseal
seal "raft" {
}

log_level = "info"

# API address configuration for Raft peers
api_addr = "http://$HOSTNAME.vault-internal:8200"