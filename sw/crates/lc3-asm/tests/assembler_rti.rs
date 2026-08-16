use lc3_asm::assemble;

#[test]
fn assembles_rti_instruction() {
    let source = r"
.ORIG x0200
RTI
.END
";

    let assembly = assemble(source).expect("source should assemble");

    assert_eq!(assembly.image.origin(), 0x0200);
    assert_eq!(assembly.image.words(), &[0x8000]);
}
