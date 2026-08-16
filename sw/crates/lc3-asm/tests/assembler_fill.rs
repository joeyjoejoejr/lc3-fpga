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
fn assembles_stringz_as_ascii_words_with_zero_terminator() {
    let source = r#"
.ORIG x3000
MESSAGE .STRINGZ "HI"
NEXT .FILL MESSAGE
.FILL NEXT
.END
"#;

    let assembly = assemble(source).expect("source should assemble");

    assert_eq!(assembly.image.origin(), 0x3000);
    assert_eq!(
        assembly.image.words(),
        &[
            0x0048, // 'H'
            0x0049, // 'I'
            0x0000, // zero terminator
            0x3000, // .FILL MESSAGE
            0x3003, // .FILL NEXT
        ]
    );
}

#[test]
fn assembles_empty_stringz_as_zero_terminator() {
    let source = r#"
.ORIG x3000
EMPTY .STRINGZ ""
NEXT .FILL NEXT
.END
"#;

    let assembly = assemble(source).expect("source should assemble");

    assert_eq!(assembly.image.origin(), 0x3000);
    assert_eq!(
        assembly.image.words(),
        &[
            0x0000, // zero terminator
            0x3001, // .FILL NEXT
        ]
    );
}

#[test]
fn assembles_stringz_with_pennsim_escapes() {
    let source = r#"
.ORIG x3000
.STRINGZ "A\nB\tC\"D\0E"
.END
"#;

    let assembly = assemble(source).expect("source should assemble");

    assert_eq!(assembly.image.origin(), 0x3000);
    assert_eq!(
        assembly.image.words(),
        &[
            0x0041, // 'A'
            0x000A, // '\n'
            0x0042, // 'B'
            0x0009, // '\t'
            0x0043, // 'C'
            0x0022, // '"'
            0x0044, // 'D'
            0x0000, // '\0'
            0x0045, // 'E'
            0x0000, // zero terminator
        ]
    );
}

#[test]
fn keeps_unknown_stringz_escapes_literal_like_pennsim() {
    let source = r#"
.ORIG x3000
.STRINGZ "A\\B\x41C\rD\bE\'F"
.END
"#;

    let assembly = assemble(source).expect("source should assemble");

    assert_eq!(assembly.image.origin(), 0x3000);
    assert_eq!(
        assembly.image.words(),
        &[
            0x0041, // 'A'
            0x005C, // '\'
            0x005C, // '\'
            0x0042, // 'B'
            0x005C, // '\'
            0x0078, // 'x'
            0x0034, // '4'
            0x0031, // '1'
            0x0043, // 'C'
            0x005C, // '\'
            0x0072, // 'r'
            0x0044, // 'D'
            0x005C, // '\'
            0x0062, // 'b'
            0x0045, // 'E'
            0x005C, // '\'
            0x0027, // '''
            0x0046, // 'F'
            0x0000, // zero terminator
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
