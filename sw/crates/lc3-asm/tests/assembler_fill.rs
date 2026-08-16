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
fn assembles_blkw_as_zero_filled_words() {
    let source = r"
.ORIG x3000
START .BLKW #3
NEXT .FILL START
.FILL NEXT
.END
";

    let assembly = assemble(source).expect("source should assemble");

    assert_eq!(assembly.image.origin(), 0x3000);
    assert_eq!(
        assembly.image.words(),
        &[
            0x0000, // START .BLKW #3
            0x0000, 0x0000, 0x3000, // .FILL START
            0x3003, // .FILL NEXT
        ]
    );
}

#[test]
fn reports_blkw_that_exceeds_address_space() {
    let source = r"
.ORIG xFFFF
.BLKW #2
.END
";

    let diagnostics = assemble(source).expect_err("source should not assemble");

    assert_eq!(diagnostics.len(), 1);
    assert_eq!(diagnostics[0].message, "address out of bounds");
    assert_eq!(diagnostics[0].location.line, 3);
}

#[test]
fn reports_instruction_after_blkw_that_exceeds_address_space() {
    let source = r"
.ORIG xFFFE
.BLKW #2
.FILL #1
.END
";

    let diagnostics = assemble(source).expect_err("source should not assemble");

    assert_eq!(diagnostics.len(), 1);
    assert_eq!(diagnostics[0].message, "address out of bounds");
    assert_eq!(diagnostics[0].location.line, 4);
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
