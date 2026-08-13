use lc3_asm::assemble;

#[test]
fn assembles_single_fill_literal() {
    let source = r"
.ORIG x3000
.FILL #42
.END
";

    let assembly = assemble(source).expect("source should assemble");

    assert_eq!(assembly.image.origin(), 0x3000);
    assert_eq!(assembly.image.words(), &[0x002A]);
}

#[test]
fn reports_statement_after_end() {
    let source = r"
.ORIG x3000
.END
.FILL #42
";

    let diagnostics = assemble(source).expect_err("source should not assemble");

    assert_eq!(diagnostics.len(), 1);
    assert_eq!(diagnostics[0].message, "statement after .END");
    assert_eq!(diagnostics[0].location.line, 4);
}
