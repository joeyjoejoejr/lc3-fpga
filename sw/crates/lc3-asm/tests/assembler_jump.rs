use lc3_asm::assemble;

fn assembled_words(source: &str) -> (u16, Vec<u16>) {
    let assembly = assemble(source).expect("source should assemble");

    (assembly.image.origin(), assembly.image.words().to_vec())
}

#[test]
fn assembles_jmp_and_ret() {
    let source = r"
.ORIG x3000
JMP R3
RET
.END
";

    let (origin, words) = assembled_words(source);

    assert_eq!(origin, 0x3000);
    assert_eq!(words, vec![0xC0C0, 0xC1C0]);
}

#[test]
fn assembles_jmpt_and_rtt_extensions() {
    let source = r"
.ORIG x0200
JMPT R7
RTT
.END
";

    let (origin, words) = assembled_words(source);

    assert_eq!(origin, 0x0200);
    assert_eq!(words, vec![0xC1C1, 0xC1C1]);
}
