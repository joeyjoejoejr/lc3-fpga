use lc3_asm::assemble;

#[test]
fn assembles_trap_instruction() {
    let source = r"
.ORIG x3000
TRAP x25
.END
";

    let assembly = assemble(source).expect("source should assemble");

    assert_eq!(assembly.image.origin(), 0x3000);
    assert_eq!(assembly.image.words(), &[0xF025]);
}

#[test]
fn assembles_trap_aliases() {
    let source = r"
.ORIG x3000
GETC
OUT
PUTS
IN
PUTSP
HALT
.END
";

    let assembly = assemble(source).expect("source should assemble");

    assert_eq!(assembly.image.origin(), 0x3000);
    assert_eq!(
        assembly.image.words(),
        &[0xF020, 0xF021, 0xF022, 0xF023, 0xF024, 0xF025]
    );
}

#[test]
fn reports_trap_alias_operands() {
    let source = r"
.ORIG x3000
HALT x25
.END
";

    let diagnostics = assemble(source).expect_err("source should not assemble");

    assert_eq!(diagnostics.len(), 1);
    assert_eq!(diagnostics[0].message, "HALT expects no operands");
    assert_eq!(diagnostics[0].location.line, 3);
}
