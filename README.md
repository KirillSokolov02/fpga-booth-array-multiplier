# booth_mult — Area-Efficient Booth Array Multiplier

A **Vivado FPGA project** implementing an **area-efficient Booth array multiplier** based on the architecture proposed by Martin Kumm et al. (IEEE ARITH 2015). Built for **Xilinx Artix-7** using **Vivado 2021.1**.

## Overview

This project implements a **Booth array multiplier** optimized for **Xilinx FPGA architectures** (Virtex 5-7, Spartan 6, and Series 7). It uses a novel slice-based design that leverages Xilinx's **LUT6-2** and **carry4** primitives to achieve high area efficiency.

The multiplier uses **Booth encoding** to reduce the number of partial products, then arranges the encoding and accumulation in a regular array of slices that map efficiently onto Xilinx LUT resources.

## Booth Encoding

Booth encoding is a technique for multiplying signed binary numbers that reduces the number of partial products compared to simple array multipliers.

### How It Works

For an **n-bit multiplier**, Booth encoding examines **groups of 3 bits** (b[i-1], b[i], b[i+1]) and generates control signals that determine whether to add, subtract, or skip the multiplicand at each step:

| b[i+1] | b[i] | b[i-1] | Operation |
|--------|------|--------|-----------|
| 0 | 0 | 0 | 0 × A (skip) |
| 0 | 0 | 1 | +1 × A |
| 0 | 1 | 0 | +1 × A |
| 0 | 1 | 1 | +2 × A |
| 1 | 0 | 0 | -2 × A |
| 1 | 0 | 1 | -1 × A |
| 1 | 1 | 0 | -1 × A |
| 1 | 1 | 1 | 0 × A (skip) |

This reduces the number of partial products from **n** to **n/2 + 1** for even n, roughly **halving** the array size.

## Architecture

### mult_booth_array (Top-Level)

The main multiplier entity implements the Booth array:

| Generic | Default | Description |
|---------|---------|-------------|
| **word_size_a** | 8 | Bits in first operand (A) |
| **word_size_b** | 8 | Bits in second operand (B) |
| **sync_in_out** | false | Synchronous I/O (true) or combinational (false) |
| **use_pipelining** | true | Pipeline registers between rows |

| Signal | Width | Direction | Description |
|--------|-------|-----------|-------------|
| **clk_i** | 1-bit | Input | Clock |
| **rst_i** | 1-bit | Input | Active-high reset |
| **ce_i** | 1-bit | Input | Clock enable |
| **a_i** | word_size_a-bit | Input | First operand (A) |
| **b_i** | word_size_b-bit | Input | Second operand (B) |
| **p_o** | (word_size_a+word_size_b)-bit | Output | Product (A × B) |

**Default configuration**: 8×8 = 16-bit product

### bd_mult_slice (Multiplier Slice)

The fundamental building block — a single slice that processes one column of the Booth array:

**Inputs**:
- **a0_i[3:0]**, **a1_i[3:0]** — Two 4-bit segments of the extended multiplicand
- **b0_i**, **b1_i**, **b2_i** — Booth encoded control bits (3 bits per row)
- **p_i[3:0]** — Partial product bits from previous row
- **carry_i** — Carry-in from previous slice

**Outputs**:
- **p_o[3:0]** — Accumulated partial product (4 bits)
- **a0_o[3:0]** — Shifted multiplicand segment
- **carry_o** — Carry-out to next slice

**Internal Implementation**:
- **4× LUT6-2** — Each LUT6-2 implements one bit of the Booth encoding + addition
- **1× Carry4** — Xilinx carry chain for fast carry propagation between slices
- **Output flip-flops** (optional) — Registered output for pipelining

**LUT6-2 Configuration**: The slice uses hardcoded LUT content arrays optimized for Booth encoding:

| LUT Index | Purpose | Content |
|-----------|---------|---------|
| LUT 0 | Booth encode/decode | `0xFCCA533F0335ACC0` |
| LUT 1 | Conditional add | `0x0FFF0000F000FFFF` |
| LUT 2 | Adder with carry | `0xFFFFFFFF00000000` |

### register_chain (Delay Element)

A configurable delay chain used for pipelining between Booth array rows:

| Generic | Description |
|---------|-------------|
| **word_size** | Width of data path |
| **delay** | Number of clock cycles of delay |

Used to synchronize:
- **b_delayed**: Booth control bit delays per row
- **carry_delay**: Carry chain synchronization
- **res_delay**: Partial product output registration

## Data Flow

```
Operand A (8-bit) ──► a_ext[0..no_of_rows] (extended with zeros)
Operand B (8-bit) ──► b_ext (extended: "00" + B + "0")
                    │
                    ▼
┌──────────────────────────────────────────────────┐
│  Booth Array (no_of_rows × no_of_slices_per_row) │
│                                                  │ 
│  Row 0: Booth encode B[1:0], process A[7:0]      │
│  Row 1: Booth encode B[3:2], process A[7:0]      │
│  ...                                             │
│  Row N: Final accumulation                       │ 
│                                                  │ 
│  Each row:                                       │ 
│    ├─ bd_mult_slice × no_of_slices_per_row       │ 
│    ├─ Carry4 chain (horizontal)                  │ 
│    └─ LUT6-2 array (vertical per slice)          │ 
└──────────────────────────────────────────────────┘
                    │
                    ▼
Product P (16-bit)
```

### Array Dimensions (8×8 Default)

For an 8×8 multiplier:

| Parameter | Value | Description |
|-----------|-------|-------------|
| **no_of_rows** | 5 | ⌈(8+2)/2⌉ = 5 Booth rows |
| **no_of_slices_per_row** | 2 | ⌈(8+4)/4⌉ = 3... actually computed as needed |
| **no_of_cols** | 8 | slices_per_row × 4 |
| **unused_luts** | 0-3 | Padding in last slice |

## Booth Multiplier vs. Traditional Array

| Feature | Traditional Array | Booth Array (this design) |
|---------|-------------------|--------------------------|
| **Partial products (8×8)** | 8 | 5 |
| **Adder rows** | 8 | 5 |
| **Array height** | n | n/2 + 1 |
| **Signed arithmetic** | Requires sign extension | Native (Booth handles sign) |
| **Xilinx optimization** | Generic | LUT6-2 + Carry4 specific |

## Pipelining Options

The multiplier supports two modes:

### Synchronous (use_pipelining = true, default)

- Flip-flops between each row
- Better timing (pipeline breaks critical path)
- Latency = no_of_rows clock cycles
- Higher throughput (one product per cycle after pipeline fills)

### Asynchronous (use_pipelining = false)

- Combinational path through entire array
- Lower latency (1 cycle, but slower max frequency)
- Lower resource usage (fewer flip-flops)

## APB Wrapper (apb_wrapper_booth)

Memory-mapped interface for processor access:

| APB Address | Register | Access | Description |
|-------------|----------|--------|-------------|
| **0x00** | a_i | Read/Write | First operand A (8-bit, zero-extended) |
| **0x04** | b_i | Read/Write | Second operand B (8-bit, zero-extended) |
| **0x08** | ce_i | Read/Write | Clock enable (trigger computation) |
| **0x0C** | p_o | Read | Product (16-bit, zero-extended to 32-bit) |

**Operation**:
1. Write operand A to address 0x00
2. Write operand B to address 0x04
3. Assert ce_i (write 1) to address 0x08 to trigger computation
4. Read result from address 0x0C after no_of_rows clock cycles

## Building

### Prerequisites

- **Xilinx Vivado 2021.1** (or later, 64-bit)
- **Xilinx Artix-7 FPGA board** (e.g., Digilent Arty A7, Basys 3)

### Compilation Steps

1. Open **Vivado 2021.1**
2. Select **File → Open Project**
3. Open `booth_mult.xpr`
4. Select **Flow → Run Synthesis**
5. After synthesis, select **Flow → Run Implementation**
6. Generate bitstream with **Flow → Generate Bitstream**
7. Program the Artix-7 board

### Device Configuration

| Parameter | Value |
|-----------|-------|
| **Family** | Artix-7 |
| **Device** | XC7A35T |
| **Package** | CPG236 |
| **Speed Grade** | -1 |
| **Vivado Version** | 2021.1 |
| **Top-Level Entity** | mult_booth_array (or apb_wrapper_booth) |

### Resource Usage (Estimated for 8×8)

| Resource | Estimated Usage |
|----------|----------------|
| **LUTs** | ~2-5% of available |
| **FFs** | ~1-3% (pipelining registers) |
| **DSPs** | 0 (LUT-based multiplier) |
| **BRAM** | 0 |
| ** Carry4 instances** | 1 per row × slices_per_row |

The key advantage of this design is **zero DSP utilization** — all multiplication is done in LUTs, leaving DSP slices free for other operations.

## Testbench

The project includes a testbench (`mult_booth_array_tb.v`) for simulation:

1. Open Vivado and select **Add Sources**
2. Add `mult_booth_array_tb.v` from the project directory
3. Set **testbench** as the top module
4. Run **Run Simulation → Run Behavioral Simulation**

The testbench applies various input combinations and verifies the product output.

## Research Reference

This implementation is based on:

> **M. Kumm, S. Abbas, and P. Zipf**, "An Efficient Softcore Multiplier Architecture for Xilinx FPGAs," *IEEE Symposium on Computer Arithmetic (ARITH)*, 2015, pp. 18-25.
>
> **DOI**: https://doi.org/10.1109/ARITH.2015.17

**License**: This code is released under the **LGPL** (Lesser General Public License) as noted in the source files.

## Configuring Different Sizes

To use different operand widths, modify the generics:

```vhdl
-- 16×16 multiplier
mult_booth_array #(
    word_size_a => 16,
    word_size_b => 16,
    sync_in_out => true,
    use_pipelining => true
) uut (
    .clk_i(clk),
    .rst_i(rst),
    .ce_i(ce),
    .a_i(a),
    .b_i(b),
    .p_o(product)
);
```

The architecture automatically adjusts:
- **no_of_rows** = ⌈(word_size_b + 2) / 2⌉
- **no_of_slices_per_row** = ⌈(word_size_a + 4) / 4⌉

## VHDL Conventions

- **IEEE 1164** — Standard logic types
- **Unisim primitives** — LUT6-2, Carry4, FDCE for optimal Xilinx mapping
- **Generate statements** — Parametric array construction
- **Boolean generics** — sync_in_out and use_pipelining for configuration
- **Package** — `mult_types_pkg` defines LUT type arrays

## Related Projects

- **register_chain.vhd**: Reusable delay element for pipeline stages
- **apb_wrapper_booth.v**: APB bus interface for processor access

## References

- Kumm, M. et al. (2015). "An Efficient Softcore Multiplier Architecture for Xilinx FPGAs." ARITH 2015.
- Xilinx UG687: Vivado Design Suite User Guide
- Xilinx UG573: Artix-7 Data Sheet
- Booth, K. S. (1951). "A Signed Binary Multiplication Technique." Quarterly of Applied Mathematics.

> *Note: This README was generated by AI to describe the project. The source code itself was written by the user.*
