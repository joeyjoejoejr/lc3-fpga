`timescale 1ns/1ps

module lc3_framebuffer_reader (
  input logic clk,
  input logic reset,
  input logic lcd_en,
  input logic [8:0] lcd_x,
  input logic [8:0] lcd_y,
  input logic video_en,
  input logic [15:9] video_pixel,
  output logic [4:0] lcd_r,
  output logic [5:0] lcd_g,
  output logic [4:0] lcd_b,
  output logic [15:0] video_address
);
  logic [7:0] line_number;
  logic [7:0] pixel_number;

  assign line_number = (lcd_y > 12 && lcd_y <= 260) ? lcd_y - 12 : 0;
  assign pixel_number = (lcd_x > 111 && lcd_x <= 367) ? lcd_x - 111 : 0;
  assign video_address = {line_number, pixel_number};
  assign lcd_r = lcd_en ? video_pixel[14:10] : 0;
  assign lcd_g = lcd_en ? {video_pixel[9:5], 1'b0} : 0;
  assign lcd_b = lcd_en ? video_pixel[4:0] : 0;
endmodule
