use lc3_asm::assemble;

fn assembled_words(source: &str) -> (u16, Vec<u16>) {
    let assembly = assemble(source).expect("source should assemble");

    (assembly.image.origin(), assembly.image.words().to_vec())
}

#[test]
fn assembles_ldr_and_str_with_offset6_boundaries() {
    let source = r"
.ORIG x3000
LDR R1, R2, #0
LDR R3, R4, #31
LDR R5, R6, #-32
STR R1, R2, #0
STR R3, R4, #31
STR R5, R6, #-32
.END
";

    let (origin, words) = assembled_words(source);

    assert_eq!(origin, 0x3000);
    assert_eq!(
        words,
        vec![
            0x6280, // LDR R1, R2, #0
            0x671F, // LDR R3, R4, #31
            0x6BA0, // LDR R5, R6, #-32
            0x7280, // STR R1, R2, #0
            0x771F, // STR R3, R4, #31
            0x7BA0, // STR R5, R6, #-32
        ]
    );
}

#[test]
fn reports_offset6_values_above_range() {
    let source = r"
.ORIG x3000
LDR R1, R2, #32
.END
";

    let diagnostics = assemble(source).expect_err("source should not assemble");

    assert_eq!(diagnostics.len(), 1);
    assert_eq!(diagnostics[0].message, "offset6 out of range");
    assert_eq!(diagnostics[0].location.line, 3);
}

#[test]
fn reports_offset6_values_below_range() {
    let source = r"
.ORIG x3000
STR R1, R2, #-33
.END
";

    let diagnostics = assemble(source).expect_err("source should not assemble");

    assert_eq!(diagnostics.len(), 1);
    assert_eq!(diagnostics[0].message, "offset6 out of range");
    assert_eq!(diagnostics[0].location.line, 3);
}
