# ---- STAGE 1: COMPILATION MATRIX ----
FROM quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:821875b1cc5d890626112736088d7e33c40900683045e027dc9af32d47fdd437 AS builder

WORKDIR /build

COPY src/ ./src/
COPY Makefile .

# 1. Fix PDE_DATA removal backport in RHEL 9
RUN sed -i 's/PDE_DATA/pde_data/g' src/r8125_n.c

# 2. Delete the unpatched ringparam and EEE operations from the ethtool structure
RUN sed -i '/\.get_ringparam/d' src/r8125_n.c && \
    sed -i '/\.set_ringparam/d' src/r8125_n.c && \
    sed -i '/\.get_eee/d' src/r8125_n.c && \
    sed -i '/\.set_eee/d' src/r8125_n.c

# 3. Strip out the 4th argument (weight) from the core NAPI configuration macro
RUN sed -i '/#define RTL_NAPI_CONFIG/c\#define RTL_NAPI_CONFIG(ndev, priv, function, weight) netif_napi_add(ndev, \&priv->napi, function)' src/r8125.h

# 4. Locate the exact embedded cluster kernel directory path headers and compile
RUN KERNEL_DIR=$(ls /usr/src/kernels/ | head -n 1) && \
    make -C /usr/src/kernels/${KERNEL_DIR} M=$(pwd)/src modules


# ---- STAGE 2: CREATE LIGHTWEIGHT RUNTIME IMAGE ----
# FIX: Use the builder image hash you already have locally to bypass the internet lookup error
FROM quay.io/openshift-release-dev/ocp-v4.0-art-dev@sha256:821875b1cc5d890626112736088d7e33c40900683045e027dc9af32d47fdd437

# The Kernel Module Management (KMM) operator requires this exact path layout
WORKDIR /lib/modules

# Extract only the final compiled network driver binary file
COPY --from=builder /build/src/r8125.ko .
