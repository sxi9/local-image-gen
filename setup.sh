#!/usr/bin/env bash
# =====================================================================
#  Local image generation — ComfyUI + FLUX.1-schnell.
#  Runs on a host venv with PyTorch cu128 (works on Blackwell / sm_120),
#  downloads the ungated FLUX.1-schnell fp8 checkpoint, and exposes the
#  UI with a public URL via a Cloudflare quick tunnel. Idempotent.
#
#  Usage:   bash setup.sh
# =====================================================================
set -euo pipefail

WS="${WORKSPACE:-$HOME/workspace}"
DIR="$WS/ComfyUI"
VENV="$WS/comfyui-venv"
CKPT_DIR="$DIR/models/checkpoints"
MODEL_FILE="flux1-schnell-fp8.safetensors"
MODEL_URL="https://huggingface.co/Comfy-Org/flux1-schnell/resolve/main/$MODEL_FILE"
PORT=8188

sudo apt-get update -qq 2>/dev/null || true
sudo apt-get install -y -qq git python3-venv 2>/dev/null || true

# ---------- 1. venv + PyTorch (cu128, Blackwell-compatible) ----------
[ -d "$VENV" ] || python3 -m venv "$VENV"
# shellcheck disable=SC1091
source "$VENV/bin/activate"
python -c "import torch" 2>/dev/null || pip install -q torch torchvision --index-url https://download.pytorch.org/whl/cu128

# ---------- 2. ComfyUI ----------
[ -d "$DIR/.git" ] || git clone https://github.com/comfyanonymous/ComfyUI "$DIR"
pip install -q -r "$DIR/requirements.txt"

# ---------- 3. model (download only if missing) ----------
mkdir -p "$CKPT_DIR"
if [ -f "$CKPT_DIR/$MODEL_FILE" ]; then
  echo "[=] $MODEL_FILE already present"
else
  echo "[*] Downloading FLUX.1-schnell fp8 (~17GB, one-time)..."
  curl -L "$MODEL_URL" -o "$CKPT_DIR/$MODEL_FILE"
fi

# ---------- 4. launch ComfyUI ----------
fuser -k ${PORT}/tcp 2>/dev/null || true; sleep 2
cd "$DIR"
setsid nohup python main.py --listen 0.0.0.0 --port $PORT > "$WS/comfyui.log" 2>&1 < /dev/null &
echo "[*] ComfyUI starting on :$PORT ..."

# ---------- 5. public URL via Cloudflare quick tunnel ----------
CF="$(command -v cloudflared || echo "$HOME/cloudflared")"
if [ ! -x "$CF" ]; then
  curl -sL https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o "$HOME/cloudflared"
  chmod +x "$HOME/cloudflared"; CF="$HOME/cloudflared"
fi
pkill -f "cloudflared tunnel --url http://localhost:$PORT" 2>/dev/null || true
setsid nohup "$CF" tunnel --url http://localhost:$PORT --no-autoupdate > "$WS/comfyui-tunnel.log" 2>&1 < /dev/null &
for i in $(seq 1 25); do
  U=$(grep -oE "https://[a-z0-9-]+\.trycloudflare\.com" "$WS/comfyui-tunnel.log" | head -1)
  if [ -n "$U" ]; then PUBLIC="$U"; break; fi
  sleep 3
done

echo ""
echo "============================================================"
echo "  ComfyUI (local):  http://localhost:$PORT"
[ -n "${PUBLIC:-}" ] && echo "  ComfyUI (public): $PUBLIC" || echo "  tunnel: see $WS/comfyui-tunnel.log"
echo "  Model: FLUX.1-schnell (in models/checkpoints)"
echo "============================================================"
echo "[+] In the UI: Workflow -> Browse Templates -> Flux -> 'Flux Schnell', type a prompt, Queue."
