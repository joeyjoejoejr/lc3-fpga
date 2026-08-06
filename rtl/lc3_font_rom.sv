`timescale 1ns/1ps

module lc3_font_rom (
  input  logic [7:0] char_code,
  input  logic [2:0] glyph_y,
  output logic [7:0] glyph_row
);
  always_comb begin
    glyph_row = 8'b00000000;

    case (char_code)
      "A": begin
        case (glyph_y)
          3'd0: glyph_row = 8'b10000000;
          default: glyph_row = 8'b00000000;
        endcase
      end
      default: glyph_row = 8'b00000000;
    endcase
  end
endmodule
