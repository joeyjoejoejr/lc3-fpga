use lc3_asm::assemble;

fn assembled_words(source: &str) -> (u16, Vec<u16>) {
    let assembly = assemble(source).expect("source should assemble");

    (assembly.image.origin(), assembly.image.words().to_vec())
}

#[test]
fn assembles_pc_relative_load_store_family() {
    let source = r"
.ORIG x3000
LD R1, VALUE
LDI R3, VALUE
LEA R2, VALUE
ST R1, VALUE
STI R3, VALUE
VALUE .FILL x1234
.END
";

    let (origin, words) = assembled_words(source);

    assert_eq!(origin, 0x3000);
    assert_eq!(
        words,
        vec![
            0x2204, // LD R1, VALUE
            0xA603, // LDI R3, VALUE
            0xE402, // LEA R2, VALUE
            0x3201, // ST R1, VALUE
            0xB600, // STI R3, VALUE
            0x1234,
        ]
    );
}
