# agent/ — agent documents

Documents produced or maintained by an AI coding agent working on this repo (bpytop-gpu).
This is a workspace for the agent's own knowledge, not part of the shipped `bpytop.py`.
Treat it as reviewable, human-readable notes: safe to edit, safe to delete.

## Layout

```
agent/
├── README.md                     # this file — index and conventions
├── skills/                       # reusable procedural knowledge (agent skills)
│   └── nvidia-gpu-monitoring/
│       ├── SKILL.md              # how to read/fix NVIDIA GPU stats via NVML (pynvml)
│       └── references/
│           └── nvml-capabilities.md  # NVML probe + per-GPU-class capability table + recipes
├── knowledge/                    # project-specific findings, diagnosis, decisions
│   └── dgx-spark-gb10-gpu-monitoring.md   # why GPU monitoring was broken on DGX Spark, the fix, verification
└── readme-addendums/             # standalone records of README changes + rationale
    └── dgx-spark-gpu.md          # the DGX Spark / GB10 README bullet + why
```

## What goes where

- **skills/** — *reusable* how-tos that apply beyond this repo. These mirror the agent's
  installed skills (kept in sync here as a repo-local, reviewable copy). A `SKILL.md`
  front-matter block plus optional `references/`, `scripts/`, `templates/`, `assets/`.
- **knowledge/** — *this project's* reasoning: root-cause analysis, environment facts
  (which GPU / driver / OS), decisions and their rationale, verification steps and
  results. One file per topic; prefer updating an existing file over adding near-duplicates.
- **readme-addendums/** — a copy of each README.md change with the rationale, so the
  "why" is preserved even if the README wording later changes.

## Conventions

- Plain Markdown, dated where relevant, and grounded in what was actually observed or
  run on a real host — not speculation.
- Keep secrets out of this directory (credentials, keys, tokens).
- If a `skills/` file changes here, keep the installed skill
  (`~/.hermes/skills/<name>/`) and this copy consistent, or note the drift.
