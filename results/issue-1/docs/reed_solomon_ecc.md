# `reed_solomon_ecc` — Reed-Solomon ECC Wrapper

## Overview

`reed_solomon_ecc` is a parameterised **Reed-Solomon error-correction wrapper** that supports
data widths of 4, 8, 16, 32, 64, and 128 bits.  It targets the GF(2⁸) field with a
correction capability of **T = 2** (two-symbol errors), which requires **4 parity bytes**.

At elaboration time the `generate` block selects and instantiates one of six width-specific
sub-modules (`reed_solomon_ecc_w4` … `reed_solomon_ecc_w128`).  All top-level codeword ports
are kept at a fixed 160-bit width (the maximum codeword size) and the wrapper zero-pads or
slices them to match the actual sub-module width.

| `DATA_WIDTH` | Data bytes | Parity bytes | Codeword bits | Sub-module               |
|:---:|:---:|:---:|:---:|:---|
| 4  | 1 | 4 | 40  | `reed_solomon_ecc_w4`   |
| 8  | 1 | 4 | 40  | `reed_solomon_ecc_w8`   |
| 16 | 2 | 4 | 48  | `reed_solomon_ecc_w16`  |
| 32 | 4 | 4 | 64  | `reed_solomon_ecc_w32`  |
| 64 | 8 | 4 | 96  | `reed_solomon_ecc_w64`  |
| 128| 16| 4 | 160 | `reed_solomon_ecc_w128` |

> **Standards note:** Reed-Solomon codes over GF(2⁸) with 4 parity symbols are widely used in
> storage and communications (e.g. JEDEC NAND ECC, various RAID implementations).  The
> mathematical background is described in the classic Wicker & Bhargava,
> *Reed-Solomon Codes and Their Applications* (IEEE Press, 1994).

---

## Port List

| Port | Direction | Width | Description |
|------|-----------|-------|-------------|
| `clk` | input | 1 | System clock (rising-edge triggered) |
| `rst_n` | input | 1 | Asynchronous active-low reset |
| `encode_en` | input | 1 | Assert to perform an RS encode operation |
| `decode_en` | input | 1 | Assert to perform an RS decode / error-correct operation |
| `data_in` | input | `DATA_WIDTH` | Raw data word to encode, or received data word for decode |
| `codeword_in` | input | 160 | Received codeword for decode (only the lower `N` bits used; see table above) |
| `codeword_out` | output | 160 | Encoded codeword (only the lower `N` bits are valid; upper bits are zero) |
| `data_out` | output | `DATA_WIDTH` | Corrected data word produced after a decode operation |
| `error_detected` | output | 1 | Asserted when at least one symbol error was detected in the codeword |
| `error_corrected` | output | 1 | Asserted when detected errors were successfully corrected (≤ T errors) |
| `valid_out` | output | 1 | Asserted when the output data (`data_out` / `codeword_out`) is valid |

---

## Parameters

| Parameter | Default | Allowed values | Description |
|-----------|---------|----------------|-------------|
| `DATA_WIDTH` | 8 | 4, 8, 16, 32, 64, 128 | Width of the data bus in bits.  Any other value activates the `fallback` branch, which drives all outputs to zero. |

---

## Functional Description

### Encode path

When `encode_en` is asserted, `data_in` is presented to the sub-module.  The sub-module
appends 4 bytes of GF(2⁸) Reed-Solomon parity to form the complete codeword, which appears on
`codeword_out` when `valid_out` is asserted.

### Decode / correct path

When `decode_en` is asserted, `codeword_in` (lower `N` bits, see table) is fed into the
sub-module's syndrome–error-locator–Chien-search pipeline.  The sub-module:

1. Computes syndromes S₀…S₃.
2. Runs the Berlekamp-Massey (or Euclidean) algorithm to find the error-locator polynomial.
3. Performs a Chien search to locate error positions.
4. Applies Forney's algorithm to compute error magnitudes and corrects the codeword.
5. Outputs corrected `data_out`, asserts `error_detected` and/or `error_corrected`, and pulses
   `valid_out`.

### Reset behaviour

`rst_n` is **active-low asynchronous**.  When `rst_n = 0`, all internal state and output
registers inside the sub-module are reset.  The wrapper itself is purely combinational
(`generate`/`assign`), so outputs follow the sub-module immediately after de-assertion.

### Fallback branch

If `DATA_WIDTH` is not one of the six supported values, the `fallback` `generate` branch drives
all outputs (`codeword_out`, `data_out`, `error_detected`, `error_corrected`, `valid_out`) to
zero.  This is a safe default; a synthesis warning is expected.

---

## Codeword Width Mapping

The wrapper uses a **fixed 160-bit** `codeword_in` / `codeword_out` pair to present a uniform
interface regardless of `DATA_WIDTH`.  Internally it slices the lower bits for the sub-module
and zero-pads the upper bits on output:

```
DATA_WIDTH=4/8  : codeword[39:0]   ↔ w4 / w8 sub-module  (120 MSBs zeroed on output)
DATA_WIDTH=16   : codeword[47:0]   ↔ w16 sub-module       (112 MSBs zeroed on output)
DATA_WIDTH=32   : codeword[63:0]   ↔ w32 sub-module       ( 96 MSBs zeroed on output)
DATA_WIDTH=64   : codeword[95:0]   ↔ w64 sub-module       ( 64 MSBs zeroed on output)
DATA_WIDTH=128  : codeword[159:0]  ↔ w128 sub-module      (no padding needed)
```

---

## Instantiation Example

```verilog
// 8-bit data, GF(2^8) T=2
reed_solomon_ecc #(
    .DATA_WIDTH(8)
) u_rs_ecc (
    .clk            (clk),
    .rst_n          (rst_n),
    .encode_en      (enc_start),
    .decode_en      (dec_start),
    .data_in        (tx_byte),          // 8-bit input
    .codeword_in    (rx_codeword),      // 160-bit bus; only [39:0] used for w8
    .codeword_out   (tx_codeword),      // [39:0] valid; [159:40] = 0
    .data_out       (rx_corrected),
    .error_detected (err_det),
    .error_corrected(err_cor),
    .valid_out      (out_valid)
);
```

---

## Timing / Latency Assumptions

- Both `encode_en` and `decode_en` are **level-sensitive** controls as seen by the sub-modules;
  exact latency (clock cycles from assertion to `valid_out`) depends on the individual
  `reed_solomon_ecc_wN` implementations.
- `valid_out` should be treated as a **single-cycle pulse** indicating the pipeline output is
  ready, unless the sub-module specification states otherwise.
- Do not assert `encode_en` and `decode_en` simultaneously unless the sub-modules explicitly
  support it.

---

## Source Files

| Type | Path |
|------|------|
| RTL wrapper | [`results/issue-1/rtl/reed_solomon_ecc.v`](../rtl/reed_solomon_ecc.v) |
| Testbench (TBD) | `results/issue-1/tb/reed_solomon_ecc_tb.sv` |
| Architecture overview | [`docs/ARCHITECTURE.md`](../../../docs/ARCHITECTURE.md) |
