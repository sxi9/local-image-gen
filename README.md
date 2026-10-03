# Local Image Generation — ComfyUI + FLUX.1

Self-hosted, high-quality **AI image generation** on your own GPU, with a web UI and a public share link.
No API keys, no per-image cost, no content filter — it runs **FLUX.1-schnell**, a state-of-the-art open
image model, locally.

Built and tested on an **NVIDIA RTX PRO 6000 Blackwell (96 GB)** with CUDA 13 / driver 580.

## What you get

- **ComfyUI** — the most capable node-based Stable-Diffusion / FLUX interface
- **FLUX.1-schnell** — SOTA open image model (Apache-2.0, ungated), as a single all-in-one fp8 checkpoint
- **PyTorch cu128** on a host venv — works on **Blackwell (sm_120)**, where older CUDA builds fail
- A **public URL** via a Cloudflare quick tunnel (no account needed)
- One idempotent script: `bash setup.sh`

## Requirements

- Linux host with an NVIDIA GPU (12 GB+ VRAM; 24 GB+ comfortable for FLUX)
- NVIDIA driver recent enough for CUDA 12.8 runtime (e.g. 570+/580)
- ~20 GB free disk for the model

## Quick start

```bash
git clone https://github.com/<you>/local-image-gen.git
cd local-image-gen
bash setup.sh
```

It creates a venv with PyTorch cu128, installs ComfyUI, downloads the FLUX.1-schnell checkpoint (one-time),
launches ComfyUI on port 8188, and prints a public `trycloudflare.com` URL.

**To generate:** open the URL → *Workflow → Browse Templates → Flux → "Flux Schnell"* → type a prompt →
click **Queue**. FLUX.1-schnell produces great results in just 4 steps, so images are fast.

## Why this stack

| Choice | Reason |
|---|---|
| ComfyUI | Most powerful + flexible; FLUX/SDXL/SD3 support, templates built in |
| FLUX.1-schnell | Best ungated open image model; Apache-2.0; 4-step fast generation |
| fp8 single-file checkpoint | Loads in the standard checkpoint node — no separate CLIP/T5/VAE wiring |
| Host venv + torch cu128 | Only reliable way to drive a Blackwell GPU (sm_120) today |
| Cloudflare quick tunnel | Public URL without opening firewall ports |

## Swapping models

Drop any `.safetensors` checkpoint into `ComfyUI/models/checkpoints/` and pick it in the Load Checkpoint
node. SDXL community checkpoints (Juggernaut XL, RealVisXL) work too and are lighter (~7 GB).

## Responsible use

For lawful use only. A locally-run, unfiltered image model can produce content hosted services block — you
are responsible for complying with applicable laws, the model licenses, and not generating content that
depicts real people without consent or that is otherwise illegal or harmful.
