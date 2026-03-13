# Architecture Overview — Issue 5

## Purpose

This workspace documents the **Reed-Solomon ECC** module family delivered in
[issue #5](https://github.com/mini-bicasl/open-verilog-workbench/issues/5).

The design implements a parameterised Reed-Solomon error-correction engine over **GF(2⁸)** with a
correction capability of **T = 2** (two-symbol errors, four parity bytes) and a primitive polynomial
of **0x11D** (first consecutive root FCR = 0).  It is intended for use as a synthesisable
memory/link-layer ECC block.

---

## Top-Level RTL: `reed_solomon_ecc`

**File:** [`results/issue-5/rtl/reed_solomon_ecc.v`](../rtl/reed_solomon_ecc.v)

### Parameter

| Parameter    | Default | Supported values       | Description                                      |
|--------------|---------|------------------------|--------------------------------------------------|
| `DATA_WIDTH` | 8       | 4, 8, 16, 32, 64, 128 | Data bus width in bits.  Any other value selects the `fallback` branch (all outputs = 0). |

### External Ports

| Port             | Dir    | Width        | Description                                               |
|------------------|--------|--------------|-----------------------------------------------------------|
| `clk`            | input  | 1            | System clock — rising-edge triggered                      |
| `rst_n`          | input  | 1            | Asynchronous active-low reset                             |
| `encode_en`      | input  | 1            | Assert to start RS encode; `data_in` is consumed          |
| `decode_en`      | input  | 1            | Assert to start RS decode; `codeword_in` is consumed      |
| `data_in`        | input  | `DATA_WIDTH` | Raw data word (encode) or received word (decode)          |
| `codeword_in`    | input  | 160          | Received codeword; only lower N bits used (see table)     |
| `codeword_out`   | output | 160          | Encoded codeword; lower N bits valid, upper bits = 0      |
| `data_out`       | output | `DATA_WIDTH` | Corrected data word after decode                          |
| `error_detected` | output | 1            | At least one symbol error detected (syndrome ≠ 0)         |
| `error_corrected`| output | 1            | Errors corrected — **placeholder, currently always 0**    |
| `valid_out`      | output | 1            | Single-cycle pulse: outputs are valid                     |

### Clock / Reset

- **Single clock domain** — all sequential logic clocked on `posedge clk`.
- **Active-low asynchronous reset** — `rst_n = 0` clears all sub-module registers immediately.
- The wrapper itself is purely combinational (`generate` / `assign`); registered outputs live in the selected `reed_solomon_ecc_wN` sub-module.

---

## Sub-Module Breakdown

A `generate` block at elaboration time selects and instantiates exactly one width-specific
sub-module.  The wrapper slices `codeword_in[N-1:0]` for the sub-module input and zero-pads
`codeword_out` back to 160 bits.

| `DATA_WIDTH` | Data bytes (K) | Parity bytes | Codeword bits (N×8) | Active slice  | Sub-module                | Doc page                              |
|:---:|:---:|:---:|:---:|:---:|:---|:---|
| 4   | 1 | 4 | 40  | `[39:0]`   | `reed_solomon_ecc_w4`   | [reed_solomon_ecc_wN.md](reed_solomon_ecc_wN.md) |
| 8   | 1 | 4 | 40  | `[39:0]`   | `reed_solomon_ecc_w8`   | [reed_solomon_ecc_wN.md](reed_solomon_ecc_wN.md) |
| 16  | 2 | 4 | 48  | `[47:0]`   | `reed_solomon_ecc_w16`  | [reed_solomon_ecc_wN.md](reed_solomon_ecc_wN.md) |
| 32  | 4 | 4 | 64  | `[63:0]`   | `reed_solomon_ecc_w32`  | [reed_solomon_ecc_wN.md](reed_solomon_ecc_wN.md) |
| 64  | 8 | 4 | 96  | `[95:0]`   | `reed_solomon_ecc_w64`  | [reed_solomon_ecc_wN.md](reed_solomon_ecc_wN.md) |
| 128 |16 | 4 | 160 | `[159:0]`  | `reed_solomon_ecc_w128` | [reed_solomon_ecc_wN.md](reed_solomon_ecc_wN.md) |

If `DATA_WIDTH` is not one of the six supported values the `fallback` `generate` branch drives
all outputs to zero.

For complete per-module documentation see:
- [`results/issue-5/docs/reed_solomon_ecc.md`](reed_solomon_ecc.md) — top-level wrapper
- [`results/issue-5/docs/reed_solomon_ecc_wN.md`](reed_solomon_ecc_wN.md) — sub-modules

---

## Key Design Notes

- **Error detection only** — `error_corrected` is a registered placeholder that is always driven
  to `0`.  Full error correction (Berlekamp-Massey / Chien search / Forney) is not yet
  implemented in the sub-modules.
- **One-cycle latency** — from the rising edge that samples `encode_en` or `decode_en`, outputs
  (`codeword_out`, `data_out`, `error_detected`, `valid_out`) are valid on the very next rising
  edge (single-register pipeline).
- **Mutually exclusive enables** — do not assert `encode_en` and `decode_en` simultaneously
  unless sub-module behaviour for that case is explicitly tested.
- **Iverilog elaboration issue** — the generated syndrome-generator code uses chained
  range+bit indexing (`codeword_in[7:0][0]`) not supported by iverilog.  This is a pre-existing
  code-generation artefact; see the
  [Known Limitations section](reed_solomon_ecc_wN.md#known-limitations) for details.

---

## Directory Layout

```
results/
  issue-5/
    rtl/    – reed_solomon_ecc.v (top-level wrapper)
             reed_solomon_ecc_w4.v
             reed_solomon_ecc_w8.v
             reed_solomon_ecc_w16.v
             reed_solomon_ecc_w32.v
             reed_solomon_ecc_w64.v
             reed_solomon_ecc_w128.v
    tb/     – testbenches (TBD)
    docs/   – this file, reed_solomon_ecc.md, reed_solomon_ecc_wN.md
    build/  – compiled simulation outputs (TBD)
```

---

## External Standards

Reed-Solomon codes over GF(2⁸) with T = 2 correction are widely used in:

- JEDEC NAND Flash ECC
- Various RAID-6 and storage controller implementations

Reference: S. B. Wicker & V. K. Bhargava, *Reed-Solomon Codes and Their Applications*,
IEEE Press, 1994.
