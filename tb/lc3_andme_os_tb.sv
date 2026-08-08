`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_andme_os_tb;
  logic clk = 1'b0;
  logic reset = 1'b1;

  logic [15:0] mem_addr;
  logic [15:0] mem_rdata;
  logic [15:0] mem_wdata;
  logic        mem_we;
  logic [15:0] pc;
  logic [15:0] ir;
  logic [15:0] mpr;

  logic [15:0] video_pixel;
  logic        machine_halt;
  logic        display_valid;
  logic [7:0]  display_data;
  logic        keyboard_valid;
  logic [7:0]  keyboard_data;
  logic        keyboard_ready;
  integer      cycle;
  integer      output_index;

  always #5 clk = ~clk;

  lc3_core core (
    .clk(clk),
    .reset(reset),
    .reset_pc(16'h0200),
    .machine_halt(machine_halt),
    .mem_addr(mem_addr),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_we(mem_we),
    .pc(pc),
    .ir(ir),
    .mpr(mpr)
  );

  lc3_memory_controller #(
    .INIT_FILE("programs/top/andme_with_os.hex"),
    .RAM_WORDS(12800)
  ) memory_controller (
    .clk(clk),
    .reset(reset),
    .cpu_addr(mem_addr),
    .cpu_rdata(mem_rdata),
    .cpu_wdata(mem_wdata),
    .cpu_we(mem_we),
    .video_clk(clk),
    .video_enabled(1'b0),
    .video_addr(14'h0000),
    .video_pixel(video_pixel),
    .keyboard_valid(keyboard_valid),
    .keyboard_data(keyboard_data),
    .keyboard_ready(keyboard_ready),
    .machine_halt(machine_halt),
    .mpr(mpr),
    .display_valid(display_valid),
    .display_data(display_data),
    .display_ready(1'b1)
  );

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

  function automatic logic [7:0] expected_output_char(input integer index);
    begin
      case (index)
        0: expected_output_char = 8'h0A;
        1: expected_output_char = "E";
        2: expected_output_char = "n";
        3: expected_output_char = "t";
        4: expected_output_char = "e";
        5: expected_output_char = "r";
        6: expected_output_char = " ";
        7: expected_output_char = "F";
        8: expected_output_char = "i";
        9: expected_output_char = "r";
        10: expected_output_char = "s";
        11: expected_output_char = "t";
        12: expected_output_char = " ";
        13: expected_output_char = "B";
        14: expected_output_char = "i";
        15: expected_output_char = "n";
        16: expected_output_char = "a";
        17: expected_output_char = "r";
        18: expected_output_char = "y";
        19: expected_output_char = " ";
        20: expected_output_char = "N";
        21: expected_output_char = "u";
        22: expected_output_char = "m";
        23: expected_output_char = "b";
        24: expected_output_char = "e";
        25: expected_output_char = "r";
        26: expected_output_char = ":";
        27: expected_output_char = " ";
        28: expected_output_char = "1";
        29: expected_output_char = "0";
        30: expected_output_char = "1";
        31: expected_output_char = "0";
        32: expected_output_char = 8'h0A;
        33: expected_output_char = "E";
        34: expected_output_char = "n";
        35: expected_output_char = "t";
        36: expected_output_char = "e";
        37: expected_output_char = "r";
        38: expected_output_char = " ";
        39: expected_output_char = "S";
        40: expected_output_char = "e";
        41: expected_output_char = "c";
        42: expected_output_char = "o";
        43: expected_output_char = "n";
        44: expected_output_char = "d";
        45: expected_output_char = " ";
        46: expected_output_char = "B";
        47: expected_output_char = "i";
        48: expected_output_char = "n";
        49: expected_output_char = "a";
        50: expected_output_char = "r";
        51: expected_output_char = "y";
        52: expected_output_char = " ";
        53: expected_output_char = "N";
        54: expected_output_char = "u";
        55: expected_output_char = "m";
        56: expected_output_char = "b";
        57: expected_output_char = "e";
        58: expected_output_char = "r";
        59: expected_output_char = ":";
        60: expected_output_char = " ";
        61: expected_output_char = "1";
        62: expected_output_char = "1";
        63: expected_output_char = "0";
        64: expected_output_char = "0";
        65: expected_output_char = 8'h0A;
        66: expected_output_char = "T";
        67: expected_output_char = "h";
        68: expected_output_char = "e";
        69: expected_output_char = " ";
        70: expected_output_char = "X";
        71: expected_output_char = "O";
        72: expected_output_char = "R";
        73: expected_output_char = " ";
        74: expected_output_char = "f";
        75: expected_output_char = "u";
        76: expected_output_char = "n";
        77: expected_output_char = "c";
        78: expected_output_char = "t";
        79: expected_output_char = "i";
        80: expected_output_char = "o";
        81: expected_output_char = "n";
        82: expected_output_char = " ";
        83: expected_output_char = "o";
        84: expected_output_char = "f";
        85: expected_output_char = " ";
        86: expected_output_char = "t";
        87: expected_output_char = "h";
        88: expected_output_char = "e";
        89: expected_output_char = " ";
        90: expected_output_char = "t";
        91: expected_output_char = "w";
        92: expected_output_char = "o";
        93: expected_output_char = " ";
        94: expected_output_char = "n";
        95: expected_output_char = "u";
        96: expected_output_char = "m";
        97: expected_output_char = "b";
        98: expected_output_char = "e";
        99: expected_output_char = "r";
        100: expected_output_char = "s";
        101: expected_output_char = " ";
        102: expected_output_char = "i";
        103: expected_output_char = "s";
        104: expected_output_char = ":";
        105: expected_output_char = " ";
        106: expected_output_char = "0";
        107: expected_output_char = "1";
        108: expected_output_char = "1";
        109: expected_output_char = "0";
        110: expected_output_char = 8'h0A;
        default: expected_output_char = 8'hxx;
      endcase
    end
  endfunction

  initial begin
    keyboard_valid = 1'b0;
    keyboard_data = 8'h00;

    repeat (2) @(posedge clk);
    wait (!reset);

    inject_key("1");
    inject_key("0");
    inject_key("1");
    inject_key("0");
    inject_key("1");
    inject_key("1");
    inject_key("0");
    inject_key("0");
  end

  initial begin
    if ($test$plusargs("dump")) begin
      $dumpfile("sim/lc3_andme_os_tb.vcd");
      $dumpvars(0, lc3_andme_os_tb);
    end

    output_index = 0;
    repeat (2) @(posedge clk);
    reset <= 1'b0;

    for (cycle = 0; cycle < 20000; cycle = cycle + 1) begin
      @(posedge clk);

      if (pc >= 16'h3000 && mpr !== 16'h0FF8) begin
        $display("%s[FAIL]%s %-14s OS did not program MPR before user mode",
                 TB_RED, TB_RESET, "andme_os");
        $display("       PC=%04h IR=%04h MPR=%04h", pc, ir, mpr);
        $fatal(1);
      end

      if (machine_halt) begin
        $display("%s[FAIL]%s %-14s halted before transcript completed",
                 TB_RED, TB_RESET, "andme_os");
        $display("       PC=%04h IR=%04h output_index=%0d", pc, ir, output_index);
        $fatal(1);
      end

      if (display_valid) begin
        if (display_data !== expected_output_char(output_index)) begin
          $display("%s[FAIL]%s %-14s transcript character mismatch",
                   TB_RED, TB_RESET, "andme_os");
          $display("       index    %0d", output_index);
          $display("       actual   %02h", display_data);
          $display("       expected %02h", expected_output_char(output_index));
          $fatal(1);
        end

        output_index = output_index + 1;
        if (output_index == 111) begin
          print_case_pass("andme_os");
          $finish;
        end
      end
    end

    $display("%s[FAIL]%s %-14s timed out before transcript completed",
             TB_RED, TB_RESET, "andme_os");
    $display("       output_index=%0d PC=%04h IR=%04h", output_index, pc, ir);
    $fatal(1);
  end
endmodule
