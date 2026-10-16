# Booth Array Multiplier — LUT-Optimized on Artix-7

VHDL implementation of a Booth-encoded array multiplier optimized for LUT6-2 + Carry4 usage. Built for Xilinx Artix-7.

## Overview

A Booth array multiplier implementing the Booth encoding algorithm for signed multiplication. The design is optimized for Artix-7 LUT6-2 resources with Carry4 chaining, achieving zero DSP slice usage. Word sizes are configurable via generics.

## Project Structure

| File | Description |
|------|-------------|
| `mult_booth_array.vhd` | Core Booth array multiplier with configurable word sizes |
| `bd_mult_slice.vhd` | Multiplier slice element |
| `register_chain.vhd` | Pipeline register chain |
| `apb_wrapper_booth.v` | APB bus wrapper for SoC integration |
| `mult_booth_array_tb.v` | Testbench |

## Hardware

- **Device:** Xilinx Artix-7 XC7A35T (xc7a35tcpg236-1)
- **Tool:** Vivado 2021.1
- **Language:** VHDL-2008

## Architecture

Booth encoding reduces the number of partial products by encoding groups of 3 bits at a time. The array multiplier arranges partial products in a regular grid with carry-save adders, optimized for LUT6-2 fabric with Carry4 chains for efficient addition.

## Building

1. Open the project in Vivado
2. Run Synthesis and Implementation
3. Generate bitstream
