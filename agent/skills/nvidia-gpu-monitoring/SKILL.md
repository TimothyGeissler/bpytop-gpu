---
name: nvidia-gpu-monitoring
description: "Read & fix NVIDIA GPU stats via NVML (pynvml)"
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [nvidia, gpu, nvml, pynvml, dgx, spark, gb10, monitoring, psutil]
    related_skills: [systematic-debugging, codebase-inspection]
---

# NVIDIA GPU Monitoring (NVML / pynvml)

Reading or fixing GPU utilization / memory / temperature / power from NVML (pynvml).

## When to Use

- A GPU stat is missing, zero, or wrong on a specific host ("no statistics", "box shows nothing").
- You are adding or fixing a GPU box/backend in a resource monitor (bpytop, gpytop, custom).
- You need to know which NVML calls a given GPU/SoC actually supports before writing or debugging code.

## Core rule: capability varies by GPU class

NVML returns `NVMLError_NotSupported` (or similar) for calls the silicon does not implement. Discrete GPUs and unified-memory SoCs are DIFFERENT: a field can work on one and be NotSupported on the other. Never assume a call set that worked on a discrete card works on the target — probe the target.

## Procedure

### 1. Establish ground truth on the target host first

```bash
nvidia-smi                        # human view: util, mem, temp, power, per-process GPU memory
lspci | grep -iE 'vga|3d|nvidia'  # GPU model / SoC (e.g. GB10, GB20B, H100)
```

Note anything nvidia-smi itself prints as "Not Supported" / "N/A" — those are your NotSupported candidates.

### 2. Probe every NVML call the code (or you) relies on, individually

Run a tiny probe that calls each function and reports OK vs FAIL + the exception. This is the red-capable loop: it names exactly which calls the target supports. Use `scripts/probe_nvml.py` or the inline version in `references/nvml-capabilities.md`.

### 3. Make each metric independent (best-effort)

**PITFALL — do not wrap a whole multi-metric sample in one try/except.** If one call is NotSupported, the whole sample returns None and every working metric is lost (the box shows nothing, not partial data). Wrap each field in its own try/except and set a per-field availability flag (`has_temp`, `has_power`, ...). A field that cannot be read stays default/hidden; the rest still render.

### 4. Memory on unified-memory SoCs (DGX Spark / GB10, GB20B)

`nvmlDeviceGetMemoryInfo` is NotSupported here — the GPU shares one pool with the CPU. Fallback, in order:
1. **Per-process allocation table**: sum `usedGpuMemory` from `nvmlDeviceGetComputeRunningProcesses(h)` + `nvmlDeviceGetGraphicsRunningProcesses(h)`. **Dedupe by PID** (a PID can appear in both lists); keep the max per PID. This matches nvidia-smi's per-process GPU memory.
2. **Total** = the unified pool = `psutil.virtual_memory().total` (the approach Apple-Silicon monitors use).
3. `mem_percent = used / total * 100`.

pynvml returns `nvmlFriendlyObject` with attrs `pid` and `usedGpuMemory` (not `.type`). Guard each getter — one can be NotSupported while the other works.

### 5. Verify end-to-end

- **Data path**: drive the real collector/backend against the live GPU and assert util/mem/temp/power are populated (not just "didn't crash").
- **Render path (TUI)**: run the app in a PTY in the background, wait ~2s for a couple of samples, poll the log, strip ANSI, check the rendered box shows the numbers + GPU name; then send `q`.
- **Cross-check** your computed memory against `nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader,nounits`.

## Testing pitfalls

- **A module that calls `argparse.parse_args()` at import time breaks pytest** (pytest's own argv leaks in → SystemExit 2). Run the tests via a manual runner that sets `sys.argv = ["progname"]` before `import`, or run the test functions directly. This is a harness limit, not your bug.
- TUI apps need a real terminal size; below 80x24 the menu/box code can refuse to render. Use a PTY.
- **Test the code you edited, not the installed copy.** If a pipx/pip-installed copy in site-packages is stale, import by path (`sys.path.insert(0, repo_dir)`) or run `python repo/app.py` with an interpreter that has the deps (psutil, nvidia-ml-py). Reinstalling the installed command is a separate, later step.

## See also

- `references/nvml-capabilities.md` — standard probe, per-GPU-class capability table, and the unified-memory memory recipe.
