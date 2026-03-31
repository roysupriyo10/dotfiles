#!/bin/bash
# NVIDIA hybrid graphics — Intel iGPU drives display, dGPU sleeps until prime-run

# Force Wayland compositor to use Mesa/Intel for EGL and GLX
# Without these, sway probes the NVIDIA GPU on startup and wakes it from D3
export __EGL_VENDOR_LIBRARY_FILENAMES=/usr/share/glvnd/egl_vendor.d/50_mesa.json
export __GLX_VENDOR_LIBRARY_NAME=mesa

# VA-API hardware video decode via NVIDIA (active only under prime-run)
export NVD_BACKEND=direct
export LIBVA_DRIVER_NAME=nvidia
