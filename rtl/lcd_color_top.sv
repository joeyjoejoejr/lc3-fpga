`timescale 1ns/1ps

module lcd_color_top(
  input logic clk,
  input logic reset,
  output logic [4:0]lcd_b,
  output logic [5:0]lcd_g,
  output logic [4:0]lcd_r,
  output logic lcd_en,
  output logic lcd_clk
);
  logic [8:0] x;
  logic [8:0] y;

  Gowin_rPLL_9MHz Gowin_rPLL_9Mhz(
      .clkout(lcd_clk), // 9MHz
      .clkin(clk)   //27MHz
  );
  lcd_timing timing(
    .lcd_clk(lcd_clk),
    .reset(reset),
    .x(x),
    .y(y),
    .lcd_en(lcd_en)
  );
  lcd_color_bars bars(
    .x(x),
    .y(y),
    .lcd_en(lcd_en),
    .r(lcd_r),
    .g(lcd_g),
    .b(lcd_b)
  );
endmodule
