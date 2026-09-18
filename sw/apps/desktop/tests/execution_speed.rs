use lc3_desktop::ExecutionSpeed;

#[test]
fn pennsim_like_is_the_default_speed() {
    assert_eq!(ExecutionSpeed::default(), ExecutionSpeed::PennSimLike);
    assert_eq!(
        ExecutionSpeed::default().target_instructions_per_second(),
        Some(1_000_000)
    );
}

#[test]
fn speed_options_have_distinct_targets_and_no_manual_mode() {
    assert_eq!(
        ExecutionSpeed::ALL.map(ExecutionSpeed::target_instructions_per_second),
        [
            Some(1),
            Some(10),
            Some(100),
            Some(1_000),
            Some(1_000_000),
            None
        ]
    );
    assert_eq!(ExecutionSpeed::Fastest.label(), "Fastest");
    assert_eq!(ExecutionSpeed::PennSimLike.label(), "PennSim-like");
}
