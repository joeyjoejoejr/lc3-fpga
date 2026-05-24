`timescale 1ns/1ps

module lc3_memory_controller #(
  parameter INIT_FILE = "",
  parameter int RAM_WORDS = 65536
) (
  input  logic        clk,

  input  logic [15:0] cpu_addr,
  output logic [15:0] cpu_rdata,
  input  logic [15:0] cpu_wdata,
  input  logic        cpu_we,

  input  logic        video_enabled,
  input  logic [13:0] video_addr,
  output logic [15:0] video_pixel,

  output logic [5:0]  led_value
);
  localparam logic [15:0] FRAMEBUFFER_START = 16'hC000;
  localparam logic [15:0] FRAMEBUFFER_END   = 16'hFDFF;
  localparam logic [15:0] DEVICE_START      = 16'hFE00;
  localparam logic [15:0] LED_REG_ADDR      = 16'hFE10;
  localparam logic [13:0] FRAMEBUFFER_WORDS = 14'd15872;

  logic [15:0] mem [0:RAM_WORDS-1];

  logic cpu_addr_is_framebuffer;
  logic cpu_addr_is_device;
  logic cpu_addr_in_ram;
  logic video_addr_in_ram;
  logic video_addr_in_range;

  assign cpu_addr_is_framebuffer =
    cpu_addr >= FRAMEBUFFER_START && cpu_addr <= FRAMEBUFFER_END;
  assign cpu_addr_is_device = cpu_addr >= DEVICE_START;
  assign cpu_addr_in_ram = cpu_addr < RAM_WORDS;
  assign video_addr_in_ram = (FRAMEBUFFER_START + {2'b00, video_addr}) < RAM_WORDS;
  assign video_addr_in_range = video_addr < FRAMEBUFFER_WORDS;

  initial begin
    led_value = 6'h00;
    video_pixel = 16'h0000;
    cpu_rdata = 16'h0000;

    if (INIT_FILE != "") begin
      $readmemh(INIT_FILE, mem);
    end
  end

  always_ff @(posedge clk) begin
    if (cpu_we && cpu_addr == LED_REG_ADDR) led_value <= cpu_wdata[5:0];

    if (cpu_we && !cpu_addr_is_device && cpu_addr_in_ram) mem[cpu_addr] <= cpu_wdata;

    if (cpu_addr == LED_REG_ADDR) begin
      cpu_rdata <= {10'b0, led_value};
    end
    else if (cpu_addr_is_device) begin
      // Device registers will be decoded here one at a time.
      cpu_rdata <= 16'h0000;
    end
    else if (cpu_addr_in_ram) cpu_rdata <= mem[cpu_addr];
    else cpu_rdata <= 16'h0000;

    if (video_enabled && video_addr_in_range && video_addr_in_ram) 
      video_pixel <= mem[FRAMEBUFFER_START + {2'b00, video_addr}];
    else video_pixel <= 16'h0000;
  end
endmodule
