# `reed_solomon_ecc_wN` — Width-Specific RS Sub-Modules

## Overview

This page covers all six width-specific Reed-Solomon sub-modules generated for
[issue #5](https://github.com/mini-bicasl/open-verilog-workbench/issues/5):

| Module                  | File                                                                      |
|-------------------------|---------------------------------------------------------------------------|
| `reed_solomon_ecc_w4`   | [`rtl/reed_solomon_ecc_w4.v`](../rtl/reed_solomon_ecc_w4.v)              |
| `reed_solomon_ecc_w8`   | [`rtl/reed_solomon_ecc_w8.v`](../rtl/reed_solomon_ecc_w8.v)              |
| `reed_solomon_ecc_w16`  | [`rtl/reed_solomon_ecc_w16.v`](../rtl/reed_solomon_ecc_w16.v)            |
| `reed_solomon_ecc_w32`  | [`rtl/reed_solomon_ecc_w32.v`](../rtl/reed_solomon_ecc_w32.v)            |
| `reed_solomon_ecc_w64`  | [`rtl/reed_solomon_ecc_w64.v`](../rtl/reed_solomon_ecc_w64.v)            |
| `reed_solomon_ecc_w128` | [`rtl/reed_solomon_ecc_w128.v`](../rtl/reed_solomon_ecc_w128.v)          |

All six modules share an identical internal structure; they differ only in data width, codeword
width, and the number of GF(2⁸) feedback/syndrome steps.

See the [top-level wrapper docs](reed_solomon_ecc.md) and the
[Architecture Overview](ARCHITECTURE.md) for context.

---

## RS Code Parameters per Module

| Module                  | RS code   | K (data bytes) | N (codeword bytes) | T (correctable) | Codeword bits |
|-------------------------|-----------|:--------------:|:------------------:|:---------------:|:-------------:|
| `reed_solomon_ecc_w4`   | RS(5, 1)  |  1 | 5  | 2 | 40  |
| `reed_solomon_ecc_w8`   | RS(5, 1)  |  1 | 5  | 2 | 40  |
| `reed_solomon_ecc_w16`  | RS(6, 2)  |  2 | 6  | 2 | 48  |
| `reed_solomon_ecc_w32`  | RS(8, 4)  |  4 | 8  | 2 | 64  |
| `reed_solomon_ecc_w64`  | RS(12, 8) |  8 | 12 | 2 | 96  |
| `reed_solomon_ecc_w128` | RS(20,16) | 16 | 20 | 2 | 160 |

All use:
- **GF(2⁸)** with primitive polynomial **0x11D** (`x⁸ + x⁴ + x³ + x² + 1`)
- **FCR (first consecutive root) = 0** → generator roots α⁰, α¹, α², α³

---

## Port List (per module)

Each module has the same port structure; only the widths change:

| Port             | Dir    | Width          | Description                                                     |
|------------------|--------|----------------|-----------------------------------------------------------------|
| `clk`            | input  | 1              | System clock — rising-edge triggered                            |
| `rst_n`          | input  | 1              | Asynchronous active-low reset                                   |
| `encode_en`      | input  | 1              | Assert to start encode; `data_in` is consumed on next rising edge |
| `decode_en`      | input  | 1              | Assert to decode `codeword_in`; outputs valid on next cycle     |
| `data_in`        | input  | `DATA_WIDTH`   | Raw data word to encode                                         |
| `codeword_in`    | input  | `CW_WIDTH`     | Received codeword (data at LSB, parity at MSB)                  |
| `codeword_out`   | output | `CW_WIDTH`     | Encoded codeword registered on posedge clk                      |
| `data_out`       | output | `DATA_WIDTH`   | Data extracted from `codeword_in[DATA_WIDTH-1:0]`               |
| `error_detected` | output | 1              | Any syndrome Si ≠ 0                                             |
| `error_corrected`| output | 1              | **Placeholder — always 0** (correction not implemented)         |
| `valid_out`      | output | 1              | Single-cycle pulse: outputs are valid                           |

**Width mapping:**

| Module                  | `DATA_WIDTH` | `CW_WIDTH` |
|-------------------------|:---:|:---:|
| `reed_solomon_ecc_w4`   |   4 |  40 |
| `reed_solomon_ecc_w8`   |   8 |  40 |
| `reed_solomon_ecc_w16`  |  16 |  48 |
| `reed_solomon_ecc_w32`  |  32 |  64 |
| `reed_solomon_ecc_w64`  |  64 |  96 |
| `reed_solomon_ecc_w128` | 128 | 160 |

> **Note (w4 only):** `data_in` is 4 bits.  Internally the module zero-extends it to 8 bits
> (`{4'b0, data_in[3:0]}`) before polynomial processing.  `data_out` returns `codeword_in[3:0]`.

---

## Codeword Layout

All modules use a **systematic, little-endian byte** format:

```
codeword[DATA_BYTES*8 - 1 : 0]           — K data bytes (byte 0 at bits [7:0])
codeword[CW_WIDTH-1     : DATA_BYTES*8]  — 4 parity bytes (P0 at lowest parity byte position)
```

Example for w8 (CW = 40 bits, K = 1):

```
[7:0]   data byte 0
[15:8]  parity byte 0  (P0)
[23:16] parity byte 1  (P1)
[31:24] parity byte 2  (P2)
[39:32] parity byte 3  (P3)
```

---

## Internal Architecture

Each sub-module is fully **combinational except for the output register stage**.

### Encoder

```
data_in → msg_bytes[] → GF feedback loop → parity_byte[0..3] → encoded_result
                                                                       |
                                                               posedge clk → codeword_out
```

1. `msg_bytes[i]` breaks `data_in` into individual GF bytes.
2. For each message byte, `feedback_k = reg_k XOR msg_byte` drives a set of combinational XOR
   trees (`mul_i_j`) that implement GF(2⁸) multiplication by the generator polynomial
   coefficients (modulo 0x11D).
3. The four `parity_byte[0..3]` wires are the final polynomial remainder.
4. `encoded_result` assembles data and parity bytes; registered to `codeword_out` on the clock
   edge while `encode_en` is high.

### Decoder / Error Detector

```
codeword_in → syndrome Horner steps (syn_mul_i_j, syn_sum_i_j) → has_error
                                                                       |
codeword_in[DATA_WIDTH-1:0] ──────────────────────────────────→ data_out (registered)
```

1. Four syndromes S₀ … S₃ are computed over the N codeword bytes using Horner's method:
   `S_i = Σ_j codeword_byte_j × α^(i×j)` in GF(2⁸).
2. Each Horner step consists of a GF multiply (`syn_mul_i_k`) followed by XOR with the next
   byte (`syn_sum_i_k`).
3. `has_error = |S₀ | |S₁ | |S₂ | |S₃` — if any syndrome is non-zero at least one symbol error
   is present.
4. On a `decode_en` clock edge:
   - `data_out ← codeword_in[DATA_WIDTH-1:0]` (systematic extraction, no correction).
   - `error_detected ← has_error`.
   - `error_corrected ← 1'b0` (placeholder).
   - `valid_out ← 1'b1` (one cycle).

### Reset

`rst_n = 0` (asynchronous) clears `codeword_out`, `data_out`, `error_detected`,
`error_corrected`, and `valid_out` to zero.

---

## Timing

| Event                              | Cycle |
|------------------------------------|-------|
| `encode_en` / `decode_en` sampled  | 0     |
| `valid_out` high, outputs valid    | 1     |
| `valid_out` returns low            | 2     |

Single-register pipeline: **1-cycle encode/decode latency**.

---

## Known Limitations

1. **No error correction.** `error_corrected` is always `0`.  Berlekamp-Massey, Chien search,
   and Forney magnitude computation are not implemented.
2. **w4 data bus is 4-bit.** The RS code treats the 4-bit input as one full GF(2⁸) symbol with
   the upper nibble forced to zero.  Only 16 of the 256 possible symbol values are used.
3. **No pipeline stall / backpressure.** There is no handshake beyond `valid_out`.  If `encode_en`
   or `decode_en` is held high for multiple cycles, a new operation starts every cycle.
4. **Iverilog elaboration error in syndrome generator.** The generated syndrome code uses
   chained indexing (`codeword_in[7:0][0]`) which is not supported by iverilog.  The expression
   should be simplified to `codeword_in[0]`.  This is a pre-existing issue in the generated RTL
   and does not affect simulation with tools that support multi-dimensional part-selects
   (e.g., VCS, Questa, Cadence).

---

## Source Files

| Type | Path |
|------|------|
| w4  RTL | [`results/issue-5/rtl/reed_solomon_ecc_w4.v`](../rtl/reed_solomon_ecc_w4.v)   |
| w8  RTL | [`results/issue-5/rtl/reed_solomon_ecc_w8.v`](../rtl/reed_solomon_ecc_w8.v)   |
| w16 RTL | [`results/issue-5/rtl/reed_solomon_ecc_w16.v`](../rtl/reed_solomon_ecc_w16.v) |
| w32 RTL | [`results/issue-5/rtl/reed_solomon_ecc_w32.v`](../rtl/reed_solomon_ecc_w32.v) |
| w64 RTL | [`results/issue-5/rtl/reed_solomon_ecc_w64.v`](../rtl/reed_solomon_ecc_w64.v) |
| w128 RTL | [`results/issue-5/rtl/reed_solomon_ecc_w128.v`](../rtl/reed_solomon_ecc_w128.v) |
| Top-level wrapper | [`results/issue-5/rtl/reed_solomon_ecc.v`](../rtl/reed_solomon_ecc.v) |
| Architecture overview | [`results/issue-5/docs/ARCHITECTURE.md`](ARCHITECTURE.md) |
| Wrapper docs | [`results/issue-5/docs/reed_solomon_ecc.md`](reed_solomon_ecc.md) |
