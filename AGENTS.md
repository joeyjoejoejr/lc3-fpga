# Agent Notes

This repository is a collaborative LC-3 FPGA project. Future Codex sessions should follow these preferences unless the user says otherwise.

- Prefer review, tests, and scaffolding before implementing new features. The user often wants to write the RTL changes personally.
- When the user asks for implementation, keep changes tightly scoped to the requested behavior and existing repo patterns.
- Before privilege, OS, interrupt, or memory-protection work, inspect `docs/os-compatibility.md` and `rtl/lc3_core.sv`.
- After making a commit, push the current branch to the configured remote.
- Do not revert user changes unless the user explicitly asks for that.
