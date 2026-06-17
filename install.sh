#!/usr/bin/env bash
#
# gpytop installer — a fork of bpytop with GPU monitoring support.
# Installs the `gpytop` command (and its dependencies) directly from GitHub.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/TimothyGeissler/bpytop-gpu/master/install.sh | bash
#
set -euo pipefail

REPO_URL="https://github.com/TimothyGeissler/bpytop-gpu.git"
BRANCH="master"

# Automatically enable NVIDIA support when an NVIDIA driver is present.
EXTRA=""
if command -v nvidia-smi >/dev/null 2>&1; then
	echo "NVIDIA GPU detected — installing with NVIDIA (NVML) support."
	EXTRA="[nvidia]"
else
	echo "No NVIDIA GPU detected — installing base version (Apple Silicon uses the built-in backend)."
fi

SPEC="gpytop${EXTRA} @ git+${REPO_URL}@${BRANCH}"

if command -v pipx >/dev/null 2>&1; then
	echo "Installing with pipx..."
	pipx install --force "${SPEC}"
	pipx ensurepath >/dev/null 2>&1 || true
elif command -v python3 >/dev/null 2>&1; then
	echo "pipx not found — installing with 'pip --user'..."
	python3 -m pip install --user --upgrade "${SPEC}"
else
	echo "Error: this installer needs either pipx, or python3 with pip." >&2
	exit 1
fi

echo
echo "Done. Run 'gpytop' to start."
echo "(If the command isn't found, restart your shell or run 'pipx ensurepath'.)"
