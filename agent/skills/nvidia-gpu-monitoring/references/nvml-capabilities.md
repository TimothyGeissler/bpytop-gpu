# NVML capability notes & recipes

Reference for reading NVIDIA GPU stats via pynvml. Companion to SKILL.md. All calls below are on device handle `h = pynvml.nvmlDeviceGetHandleByIndex(0)` after `pynvml.nvmlInit()`.

## Capability by GPU class (observed)

| NVML call | Discrete GPU (e.g. H100) | Unified-memory SoC (DGX Spark GB10 / GB20B) |
|---|---|---|
| `nvmlDeviceGetUtilizationRates` | OK | OK |
| `nvmlDeviceGetMemoryInfo` (VRAM) | OK | **NotSupported** |
| `nvmlDeviceGetTemperature` (GPU) | OK | OK |
| `nvmlDeviceGetPowerUsage` | OK | OK |
| `nvmlDeviceGetFanSpeed` | OK | **NotSupported** |
| `nvmlDeviceGetPowerManagementLimit` | OK | **NotSupported** |
| `nvmlDeviceGetComputeRunningProcesses` | OK | OK (attrs: `pid`, `usedGpuMemory`) |
| `nvmlDeviceGetGraphicsRunningProcesses` | OK | OK (attrs: `pid`, `usedGpuMemory`) |
| `nvmlDeviceGetBAR1MemoryInfo` | OK | **NotSupported** |

Rule: capability is a property of the silicon, not the driver. Always probe the target (SKILL.md step 2) rather than trusting this table as complete — new silicon may differ.

## Standard capability probe

```python
import pynvml
pynvml.nvmlInit()
h = pynvml.nvmlDeviceGetHandleByIndex(0)
name = pynvml.nvmlDeviceGetName(h)
print("GPU:", (name.decode() if isinstance(name, bytes) else name))

def probe(label, fn):
    try: print(f"OK   {label}: {fn()!r}")
    except Exception as e: print(f"FAIL {label}: {type(e).__name__}: {e}")

probe("util  ", lambda: (lambda u: (u.gpu, u.memory))(pynvml.nvmlDeviceGetUtilizationRates(h)))
probe("mem   ", lambda: (lambda m: (m.used, m.total, m.free))(pynvml.nvmlDeviceGetMemoryInfo(h)))
probe("temp  ", lambda: pynvml.nvmlDeviceGetTemperature(h, pynvml.NVML_TEMPERATURE_GPU))
probe("power ", lambda: pynvml.nvmlDeviceGetPowerUsage(h))
probe("fan   ", lambda: pynvml.nvmlDeviceGetFanSpeed(h))
probe("pwrLim", lambda: pynvml.nvmlDeviceGetPowerManagementLimit(h))
for g in ("nvmlDeviceGetComputeRunningProcesses", "nvmlDeviceGetGraphicsRunningProcesses"):
    if hasattr(pynvml, g):
        probe(g, lambda: [getattr(p, "usedGpuMemory") for p in getattr(pynvml, g)(h)])
    else:
        print(f"MISSING {g}: not in this pynvml build")
```

## Unified-memory (GB10 / DGX Spark) memory recipe

```python
import pynvml, psutil

def gpu_memory(handle):
    # 1) discrete VRAM if the silicon supports it
    try:
        m = pynvml.nvmlDeviceGetMemoryInfo(handle)
        return int(m.used), int(m.total)
    except Exception:
        pass
    # 2) unified-memory SoC: sum per-process GPU allocations, dedupe by PID
    per_pid = {}
    for g in (pynvml.nvmlDeviceGetComputeRunningProcesses,
              pynvml.nvmlDeviceGetGraphicsRunningProcesses):
        try:
            for p in g(handle):
                per_pid[p.pid] = max(per_pid.get(p.pid, 0), int(p.usedGpuMemory))
        except Exception:
            pass
    used = sum(per_pid.values())
    total = int(psutil.virtual_memory().total)  # the shared pool
    return used, total
```

Notes:
- A single PID can appear in BOTH compute and graphics lists; dedupe by PID (max) to avoid double counting.
- `total` = unified pool = system RAM. The percentage is "fraction of the pool allocated to GPU processes" — a reasonable, honest metric; there is no discrete-VRAM denominator on this class of silicon.
- Cross-check: `nvidia-smi --query-compute-apps=pid,used_memory --format=csv,noheader,nounits`.

## Sampler design (best-effort)

```python
class GpuStats:
    def __init__(self):
        self.utilization = 0; self.mem_used = 0; self.mem_total = 0
        self.mem_percent = 0; self.temp = -1; self.power = -1
        self.has_temp = False; self.has_power = False

def sample(handle):
    st = GpuStats()
    try: st.utilization = int(pynvml.nvmlDeviceGetUtilizationRates(handle).gpu)
    except Exception: pass
    try:
        st.mem_used, st.mem_total = gpu_memory(handle)
        st.mem_percent = round(st.mem_used / st.mem_total * 100) if st.mem_total else 0
    except Exception: pass
    try: st.temp = int(pynvml.nvmlDeviceGetTemperature(handle, pynvml.NVML_TEMPERATURE_GPU)); st.has_temp = True
    except Exception: pass
    try: st.power = round(pynvml.nvmlDeviceGetPowerUsage(handle) / 1000); st.has_power = True
    except Exception: pass
    return st
```

One try/except per metric. Never one wrapper around the whole thing.
