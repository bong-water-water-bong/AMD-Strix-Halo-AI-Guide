# AMD Strix Halo AI Guide
## LTX-2, ComfyUI, and TheROCk 7.11 on gfx1151

**I use AMD Strix Halo for AI video generation every day. This repo documents how.**

### Made in Collaboration: Human + AI (Anthropic Claude) Working Together

---

## What This Is

A complete guide to running LTX-2 audio-video generation on AMD Strix Halo APU with 128GB unified memory. 10-second talking videos with synchronized audio in ~10 minutes. No NVIDIA required.

## What's Included

| File | Description |
|------|-------------|
| `README.md` | This guide |
| `comfyui-amd.sh` | Startup script with all environment variables |
| `LTX2-I2V-Minimal.json` | Working ComfyUI workflow |
| `video_types.patch` | Fix for AMD audio saving bug |

## Hardware Tested

- **Device:** GMTEK NUC EVO 2
- **APU:** AMD Strix Halo (gfx1151) - Radeon 8060S Graphics
- **Memory:** 128GB Unified (64GB VRAM / 64GB RAM split)
- **OS:** Ubuntu 25.10

> ⚠️ This guide is for Strix Halo APU (gfx1151) specifically. I haven't tested discrete GPUs.

> 💰 **On NVIDIA's alternative:** The DGX Spark costs roughly **2x** and locks you into NVIDIA's ecosystem. Strix Halo runs standard Linux with no vendor lock-in.

---

## What Works

| Software | Status | Notes |
|----------|--------|-------|
| LTX-2 | ✅ Full | Video + Audio sync, I2V, talking characters |
| Z Turbo | ✅ Works | Fast inference |
| SimpleTuner | ✅ Works | Local LoRA training on APU |
| Hunyuan Video | ✅ Full | Slower but stable |
| Flux | ✅ Full | Fast image generation |
| SDXL | ✅ Full | Fast |

---

## Quick Start

### 1. Install Base ROCm

```bash
wget https://repo.radeon.com/rocm/rocm.gpg.key -O - | sudo apt-key add -
echo 'deb [arch=amd64] https://repo.radeon.com/rocm/apt/latest ubuntu main' | sudo tee /etc/apt/sources.list.d/rocm.list
sudo apt update
sudo apt install rocm-dev rocm-libs
sudo usermod -a -G render,video $USER
sudo reboot
```

### 2. Install CoreCtl (CRITICAL)

APU power management is broken without this. `rocm-smi` leaves the chip throttled.

```bash
sudo apt install corectrl
corectrl  # Set Performance mode for Radeon 8060S
```

### 3. Create Python venv

```bash
sudo apt install python3.11 python3.11-venv python3.11-dev
mkdir -p ~/ComfyUI && cd ~/ComfyUI
python3.11 -m venv venv_rocm711
source venv_rocm711/bin/activate
```

### 4. Install TheROCk Nightly (THE KEY STEP)

**Important:** TheROCk is AMD's official next-generation stack, not a community fork. ROCm is at 7.2. TheROCk started at 7.9, is now at 7.11, and becomes **ROCm 8.0 in March 2026**. The performance difference is dramatic.

```bash
source ~/ComfyUI/venv_rocm711/bin/activate
pip uninstall torch torchvision torchaudio -y
pip install --index-url https://rocm.nightlies.amd.com/v2/gfx1151/ \
    torch torchvision torchaudio --force-reinstall
```

Verify:
```bash
python -c "import torch; print(torch.__version__)"
# Should show: 2.11.0a0+rocm7.11.0a20260106
```

### 5. Install ComfyUI

```bash
cd ~/ComfyUI
git clone https://github.com/comfyanonymous/ComfyUI.git .
pip install -r requirements.txt
cd custom_nodes
git clone https://github.com/ltdrdata/ComfyUI-Manager.git
cd ..
```

### 6. Apply AMD Audio Fix

ComfyUI has a bug where audio tensors don't get moved to CPU before saving. Works on NVIDIA by accident, crashes on AMD.

```bash
sed -i 's/\.float()\.numpy()/.float().cpu().numpy()/g' \
    ~/ComfyUI/comfy_api/latest/_input_impl/video_types.py
```

### 7. Use the Startup Script

```bash
cp comfyui-amd.sh ~/ComfyUI/
chmod +x ~/ComfyUI/comfyui-amd.sh
~/ComfyUI/comfyui-amd.sh
```

---

## Key Environment Variables

| Variable | Value | Why |
|----------|-------|-----|
| `HSA_ENABLE_SDMA=0` | Disable | Prevents GPU hangs on gfx1151 |
| `HSA_USE_SVM=0` | Disable | Fixes VRAM crashes |
| `PYTORCH_HIP_ALLOC_CONF` | See script | Memory fragmentation prevention |
| `TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1` | Enable | Faster attention |

---

## LTX-2 Workflow Tips

**Critical settings in LTXVImgToVideoInplace:**
- `strength: 0.3` - Lower = more natural movement (0.5+ causes frozen poses)

**Prompting structure:**
```
1. Shot + Character description
2. Immediate action + dialogue in quotes
3. "her mouth moves as she speaks" ← CRITICAL
4. Camera direction
5. Timed events: "at 5 seconds she says..."
6. Mood anchor at end
```

---

## Performance

| Metric | Result |
|--------|--------|
| 10-second video + audio | ~10-13 minutes |
| Resolution | 480x832 (portrait) |
| Frames | 121 @ 12fps |
| VRAM usage | ~20GB |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| APU running slow | Install CoreCtl, set Performance mode |
| GPU hangs | `export HSA_ENABLE_SDMA=0` |
| VRAM crashes | `export HSA_USE_SVM=0` |
| No audio in video | Apply the sed fix in step 6 |
| Wrong PyTorch | Verify with `python -c "import torch; print(torch.__version__)"` |

---

## A Message to AMD

The hardware is incredible. 128GB unified memory in a NUC. NVIDIA has nothing comparable at this price without ecosystem lock-in.

What's needed:
1. **Partner with AI companies** - Lightricks, Stability, Hugging Face
2. **Accelerate TheROCk visibility** - Most users don't know it exists
3. **Fix APU power management** - CoreCtl shouldn't be required
4. **Document AI workflows** - HSA_ENABLE_SDMA=0 shouldn't require forum diving

The technology works. I use it daily. The opening is there.

---

## Credits

- **TheROCk team** - Making gfx1151 usable
- **ComfyUI team** - Great software  
- **Lightricks** - Open-sourcing LTX-2
- **AMD community** - Sharing knowledge

---

## License

MIT - Use freely, attribution appreciated.

---

**Tested:** January 2026 | **Hardware:** GMTEK NUC EVO 2, Strix Halo, 128GB | **OS:** Ubuntu 25.10

*This is what I actually run. Every day. For real work.*
