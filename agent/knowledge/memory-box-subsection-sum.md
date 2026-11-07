# Memory box subsections summed to more than the on-device total

- Date: 2026-11-07
- Host: DGX Spark, NVIDIA GB10 (unified memory)
- Scope: the **MEM box** (system memory), not the GPU box

## Symptom

The MEM box showed four subsections whose values/percentages added up to well over the
total on-device memory. On this host the rows summed to ~160% of `Total`:

```
Total:   121 GiB
Used:     52 GiB   (43%)
Available:72 GiB   (57%)
Cached:   28 GiB   (24%)
Free:     44 GiB   (36%)
```

## Diagnosis (root cause)

It is **not** a unified-SoC data bug and **not** a fork regression:

* The fork's memory handling is byte-for-byte the same as upstream bpytop
  (`mem_names = ["used","available","cached","free"]`, `used = total - available`).
* `/proc/meminfo` is self-consistent: `MemAvailable` (≈ free + reclaimable) ≥ `MemFree`;
  `used` (as `total - available`) + `available` == `total` exactly.

The real cause is the **row set**: the four rows are *overlapping* metrics, presented as
if they were disjoint slices. `available ≈ free + cached + buffers`, so listing
`used + available + cached + free` double-counts. Their percentages sum to
`(used+available) + (free+cached) ≈ total + available > total`. True on **every** Linux
system — just most visible where `free`/`cached` are large fractions (e.g. a unified SoC).

## Fix

Make the MEM rows a **true partition** of `total`, using the classic `free` breakdown so
they add up to exactly the on-device memory (with `used` as the residual, guaranteeing
the identity holds):

```
used + free + buffers + cached == total
```

Changes (all in `bpytop.py`):
* `MemBox.mem_names` → `["used", "free", "buffers", "cached"]` (drops `available`, which
  overlaps the others).
* `MemCollector._collect()`:
  * `values["buffers"] = getattr(mem, "buffers", 0)` (0 on macOS/BSD).
  * `used = max(0, total - free - buffers - cached)` (residual → the identity holds by
    construction).
  * `values["available"]` is still computed (harmless); it is no longer a displayed row.
* Added a `buffers` gradient so its meter renders:
  * base `Theme.gradient` dict: `"buffers"`.
  * `Theme` class attrs: `buffers_start/mid/end`.
  * `DEFAULT_THEME`: `buffers_start/mid/end` colors (the per-theme fallback that themes
    without `buffers_*` use).

Why "buffers" and not just dropping to 3 rows: keeps the familiar 4-row layout and gives
the standard `free` command breakdown (used / free / buff-cache), which users recognize as
a coherent partition.

## Verification on this host

* Backend: `used + free + buffers + cached == total` **exactly** (121.686 GiB); the four
  row percents sum to 101% (rounding) instead of ~160%.
  - Observed: Used 47.6 GiB (39%), Free 44.5 GiB (37%), Buffers 832 MiB (1%), Cached
    28.6 GiB (24%).
* `buffers` gradient builds cleanly (101 steps) for Default, dracula, and oceanic
  (fallback path for themes that don't define `buffers_*`).
* Real TUI (`python bpytop.py -b mem`): MEM box renders the four coherent rows; meters,
  disks, swap and IO sections all still draw; quit cleanly (exit 0).

## Notes / trade-offs

* `available` is no longer its own row; it is implicitly `free + buffers + cached` (the
  reclaimable part) plus the truly-free part — i.e. still derivable, just not double-counted.
* This is a deviation from upstream bpytop's default MEM layout; it is intentional and
  documented in README.
* `Theme.gradient` is a shared, mutable class-level dict that accumulates if you construct
  multiple `Theme(...)` objects in one process. The app creates one instance (and theme
  switches go through `Theme.__call__`, which resets first), so this is a harness-only
  gotcha, not an app bug.
