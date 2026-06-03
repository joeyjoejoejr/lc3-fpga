`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_framebuffer_reader_tb;
  localparam logic [15:0] FRAMEBUFFER_START = 16'hC000;

  logic clk = 1'b0;
  logic reset;

  logic [15:0] cpu_addr;
  logic [15:0] cpu_rdata;
  logic [15:0] cpu_wdata;
  logic        cpu_we;

  logic        lcd_en;
  logic [8:0]  lcd_x;
  logic [8:0]  lcd_y;
  logic [4:0]  lcd_r;
  logic [5:0]  lcd_g;
  logic [4:0]  lcd_b;

  logic        video_enabled;
  logic [13:0] video_addr;
  logic [15:0] video_pixel;
  int unsigned scan_x;
  int unsigned scan_y;

  always #5 clk = ~clk;

  lc3_memory_controller memory (
    .clk(clk),
    .reset(reset),
    .cpu_addr(cpu_addr),
    .cpu_rdata(cpu_rdata),
    .cpu_wdata(cpu_wdata),
    .cpu_we(cpu_we),
	    .video_enabled(video_enabled),
	    .video_addr(video_addr),
	    .video_pixel(video_pixel),
	    .video_clk(clk),
	    .keyboard_valid(1'b0),
	    .keyboard_data(8'h00),
	    .keyboard_ready()
	  );

  // This module is intentionally not implemented yet. This test defines the
  // contract for the next step: map the LC-3 framebuffer onto the LCD pixels.
  lc3_framebuffer_reader dut (
    .clk(clk),
    .reset(reset),
    .lcd_en(lcd_en),
    .lcd_x(lcd_x),
    .lcd_y(lcd_y),
    .video_en(video_enabled),
    .video_addr(video_addr),
    .video_pixel(video_pixel),
    .lcd_r(lcd_r),
    .lcd_g(lcd_g),
    .lcd_b(lcd_b)
  );

  task automatic write_word(input logic [15:0] addr, input logic [15:0] data);
    begin
      cpu_addr <= addr;
      cpu_wdata <= data;
      cpu_we <= 1'b1;
      @(posedge clk);
      cpu_we <= 1'b0;
      @(posedge clk);
    end
  endtask

  task automatic advance_scan;
    begin
      if (scan_x == 479) begin
        scan_x = 0;
        scan_y = scan_y + 1;
      end
      else begin
        scan_x = scan_x + 1;
      end

      lcd_x <= scan_x[8:0];
      lcd_y <= scan_y[8:0];
      lcd_en <= 1'b1;
      @(posedge clk);
      #1;
    end
  endtask

  task automatic scan_to(input int unsigned x, input int unsigned y);
    begin
      while (scan_x != x || scan_y != y) begin
        advance_scan();
      end
    end
  endtask

  task automatic expect_pixel(
    input string name,
    input logic expected_video_en,
    input logic [13:0] expected_addr,
    input logic [14:0] expected_rgb555
  );
    logic [15:0] expected_rgb565;
    begin
      expected_rgb565 = {expected_rgb555[14:10],
                         expected_rgb555[9:5], expected_rgb555[9],
                         expected_rgb555[4:0]};

      if (video_enabled !== expected_video_en ||
          (expected_video_en && video_addr !== expected_addr) ||
          {lcd_r, lcd_g, lcd_b} !== expected_rgb565) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       lcd      x=%0d y=%0d", scan_x, scan_y);
        $display("       video_en actual=%0b expected=%0b",
                 video_enabled, expected_video_en);
        $display("       addr     actual=%04h expected=%04h",
                 video_addr, expected_addr);
        $display("       rgb565   actual=%04h expected=%04h",
                 {lcd_r, lcd_g, lcd_b}, expected_rgb565);
        $fatal(1);
      end
    end
  endtask

  task automatic expect_black(
    input string name,
    input logic expected_video_en,
    input logic [13:0] expected_addr
  );
    begin
      if (video_enabled !== expected_video_en ||
          (expected_video_en && video_addr !== expected_addr) ||
          {lcd_r, lcd_g, lcd_b} !== 16'h0000) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       lcd      x=%0d y=%0d", scan_x, scan_y);
        $display("       video_en actual=%0b expected=%0b",
                 video_enabled, expected_video_en);
        $display("       addr     actual=%04h expected=%04h",
                 video_addr, expected_addr);
        $display("       rgb565   actual=%04h expected=0000",
                 {lcd_r, lcd_g, lcd_b});
        $fatal(1);
      end
    end
  endtask

  initial begin
    reset = 1'b1;
    cpu_addr = 16'h0000;
    cpu_wdata = 16'h0000;
    cpu_we = 1'b0;
    lcd_en = 1'b0;
    lcd_x = 9'd0;
    lcd_y = 9'd0;
    scan_x = 0;
    scan_y = 0;

    repeat (2) @(posedge clk);
    reset = 1'b0;

    write_word(FRAMEBUFFER_START + 16'd0,     16'h7C00);
    write_word(FRAMEBUFFER_START + 16'd1,     16'h03E0);
    write_word(FRAMEBUFFER_START + 16'd128,   16'h001F);
    write_word(FRAMEBUFFER_START + 16'd15871, 16'h7FFF);

    lcd_en <= 1'b1;
    @(posedge clk);
    #1;

    // The visible LC-3 framebuffer is 128x124 words at xC000..xFDFF.
    // This test expects a 2x scaled image centered in the 480x272 LCD:
    // x margin = 112, y margin = 12.
    scan_to(111, 12);
    expect_black("prefetch_first", 1'b1, 14'd0);

    scan_to(112, 12);
    expect_pixel("first_pixel", 1'b1, 14'd0, 15'h7C00);

    scan_to(113, 12);
    expect_pixel("x_scale", 1'b1, 14'd1, 15'h7C00);

    scan_to(114, 12);
    expect_pixel("next_column", 1'b1, 14'd1, 15'h03E0);

    scan_to(111, 14);
    expect_black("prefetch_next_row", 1'b1, 14'd128);

    scan_to(112, 14);
    expect_pixel("next_row", 1'b1, 14'd128, 15'h001F);

    scan_to(367, 259);
    expect_pixel("last_pixel", 1'b0, 14'd15871, 15'h7FFF);

    scan_to(112, 260);
    expect_black("bottom_margin", 1'b0, 14'd15871);

    lcd_en <= 1'b0;
    @(posedge clk);
    #1;
    expect_black("lcd_blank", 1'b0, 14'd15871);

    print_case_pass("fb_reader");
    $finish;
  end
endmodule
