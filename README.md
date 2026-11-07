# ![bpytop](Imgs/logo.png)

![Linux](https://img.shields.io/badge/-Linux-grey?logo=linux)
![OSX](https://img.shields.io/badge/-OSX-black?logo=apple)
![FreeBSD](https://img.shields.io/badge/-FreeBSD-red?logo=freebsd)
![Python](https://img.shields.io/badge/Python-v3.7%5E-green?logo=python)
![GPU](https://img.shields.io/badge/GPU-NVIDIA%20%7C%20Apple%20Silicon-76b900)

> **`gpytop`** — a fork of the original open-source [bpytop](https://github.com/aristocratos/bpytop)
> resource monitor, with an added **GPU monitoring** box (utilization + memory) for
> NVIDIA and Apple Silicon GPUs. Everything from upstream bpytop still works; this fork
> only adds the GPU support and an installable `gpytop` command.

## Index

* [Installation](#installation)
* [What's different in this fork](#whats-different-in-this-fork)
* [GPU monitoring](#gpu-monitoring)
* [Usage](#usage)
* [Screenshots](#screenshots)
* [Dependencies](#dependencies)
* [Credits and license](#credits-and-license)

## Installation

One command installs the dependencies and the `gpytop` terminal command. It auto-detects
an NVIDIA GPU and enables NVIDIA support when present:

``` bash
curl -fsSL https://raw.githubusercontent.com/TimothyGeissler/bpytop-gpu/master/install.sh | bash
```

Then run it from anywhere:

``` bash
gpytop
```

> If `gpytop` isn't found afterwards, restart your shell or run `pipx ensurepath`
> (for pip `--user` installs, make sure `~/.local/bin` is on your `PATH`).

<details>
<summary>Manual installation from a local clone</summary>

Recommended (isolated, automatically puts the command on your `PATH`):

``` bash
pipx install ".[nvidia]"
```

Or with plain pip (use `--user` to avoid needing sudo):

``` bash
pip3 install --user ".[nvidia]"
```

* On **Apple Silicon** or any non-NVIDIA system, drop the extra: `pipx install .`
* For development (tracks edits to the repo): `pip3 install -e ".[nvidia]"`

You can also run it directly without installing:

``` bash
pip3 install -r requirements.txt
python3 bpytop.py
```

</details>

### Uninstall

``` bash
pipx uninstall gpytop          # if installed with pipx
pip3 uninstall gpytop          # if installed with pip
```

The config file at `~/.config/bpytop/` is left in place; remove it manually to fully clean up.

## What's different in this fork

* Adds a **GPU box** (box number `5`) showing GPU utilization and memory usage.
* Pluggable GPU backends, auto-detected at startup:
  * **NVIDIA** through NVML (the `nvidia-ml-py` package).
  * **Apple Silicon** through `ioreg` (no extra dependencies, no root required).
* The **memory box** subsections now partition the on-device total — `Used` / `Free` /
  `Buffers` / `Cached` add up to exactly `Total` — replacing upstream's overlapping
  `Used` / `Available` / `Cached` / `Free` set, whose percentages summed to well over 100%.
* Adds an installable `gpytop` console command.
* `gpu` is accepted everywhere a box name is, e.g. `shown_boxes` and `gpytop -b "cpu gpu mem proc"`.

All other functionality (CPU, disks, network, processes, themes, menus) is unchanged from
upstream bpytop.

## GPU monitoring

The GPU box is **hidden by default**. Enable it in any of these ways:

* Press `5` while running to toggle the GPU box.
* Add `gpu` to `shown_boxes` from the options menu, or in `~/.config/bpytop/bpytop.conf`.
* Start with it shown: `gpytop -b "cpu gpu mem proc"`.

Behavior:

* The first available backend wins (NVIDIA, then Apple Silicon).
* On Apple Silicon, memory is reported from the unified memory pool.
* On NVIDIA unified-memory SoCs such as the GB10 on the DGX Spark, per-device VRAM
  (`nvmlDeviceGetMemoryInfo`) is not supported; memory is reported as the sum of the
  per-process GPU allocations over the shared unified-memory pool, and utilization,
  temperature and power are still shown from NVML.
* Optional fields (temperature, power) are shown when the backend exposes them; a single
  unavailable metric never blanks out the metrics that do work.
* Multi-GPU systems currently display the first GPU.
* If no supported GPU is found, the box shows a **"No supported GPU detected"** message.

## Usage

Run `gpytop` and use the keys below (all highlighted keys are also clickable with the mouse):

| Key                | Action                                              |
| ------------------ | --------------------------------------------------- |
| `Esc`, `M`         | Open / close the main menu                          |
| `o`, `F2`          | Options menu (change any setting)                   |
| `h`, `F1`          | Help menu                                           |
| `q`, `Ctrl-C`      | Quit                                                |
| `1` `2` `3` `4` `5`| Toggle the CPU / MEM / NET / PROC / **GPU** boxes   |
| `m`                | Cycle through box layout presets                    |
| `+` / `-`          | Increase / decrease the update interval (100 ms)    |
| `Up` `Down`, `j` `k`| Select a process                                   |
| `Enter`            | Show detailed stats for the selected process        |
| `f`                | Filter the process list                             |
| `t` `k` `i`        | Send SIGTERM / SIGKILL / SIGINT to selected process |

All options are configurable from within the UI; settings are stored in
`~/.config/bpytop/bpytop.conf`. See `gpytop --help` for command-line options.

## Screenshots

Main UI (showing details for a selected process):

![Main UI](Imgs/main.png)

Mini mode:

![Mini mode](Imgs/mini.png)

Main menu:

![Main menu](Imgs/menu.png)

Options menu:

![Options menu](Imgs/options.png)

## Dependencies

* **[Python](https://www.python.org/downloads/)** 3.7 or later
* **[psutil](https://github.com/giampaolo/psutil)** 5.7.0 or later (installed automatically)
* **[nvidia-ml-py](https://pypi.org/project/nvidia-ml-py/)** — optional, for NVIDIA GPU
  monitoring (installed via the `[nvidia]` extra). Provides the `pynvml` module.

For correct rendering you need a terminal with 24-bit truecolor and a UTF-8 locale with a
font that covers Braille, Geometric Shapes and Box Drawing characters. See the
[upstream notes](https://github.com/aristocratos/bpytop#prerequisites) if the graphs
don't render correctly.

## Credits and license

This is a fork of [**bpytop**](https://github.com/aristocratos/bpytop) by
[Aristocratos](https://github.com/aristocratos), itself a continuation of
[bashtop](https://github.com/aristocratos/bashtop). All credit for the original program
goes to the upstream authors. This fork only adds GPU monitoring support.

Licensed under the [Apache License 2.0](LICENSE), same as the original project.
