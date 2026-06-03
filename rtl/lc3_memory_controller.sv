`timescale 1ns/1ps

module lc3_memory_controller #(
  parameter INIT_FILE = "",
  parameter FRAMEBUFFER_INIT_FILE = "",
  parameter int RAM_WORDS = 16'hC000
) (
  input  logic        clk,
  input  logic        reset,

  input  logic [15:0] cpu_addr,
  output logic [15:0] cpu_rdata,
  input  logic [15:0] cpu_wdata,
  input  logic        cpu_we,

  input  logic        video_clk,
  input  logic        video_enabled,
  input  logic [13:0] video_addr,
  output logic [15:0] video_pixel,

  // Keyboard
  input  logic        keyboard_valid,
  input  logic [7:0]  keyboard_data,
  output logic        keyboard_ready,

  // Display / console
  output logic        display_valid,
  output logic [7:0]  display_data,
  input  logic        display_ready
);
  localparam logic [15:0] FRAMEBUFFER_START = 16'hC000;
  localparam logic [15:0] FRAMEBUFFER_END   = 16'hFDFF;
  localparam logic [15:0] DEVICE_START      = 16'hFE00;
  localparam logic [15:0] LED_REG_ADDR      = 16'hFE10;
  localparam logic [13:0] FRAMEBUFFER_WORDS = 14'd15872;

  // Hardware IO
  localparam logic [15:0] KBSR_ADDR         = 16'hFE00;
  localparam logic [15:0] KBDR_ADDR         = 16'hFE02;
  localparam logic [15:0] DSR_ADDR          = 16'hFE04;
  localparam logic [15:0] DDR_ADDR          = 16'hFE06;
  localparam logic [15:0] TMR_ADDR          = 16'hFE08;
  localparam logic [15:0] TMI_ADDR          = 16'hFE0A;

  logic [15:0] mem [0:RAM_WORDS-1];
  logic [15:0] framebuffer [0:FRAMEBUFFER_WORDS-1];

  logic cpu_addr_is_framebuffer;
  logic cpu_addr_is_device;
  logic cpu_addr_in_ram;
  logic video_addr_in_range;
  logic [13:0] cpu_framebuffer_addr;

  // Timer
  logic tmr_read;
  logic tmi_we;
  logic [15:0] tmr_value;
  logic [15:0] tmi_value;

  lc3_timer timer(
    .clk(clk),
    .reset(reset),
    .tmr_read(tmr_read),
    .tmi_we(tmi_we),
    .tmi_wdata(cpu_wdata),
    .tmr_value(tmr_value),
    .tmi_value(tmi_value)
  );

  // Keyboard
  logic [15:0] kbsr_value;
  logic [15:0] kbdr_value;
  logic kbdr_read;

  assign keyboard_ready = !kbsr_value[15];
  lc3_keyboard keyboard(
    .clk(clk),
    .reset(reset),
    .keyboard_valid(keyboard_valid),
    .keyboard_data(keyboard_data),
    .kbdr_read(kbdr_read),
    .kbsr_value(kbsr_value),
    .kbdr_value(kbdr_value)
  );

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
    tmr_read <= 1'b0;
    tmi_we <= 1'b0;
    kbdr_read <= 1'b0;
    display_valid <= 1'b0;

    if(reset) begin
      tmr_read <= 1'b0;
      tmi_we <= 1'b0;
      kbdr_read <= 1'b0;
      display_valid <= 1'b0;
      display_data <= 8'h00;
      cpu_rdata <= 16'd0;
    end
    else begin
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
        case(cpu_addr)
          KBSR_ADDR: begin
            if(!cpu_we) cpu_rdata <= kbsr_value;
          end
          KBDR_ADDR: begin
            if(!cpu_we) begin
              kbdr_read <= 1'b1;
              cpu_rdata <= kbdr_value;
            end
          end
          DSR_ADDR: begin
            if(!cpu_we) cpu_rdata <= display_ready ? 16'h8000 : 16'h0000;
          end
          DDR_ADDR: begin
            if(cpu_we && display_ready) begin
              display_data <= cpu_wdata[7:0];
              display_valid <= 1'b1;
            end
          end
          TMR_ADDR: begin
            if(!cpu_we) begin
              cpu_rdata <= tmr_value;
              tmr_read <= 1'b1;
            end
          end
          TMI_ADDR: begin
            if(cpu_we) tmi_we <= 1'b1;
            else cpu_rdata <= tmi_value;
          end
          default: cpu_rdata <= 16'h0000;
        endcase
      end
      else if (cpu_addr_in_ram) cpu_rdata <= mem[cpu_addr];
      else cpu_rdata <= 16'h0000;
    end

  end

  always_ff @(posedge video_clk) begin
    if (video_enabled && video_addr_in_range)
      video_pixel <= framebuffer[video_addr];
    else video_pixel <= 16'h0000;
  end
endmodule
