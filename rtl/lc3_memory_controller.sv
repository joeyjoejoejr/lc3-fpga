`timescale 1ns/1ps

module lc3_memory_controller #(
  parameter INIT_FILE = "",
  parameter FRAMEBUFFER_INIT_FILE = "",
  parameter int RAM_WORDS = 16'hC000
) (
  input  logic        clk,

  input  logic [15:0] cpu_addr,
  output logic [15:0] cpu_rdata,
  input  logic [15:0] cpu_wdata,
  input  logic        cpu_we,

  input  logic        video_clk,
  input  logic        video_enabled,
  input  logic [13:0] video_addr,
  output logic [15:0] video_pixel
);
  localparam logic [15:0] FRAMEBUFFER_START = 16'hC000;
  localparam logic [15:0] FRAMEBUFFER_END   = 16'hFDFF;
  localparam logic [15:0] DEVICE_START      = 16'hFE00;
  localparam logic [15:0] LED_REG_ADDR      = 16'hFE10;
  localparam logic [13:0] FRAMEBUFFER_WORDS = 14'd15872;

  logic [15:0] mem [0:RAM_WORDS-1];
  logic [15:0] framebuffer [0:FRAMEBUFFER_WORDS-1];

  logic cpu_addr_is_framebuffer;
  logic cpu_addr_is_device;
  logic cpu_addr_in_ram;
  logic video_addr_in_range;
  logic [13:0] cpu_framebuffer_addr;

  assign cpu_addr_is_framebuffer =
    cpu_addr >= FRAMEBUFFER_START && cpu_addr <= FRAMEBUFFER_END;
  assign cpu_addr_is_device = cpu_addr >= DEVICE_START;
  assign cpu_addr_in_ram = cpu_addr < RAM_WORDS;
  assign video_addr_in_range = video_addr < FRAMEBUFFER_WORDS;
  assign cpu_framebuffer_addr = cpu_addr[13:0];

  initial begin
    video_pixel = 16'h0000;
    cpu_rdata = 16'h0000;

    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem);
    end

    if (FRAMEBUFFER_INIT_FILE != "") begin
      $readmemh(FRAMEBUFFER_INIT_FILE, framebuffer);
    end
  end

  always_ff @(posedge clk) begin
    if (cpu_we && cpu_addr_is_framebuffer) begin
      framebuffer[cpu_framebuffer_addr] <= cpu_wdata;
    end
    else if (cpu_we && !cpu_addr_is_device && cpu_addr_in_ram) begin
      mem[cpu_addr] <= cpu_wdata;
    end

    if (cpu_addr_is_framebuffer) begin
      cpu_rdata <= framebuffer[cpu_framebuffer_addr];
    end
    else if (cpu_addr_is_device) begin
      // Device registers will be decoded here one at a time.
      cpu_rdata <= 16'h0000;
    end
    else if (cpu_addr_in_ram) cpu_rdata <= mem[cpu_addr];
    else cpu_rdata <= 16'h0000;

  end

  always_ff @(posedge video_clk) begin
    if (video_enabled && video_addr_in_range)
      video_pixel <= framebuffer[video_addr];
    else video_pixel <= 16'h0000;
  end
endmodule
