use lc3_asm::assemble;

fn assembled_words(source: &str) -> (u16, Vec<u16>) {
    let assembly = assemble(source).expect("source should assemble");

    (assembly.image.origin(), assembly.image.words().to_vec())
}

#[test]
fn assembles_forward_jsr_and_jsrr() {
    let source = r"
.ORIG x3000
JSR TARGET
JSRR R4
TARGET TRAP x25
.END
";

    let (origin, words) = assembled_words(source);

    assert_eq!(origin, 0x3000);
    assert_eq!(words, vec![0x4801, 0x4100, 0xF025]);
}

#[test]
fn assembles_backward_jsr() {
    let source = r"
.ORIG x3000
TARGET TRAP x25
JSR TARGET
.END
";

    let (origin, words) = assembled_words(source);

    assert_eq!(origin, 0x3000);
    assert_eq!(words, vec![0xF025, 0x4FFE]);
}
