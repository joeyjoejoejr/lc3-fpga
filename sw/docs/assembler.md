# Assembler Notes

The assembler should accept the course-visible PennSim LC-3 language first:

- instructions: `ADD`, `AND`, `NOT`, `BR`, `JMP`, `JSR`, `JSRR`, `LD`, `LDI`,
  `LDR`, `LEA`, `ST`, `STI`, `STR`, `TRAP`, `RTI`
- pseudo-ops: `.ORIG`, `.END`, `.FILL`, `.BLKW`, `.STRINGZ`
- literals: decimal `#n`, hex `xNNNN`, and PennSim-compatible character and
  string forms

The first implementation should favor clear diagnostics and PennSim golden
comparisons over clever parser machinery.
