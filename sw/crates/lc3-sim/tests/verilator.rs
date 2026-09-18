#![cfg(feature = "verilator")]

use std::collections::HashMap;

use lc3_image::{DenseMemoryImage, MemoryImage};
use lc3_sim::Simulator;

#[test]
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

#[test]
fn runs_until_halt_with_default_cycle_limit() {
    let trap_vector = MemoryImage::new(0x0025, vec![0x3002], HashMap::new());
    let program = MemoryImage::new(0x3000, vec![0x1021, 0xF025, 0xD000], HashMap::new());
    let dense = DenseMemoryImage::from_memory_images(&[trap_vector, program])
        .expect("smoke image should compose");

    let mut sim = Simulator::new(0x3000, None).expect("should create simulator");
    sim.load_dense_image(&dense)
        .expect("dense image should load into simulator");
    let report = sim.run().expect("simulator should run until halt");

    assert_eq!(report.pc, 0x3003);
    assert_eq!(report.ir, 0xD000);
    assert!(report.cycles > 0);
}

#[test]
fn bounded_runs_resume_without_resetting_the_machine() {
    let trap_vector = MemoryImage::new(0x0025, vec![0x3002], HashMap::new());
    let program = MemoryImage::new(0x3000, vec![0x1021, 0xF025, 0xD000], HashMap::new());
    let dense = DenseMemoryImage::from_memory_images(&[trap_vector, program])
        .expect("smoke image should compose");

    let mut single_cycle = Simulator::new(0x3000, Some(1)).expect("single-cycle simulator");
    single_cycle
        .load_dense_image(&dense)
        .expect("dense image should load");

    let first = single_cycle
        .run()
        .expect("first bounded run should succeed");
    assert_eq!(first.cycles, 1);
    assert_ne!(first.ir, 0xD000, "one cycle must not run to completion");

    let mut total_cycles = first.cycles;
    let mut last = first;
    for _ in 0..20 {
        last = single_cycle.run().expect("bounded run should succeed");
        total_cycles += last.cycles;
        if last.cycles == 0 {
            break;
        }
    }

    assert_eq!(last.pc, 0x3003);
    assert_eq!(last.ir, 0xD000);
    assert_eq!(single_cycle.run().expect("halted run").cycles, 0);

    let mut batch = Simulator::new(0x3000, Some(20)).expect("batch simulator");
    batch
        .load_dense_image(&dense)
        .expect("dense image should load");
    let batch_report = batch.run().expect("batch run should succeed");
    assert_eq!(total_cycles, batch_report.cycles);
    assert_eq!((last.pc, last.ir), (batch_report.pc, batch_report.ir));
}
