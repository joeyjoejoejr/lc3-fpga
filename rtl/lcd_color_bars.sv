`timescale 1ns/1ps

module lcd_color_bars(
  input logic [8:0] x,
  input logic [8:0] y,
  input logic lcd_en,
  output logic [4:0] r,
  output logic [5:0] g,
  output logic [4:0] b
);
  always_comb begin
    r = 5'h00;
    g = 6'h00;
    b = 5'h00;

    if(lcd_en) begin
      if(x < 9'd60) begin
        r = 5'h1f; g = 6'h00; b = 5'h00;
      end
      else if(x < 9'd120) begin
        r = 5'h1f; g = 6'h20; b = 5'h00;
      end
      else if(x < 9'd180) begin
        r = 5'h1f; g = 6'h3f; b = 5'h00;
      end
      else if(x < 9'd240) begin
        r = 5'h00; g = 6'h3f; b = 5'h00;
      end
      else if(x < 9'd300) begin
        r = 5'h00; g = 6'h3f; b = 5'h1f;
      end
      else if(x < 9'd360) begin
        r = 5'h00; g = 6'h00; b = 5'h1f;
      end
      else if(x < 9'd420) begin
        r = 5'h10; g = 6'h00; b = 5'h1f;
      end
      else begin
        r = 5'h1f; g = 6'h1f; b = 5'h1f;
      end
    end
  end
endmodule
