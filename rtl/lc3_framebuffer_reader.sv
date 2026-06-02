`timescale 1ns/1ps

module lc3_framebuffer_reader (
  input logic clk,
  input logic reset,
  input logic lcd_en,
  input logic [8:0] lcd_x,
  input logic [8:0] lcd_y,
  input logic [15:0] video_pixel,
  output logic video_en,
  output logic [4:0] lcd_r,
  output logic [5:0] lcd_g,
  output logic [4:0] lcd_b,
  output logic [13:0] video_addr
);
  localparam int FB_WIDTH = 128;
  localparam int FB_HEIGHT = 124;
  localparam int SCALE = 2;
  localparam int X_MARGIN = 112;
  localparam int Y_MARGIN = 12;
  localparam int PREFETCH_PIXELS = 1;

  localparam int REQUEST_X_START = X_MARGIN - PREFETCH_PIXELS;
  localparam int REQUEST_X_END = X_MARGIN + (FB_WIDTH * SCALE) - PREFETCH_PIXELS - 1;
  localparam int REQUEST_Y_START = Y_MARGIN;
  localparam int REQUEST_Y_END = Y_MARGIN + (FB_HEIGHT * SCALE) - 1;

  localparam int DISPLAY_X_START = X_MARGIN;
  localparam int DISPLAY_X_END = X_MARGIN + (FB_WIDTH * SCALE);
  localparam int DISPLAY_Y_START = Y_MARGIN;
  localparam int DISPLAY_Y_END = Y_MARGIN + (FB_HEIGHT * SCALE);

  logic request_in_framebuffer;
  logic display_in_framebuffer;
  logic [8:0] request_x_offset;
  logic [8:0] request_y_offset;
  logic [6:0] fb_x;
  logic [6:0] fb_y;

  assign request_in_framebuffer =
    lcd_en &&
    lcd_x >= REQUEST_X_START && lcd_x <= REQUEST_X_END &&
    lcd_y >= REQUEST_Y_START && lcd_y <= REQUEST_Y_END;

  assign display_in_framebuffer =
    lcd_en &&
    lcd_x >= DISPLAY_X_START && lcd_x <= DISPLAY_X_END &&
    lcd_y >= DISPLAY_Y_START && lcd_y <= DISPLAY_Y_END;

  assign request_x_offset = request_in_framebuffer ? lcd_x - REQUEST_X_START : 9'd0;
  assign request_y_offset = request_in_framebuffer ? lcd_y - REQUEST_Y_START : 9'd0;
  assign fb_x = request_x_offset[8:1];
  assign fb_y = request_y_offset[7:1];

  assign video_addr = (fb_y * FB_WIDTH) + fb_x;
  assign video_en = request_in_framebuffer;

  always_ff @(posedge clk) begin
    if (reset) begin
      lcd_r <= 5'd0;
      lcd_g <= 6'd0;
      lcd_b <= 5'd0;
    end else begin
      if (display_in_framebuffer) begin
        lcd_r <= video_pixel[14:10];
        lcd_g <= {video_pixel[9:5], video_pixel[9]};
        lcd_b <= video_pixel[4:0];
      end else begin
        lcd_r <= 5'd0;
        lcd_g <= 6'd0;
        lcd_b <= 5'd0;
      end
    end
  end
endmodule
