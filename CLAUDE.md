# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

A collection of scripts, configuration files, and templates for setting up Ubuntu/Fedora/WSL development environments and HDL (hardware description language) simulation workflows.

**Distro Support:**
- **Ubuntu 24.04+**: Uses `apt` package manager, Microsoft GPG repo for VS Code
- **Fedora 44+**: Uses `dnf` package manager, Microsoft RPM repo for VS Code

Scripts auto-detect distro via `/etc/os-release` (`$ID`, `$ID_LIKE`). WSL is detected with:
```bash
if [[ $(grep -i Microsoft /proc/version) ]]; then WSL=1; else WSL=0; fi
```
WSL branches skip packages requiring a display server or use Windows-side tools.

## Repository Structure

- **`scripts/`** — Environment setup scripts. Entry point is `linux_setup.sh` (interactive, Ubuntu+Fedora). Per-app installs in `scripts/install_apps/`, each following `_template.sh`. Bash config files are copied to `~` during setup.
- **`templates/cocotb/`** — Reusable cocotb testbench framework for Verilog/SystemVerilog simulation. `sim_modules/` is the shared Python library; `top_tb_class.py` and `_test_testcase_template.py` are per-project starting points.
- **`virtualenv/`** — Python pip requirements files split by use-case: `dev`, `hdl`, `jupyterlab`, `ml`, `pytest`, `rnd`.
- **`settings/`** — Standalone config files deployed manually (tmux config with TPM plugins, GPU status bar script).
- **`archive/`** — Legacy scripts and requirements; kept for reference, not actively maintained.

## Scripts

### Setup
- `scripts/linux_setup.sh` — Unified script for Ubuntu/Fedora (recommended, interactive)
- `scripts/ubuntu_setup.sh` — Ubuntu-specific legacy variant
- `scripts/fedora_setup.sh` — Fedora-specific legacy variant
- `scripts/gnome_setup.sh` — GNOME desktop configuration
- `scripts/check_tools.py` — Verify installed tool versions
- `scripts/test.sh` — Version check utility

### App Installers (`scripts/install_apps/`)
All scripts follow `_template.sh`: detect distro/WSL, check prerequisites, set `VENV_TGT` (default: `"dev"`), activate virtualenv, then install. Interactive prompts use `read -p "... (y/n)? " ok` guards. Notable installers: `verilator_cocotb.sh`, `icarus_verilog.sh`, `intel_quartus_*.sh`, `arm_toolchain.sh`, `riscv.sh`, `vscode.sh`.

## Bash Configuration

Distro-specific files take priority; setup copies them to `~`:

| Source file | Destination | Notes |
|---|---|---|
| `.bashrc_${ID}` (e.g. `.bashrc_fedora`) | `~/.bashrc` | Falls back to `.bashrc` |
| `.bash_aliases_${ID}` | `~/.bash_aliases` | Falls back to `.bash_aliases` |
| `.bashrc_local` | `~/.bashrc_local` | Machine-local overrides, not overwritten if exists |
| `.bashrc_devsetup` | — | devsetup-specific env vars template |
| `.bashrc_wsl` / `.bashrc_wsl_work` | — | WSL variants |

## Virtual Environments

Requirements files in `virtualenv/`:
- `dev_requirements.txt` — Core Python packages (numpy, pandas, matplotlib, etc.)
- `hdl_requirements.txt` — HDL tools (hypothesis, pyslang, pysmt, pyvsc)
- `pytest_requirements.txt` — Testing framework (pytest, pytest-xdist, pytest-html)
- `jupyterlab_requirements.txt`, `ml_requirements.txt`, `rnd_requirements.txt` — Optional stacks

## cocotb Testbench Architecture

Templates in `templates/cocotb/` provide a reusable, simulator-agnostic testbench structure:

- `top_tb_class.py` — Starting point for DUT-specific subclasses; imports `UUT_Base` and `TestBenchBase` from `sim_modules/tb_base.py`
- `sim_modules/tb_base.py` — Base classes (`TestBenchBase`, `UUT_Base`) with clock, reset, and signal helpers
- `sim_modules/run_cocotb_sim.py` — pytest-integrated simulator runner; handles RTL file discovery, timeunit/timeprecision, simulator selection
- `sim_modules/sim_helpers.py` — Cycle generators, time formatting utilities
- `sim_modules/cocotb_methods.py` / `pytest_methods.py` — Shared coroutines and pytest fixtures
- `_test_testcase_template.py` — Test case template to copy for new tests
- `Makefile` + `pytest.ini` — Simulation entry points; `rtlfiles.lst` lists RTL sources (one path per line)

Run simulations with: `make SIM=verilator WAVES=1 TESTCASE=<test_function_name>`

**Workflow for a new DUT:** copy `top_tb_class.py`, subclass `UUT_Base` with DUT-specific ports/parameters, subclass `TestBenchBase` with stimulus methods, copy `_test_testcase_template.py` for test cases.

## Assets

- `scripts/assets/vscode/` — VS Code `settings.json`, `keybindings.json`, and extension lists (`ui_extensions.ext`, `workspace_extensions.ext`)
- `scripts/assets/gnome-backup` — GNOME dconf settings backup
- `scripts/assets/Desktop/` — `.desktop` launcher files
- `scripts/assets/docs/teroshdl.md` — TerosHDL setup notes

## Plans

Ongoing work is tracked in `plans/llm_tasks.md` — includes Claude Code integration tasks (statusline, hooks, skills).
