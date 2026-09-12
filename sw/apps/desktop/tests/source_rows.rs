use lc3_asm::assemble;
use lc3_desktop::source_rows;

#[test]
fn builds_source_rows_from_an_assembly() {
    let assembly = assemble(
        r#"
.ORIG x3000
ADD R1, R2, R3
MESSAGE .STRINGZ "HI"
.END
"#,
    );

    let rows = source_rows(&assembly);

    assert_eq!(rows.len(), 4);

    assert_eq!(rows[0].line, 2);
    assert_eq!(rows[0].address, Some(0x3000));
    assert_eq!(rows[0].source, ".ORIG x3000");
    assert!(rows[0].words.is_empty());

    assert_eq!(rows[1].line, 3);
    assert_eq!(rows[1].address, Some(0x3000));
    assert_eq!(rows[1].source, "ADD R1, R2, R3");
    assert_eq!(rows[1].words, [0x1283]);

    assert_eq!(rows[2].line, 4);
    assert_eq!(rows[2].address, Some(0x3001));
    assert_eq!(rows[2].source, "MESSAGE .STRINGZ \"HI\"");
    assert_eq!(rows[2].words, [0x0048, 0x0049, 0x0000]);

    assert_eq!(rows[3].line, 5);
    assert_eq!(rows[3].address, Some(0x3004));
    assert_eq!(rows[3].source, ".END");
    assert!(rows[3].words.is_empty());
}
