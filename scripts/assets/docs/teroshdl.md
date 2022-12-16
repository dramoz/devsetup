# TerosHDL Setup

## Info

- Project Manager
- Document generator (Markdown, Doxygen, Wavedrom, Bitfield)
- FSM viewer
- Linter+Style+CodeFormatting+Templates

## Global Configuration

> In general, there is no need to setup the paths for the tools iff they can be found with `$PATH` env. variable

### General

- Python: `. ~/virtualenvs/hdl/bin/activate; python`
- Select a tool, framework, simulator...: `[Modelsim]` (basic testing)
  - frameworks: `[CoCoTB | VUnit]`
    - `CoCoTB` + `[ Icarus | Verilator | Questa]`
    - `VUnit` + `Questa`
  - tools: `[Quartus | Vivado | Yosys | ...]`
  - simulators: `[ModelSim (Quartus/Questa) | Xsim (Vivado) | Icarus | Verilator | ...]`
- Select waveform viewer: `VDRom` (basic testing)
  - `[Tool GUI | GTKwave | VCDrom ]`
  - `VCDrom`: shows inside VS code with plugin

### Editor

- NA

### Templates

- NA

### Schematic viewer

- Yosys (Installed with OSS CAD Suite)

### Documentation settings

- NA

### Linter Settings

- VHDL/SV: `Modelsim`
- Verilog/SV style checker (SV): `Verible`

### Formatter Settings

  Verilog/SV Formatter: `Verible`
  Verilog/SV Verible formatter: `~/tools/verible/bin/verible-verilog-format` `[Optional]`

## Tools configuration

> Required tools installation independently from theros
>
> No paths requires if properly set on environment (`$PATH`) or installed (`make install`)

### Tools with configuration

- Modelsim

  - vsim: `-voptargs="+acc"` (should be disabled for regression)
- Veriblelint

  - rules: `-no-trailing-spaces, -line-length`
- Verilator

  - options
    - `-Wall, -Wno-fatal, -Wno-TIMESCALEMOD`
    - `-Wno-UNOPT, -Wno-UNOPTFLAT, -Wno-UNUSED, -Wno-WIDTH, -Wno-CASEINCOMPLETE` (optional)
- Quartus-Intel / Vivado-AMD

  - ! Requires FPGA target configuration

### [XSim (Vivado)](https://www.xilinx.com/products/design-tools/vivado.html)

- path: `~/tools/Xilinx/Vivado/2022.2/bin/` `[Optional]`
- install: `~/dev/devsetup/scripts/install_apps/amd_xilinx.sh`

### [GHDL](https://ghdl.github.io/ghdl/)

- path: `~/tools/oss-cad-suite/bin/` `[Optional]`
- install: (OSS-CAD-SUITE, this script)

### [Icarus](http://iverilog.icarus.com/)

- path: `NA`
- install: `~/dev/devsetup/scripts/install_apps/icarus_verilog.sh`

### [Modelsim (Intel Questa)](https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/questa-edition.html)

- path: `~/tools/intel/intelFPGA_pro/22.3/questa_fse/bin/` `[Optional - free edition]`
- path: `~/tools/intel/intelFPGA_pro/22.3/questa_fe/bin/` `[Optional - paid version]`
- install: `~/dev/devsetup/scripts/install_apps/intel_questa.sh`
- options:
  - vsim: `-voptargs="+acc"` (should be disabled for regression)

### [Quartus (Intel)](https://www.intel.ca/content/www/ca/en/products/details/fpga/development-tools/quartus-prime.html)

> ! Requires FPGA target configuration

- path: `~/tools/intel/intelFPGA_pro/22.3/quartus/bin/` `[Optional]`
- install: ~/dev/devsetup/scripts/install_apps/intel_quartus.sh

### [Symbiyosys Formal Verification](https://symbiyosys.readthedocs.io/en/latest/)

- path: `~/tools/oss-cad-suite/bin/` `[Optional]`
  install: (OSS-CAD-SUITE, this script)

### [Veriblelint](https://chipsalliance.github.io/verible/lint.html)

- path: `~/tools/verible/bin/` `[Optional]`
- install: (Verible, this script)
- options:
  - -Rules: `-no-trailing-spaces, -line-length`

### [Verilator](https://www.veripool.org/verilator/)

- path: `~/tools/verilator/bin/` `[Optional]`
- install: `~/dev/devsetup/scripts/install_apps/verilator_cocotb.sh`
- options:
  - `-Wall, -Wno-fatal, -Wno-TIMESCALEMOD`
  - optional: `-Wno-UNOPT, -Wno-UNOPTFLAT, -Wno-UNUSED, -Wno-WIDTH, -Wno-CASEINCOMPLETE`

### [Vivado (Xilinx)](https://www.xilinx.com/products/design-tools/vivado.html)

> ! Requires FPGA target configuration

- path: `~/tools/Xilinx/Vivado/2022.2/bin/` `[Optional]`
- install: `~/dev/devsetup/scripts/install_apps/amd_xilinx.sh`

### [Vunit](https://vunit.github.io/)

- simulator: `ModelSim/Questa`
- install: (this script)

### [Yosys](https://yosyshq.net/yosys/) (https://yosyshq.readthedocs.io/en/latest/)

- path: `~/tools/oss-cad-suite/bin/` `[Optional]`
- install: (OSS-CAD-SUITE, this script)

### [CoCoTB](https://docs.cocotb.org/en/stable/)

- path: `${VIRTUAL_ENV}/bin/cocotb` `[Optional]`
- install: `~/dev/devsetup/scripts/install_apps/verilator_cocotb.sh`
