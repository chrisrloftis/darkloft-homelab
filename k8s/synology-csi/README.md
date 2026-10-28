# Synology OpenSource CSI

<https://github.com/SynologyOpenSource/synology-csi/tree/main>

- NFS StorageClass Installed
- SMB StorageClass Installed
- Smoke Test Passed

# Manual Step

Until Vault is up/running, need to manually seed the 'synology-csi-config-secret' before the deployments will come online

```
oc create secret -n synology-csi generic synology-csi-config-secret --from-file=./client-info.yml
```

Format for 'client-info.yml' - See here for more info <https://github.com/SynologyOpenSource/synology-csi#creating-a-secret>

```
clients:
- host: 192.168.1.1
  port: 5000
  https: false
  username: <username>
  password: <password>
- host: 192.168.1.2
  port: 5001
  https: true
  username: <username>
  password: <password>
  tlsCACert: |
    -----BEGIN CERTIFICATE-----
    <DSM self-signed certificate PEM>
    -----END CERTIFICATE-----
```
