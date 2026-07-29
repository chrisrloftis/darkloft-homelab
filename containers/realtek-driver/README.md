# Instructions

```bash
## 1. Clean out old attempts and establish a isolated repository folder context
cd cd ~/containers/realtek-driver/
rm -rf ./realtek-driver-context
git clone <https://github.com/awesometic/realtek-r8125-dkms.git> ./realtek-driver-context
cd ./realtek-driver-context

## 2. Apply the RHEL 9 function renaming patch via macOS-compliant syntax parameters

sed -i '' 's/netif_set_gso_max_size/netif_set_tso_max_size/g' src/r8125_n.c

## 3. Apply the NAPI macro override using a structural block rewrite pattern

sed -i '' 's/#define RTL_NAPI_CONFIG(ndev, priv, function, weight)   netif_napi_add(ndev, \&priv->napi,function, weight)/#define RTL_NAPI_CONFIG(ndev, priv, function, weight) netif_napi_add(ndev, \&priv->napi, function)/g' src/r8125.h

## 4. Build Image 
tar -cf - Containerfile src Makefile | podman build \
    --no-cache \
    --authfile <authfile.json> \
    --platform linux/amd64 \
    -t realtek-driver:latest \
    -t realtek-driver:v0.0.1 \
    -f ./../realtek.containerfile -
```
