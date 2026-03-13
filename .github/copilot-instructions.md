# Copilot instructions (open-verilog-workbench)

This repository is meant to help users with **three workflows** only:

- **Docs**: create or improve documentation for Verilog/SystemVerilog RTL and testbenches.
- **Testbench**: generate or improve testbenches based on existing RTL.
- **Fix**: fix RTL/TB compile or simulation issues.

Users should:

1. Click **New issue**.
2. Choose **Docs**, **Testbench**, or **Fix**.
3. **Attach their Verilog/SystemVerilog files (and logs for Fix)** directly to the issue.

As Copilot/agent, always treat the issue body + attachments as the **single source of truth**.

## Mapping from issues to tasks

- `.github/ISSUE_TEMPLATE/docs.yml` → **Documentation task** for attached RTL/TB.
- `.github/ISSUE_TEMPLATE/testbench.yml` → **Testbench generation/improvement** based on attached RTL.
- `.github/ISSUE_TEMPLATE/fix.yml` → **Debug/fix** for attached RTL/TB and logs.

Do **not** depend on any external planning JSON or legacy `results/` / `PLAN.md` files. Everything you need should be in:

- the **issue template prompts**,
- the **attached RTL/TB files and logs**, and
- any existing files in the repo under `rtl/`, `tb/`, and `docs/`.

## Repo layout (expected inputs/outputs)

This repo uses **per-issue workspaces** under `results/` so multiple users can work safely in parallel.

- `results/issue-<number>/rtl/`: RTL modules for that issue (e.g. `results/issue-123/rtl/uart_rx.v`).
- `results/issue-<number>/tb/`: testbenches for that issue (e.g. `results/issue-123/tb/uart_rx_tb.sv`).
- `results/issue-<number>/docs/`: Markdown docs for that issue (e.g. `results/issue-123/docs/uart_rx.md`).
- `results/issue-<number>/build/`: compiled simulation outputs and VCDs for that issue.

When users attach standalone files (not yet in the repo), you should:

- determine the GitHub issue number (for example `#123` → `issue-123`),
- create or update files under `results/issue-<number>/{rtl,tb,docs,build}` with clear module-based names,
- keep all artifacts for that issue self-contained in its `results/issue-<number>/` tree.

## Workflow 1: Documentation from RTL/TB

When the **Docs** template is used:

1. Read all attached RTL/TB files and any existing `docs/*.md` for context.
2. For each module the user calls out, generate or update `docs/<module>.md` with:
   - high-level purpose and behavior,
   - ports table (direction, width, meaning),
   - parameters and defaults,
   - reset behavior and any latency/timing assumptions,
   - a short usage example when possible,
   - links back to `rtl/<module>.v` and `tb/<module>_tb.{v,sv}`.
3. Where it improves readability, add or refine **brief inline comments** in the relevant RTL/testbench files to clarify intent, non-obvious timing/handshake behavior, or protocol assumptions. Keep comments consistent with the code and the docs, and avoid restating the obvious.
4. Keep documentation **technical and concise**, matching the actual RTL, not guesses.

## Workflow 2: Generate / improve testbench from RTL

When the **Testbench** template is used:

1. Read the attached RTL (and any existing TB) and the user’s description of what to verify.
2. Create or update a deterministic, self-checking testbench in `tb/<module>_tb.{v,sv}` that:
   - instantiates the DUT with the correct ports/parameters,
   - generates clock and active-low reset (`rst_n`, unless told otherwise),
   - drives nominal scenarios and the edge/corner cases described in the issue,
   - uses assertions or explicit `$fatal` checks for pass/fail,
   - optionally dumps VCD to `build/<module>.vcd` (or similar) for debugging.
3. Include example commands in the PR description for how to build and run with Icarus Verilog.

## Workflow 3: Fix RTL/TB compile or simulation issues

When the **Fix** template is used:

1. Read the attached RTL/TB files, logs, and the exact commands the user runs.
2. Reproduce the compile/simulation issue when possible using the provided commands.
3. Propose minimal, well-justified changes to RTL and/or TB to:
   - restore clean compilation,
   - and/or make the simulation behavior match the described expectations.
4. Clearly explain in the PR what changed and why, and how to re-run the fix.

## Validation gate (must be real)

Do not claim completion unless you actually ran compilation/simulation successfully (when a simulator is available).

Example commands (edit to match the repo):

- Compile: `iverilog -g2012 -o build/a.out tb/<module>_tb.sv rtl/<module>.v`
- Run: `vvp build/a.out`

## Quality bars

### Documentation

Docs should include:

- purpose + high-level behavior,
- ports table (direction, width, meaning),
- parameters and defaults,
- reset behavior and any latency/timing assumptions,
- brief usage examples when helpful.

### Testbenches

Testbenches should be:

- deterministic and self-checking,
- include clock/reset generation,
- cover at least nominal flow + edge/corner cases described in the issue,
- produce a VCD (when practical) for debugging.

