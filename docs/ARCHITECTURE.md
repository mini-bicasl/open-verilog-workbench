# Architecture Overview

This document lists the modules present in the repository and links to their individual
documentation pages.

## Modules

| Module | RTL | Documentation |
|--------|-----|---------------|
| `reed_solomon_ecc` | [`results/issue-1/rtl/reed_solomon_ecc.v`](../results/issue-1/rtl/reed_solomon_ecc.v) | [`results/issue-1/docs/reed_solomon_ecc.md`](../results/issue-1/docs/reed_solomon_ecc.md) |

## Directory Layout

```
results/
  issue-<N>/
    rtl/    – synthesisable RTL for issue N
    tb/     – testbenches for issue N
    docs/   – per-module Markdown documentation for issue N
    build/  – compiled simulation outputs and VCDs for issue N
docs/
  ARCHITECTURE.md  – this file (system-level module list)
```
