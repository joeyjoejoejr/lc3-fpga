# Assembler Notes

The assembler should accept the course-visible PennSim LC-3 language first:

- instructions: `ADD`, `AND`, `NOT`, `BR`, `JMP`, `JSR`, `JSRR`, `LD`, `LDI`,
  `LDR`, `LEA`, `ST`, `STI`, `STR`, `TRAP`, `RTI`
- trap aliases: `GETC`, `OUT`, `PUTS`, `IN`, `PUTSP`, `HALT`
- pseudo-ops: `.ORIG`, `.END`, `.FILL`, `.BLKW`, `.STRINGZ`
- literals currently implemented: decimal `#n` or bare `n`, hex `xNNNN`, and
  PennSim-compatible `.STRINGZ` strings
- output: PennSim-style `.obj` files and `.sym` symbol files

PennSim compatibility notes:

- PennSim does not appear to support standalone character literals such as
  `.FILL 'A'`; use numeric ASCII values or `.STRINGZ`.
- PennSim accepts bare decimal literals such as `0` and `2` in operand
  positions; `lc3-asm` accepts those too.

The implementation should favor clear diagnostics and PennSim golden
comparisons over clever parser machinery.
