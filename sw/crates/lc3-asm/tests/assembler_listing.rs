use lc3_asm::assemble;

#[test]
#[ignore = "listing generation is not implemented yet"]
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
    assert_eq!(rows[3].address, None);
    assert_eq!(rows[3].word_count, 0);
}

#[test]
#[ignore = "listing generation is not implemented yet"]
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
