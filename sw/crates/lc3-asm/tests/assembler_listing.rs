use lc3_asm::assemble;

#[test]
fn lists_directives_and_encoded_instructions() {
    let source = r"
.ORIG x3000
ADD R1, R2, R3
HALT
.END
";

    let assembly = assemble(source);

    assert!(assembly.diagnostics.is_empty());
    let rows = &assembly.listing.rows;
    assert_eq!(rows.len(), 4);

    assert_eq!(rows[0].line, 2);
    assert_eq!(rows[0].address, Some(0x3000));
    assert_eq!(rows[0].word_count, 0);

    assert_eq!(rows[1].line, 3);
    assert_eq!(rows[1].address, Some(0x3000));
    assert_eq!(rows[1].word_count, 1);

    assert_eq!(rows[2].line, 4);
    assert_eq!(rows[2].address, Some(0x3001));
    assert_eq!(rows[2].word_count, 1);

    assert_eq!(rows[3].line, 5);
    assert_eq!(rows[3].address, Some(0x3002));
    assert_eq!(rows[3].word_count, 0);
}

#[test]
fn lists_fill_at_its_encoded_address() {
    let source = r"
.ORIG x3100
VALUE .FILL xABCD
.END
";

    let assembly = assemble(source);

    assert!(assembly.diagnostics.is_empty());
    let rows = &assembly.listing.rows;
    assert_eq!(rows.len(), 3);

    assert_eq!(rows[1].line, 3);
    assert_eq!(rows[1].address, Some(0x3100));
    assert_eq!(rows[1].word_count, 1);
}

#[test]
fn lists_multiword_directives() {
    let source = r#"
.ORIG x3000
MESSAGE .STRINGZ "HI"
SPACE .BLKW #2
HALT
.END
"#;

    let assembly = assemble(source);

    assert!(assembly.diagnostics.is_empty());
    let rows = &assembly.listing.rows;
    assert_eq!(rows.len(), 5);

    assert_eq!(rows[0].line, 2);
    assert_eq!(rows[0].address, Some(0x3000));
    assert_eq!(rows[0].word_count, 0);

    assert_eq!(rows[1].line, 3);
    assert_eq!(rows[1].address, Some(0x3000));
    assert_eq!(rows[1].word_count, 3);

    assert_eq!(rows[2].line, 4);
    assert_eq!(rows[2].address, Some(0x3003));
    assert_eq!(rows[2].word_count, 2);

    assert_eq!(rows[3].line, 5);
    assert_eq!(rows[3].address, Some(0x3005));
    assert_eq!(rows[3].word_count, 1);

    assert_eq!(rows[4].line, 6);
    assert_eq!(rows[4].address, Some(0x3006));
    assert_eq!(rows[4].word_count, 0);
}

#[test]
fn leaves_listing_addresses_unknown_when_origin_is_invalid() {
    let source = r"
.ORIG INVALID
ADD R0, R0, #1
.END
";

    let assembly = assemble(source);

    assert!(assembly.image.is_none());
    assert!(!assembly.diagnostics.is_empty());
    let rows = &assembly.listing.rows;
    assert_eq!(rows.len(), 3);
    assert_eq!(rows[0].address, None);
    assert_eq!(rows[1].address, None);
    assert_eq!(rows[2].address, None);
}

#[test]
fn retains_listing_row_for_malformed_instruction() {
    let source = r"
.ORIG x3000
ADD R0, R0, #16
.END
";

    let assembly = assemble(source);

    assert!(assembly.image.is_none());
    assert!(!assembly.diagnostics.is_empty());
    let rows = &assembly.listing.rows;
    assert_eq!(rows.len(), 3);
    assert_eq!(rows[1].line, 3);
    assert_eq!(rows[1].address, Some(0x3000));
    assert_eq!(rows[1].word_count, 0);
}
