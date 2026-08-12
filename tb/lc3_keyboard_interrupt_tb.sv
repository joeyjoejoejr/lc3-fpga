`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_keyboard_interrupt_tb;
  localparam logic [15:0] KBSR_ADDR = 16'hFE00;
  localparam logic [15:0] KBDR_ADDR = 16'hFE02;

  logic clk = 1'b0;
  logic reset;

  logic [15:0] cpu_addr;
  logic [15:0] cpu_rdata;
  logic [15:0] cpu_wdata;
  logic        cpu_we;

  logic        keyboard_valid;
  logic        keyboard_ready;
  logic [7:0]  keyboard_data;

  logic        irq_pending;
  logic [2:0]  irq_priority;
  logic [7:0]  irq_vector;

  always #5 clk = ~clk;

  lc3_memory_controller dut (
    .clk(clk),
    .reset(reset),
    .cpu_addr(cpu_addr),
    .cpu_rdata(cpu_rdata),
    .cpu_wdata(cpu_wdata),
    .cpu_we(cpu_we),
    .video_clk(clk),
    .video_enabled(1'b0),
    .video_addr(14'h0000),
    .video_pixel(),
    .keyboard_valid(keyboard_valid),
    .keyboard_ready(keyboard_ready),
    .keyboard_data(keyboard_data),
    .machine_halt(),
    .mpr(),
    .display_valid(),
    .display_data(),
    .display_ready(1'b1),
    .irq_pending(irq_pending),
    .irq_priority(irq_priority),
    .irq_vector(irq_vector)
  );

  task automatic fail_case(input string message);
    begin
      $display("%s[FAIL]%s %-14s %s", TB_RED, TB_RESET, "kbd_irq", message);
      $display("       addr=%04h rdata=%04h wdata=%04h we=%0b ready=%0b key_valid=%0b key=%02h",
               cpu_addr, cpu_rdata, cpu_wdata, cpu_we,
               keyboard_ready, keyboard_valid, keyboard_data);
      $display("       irq_pending=%0b irq_priority=%0d irq_vector=%02h",
               irq_pending, irq_priority, irq_vector);
      $fatal(1);
    end
  endtask

  task automatic expect_irq(
    input string name,
    input logic expected_pending,
    input logic [2:0] expected_priority,
    input logic [7:0] expected_vector
  );
    begin
      @(negedge clk);
      if (irq_pending !== expected_pending ||
          irq_priority !== expected_priority ||
          irq_vector !== expected_vector) begin
        fail_case(name);
      end
    end
  endtask

  task automatic write_word(input logic [15:0] addr, input logic [15:0] data);
    begin
      @(negedge clk);
      cpu_addr <= addr;
      cpu_wdata <= data;
      cpu_we <= 1'b1;
      @(posedge clk);

      @(negedge clk);
      cpu_we <= 1'b0;
      cpu_addr <= 16'h0000;
      cpu_wdata <= 16'h0000;
      @(posedge clk);
    end
  endtask

  task automatic read_expect(
    input string name,
    input logic [15:0] addr,
    input logic [15:0] expected
  );
    begin
      @(negedge clk);
      cpu_addr <= addr;
      cpu_we <= 1'b0;
      @(posedge clk);
      @(posedge clk);

      if (cpu_rdata !== expected) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       addr     %04h", addr);
        $display("       actual   %04h", cpu_rdata);
        $display("       expected %04h", expected);
        $fatal(1);
      end

      @(negedge clk);
      cpu_addr <= 16'h0000;
      @(posedge clk);
    end
  endtask

  task automatic inject_key(input logic [7:0] key);
    begin
      while (!keyboard_ready) @(posedge clk);

      @(negedge clk);
      keyboard_data <= key;
      keyboard_valid <= 1'b1;
      @(posedge clk);

      @(negedge clk);
      keyboard_valid <= 1'b0;
      keyboard_data <= 8'h00;
      @(posedge clk);
    end
  endtask

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_keyboard_interrupt_tb.vcd");
      $dumpvars(0, lc3_keyboard_interrupt_tb);
    end

    reset = 1'b1;
    cpu_addr = 16'h0000;
    cpu_wdata = 16'h0000;
    cpu_we = 1'b0;
    keyboard_valid = 1'b0;
    keyboard_data = 8'h00;

    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (2) @(posedge clk);

    expect_irq("reset should not assert keyboard interrupt", 1'b0, 3'd4, 8'h80);
    read_expect("kbd_irq_initial_sr", KBSR_ADDR, 16'h0000);

    inject_key("a");

    read_expect("kbd_ready_no_ie", KBSR_ADDR, 16'h8000);
    expect_irq("ready key without interrupt enable should not assert irq", 1'b0, 3'd4, 8'h80);

    write_word(KBSR_ADDR, 16'h4000);
    read_expect("kbd_ie_preserves_ready", KBSR_ADDR, 16'hC000);
    expect_irq("ready key with interrupt enable should assert irq", 1'b1, 3'd4, 8'h80);

    read_expect("kbd_data_clears_ready", KBDR_ADDR, 16'h0061);
    read_expect("kbd_ie_remains_set", KBSR_ADDR, 16'h4000);
    expect_irq("cleared ready bit should clear irq", 1'b0, 3'd4, 8'h80);

    inject_key("b");

    read_expect("kbd_ready_with_ie", KBSR_ADDR, 16'hC000);
    expect_irq("new key with interrupt enable should assert irq", 1'b1, 3'd4, 8'h80);

    write_word(KBSR_ADDR, 16'h0000);
    read_expect("kbd_disable_ie_preserves_ready", KBSR_ADDR, 16'h8000);
    expect_irq("disabling interrupt enable should clear irq", 1'b0, 3'd4, 8'h80);

    read_expect("kbd_second_data", KBDR_ADDR, 16'h0062);
    read_expect("kbd_second_clear", KBSR_ADDR, 16'h0000);
    expect_irq("empty keyboard should not assert irq", 1'b0, 3'd4, 8'h80);

    print_case_pass("kbd_irq");
    $finish;
  end
endmodule
