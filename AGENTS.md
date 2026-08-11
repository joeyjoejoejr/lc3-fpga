# Agent Notes

This repository is a collaborative LC-3 FPGA project. Future Codex sessions should follow these preferences unless the user says otherwise.

- Prefer review, tests, and scaffolding before implementing new features. The user often wants to write the RTL changes personally.
- When the user asks for implementation, keep changes tightly scoped to the requested behavior and existing repo patterns.
- In explanatory answers, prefer pseudocode and architectural descriptions instead of real RTL/code snippets unless the user explicitly asks for concrete code.
- For new RTL behavior, prefer adding a focused test target first. It is okay for that target to fail until the user implements the RTL.
- Keep failing or in-progress tests out of `make test`; once they pass, add them to the main run.
- Run `make test` before commits when practical, and mention if it was not run.
- When debugging RTL, explain the likely issue narrowly before making code changes unless the user explicitly asks for a fix.
- Before privilege, OS, interrupt, or memory-protection work, inspect `docs/os-compatibility.md` and `rtl/lc3_core.sv`.
- Makefile reset-PC values should use decimal to avoid shell quoting issues with Verilog literals; `512` is `x0200`, and `12288` is `x3000`.
- The real OS smoke path uses `andme` with the course OS object, resets at `x0200`, and `test-andme-os` verifies OS boot, traps, keyboard polling, and console output.
- After making a commit, push the current branch to the configured remote.
- Do not revert user changes unless the user explicitly asks for that.
