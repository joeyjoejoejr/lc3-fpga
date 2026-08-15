use lc3_asm::assemble;

fn assembled_words(source: &str) -> (u16, Vec<u16>) {
    let assembly = assemble(source).expect("source should assemble");

    (assembly.image.origin(), assembly.image.words().to_vec())
}

#[test]
fn assembles_forward_unconditional_branch() {
    let source = r"
.ORIG x3000
BRnzp TARGET
ADD R0, R0, #1
TARGET TRAP x25
.END
";

    let (origin, words) = assembled_words(source);

    assert_eq!(origin, 0x3000);
    assert_eq!(words, vec![0x0E01, 0x1021, 0xF025]);
}

#[test]
fn assembles_backward_unconditional_branch() {
    let source = r"
.ORIG x3000
LOOP ADD R0, R0, #1
BRnzp LOOP
.END
";

    let (origin, words) = assembled_words(source);

    assert_eq!(origin, 0x3000);
    assert_eq!(words, vec![0x1021, 0x0FFE]);
}
