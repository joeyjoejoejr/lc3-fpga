#![cfg(feature = "verilator")]

use std::collections::HashMap;

use lc3_image::{DenseMemoryImage, MemoryImage};
use lc3_sim::Simulator;

#[test]
#[ignore = "requires an instruction-completion signal and step_instruction implementation"]
fn stepping_counts_completed_instructions_even_when_pc_does_not_change() {
    // ADD R0, R0, #1; BRnzp #-1. The branch runs forever at x3001, so a
    // PC-change heuristic would hang or incorrectly report no progress.
    let program = MemoryImage::new(0x3000, vec![0x1021, 0x0FFF], HashMap::new());
    let dense = DenseMemoryImage::from_memory_images(&[program]).expect("image should compose");
    let mut sim = Simulator::new(0x3000, Some(100)).expect("simulator should be created");
    sim.load_dense_image(&dense).expect("image should load");

    let first = sim.step_instruction().expect("ADD should complete");
    assert_eq!(first.address, 0x3000);
    assert_eq!(first.word, 0x1021);
    assert_eq!(first.next_pc, 0x3001);
    assert_eq!(first.retired_instructions, 1);
    assert!(first.cycles > 0);

    for expected_count in [2, 3] {
        let branch = sim.step_instruction().expect("self-branch should complete");
        assert_eq!(branch.address, 0x3001);
        assert_eq!(branch.word, 0x0FFF);
        assert_eq!(branch.next_pc, 0x3001);
        assert_eq!(branch.retired_instructions, expected_count);
        assert!(branch.cycles > 0);
    }
}
