# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Purpose

A collection of scripts, configuration files, and templates for setting up Ubuntu/WSL development environments and HDL (hardware description language) simulation workflows.

## Architecture Overview

The repo is organized into four main areas:

- **`scripts/`** — Environment setup scripts for Ubuntu/WSL. Entry point is `ubuntu_setup.sh` (interactive, semi-automated). Per-app installs live in `scripts/install_apps/`, each following the pattern established by `_template.sh`. Bash config files (`.bashrc`, `.bash_aliases`, `.bashrc_devsetup`, `.bashrc_local`, `.bashrc_wsl*`) are meant to be symlinked or sourced from `~`.
- **`templates/cocotb/`** — Reusable CoCoTB testbench framework for Verilog/SystemVerilog simulation. The `sim_modules/` subdirectory contains the shared Python library (tb_base, logger, sim_helpers, cocotb_methods, pytest_methods). `top_tb_class.py` and `_test_testcase_template.py` are the per-project starting points.
- **`virtualenv/`** — Python pip requirements files split by use-case: `dev`, `hdl`, `jupyterlab`, `ml`, `pytest`, `rnd`. Used by install scripts and `_template.sh`.
- **`settings/`** — Standalone config files to be deployed manually (tmux config with TPM plugins, GPU status bar script).
- **`archive/`** — Legacy versions of scripts and requirements; kept for reference, not actively maintained.

## Key Conventions

### Install Scripts (`scripts/install_apps/`)
- All scripts follow `_template.sh`: detect Ubuntu version and WSL, check for `ubuntu_setup.sh` having been run first, activate a virtualenv, then install.
- The `VENV_TGT` variable at the top of each script controls which virtualenv is used (default: `"dev"`).
- Interactive prompts use `read -p "... (y/n)? " ok` + `if [ "${ok}" == "y" ]` guards.

### CoCoTB Templates (`templates/cocotb/`)
- Simulations are run with `make` using: `make SIM=verilator WAVES=1 TESTCASE=<test_function_name>`
- RTL files are listed in `rtlfiles.lst` (one path per line), consumed by the `Makefile`.
- Python tests use both `cocotb.test` decorators (for `make`) and `pytest` (via `pytest_methods.py`).
- The `tb_base.py` `TestBenchBase` class is the base for all testbenches; `UUT_Base` wraps the DUT.

### WSL vs Native Ubuntu
Scripts detect the environment with:
```bash
if [[ $(grep -i Microsoft /proc/version) ]]; then WSL=1; else WSL=0; fi
```
WSL-specific branches skip packages requiring a display server or use Windows-side tools.

## Plans

Ongoing work is tracked in `plans/llm_tasks.md` — includes Claude Code integration tasks (statusline, hooks, skills).
