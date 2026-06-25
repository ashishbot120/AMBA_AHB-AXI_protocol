# AHB-to-AXI4-Lite Bridge IP — Design Specification

**Document version:** 1.0  
**Date:** June 2026  
**Author:** Ashish Waghode  
**Status:** Released

---

## 1. Introduction

### 1.1 Purpose

This document describes the architecture, interface, and operation of the
AHB-to-AXI4-Lite Bridge IP — a synthesisable Verilog RTL design that
translates ARM AMBA 2.0 AHB transactions into ARM AMBA 4.0 AXI4-Lite
transactions. The IP enables legacy AHB masters to communicate with
AXI4-Lite slave peripherals without modification to either side.

### 1.2 Scope

This IP implements:
- A compliant AHB slave interface per ARM IHI0011A (AMBA 2.0)
- A compliant AXI4-Lite master interface per ARM IHI0022H (AMBA 4.0)
- Protocol translation between the two buses
- AXI SLVERR and DECERR mapping to AHB HRESP ERROR (2-cycle compliant)
- WSTRB generation from AHB HSIZE for byte, halfword, and word transfers

### 1.3 References

| Document | Version | Description |
|---|---|---|
| ARM IHI0011A | Rev E | AMBA AHB Protocol Specification |
| ARM IHI0022H | Issue H | AMBA AXI Protocol Specification |

---

## 2. Architecture

### 2.1 Block Diagram

```
         AHB Master
             │
    ┌────────▼─────────────────────────────────────┐
    │                  bridge_top.v                 │
    │                                              │
    │  ┌─────────────┐      ┌──────────────────┐   │
    │  │ ahb_slave.v │      │  bridge_fsm.v    │   │
    │  │             │◄────►│                  │   │
    │  │ AHB slave   │      │ Protocol         │   │
    │  │ interface   │      │ translation FSM  │   │
    │  └─────────────┘      └────────┬─────────┘   │
    │                               │              │
    │                      ┌────────▼─────────┐    │
    │                      │  axi_master.v    │    │
    │                      │                  │    │
    │                      │ AXI4-Lite master │    │
    │                      │ interface        │    │
    │                      └────────┬─────────┘    │
    └───────────────────────────────┼──────────────┘
                                    │
                         AXI4-Lite Slave
```

### 2.2 Sub-module Description

| Module | File | Description |
|---|---|---|
| `bridge_top` | `rtl/bridge_top.v` | Structural top-level — wires sub-modules, no logic |
| `ahb_slave` | `rtl/ahb_slave.v` | AHB slave interface — address phase capture, HREADY/HRESP control |
| `bridge_fsm` | `rtl/bridge_fsm.v` | Protocol translation FSM — WSTRB generation, response mapping |
| `axi_master` | `rtl/axi_master.v` | AXI4-Lite master — independent AW/W/B/AR/R channel handling |

---

## 3. Interface Definition

### 3.1 AHB Slave Interface

| Signal | Direction | Width | Description |
|---|---|---|---|
| `HCLK` | Input | 1 | System clock — all signals sampled on rising edge |
| `HRESETn` | Input | 1 | Active-LOW asynchronous reset |
| `HSEL` | Input | 1 | Slave select — must be HIGH for transfer to be decoded |
| `HADDR` | Input | 32 | Transfer address |
| `HTRANS` | Input | 2 | Transfer type: IDLE/BUSY/NONSEQ/SEQ |
| `HWRITE` | Input | 1 | Transfer direction: 1=write, 0=read |
| `HSIZE` | Input | 3 | Transfer size: 000=byte, 001=halfword, 010=word |
| `HBURST` | Input | 3 | Burst type: SINGLE/INCR/WRAP4/INCR4/WRAP8/INCR8/WRAP16/INCR16 |
| `HWDATA` | Input | 32 | Write data |
| `HRDATA` | Output | 32 | Read data |
| `HREADY` | Output | 1 | Transfer complete — LOW inserts wait states |
| `HRESP` | Output | 2 | Transfer response: 00=OKAY, 01=ERROR |

### 3.2 AXI4-Lite Master Interface

| Signal | Direction | Width | Description |
|---|---|---|---|
| `AWADDR` | Output | 32 | Write address |
| `AWPROT` | Output | 3 | Write protection — hardcoded to 3'b000 |
| `AWVALID` | Output | 1 | Write address valid |
| `AWREADY` | Input | 1 | Write address ready |
| `WDATA` | Output | 32 | Write data |
| `WSTRB` | Output | 4 | Write byte enable — derived from HSIZE |
| `WVALID` | Output | 1 | Write data valid |
| `WREADY` | Input | 1 | Write data ready |
| `BRESP` | Input | 2 | Write response: 00=OKAY, 10=SLVERR, 11=DECERR |
| `BVALID` | Input | 1 | Write response valid |
| `BREADY` | Output | 1 | Write response ready |
| `ARADDR` | Output | 32 | Read address |
| `ARPROT` | Output | 3 | Read protection — hardcoded to 3'b000 |
| `ARVALID` | Output | 1 | Read address valid |
| `ARREADY` | Input | 1 | Read address ready |
| `RDATA` | Input | 32 | Read data |
| `RRESP` | Input | 2 | Read response: 00=OKAY, 10=SLVERR |
| `RVALID` | Input | 1 | Read data valid |
| `RREADY` | Output | 1 | Read data ready |

---

## 4. Operation

### 4.1 Bridge FSM State Diagram

```
        ┌────────┐
   ┌───►│ S_IDLE │◄──────────────────┐
   │    └───┬────┘                   │
   │        │ ahb_valid=1            │
   │        ▼                        │
   │   ┌──────────┐                  │
   │   │ S_ISSUE  │ drive axi_master │
   │   └────┬─────┘                  │
   │        ▼                        │
   │   ┌──────────┐                  │
   │   │ S_WAIT   │ wait axi_done    │
   │   └────┬─────┘                  │
   │        ▼                        │
   │   ┌──────────┐                  │
   │   │S_COMPLETE│ capture result   │
   │   └──┬────┬──┘                  │
   │  OKAY│    │ERROR                │
   │      │    ▼                     │
   │      │  ┌─────────┐            │
   │      │  │ S_ERROR │ 2nd cycle  │
   │      │  └────┬────┘            │
   └──────┴───────┴──────────────────┘
```

### 4.2 Write Transaction Flow

```
Cycle  AHB side                    AXI side
  1    HTRANS=NONSEQ, HADDR=A     —
  2    HWDATA=D, HTRANS=IDLE      AWVALID=1, WVALID=1
  3    HREADY=0 (stall)           AWREADY=1 → AW done
  4    HREADY=0                   WREADY=1  → W done
  5    HREADY=0                   BVALID=1, BRESP=OKAY
  6    HREADY=1                   —
```

### 4.3 Read Transaction Flow

```
Cycle  AHB side                    AXI side
  1    HTRANS=NONSEQ, HADDR=A     —
  2    HREADY=0 (stall)           ARVALID=1
  3    HREADY=0                   ARREADY=1 → AR done
  4    HREADY=0                   RVALID=1, RDATA=D
  5    HREADY=1, HRDATA=D         —
```

### 4.4 Error Response

When AXI returns SLVERR or DECERR, the bridge maps it to AHB HRESP=ERROR
per the 2-cycle AHB specification rule:

```
Cycle N:   fsm_error=1  → HRESP=ERROR, HREADY=LOW   (cycle 1 of 2)
Cycle N+1: fsm_ready=1  → HRESP=ERROR, HREADY=HIGH  (cycle 2 of 2)
Cycle N+2: HRESP=OKAY                                (return to idle)
```

### 4.5 WSTRB Generation

WSTRB byte lane enables are derived from HSIZE and HADDR[1:0]:

| HSIZE | HADDR[1:0] | WSTRB |
|---|---|---|
| 000 (byte) | 00 | 0001 |
| 000 (byte) | 01 | 0010 |
| 000 (byte) | 10 | 0100 |
| 000 (byte) | 11 | 1000 |
| 001 (halfword) | x0 | 0011 |
| 001 (halfword) | x1 | 1100 |
| 010 (word) | xx | 1111 |

---

## 5. Verification

### 5.1 Basic Functional Testbench

Tool: Icarus Verilog + GTKWave

| Test | Scenario | Result |
|---|---|---|
| T1 | AHB write 0xDEADBEEF to 0x1000 — check AWADDR, WDATA, WSTRB | PASS |
| T2 | AHB read from 0x2000 — AXI slave returns 0xCAFEBABE, check HRDATA | PASS |
| T3 | AXI slave returns SLVERR — check HRESP=ERROR (2-cycle) | PASS |

### 5.2 UVM Testbench

Tool: Questa Intel FPGA Edition 2025.2 (UVM 1.1d)

Components: AHB driver, AHB monitor, AXI write/read responders, AXI monitor, scoreboard

| Scenario | AHB Input | AXI Output | Scoreboard |
|---|---|---|---|
| Write | addr=0x1000, data=0xDEADBEEF | AWADDR=0x1000, WDATA=0xDEADBEEF | MATCH ✅ |
| Read | addr=0x2000 | ARADDR=0x2000, RDATA=0xCAFEBABE | MATCH ✅ |
| Error | addr=0x3000, SLVERR injected | BRESP=10 | HRESP=ERROR MATCH ✅ |

```
UVM_ERROR:  0
UVM_FATAL:  0
Scoreboard: 3 PASS, 0 FAIL
```

### 5.3 Bugs Found During Verification

| Bug | Description | Fix |
|---|---|---|
| B1 | `ahb_valid` stale after transfer consumed | Clear on `fsm_ready` in `ahb_slave` |
| B2 | `fsm_error` not defaulted to 0 each cycle | Added per-cycle default in `bridge_fsm` |
| B3 | `fsm_error` and `fsm_ready` fired same cycle | Added `S_ERROR` state to FSM — separated by 1 cycle |
| B4 | HREADY stuck LOW with no default else clause | Added explicit default `HREADY <= 1'b1` |
| B5 | AHB driver not waiting for HREADY between transfers | Fixed `drive_transfer` task with HREADY wait loop |
| B6 | `busy` flag clearing on `fsm_error` before 2-cycle ERROR completes | `busy` now only clears on `fsm_ready` |

---

## 6. Synthesis Results

Tool: Quartus Prime Lite 25.1  
Device: Cyclone V (5CSEMA5F31C6)  
Constraints: `bridge_top.sdc` — 100 MHz clock, false paths on async reset

| Parameter | Value |
|---|---|
| Logic cells (ALMs) | 449 |
| Input pins | 117 |
| Output pins | 146 |
| Fmax (Slow 85°C model) | ~163 MHz |
| Setup slack (Slow 85°C) | +3.684 ns |
| Hold slack (Slow 85°C) | +0.305 ns |
| Compilation errors | 0 |

---

## 7. Known Limitations

- AXI4-Lite only — full AXI4 burst transactions (AWLEN > 0) not supported
- Single clock domain — AHB and AXI clocks must be the same frequency
- AWPROT/ARPROT hardcoded to 3'b000 — TrustZone-aware slaves not supported
- HBURST captured but burst address calculation delegated to AHB master

---

## 8. File Structure

```
ahb-axi-bridge/
├── rtl/
│   ├── ahb_slave.v        AHB slave interface
│   ├── bridge_fsm.v       Protocol translation FSM
│   ├── axi_master.v       AXI4-Lite master interface
│   └── bridge_top.v       Structural top-level
├── tb/
│   └── tb_bridge_top.v    Basic functional testbench (Icarus)
├── uvm/
│   ├── bridge_pkg.sv      UVM package — all testbench classes
│   ├── interfaces/        ahb_if.sv, axi_if.sv
│   ├── seq_items/         ahb_transaction.sv, axi_transaction.sv
│   ├── agents/            drivers, monitors, responders, agents
│   ├── env/               scoreboard.sv, bridge_env.sv
│   ├── seq/               ahb_basic_seq.sv
│   ├── test/              bridge_base_test.sv
│   └── tb_top_uvm.sv      UVM top-level
├── quartus/
│   ├── bridge_ip.qpf      Quartus project file
│   ├── bridge_top.qsf     Quartus settings
│   └── bridge_top.sdc     Timing constraints
├── docs/
│   └── bridge_ip_design_spec.md   This document
├── .gitignore
└── README.md
```