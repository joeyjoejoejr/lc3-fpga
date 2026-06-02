`timescale 1ns/1ps

module lcd_timing(
  input logic lcd_clk,
  input logic reset,
  output logic [8:0] x,
  output logic [8:0] y,
  output logic lcd_en
);
  localparam int H_PIXELS = 480;
  localparam int H_FP = 50;
  localparam int H_BP = 30;
  localparam int H_TOTAL = H_PIXELS + H_FP + H_BP;
  localparam int H_ACTIVE_START = H_BP;
  localparam int H_ACTIVE_END = H_BP + H_PIXELS;

  localparam int V_LINES = 272;
  localparam int V_FP = 20;
  localparam int V_BP = 5;
  localparam int V_TOTAL = V_LINES + V_FP + V_BP;
  localparam int V_ACTIVE_START = V_BP;
  localparam int V_ACTIVE_END = V_BP + V_LINES;

  logic [9:0] pixel_count;
  logic [8:0] line_count;

  always_comb begin
    x = 9'd0;
    y = 9'd0;
    lcd_en = 1'b0;
    if(line_count >= V_ACTIVE_START && line_count < V_ACTIVE_END) begin
      y = line_count - V_ACTIVE_START;
      if(pixel_count >= H_ACTIVE_START && pixel_count < H_ACTIVE_END) begin
        lcd_en = 1'b1;
        x = pixel_count - H_ACTIVE_START;
      end
    end
  end

  always_ff @(posedge lcd_clk) begin
    if(reset) begin
      pixel_count <= 10'd0;
      line_count <= 9'd0;
    end
    else if(pixel_count == H_TOTAL - 1) begin
      pixel_count <= 10'd0;
      if(line_count == V_TOTAL - 1) begin
        line_count <= 9'd0;
      end
      else begin
        line_count <= line_count + 1'b1;
      end
    end
    else begin
      pixel_count <= pixel_count + 1'b1;
    end
  end
endmodule
