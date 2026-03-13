# Reed-Solomon ECC Testbench Report — issue-9

## DUT and Testbench List

| Testbench | DUT module | DATA_WIDTH | Codeword width |
|-----------|-----------|-----------|---------------|
| `results/issue-9/tb/reed_solomon_ecc_tb.sv` | `reed_solomon_ecc` (wrapper) | 8  | 40-bit  |
| `results/issue-9/tb/reed_solomon_ecc_tb.sv` | `reed_solomon_ecc` (wrapper) | 16 | 48-bit  |
| `results/issue-9/tb/reed_solomon_ecc_tb.sv` | `reed_solomon_ecc` (wrapper) | 32 | 64-bit  |
| `results/issue-9/tb/reed_solomon_ecc_tb.sv` | `reed_solomon_ecc` (wrapper) | 64 | 96-bit  |

RTL source: `results/issue-9/rtl/` (copied from `results/issue-7/rtl/` which includes the
Icarus Verilog compatibility fixes applied in issue-7).

## How to Run

From the repository root:

```bash
# Compile
iverilog -g2012 -o results/issue-9/build/reed_solomon_ecc_tb.out \
    results/issue-9/tb/reed_solomon_ecc_tb.sv \
    results/issue-9/rtl/reed_solomon_ecc.v \
    results/issue-9/rtl/reed_solomon_ecc_w4.v \
    results/issue-9/rtl/reed_solomon_ecc_w8.v \
    results/issue-9/rtl/reed_solomon_ecc_w16.v \
    results/issue-9/rtl/reed_solomon_ecc_w32.v \
    results/issue-9/rtl/reed_solomon_ecc_w64.v \
    results/issue-9/rtl/reed_solomon_ecc_w128.v \
    2>&1 | tee results/issue-9/build/compile.log

# Run
vvp results/issue-9/build/reed_solomon_ecc_tb.out \
    2>&1 | tee results/issue-9/build/sim.log
```

Artifacts written to `results/issue-9/build/`:
- `compile.log` — iverilog compilation output
- `sim.log`     — vvp simulation output
- `reed_solomon_ecc_tb.vcd` — waveform dump (excluded from git via `.gitignore`)

## Results

**Status: PASS — all 34 checks passed.**

```
=== PASS: All checks passed ===
```

Codewords observed during simulation:

| DUT | Input data | Encoded codeword |
|-----|-----------|------------------|
| DUT8  | `0xAB`               | `0x95027b47ab`             |
| DUT8  | `0xFF`               | `0x3147e56cff`             |
| DUT16 | `0xBEEF`             | `0x680e7641beef`           |
| DUT32 | `0xDEADBEEF`         | `0xb5bb1438deadbeef`       |
| DUT64 | `0xCAFEBABEDEAD1234` | `0x01037710cafebabedead1234` |

## Coverage Description

| Scenario | DUT(s) | Description |
|----------|--------|-------------|
| S0  | all   | Active-low async reset: all outputs held 0 while `rst_n=0` |
| S1  | DUT8  | Nominal encode (0xAB) + decode round-trip; `valid_out` pulse timing |
| S2  | DUT8  | All-zero data → all-zero codeword; all-zero codeword → no error |
| S3  | DUT8  | All-ones data (0xFF) encode + decode round-trip |
| S4  | DUT8  | Error detection: single parity byte fully flipped |
| S5  | DUT8  | Error detection: single-bit flip in data byte |
| S6  | DUT8  | `error_corrected` is always 0 (RTL placeholder confirmed) |
| S7  | DUT8  | Back-to-back encodes: `encode_en` held 3 cycles; last datum wins |
| S8  | DUT8  | Simultaneous `encode_en + decode_en` in the same cycle |
| S9  | DUT8  | Async reset asserted mid-operation; outputs clear immediately |
| S10 | DUT16 | Encode (0xBEEF) + decode round-trip; systematic data bytes preserved |
| S10b| DUT16 | Error detection: parity byte flip |
| S11 | DUT32 | Encode (0xDEADBEEF) + decode round-trip |
| S11b| DUT32 | Error detection: single-bit data flip |
| S12 | DUT32 | All-zero data → all-zero codeword |
| S13 | DUT64 | Encode (0xCAFEBABEDEAD1234) + decode round-trip |
| S13b| DUT64 | Error detection: single-bit flip in data byte 0 |

## Gaps / Limitations

- **DATA_WIDTH = 4 and 128** are not directly exercised in this testbench.
  The wrapper logic for those widths is structurally identical to the tested variants
  and was already covered in `results/issue-7/`.
- **Error correction** (`error_corrected` output) is not implemented in the RTL
  (placeholder always 0). There are no decode-and-verify correction tests.
- **Multi-symbol error injection** (≥2 corrupted symbols simultaneously) is not tested.
  The RTL computes syndromes but does not perform Berlekamp-Massey / Chien search.
- **codeword_in upper bits** (beyond the meaningful slice) are not exercised with
  non-zero values; the wrapper is expected to ignore them by construction.
