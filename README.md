## Open-Verilog-Workbench

[![Status: experimental](https://img.shields.io/badge/status-experimental-orange)](https://github.com/mini-bicasl/open-verilog-workbench)
[![License: CC BY 4.0](https://img.shields.io/badge/license-CC%20BY%204.0-blue)](https://creativecommons.org/licenses/by/4.0/)
[![GitHub issues](https://img.shields.io/github/issues/mini-bicasl/open-verilog-workbench)](https://github.com/mini-bicasl/open-verilog-workbench/issues)
[![Discussions](https://img.shields.io/github/discussions/mini-bicasl/open-verilog-workbench)](https://github.com/mini-bicasl/open-verilog-workbench/discussions)

This directory configures how **issues, instructions, and AI assistants (Copilot/agents)** behave in the `open-verilog-workbench` repository. The repo is a shared workbench for **documenting, testing, and fixing Verilog/SystemVerilog designs** via GitHub Issues.

The root of the repository is licensed under **Creative Commons Attribution 4.0 International (CC BY 4.0)**. See the top-level `LICENSE` file or the [official license page](https://creativecommons.org/licenses/by/4.0/) for details.

### Workflows supported by this repo

This repo is intentionally focused on **three workflows**, all driven through GitHub Issues:

- **Docs**: create or improve documentation for Verilog/SystemVerilog RTL and testbenches.
- **Testbench**: generate or improve testbenches based on existing RTL.
- **Fix**: debug and fix RTL/TB compile or simulation issues using attached logs.

Users typically do **not** need to understand the internals of `.github`. The normal flow is:

1. Click **New issue** on the main repository page.
2. Choose one of the templates:
   - **Docs: Create / improve documentation**
   - **Testbench: Generate TB from RTL**
   - (Fix template, if enabled in this repo)
3. Attach your Verilog/SystemVerilog files (and logs for Fix) or reference in-repo paths.
4. Submit the issue and let Copilot/agents handle the rest using the instructions in this folder.

The issue templates under `.github/ISSUE_TEMPLATE/` guide you through what to provide.

### Important note about attaching files to issues

GitHub does **not** accept some source file types (for example `.v`, `.sv`, `.vh`, `.cpp`) directly in issue attachments and may show an error like:

> File type .v not supported. See the documentation for supported file types.

When that happens, you should either:

- **Compress your source files into a `.zip`** and attach the archive, or
- **Rename the files with a supported extension** (for example change `foo.v` → `foo.v.txt`) and clearly mention the original names in the issue body.

Copilot/agents are expected to treat any attached `.zip` archives or renamed files (such as `.v.txt`, `.sv.txt`) as the canonical source and restore the appropriate extensions when creating files under `results/issue-<number>/` or other repo paths.

### Canonical repository structure

This repo is organized around **per-issue workspaces** under `results/` so that many users can work in parallel without clobbering each other.

- `results/issue-<number>/rtl/` – RTL modules for that issue (e.g. `results/issue-123/rtl/uart_rx.v`).
- `results/issue-<number>/tb/` – unit testbenches for that issue (e.g. `results/issue-123/tb/uart_rx_tb.sv`).
- `results/issue-<number>/docs/` – Markdown documentation generated for that issue (e.g. `results/issue-123/docs/uart_rx.md`).
- `results/issue-<number>/build/` – simulator build artifacts for that issue (Icarus outputs, VCDs, logs).

Each GitHub Issue should map to **one `results/issue-<number>/` tree**, where `<number>` is the GitHub issue number. Within that tree, use consistent module-based naming (e.g. `rtl/uart_rx.v`, `tb/uart_rx_tb.sv`, `docs/uart_rx.md`).

### How Copilot/agents should behave

Copilot/agents should:

- Treat the **issue body + attachments** (including `.zip` archives and any `.txt`-renamed source files) as the primary requirements.
- Use the canonical layout (`rtl/`, `tb/`, `docs/`, `build/`) for any new files.
- Keep per-issue work self-contained under `results/issue-<number>/`.
- Follow the conventions in:
  - `.github/instructions/verilog.instructions.md` – RTL/TB coding standards.
  - `.github/instructions/TB.md` – testbench behavior and structure.
  - `.github/instructions/DOCS.md` – documentation standards.
  - `.github/copilot-instructions.md` – end-to-end workflow and quality bars.

