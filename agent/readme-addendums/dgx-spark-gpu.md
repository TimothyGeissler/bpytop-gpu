# README addendum — DGX Spark / NVIDIA GB10 GPU monitoring

Standalone record of the README documentation added for DGX Spark (GB10) support.
The matching text is already merged into `README.md` under the **GPU monitoring**
section (the `Behavior:` list). Kept here as a reviewable addendum and to explain the
rationale.

Applied: 2026-11-07

## What was added to `README.md`

Two bullets were added to the `Behavior:` list under **GPU monitoring**:

```markdown
* On NVIDIA unified-memory SoCs such as the GB10 on the DGX Spark, per-device VRAM
  (`nvmlDeviceGetMemoryInfo`) is not supported; memory is reported as the sum of the
  per-process GPU allocations over the shared unified-memory pool, and utilization,
  temperature and power are still shown from NVML.
* Optional fields (temperature, power) are shown when the backend exposes them; a single
  unavailable metric never blanks out the metrics that do work.
```

(The second bullet also replaces the previous, more generic
"Optional fields (temperature, power) are shown when the backend exposes them." line.)

## Rationale

- The DGX Spark is a **unified-memory** SoC; `nvmlDeviceGetMemoryInfo` returns
  `NVMLError_NotSupported`. Memory therefore cannot be shown as "used / total VRAM".
  We report it as *GPU-process allocations over the shared pool*, which is honest and
  matches `nvidia-smi`'s per-process table.
- Utilization, temperature and power **are** supported on the GB10 and must keep working;
  the box must degrade gracefully rather than go blank when one NVML call is unavailable.

## Optional follow-up (not yet done)

- The badge at the top of `README.md` reads `GPU-NVIDIA | Apple Silicon`. Consider adding
  "DGX Spark / GB10" once we want it surfaced more prominently.
- If a multi-GPU DGX Spark ever appears, note the current "first GPU only" limitation
  still applies.
