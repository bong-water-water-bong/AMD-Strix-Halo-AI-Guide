#!/bin/bash
# === AMD Strix Halo APU (gfx1151) | ComfyUI Launcher ===
# Tested: LTX-2, Z Turbo, SimpleTuner, Hunyuan, Flux, SDXL
# Hardware: Strix Halo 128GB Unified Memory
# 
# IMPORTANT: Run CoreCtl first and set Performance mode!
# sudo apt install corectrl && corectrl

# 1. Kill existing ComfyUI
pkill -f "ComfyUI/main.py"

# 2. Clear environment conflicts
unset TRITON_PTXAS_PATH
unset LLVM_SYSPATH
unset HSA_OVERRIDE_GFX_VERSION

# 3. Activate venv (adjust path if needed)
cd ~/ComfyUI
source ./venv_rocm711/bin/activate

echo "🚀 Launching ComfyUI [gfx1151 | Strix Halo APU]..."
echo "⚠️  Make sure CoreCtl is running with Performance mode!"

# 4. ROCm Paths
export HIP_VISIBLE_DEVICES=0
export ROCM_PATH=/opt/rocm
export PATH=$PATH:/opt/rocm/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/rocm/lib

# 5. CRITICAL: Strix Halo APU Fixes (without these you WILL crash)
export HSA_ENABLE_SDMA=0      # Fixes GPU hangs
export HSA_USE_SVM=0          # Fixes memory crashes

# 6. Memory Management
export PYTORCH_HIP_ALLOC_CONF="backend:native,expandable_segments:True,garbage_collection_threshold:0.7,max_split_size_mb:256"

# 7. Torch Inductor Cache
export TORCHINDUCTOR_CACHE_DIR="$HOME/.cache/torch_inductor_comfy"
export TORCHINDUCTOR_FX_GRAPH_CACHE=1
export TORCH_COMPILE_DEBUG=0

# 8. Experimental AMD Optimizations
export TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1

# 9. Python Memory Management
export PYTHONMALLOC=malloc
export MALLOC_TRIM_THRESHOLD_=100000

# 10. Launch
python main.py \
    --listen 0.0.0.0 \
    --port 8189 \
    --gpu-only \
    --disable-smart-memory

# Note: If OOM crashes occur, try --lowvram instead of --gpu-only
