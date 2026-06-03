`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_keyboard_tb;
  localparam logic [15:0] KBSR_ADDR = 16'hFE00;
  localparam logic [15:0] KBDR_ADDR = 16'hFE02;

  logic clk = 1'b0;
  logic reset;

  logic [15:0] cpu_addr;
  logic [15:0] cpu_rdata;
  logic [15:0] cpu_wdata;
  logic        cpu_we;

  logic        video_enabled;
  logic [13:0] video_addr;
  logic [15:0] video_pixel;

  logic        keyboard_valid;
  logic        keyboard_ready;
  logic [7:0]  keyboard_data;

  always #5 clk = ~clk;

  lc3_memory_controller dut (
    .clk(clk),
    .reset(reset),
    .cpu_addr(cpu_addr),
    .cpu_rdata(cpu_rdata),
    .cpu_wdata(cpu_wdata),
    .cpu_we(cpu_we),
    .video_clk(clk),
    .video_enabled(video_enabled),
    .video_addr(video_addr),
    .video_pixel(video_pixel),
	    .keyboard_valid(keyboard_valid),
	    .keyboard_ready(keyboard_ready),
	    .keyboard_data(keyboard_data),
	    .display_valid(),
	    .display_data(),
	    .display_ready(1'b1)
	  );

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
    reset = 1'b1;
    cpu_addr = 16'h0000;
    cpu_wdata = 16'h0000;
    cpu_we = 1'b0;
    video_enabled = 1'b0;
    video_addr = 14'h0000;
    keyboard_valid = 1'b0;
    keyboard_data = 8'h00;

    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (2) @(posedge clk);

    read_expect("kbd_initial_sr", KBSR_ADDR, 16'h0000);
    read_expect("kbd_initial_dr", KBDR_ADDR, 16'h0000);

    inject_key("a");

    read_expect("kbd_ready", KBSR_ADDR, 16'h8000);
    read_expect("kbd_data", KBDR_ADDR, 16'h0061);
    read_expect("kbd_read_clears", KBSR_ADDR, 16'h0000);

    inject_key("d");

    // KBSR is readable but writes are ignored for now; interrupt-enable bits
    // are intentionally not modeled yet.
    write_word(KBSR_ADDR, 16'h4000);
    read_expect("kbd_sr_write_ignored", KBSR_ADDR, 16'h8000);
    read_expect("kbd_second_data", KBDR_ADDR, 16'h0064);
    read_expect("kbd_second_clear", KBSR_ADDR, 16'h0000);

    print_case_pass("keyboard");
    $finish;
  end
endmodule
