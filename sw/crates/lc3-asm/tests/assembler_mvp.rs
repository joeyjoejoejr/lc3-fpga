use lc3_asm::assemble;

fn assembled_words(source: &str) -> (u16, Vec<u16>) {
    let assembly = assemble(source).expect("source should assemble");

    (assembly.image.origin(), assembly.image.words().to_vec())
}

#[test]
fn assembles_orig_alu_and_trap_program() {
    let source = r"
.ORIG x3000
ADD R1, R2, R3
AND R4, R4, #0
NOT R5, R5
TRAP x25
.END
";

    let (origin, words) = assembled_words(source);

    assert_eq!(origin, 0x3000);
    assert_eq!(words, vec![0x1283, 0x5920, 0x9B7F, 0xF025]);
}

#[test]
fn assembles_fill_decimal_and_hex_literals() {
    let source = r"
.ORIG x3100
.FILL #42
.FILL #-1
.FILL x4000
.END
";

    let (origin, words) = assembled_words(source);

    assert_eq!(origin, 0x3100);
    assert_eq!(words, vec![0x002A, 0xFFFF, 0x4000]);
}

#[test]
#[ignore = "assembler MVP is not implemented yet"]
fn resolves_forward_label_in_fill() {
    let source = r"
.ORIG x3000
.FILL TARGET
TARGET ADD R0, R0, #1
TRAP x25
.END
";

    let (origin, words) = assembled_words(source);

    assert_eq!(origin, 0x3000);
    assert_eq!(words, vec![0x3001, 0x1021, 0xF025]);
}
