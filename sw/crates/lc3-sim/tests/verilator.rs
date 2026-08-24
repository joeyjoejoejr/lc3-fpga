use std::collections::HashMap;

use lc3_image::{DenseMemoryImage, MemoryImage};
use lc3_sim::Simulator;

#[test]
#[ignore = "requires Verilator-backed simulator implementation"]
fn loads_dense_image_and_runs_until_halt() {
    let trap_vector = MemoryImage::new(0x0025, vec![0x3002], HashMap::new());
    let program = MemoryImage::new(0x3000, vec![0x1021, 0xF025, 0xD000], HashMap::new());
    let dense = DenseMemoryImage::from_memory_images(&[trap_vector, program])
        .expect("smoke image should compose");

    let mut sim = Simulator::new(0x3000, Some(20)).expect("should create simulator");
    sim.load_dense_image(&dense)
        .expect("dense image should load into simulator");
    let report = sim.run().expect("simulator should run");

    assert_eq!(report.pc, 0x3003);
    assert_eq!(report.ir, 0xD000);
}
