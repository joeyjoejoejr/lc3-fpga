`timescale 1ns/1ps

module lc3_text_renderer #(
  parameter int LCD_WIDTH = 480,
  parameter int LCD_HEIGHT = 272,
  parameter int CHAR_WIDTH = 8,
  parameter int CHAR_HEIGHT = 8,
  parameter int COLS = LCD_WIDTH / CHAR_WIDTH,
  parameter int ROWS = LCD_HEIGHT / CHAR_HEIGHT,
  parameter int COL_WIDTH = $clog2(COLS),
  parameter int ROW_WIDTH = $clog2(ROWS)
) (
  input  logic                 clk,
  input  logic                 reset,

  input  logic                 lcd_en,
  input  logic [8:0]           lcd_x,
  input  logic [8:0]           lcd_y,

  output logic [COL_WIDTH-1:0] cell_read_col,
  output logic [ROW_WIDTH-1:0] cell_read_row,
  input  logic [7:0]           cell_read_data,

  output logic                 text_pixel_on,
  output logic [4:0]           lcd_r,
  output logic [5:0]           lcd_g,
  output logic [4:0]           lcd_b
);
  localparam int CHAR_HEIGHT_SIZE = $clog2(CHAR_HEIGHT);
  localparam int CHAR_WIDTH_SIZE = $clog2(CHAR_WIDTH);

  logic request_en;
  logic render_en;
  logic [CHAR_WIDTH_SIZE-1:0] request_glyph_x;
  logic [CHAR_HEIGHT_SIZE-1:0] request_glyph_y;
  logic [CHAR_WIDTH_SIZE-1:0] render_glyph_x;
  logic [CHAR_HEIGHT_SIZE-1:0] render_glyph_y;
  logic [7:0] glyph_row;
  logic glyph_pixel;

  lc3_font_rom font_rom (
    .char_code(cell_read_data),
    .glyph_y(render_glyph_y),
    .glyph_row(glyph_row)
  );

  always_ff @(posedge clk) begin
    if (reset) begin
      cell_read_col <= '0;
      cell_read_row <= '0;
      request_en <= 1'b0;
      render_en <= 1'b0;
      request_glyph_x <= '0;
      request_glyph_y <= '0;
      render_glyph_x <= '0;
      render_glyph_y <= '0;
    end else begin
      render_en <= request_en;
      render_glyph_x <= request_glyph_x;
      render_glyph_y <= request_glyph_y;

      if (lcd_en) begin
        cell_read_col <= lcd_x >> CHAR_WIDTH_SIZE;
        cell_read_row <= lcd_y >> CHAR_HEIGHT_SIZE;
        request_en <= 1'b1;
        request_glyph_x <= lcd_x[CHAR_WIDTH_SIZE-1:0];
        request_glyph_y <= lcd_y[CHAR_HEIGHT_SIZE-1:0];
      end else begin
        request_en <= 1'b0;
        request_glyph_x <= '0;
        request_glyph_y <= '0;
      end
    end
  end
  
  always_comb begin
    glyph_pixel = glyph_row[CHAR_WIDTH - 1 - render_glyph_x];
    if (render_en && glyph_pixel) begin
      text_pixel_on = 1'b1;
      lcd_r = 5'h1F;
      lcd_g = 6'h3F;
      lcd_b = 5'h1F;
    end else begin
      text_pixel_on = 1'b0;
      lcd_r = 5'd0;
      lcd_g = 6'd0;
      lcd_b = 5'd0;
    end
  end
endmodule
