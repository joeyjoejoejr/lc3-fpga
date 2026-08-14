use lc3_asm::assemble;

#[test]
#[ignore = "TRAP assembly is not implemented yet"]
fn assembles_trap_instruction() {
    let source = r"
.ORIG x3000
TRAP x25
.END
";

    let assembly = assemble(source).expect("source should assemble");

    assert_eq!(assembly.image.origin(), 0x3000);
    assert_eq!(assembly.image.words(), &[0xF025]);
}
