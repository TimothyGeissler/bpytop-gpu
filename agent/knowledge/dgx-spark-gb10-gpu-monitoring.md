# DGX Spark (NVIDIA GB10) GPU monitoring

Project-specific knowledge for making the GPU box work on the DGX Spark / GB10.
Companion to the reusable procedure in `agent/skills/nvidia-gpu-monitoring/`.

- Date: 2026-11-07
- Host: DGX Spark, NVIDIA **GB10** (Blackwell, `GB20B [GB10]`, unified memory)
- Driver: NVIDIA 580.178.04, CUDA 13.0, NVML library 13.580.178.04
- Runtime: `gpytop` (pipx venv, Python 3.14), `nvidia-ml-py` 12.575.51 (module `pynvml`)

## Symptom

The GPU box showed no statistics on this host — a flat 0% / empty box — even though
`nvidia-smi` clearly reported a live GPU (util, ~60 W, ~63 C) and processes using
tens of GiB of GPU memory (e.g. `llama-server` ~36 GiB).

## Diagnosis

Probed each NVML call the backend relied on, individually, on the live GB10:

| NVML call | Result on GB10 |
|---|---|
| `nvmlDeviceGetUtilizationRates` | **OK** (e.g. 94%) |
| `nvmlDeviceGetTemperature` (GPU) | **OK** (~69 C) |
| `nvmlDeviceGetPowerUsage` | **OK** (~60 W) |
| `nvmlDeviceGetMemoryInfo` (VRAM) | **`NVMLError_NotSupported`** |
| `nvmlDeviceGetFanSpeed` | `NotSupported` |
| `nvmlDeviceGetPowerManagementLimit` | `NotSupported` |
| `nvmlDeviceGetBAR1MemoryInfo` | `NotSupported` |
| `nvmlDeviceGetComputeRunningProcesses` | OK (`pid`, `usedGpuMemory`) |
| `nvmlDeviceGetGraphicsRunningProcesses` | OK (`pid`, `usedGpuMemory`) |

Root cause of the empty box: `NvmlGpuBackend.sample()` wrapped the whole multi-metric
body in a **single** `try/except`. The one `NotSupported` call (`nvmlDeviceGetMemoryInfo`)
made the entire sample return `None`, so utilization/temperature/power — all of which work
fine — were discarded. `GpuCollector._collect()` then bailed on `stats is None`.

The GB10 is a **unified-memory** SoC (128 GiB pool shared CPU+GPU, like Apple Silicon),
so there is no discrete-VRAM denominator: `nvml-smi` itself prints "Memory-Usage: Not
Supported" in the summary, yet the per-process table shows real GPU allocations.

## Fix (in `bpytop.py`, class `NvmlGpuBackend`)

1. **Best-effort per metric.** `sample()` now reads each field in its own `try/except`
   and sets a per-field availability flag; one `NotSupported` call no longer blanks the rest.
2. **Unified-memory fallback** in a new `_memory()` helper:
   - Try `nvmlDeviceGetMemoryInfo` first (correct path for discrete GPUs — no behavior change there).
   - On failure (GB10): `used` = sum of `usedGpuMemory` over the compute + graphics
     running-process lists, **deduped by PID** (a PID can appear in both lists; keep the max).
     This matches `nvidia-smi`'s per-process GPU memory.
   - `total` = the unified pool = `psutil.virtual_memory().total` (same approach the Apple backend uses).
   - `mem_percent = used / total * 100`.

## Verification on this host

- Drove the real `GpuCollector` against the live GPU: util ~95%, memory
  **35.7 GiB / 121.7 GiB (29%)**, temp ~69 C, power ~58 W. Memory matches the
  `nvidia-smi` per-process table (176 MiB + 36315 MiB).
- Ran the TUI in a PTY (`python bpytop.py -b gpu`): GPU box rendered live, updating
  frame-to-frame (util/mem/temp/power + name "NVIDIA GB10"); quit cleanly (exit 0).
- `python -m py_compile bpytop.py` passes; module imports cleanly.

## Running the fixed code

The pipx-installed `gpytop` points at a *copy* in
`~/.local/share/pipx/venvs/gpytop/lib/python3.14/site-packages/bpytop.py`, so it stays
stale until reinstalled. To run the fixed source directly:

```bash
/home/timdg/.local/share/pipx/venvs/gpytop/bin/python /home/timdg/Documents/bpytop-gpu/bpytop.py
# enable the GPU box: add `-b gpu`  (or press `5` while running)
```

To refresh the installed command (only when wanted):

```bash
cd /home/timdg/Documents/bpytop-gpu && pipx install --force ".[nvidia]"
```

## Testing notes (this repo)

- `bpytop.py` calls `argparse.parse_args()` at import time, so `pytest` fails with
  `SystemExit(2)` (pytest's own argv leaks into argparse). This is a harness limit, not a
  regression. Run tests with `sys.argv = ["bpytop"]` set before `import bpytop`, or invoke
  the test functions directly.
- The unit tests do not exercise the GPU backend, so GPU correctness must be verified
  against a live GPU (see Verification above) or the probe in the skill reference.
