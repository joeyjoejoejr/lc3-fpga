`timescale 1ns/1ps

module lc3_top #(
  parameter INIT_FILE = "programs/top/framebuffer_cpu_smoke.hex",
  parameter FRAMEBUFFER_INIT_FILE = "",
  parameter int RAM_WORDS = 16'h3100
) (
  input  logic       clk,
  input  logic       reset_button,

  // LCD
  output logic [4:0]lcd_b,
  output logic [5:0]lcd_g,
  output logic [4:0]lcd_r,
  output logic lcd_en,
  output logic lcd_clk
);
  logic reset;

  logic [15:0] mem_addr;
  logic [15:0] mem_rdata;
  logic [15:0] mem_wdata;
  logic        mem_we;
  logic [15:0] pc;
  logic [15:0] ir;

  logic [15:0] video_pixel;
  logic video_en;
  logic [13:0] video_addr;
  logic [8:0] lcd_x;
  logic [8:0] lcd_y;
  logic pll_lock;

  assign reset = reset_button;

  lc3_core core (
    .clk(clk),
    .reset(reset),
    .mem_addr(mem_addr),
    .mem_rdata(mem_rdata),
    .mem_wdata(mem_wdata),
    .mem_we(mem_we),
    .pc(pc),
    .ir(ir)
  );

  lc3_memory_controller #(
    .INIT_FILE(INIT_FILE),
    .FRAMEBUFFER_INIT_FILE(FRAMEBUFFER_INIT_FILE),
    .RAM_WORDS(RAM_WORDS)
  ) memory_controller (
    .clk(clk),
    .cpu_addr(mem_addr),
    .cpu_rdata(mem_rdata),
    .cpu_wdata(mem_wdata),
    .cpu_we(mem_we),
    .video_clk(lcd_clk),
    .video_enabled(video_en),
    .video_addr(video_addr),
    .video_pixel(video_pixel)
  );

`ifdef SIMULATION
  assign lcd_clk = clk;
  assign pll_lock = 1'b1;
`else
  Gowin_rPLL_9MHz Gowin_rPLL_9Mhz(
      .clkout(lcd_clk), // 9MHz
      .lock(pll_lock),
      .clkin(clk)   //27MHz
  );
`endif

  lcd_timing timing(
    .lcd_clk(lcd_clk),
    .reset(reset),
    .x(lcd_x),
    .y(lcd_y),
    .lcd_en(lcd_en)
  );

  lc3_framebuffer_reader framebuffer_reader(
    .clk(lcd_clk),
    .reset(reset),
    .lcd_en(lcd_en),
    .lcd_x(lcd_x),
    .lcd_y(lcd_y),
    .lcd_r(lcd_r),
    .lcd_g(lcd_g),
    .lcd_b(lcd_b),
    .video_pixel(video_pixel),
    .video_en(video_en),
    .video_addr(video_addr)
  );
endmodule
