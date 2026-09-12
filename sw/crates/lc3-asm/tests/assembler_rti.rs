use lc3_asm::assemble;

#[test]
fn assembles_rti_instruction() {
    let source = r"
.ORIG x0200
RTI
.END
";

    let assembly = assemble(source)
        .into_image()
        .expect("source should assemble");

    assert_eq!(assembly.origin(), 0x0200);
    assert_eq!(assembly.words(), &[0x8000]);
}
