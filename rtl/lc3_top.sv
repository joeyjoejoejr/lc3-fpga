`timescale 1ns/1ps

module lc3_top (
  input  logic       clk,
  input  logic       reset_button,
  output logic [5:0] led
);
  logic reset;

  logic [15:0] mem_addr;
  logic [15:0] mem_rdata;
  logic [15:0] mem_wdata;
  logic        mem_we;
  logic [15:0] pc;
  logic [15:0] ir;

  logic [15:0] video_pixel;
  logic [5:0]  led_value;

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
    .INIT_FILE("programs/top/led_smoke.hex"),
    .RAM_WORDS(16384)
  ) memory_controller (
    .clk(clk),
    .cpu_addr(mem_addr),
    .cpu_rdata(mem_rdata),
    .cpu_wdata(mem_wdata),
    .cpu_we(mem_we),
    .video_enabled(1'b0),
    .video_addr(14'h0000),
    .video_pixel(video_pixel),
    .led_value(led_value)
  );

  // Tang Nano board LEDs are commonly active-low.
  assign led = ~led_value;
endmodule
