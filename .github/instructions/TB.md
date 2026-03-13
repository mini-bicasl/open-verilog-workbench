---
applyTo: "tb/**/*.v,tb/**/*.sv,results/issue-*/tb/**/*.v,results/issue-*/tb/**/*.sv"
---

# Testbench instructions (open-verilog-workbench)

This file defines how **testbenches** should look and behave for this repository. It complements `.github/instructions/verilog.instructions.md` and `.github/copilot-instructions.md`.

## Goals

- Make testbenches **deterministic**, **self-checking**, and easy to run with **Icarus Verilog**.
- Keep expectations consistent across:
  - `tb/<module>_tb.{v,sv}` in the root repo, and
  - `results/issue-<number>/tb/*.v` / `*.sv` for per-issue workspaces.

## Required structure

- One top-level testbench module per file, typically named `<module>_tb`.
- Instantiate exactly one DUT (design-under-test) per testbench file, unless the issue explicitly calls for a multi-DUT integration test.
- Group signals logically:
  - clock/reset
  - inputs to DUT
  - outputs from DUT

## Clock and reset

- Provide a **single primary clock** unless the design clearly needs more.
- Use an **active-low reset** named `rst_n` by default (match the RTL if it differs).
- Hold reset active for a few cycles at the start of simulation, then deassert it cleanly on a clock edge.

## Stimulus and checking

- Prefer **directed stimulus** that covers:
  - nominal / “happy path” operation, and
  - at least a couple of important edge or corner cases described in the issue.
- Make tests **self-checking**:
  - Use SystemVerilog assertions when available, or
  - Use explicit checks with `$fatal`, `$error`, or `$display` + final pass/fail summary.
- Avoid purely waveform-inspection testbenches that rely on a human to decide pass/fail.

## Waveforms and logs

- Dump a VCD (or similar) waveform to a predictable location, for example:
  - `build/<module>_tb.vcd`, or
  - `results/issue-<number>/build/<module>_tb.vcd`.
- Print clear log messages for:
  - start/end of simulation,
  - key scenario boundaries,
  - any detected failures.

## Compile and run commands

- Testbenches must compile and run with **Icarus Verilog**. A typical flow is:

  - `iverilog -g2012 -o build/<module>.out tb/<module>_tb.sv rtl/<module>.v`
  - `vvp build/<module>.out`

- For per-issue workspaces, adjust paths accordingly, for example:

  - `iverilog -g2012 -o results/issue-<number>/build/<module>.out results/issue-<number>/tb/<module>_tb.sv results/issue-<number>/rtl/<module>.v`
  - `vvp results/issue-<number>/build/<module>.out`

## Guidance for Copilot/agents

- Treat the **issue body + attachments** as the source of truth for:
  - which module(s) to test,
  - what behaviors and corner cases matter,
  - any specific timing, reset, or protocol requirements.
- When users attach standalone files, place new/updated testbenches under:
  - `tb/` if they are meant to become part of the main repo, or
  - `results/issue-<number>/tb/` if they are per-issue artifacts.
- When improving an existing testbench:
  - preserve working behavior,
  - make checking stricter and more explicit rather than looser,
  - keep names and structure consistent with the existing RTL and docs.
