# Simulator API Notes

The CLI, desktop GUI, and web app should share the same simulator-facing
concepts:

- load an origin-addressed memory image
- reset with a selected PC
- run, pause, step, and stop
- inspect registers, condition codes, memory, and device state
- deliver keyboard/UART input and collect console/display output

Execution should come from the Verilated RTL model, not from a hand-written
host CPU interpreter.
