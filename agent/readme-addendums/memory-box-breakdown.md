# README addendum — memory box breakdown (subsections sum to Total)

Record of the README change made so the MEM box subsections are coherent. Applied:
2026-11-07.

## What was changed in `README.md`

In the **What's different in this fork** section, a bullet was added and the "unchanged"
line was corrected (memory is no longer "unchanged" because the MEM box layout changed):

```markdown
* The **memory box** subsections now partition the on-device total — `Used` / `Free` /
  `Buffers` / `Cached` add up to exactly `Total` — replacing upstream's overlapping
  `Used` / `Available` / `Cached` / `Free` set, whose percentages summed to well over 100%.

All other functionality (CPU, disks, network, processes, themes, menus) is unchanged from
upstream bpytop.
```

(Previously: "All other functionality (CPU, **memory**, disks, ...) is unchanged from
upstream bpytop.")

## Rationale

The upstream MEM box shows four *overlapping* metrics (used, available, cached, free).
`available ≈ free + cached + buffers`, so those four sum to well over 100% of `Total` —
this is true on every Linux system, not just unified-memory SoCs. This fork instead shows
the classic `free` breakdown (`used + free + buffers + cached == total`) so the subsections
add up to the on-device total. See `../knowledge/memory-box-subsection-sum.md` for the full
diagnosis and the code changes (including the new `buffers` gradient).
