## open-verilog-workbench: `.github` overview

This repository is a shared workbench for **documenting, testing, and fixing Verilog/SystemVerilog designs** using GitHub Issues and AI assistants (Copilot/agents).

### Canonical repository structure

This repo is organized around **per-issue workspaces** under `results/` so that many users can work in parallel without clobbering each other.

- `results/issue-<number>/rtl/` – RTL modules for that issue (e.g. `results/issue-123/rtl/uart_rx.v`).
- `results/issue-<number>/tb/` – unit testbenches for that issue (e.g. `results/issue-123/tb/uart_rx_tb.sv`).
- `results/issue-<number>/docs/` – Markdown documentation generated for that issue (e.g. `results/issue-123/docs/uart_rx.md`).
- `results/issue-<number>/build/` – simulator build artifacts for that issue (Icarus outputs, VCDs, logs).

Each GitHub Issue should map to **one `results/issue-<number>/` tree**, where `<number>` is the GitHub issue number. Within that tree, use consistent module-based naming (e.g. `rtl/uart_rx.v`, `tb/uart_rx_tb.sv`, `docs/uart_rx.md`).

### How users interact with the repo

Most users do **not** need to understand the internals of `.github`. They:

1. Click **New issue**.
2. Choose one of:
   - **Docs** – create/improve documentation for attached RTL/TB.
   - **Testbench** – generate or improve a testbench from attached RTL.
   - **Fix** – fix compile/simulation issues for attached RTL/TB.
3. Attach their Verilog/SystemVerilog files (and logs for Fix) directly to the issue.

The issue templates under `.github/ISSUE_TEMPLATE/` guide them through this flow.

### How Copilot/agents should behave

Copilot/agents should:

- Treat the **issue body + attachments** as the primary requirements.
- Use the canonical layout (`rtl/`, `tb/`, `docs/`, `build/`) for any new files.
- Follow the conventions in:
  - `.github/instructions/verilog.instructions.md` – RTL/TB coding standards.
  - `.github/instructions/docs.instructions.md` – documentation standards.
  - `.github/instructions/ARCHITECTURE.md` – expectations for `docs/ARCHITECTURE.md`.
  - `.github/copilot-instructions.md` – end-to-end workflow and quality bars.


