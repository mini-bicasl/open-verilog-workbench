---
applyTo: "results/issue-<number>/docs/*.md"
---

Documentation in this repository should be concise, technical, and directly tied to the implemented RTL and tests.

Documentation is organized into:

- `results/issue-<number>/docs/ARCHITECTURE.md`: top-level view of the design and its top-level testbench(es).
- `results/issue-<number>/docs/<module>.md`: per-module docs that describe individual RTL modules and their associated testbenches.

## Standards & reference docs

If a module/design targets an external standard (e.g. JEDEC DDRx, AMBA AXI, PCIe, USB, Ethernet):

- Capture **standard name + version** and include official citation links.
- When the reference is **publicly accessible**, store a local copy under `docs/` and link to it from the relevant docs (especially `docs/ARCHITECTURE.md`).
- Do **not** download or redistribute **paywalled/copyrighted** documents. Instead, rely on user-provided excerpts/requirements or public summaries.

## Architecture doc (`results/issue-<number>/docs/ARCHITECTURE.md`)

`results/issue-<number>/docs/ARCHITECTURE.md` is the **entry point** for understanding the design.

When writing or updating it:

- Start with a short overview of the design’s purpose and environment (what it talks to, clocks/resets, any key standards).
- Describe the **top-level RTL**:
  - Name of the top module.
  - Its external ports and high-level function.
- Describe the **top-level testbench**:
  - File and module names.
  - How the DUT is instantiated (clocks, resets, stimulus style).
- Summarize the module breakdown:
  - For each major submodule: name, role, and where more detail can be found (link to `results/issue-<number>/docs/<module>.md` when it exists).
- Include links to any relevant external standards or requirements documents when applicable.

- **Single-module case**: if the input for an issue is only **one** Verilog module (and maybe its testbench), it is sufficient to generate/update **only** `results/issue-<number>/docs/ARCHITECTURE.md` and describe that one module + its testbench there. Separate `results/issue-<number>/docs/<module>.md` files are optional in that case.

## Module docs (`results/issue-<number>/docs/<module>.md`)

When writing or updating module documentation:

- Start with a short overview: what the module does and where it fits in `results/issue-<number>/docs/ARCHITECTURE.md`.
- Document the interface:
  - Port name, direction, width, and meaning (tables are preferred).
- Describe control flow:
  - FSM states and transitions (ASCII or Mermaid diagrams are fine).
- Note any key constraints:
  - Timing assumptions, backpressure/handshake semantics, reset behavior.
- Cross-link the code:
  - `rtl/<module>.v` and `tb/<module>_tb.v`.

## Inline comments in RTL/testbenches

When creating or updating documentation, it is also acceptable (and encouraged) to make the Verilog/SystemVerilog **easier to read** by improving inline comments, as long as:

- Comments stay **brief and technical**, avoiding restating obvious signal names or logic.
- Comments **match the implemented behavior** and do not contradict the RTL or tests.
- High-level explanations in comments are consistent with the corresponding `results/issue-<number>/docs/*.md` pages.

Examples of good comment use:

- Documenting non-obvious protocol assumptions (e.g., “AXI-lite write address must be aligned to 4 bytes”).
- Capturing subtle timing/latency behavior or corner cases that are easy to miss from the code alone.
- Explaining why specific parameters, magic numbers, or encodings are chosen.

