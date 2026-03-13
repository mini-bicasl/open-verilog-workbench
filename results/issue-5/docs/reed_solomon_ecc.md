# `reed_solomon_ecc` — Reed-Solomon ECC Wrapper

## Overview

`reed_solomon_ecc` is a parameterised **Reed-Solomon error-correction wrapper** that supports
data widths of 4, 8, 16, 32, 64, and 128 bits.  It targets the **GF(2⁸)** field with a correction
capability of **T = 2** (two-symbol errors), using **4 parity bytes** and a primitive polynomial
of **0x11D** (FCR = 0).

At elaboration time the `generate` block selects one of six width-specific sub-modules
(`reed_solomon_ecc_w4` … `reed_solomon_ecc_w128`).  The top-level codeword ports are held at a
fixed **160-bit** width (the maximum codeword size); the wrapper slices or zero-pads to match
each sub-module's actual width.

See the [Architecture Overview](ARCHITECTURE.md) for the system-level context and sub-module
breakdown table.

---

## Port List

| Port             | Direction | Width        | Description                                                  |
|------------------|-----------|--------------|--------------------------------------------------------------|
| `clk`            | input     | 1            | System clock — rising-edge triggered                         |
| `rst_n`          | input     | 1            | Asynchronous active-low reset                                |
| `encode_en`      | input     | 1            | Assert to start an RS encode operation                       |
| `decode_en`      | input     | 1            | Assert to start an RS decode / error-correct operation       |
| `data_in`        | input     | `DATA_WIDTH` | Raw data word to encode, or received word for decode         |
| `codeword_in`    | input     | 160          | Received codeword; only the lower N bits are used (see table below) |
| `codeword_out`   | output    | 160          | Encoded codeword; lower N bits valid, upper bits are zero    |
| `data_out`       | output    | `DATA_WIDTH` | Corrected data word after decode                             |
| `error_detected` | output    | 1            | At least one symbol error was detected (any syndrome ≠ 0)    |
| `error_corrected`| output    | 1            | Detected errors corrected — **placeholder, always 0**        |
| `valid_out`      | output    | 1            | Single-cycle pulse: `data_out` / `codeword_out` are valid    |

---

## Parameters

| Parameter    | Default | Allowed values         | Description                                                                               |
|--------------|---------|------------------------|-------------------------------------------------------------------------------------------|
| `DATA_WIDTH` | 8       | 4, 8, 16, 32, 64, 128 | Width of the data bus in bits.  Any other value activates the `fallback` branch, which drives all outputs to zero. |

---

## Codeword Width Mapping

The wrapper exposes a uniform 160-bit codeword interface and internally maps to the appropriate
sub-module width:

| `DATA_WIDTH` | Data bytes | Parity bytes | Codeword bits | Active slice | Sub-module              |
|:---:|:---:|:---:|:---:|:---:|:---|
| 4   | 1 | 4 | 40  | `[39:0]`   | `reed_solomon_ecc_w4`   |
| 8   | 1 | 4 | 40  | `[39:0]`   | `reed_solomon_ecc_w8`   |
| 16  | 2 | 4 | 48  | `[47:0]`   | `reed_solomon_ecc_w16`  |
| 32  | 4 | 4 | 64  | `[63:0]`   | `reed_solomon_ecc_w32`  |
| 64  | 8 | 4 | 96  | `[95:0]`   | `reed_solomon_ecc_w64`  |
| 128 |16 | 4 | 160 | `[159:0]`  | `reed_solomon_ecc_w128` |

```
DATA_WIDTH=4/8  : codeword[39:0]   ↔ w4 / w8  (120 MSBs zeroed on output)
DATA_WIDTH=16   : codeword[47:0]   ↔ w16       (112 MSBs zeroed on output)
DATA_WIDTH=32   : codeword[63:0]   ↔ w32       ( 96 MSBs zeroed on output)
DATA_WIDTH=64   : codeword[95:0]   ↔ w64       ( 64 MSBs zeroed on output)
DATA_WIDTH=128  : codeword[159:0]  ↔ w128      (no padding needed)
```

---

## Functional Description

### Encode path

When `encode_en` is asserted, `data_in` is passed to the selected sub-module.  The sub-module
performs combinational GF(2⁸) polynomial division to append 4 RS parity bytes.  The full encoded
codeword appears on `codeword_out` on the next rising clock edge, with `valid_out` pulsed for
exactly one cycle.

### Decode / detect path

When `decode_en` is asserted, the lower N bits of `codeword_in` are fed into the sub-module.
The sub-module:

1. Computes four syndromes **S₀ … S₃** combinationally using Horner's method over GF(2⁸).
2. Sets `error_detected` if any syndrome is non-zero.
3. Extracts `data_out` directly from `codeword_in[DATA_WIDTH-1:0]` (systematic code, no
   correction applied yet).
4. Drives `error_corrected = 0` (full correction is not implemented — see note below).
5. Pulses `valid_out` for one cycle.

> **Note:** `error_corrected` is a placeholder register that is always driven to `0`.
> Berlekamp-Massey / Chien search / Forney error correction is not yet implemented in the
> sub-modules.  The design correctly **detects** up to T = 2 symbol errors but cannot **correct**
> them in the current implementation.

### Reset behaviour

`rst_n` is **active-low** and **asynchronous**.  When `rst_n = 0`, all output registers inside
the selected sub-module are cleared immediately.  The wrapper itself is purely combinational
(`generate` / `assign`), so its wire outputs follow the sub-module outputs with zero extra
latency after de-assertion.

### Fallback branch

If `DATA_WIDTH` is not one of the six supported values, the `fallback` `generate` branch drives
all outputs (`codeword_out`, `data_out`, `error_detected`, `error_corrected`, `valid_out`) to
zero.  A synthesis tool may emit an informational warning for this unused case.

---

## Timing / Latency

| Event                              | Cycle |
|------------------------------------|-------|
| `encode_en` / `decode_en` asserted | 0     |
| `valid_out` pulse, outputs valid   | 1     |

- Both `encode_en` and `decode_en` are sampled on the rising edge of `clk`.
- `valid_out` is a **single-cycle pulse** (goes high for exactly one clock cycle).
- Do **not** assert both enables simultaneously unless the target sub-module explicitly supports it.

---

## Instantiation Example

```verilog
// 8-bit data, GF(2^8) T=2
reed_solomon_ecc #(
    .DATA_WIDTH(8)
) u_rs_ecc (
    .clk             (clk),
    .rst_n           (rst_n),
    .encode_en       (enc_start),
    .decode_en       (dec_start),
    .data_in         (tx_byte),        // 8-bit input
    .codeword_in     (rx_codeword),    // 160-bit bus; only [39:0] used
    .codeword_out    (tx_codeword),    // [39:0] valid; [159:40] = 0
    .data_out        (rx_corrected),
    .error_detected  (err_det),
    .error_corrected (err_cor),        // always 0 in current implementation
    .valid_out       (out_valid)
);
```

---

## Source Files

| Type               | Path                                                             |
|--------------------|------------------------------------------------------------------|
| RTL wrapper        | [`results/issue-5/rtl/reed_solomon_ecc.v`](../rtl/reed_solomon_ecc.v) |
| Testbench          | `results/issue-5/tb/reed_solomon_ecc_tb.sv` *(TBD)*             |
| Architecture overview | [`results/issue-5/docs/ARCHITECTURE.md`](ARCHITECTURE.md)    |
| Sub-module docs    | [`results/issue-5/docs/reed_solomon_ecc_wN.md`](reed_solomon_ecc_wN.md) |
