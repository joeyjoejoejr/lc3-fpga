`timescale 1ns/1ps

// 8x8 public-domain ASCII font converted from:
// https://github.com/dhepper/font8x8/blob/master/font8x8_basic.h
// Original project license: Public Domain.
// Source rows are bit-reversed here so glyph_row[7] is the leftmost pixel.

module lc3_font_rom (
  input  logic [7:0] char_code,
  input  logic [2:0] glyph_y,
  output logic [7:0] glyph_row
);
  always_comb begin
    glyph_row = 8'h00;

    case (char_code)
      8'h21: begin // !
        case (glyph_y)
          3'd0: glyph_row = 8'b00011000;
          3'd1: glyph_row = 8'b00111100;
          3'd2: glyph_row = 8'b00111100;
          3'd3: glyph_row = 8'b00011000;
          3'd4: glyph_row = 8'b00011000;
          3'd6: glyph_row = 8'b00011000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h22: begin // "
        case (glyph_y)
          3'd0: glyph_row = 8'b01101100;
          3'd1: glyph_row = 8'b01101100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h23: begin // #
        case (glyph_y)
          3'd0: glyph_row = 8'b01101100;
          3'd1: glyph_row = 8'b01101100;
          3'd2: glyph_row = 8'b11111110;
          3'd3: glyph_row = 8'b01101100;
          3'd4: glyph_row = 8'b11111110;
          3'd5: glyph_row = 8'b01101100;
          3'd6: glyph_row = 8'b01101100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h24: begin // $
        case (glyph_y)
          3'd0: glyph_row = 8'b00110000;
          3'd1: glyph_row = 8'b01111100;
          3'd2: glyph_row = 8'b11000000;
          3'd3: glyph_row = 8'b01111000;
          3'd4: glyph_row = 8'b00001100;
          3'd5: glyph_row = 8'b11111000;
          3'd6: glyph_row = 8'b00110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h25: begin // %
        case (glyph_y)
          3'd1: glyph_row = 8'b11000110;
          3'd2: glyph_row = 8'b11001100;
          3'd3: glyph_row = 8'b00011000;
          3'd4: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b01100110;
          3'd6: glyph_row = 8'b11000110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h26: begin // &
        case (glyph_y)
          3'd0: glyph_row = 8'b00111000;
          3'd1: glyph_row = 8'b01101100;
          3'd2: glyph_row = 8'b00111000;
          3'd3: glyph_row = 8'b01110110;
          3'd4: glyph_row = 8'b11011100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b01110110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h27: begin // '
        case (glyph_y)
          3'd0: glyph_row = 8'b01100000;
          3'd1: glyph_row = 8'b01100000;
          3'd2: glyph_row = 8'b11000000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h28: begin // (
        case (glyph_y)
          3'd0: glyph_row = 8'b00011000;
          3'd1: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b01100000;
          3'd3: glyph_row = 8'b01100000;
          3'd4: glyph_row = 8'b01100000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b00011000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h29: begin // )
        case (glyph_y)
          3'd0: glyph_row = 8'b01100000;
          3'd1: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b00011000;
          3'd3: glyph_row = 8'b00011000;
          3'd4: glyph_row = 8'b00011000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b01100000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h2A: begin // *
        case (glyph_y)
          3'd1: glyph_row = 8'b01100110;
          3'd2: glyph_row = 8'b00111100;
          3'd3: glyph_row = 8'b11111111;
          3'd4: glyph_row = 8'b00111100;
          3'd5: glyph_row = 8'b01100110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h2B: begin // +
        case (glyph_y)
          3'd1: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b00110000;
          3'd3: glyph_row = 8'b11111100;
          3'd4: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b00110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h2C: begin // ,
        case (glyph_y)
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b00110000;
          3'd7: glyph_row = 8'b01100000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h2D: begin // -
        case (glyph_y)
          3'd3: glyph_row = 8'b11111100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h2E: begin // .
        case (glyph_y)
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b00110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h2F: begin // /
        case (glyph_y)
          3'd0: glyph_row = 8'b00000110;
          3'd1: glyph_row = 8'b00001100;
          3'd2: glyph_row = 8'b00011000;
          3'd3: glyph_row = 8'b00110000;
          3'd4: glyph_row = 8'b01100000;
          3'd5: glyph_row = 8'b11000000;
          3'd6: glyph_row = 8'b10000000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h30: begin // 0
        case (glyph_y)
          3'd0: glyph_row = 8'b01111100;
          3'd1: glyph_row = 8'b11000110;
          3'd2: glyph_row = 8'b11001110;
          3'd3: glyph_row = 8'b11011110;
          3'd4: glyph_row = 8'b11110110;
          3'd5: glyph_row = 8'b11100110;
          3'd6: glyph_row = 8'b01111100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h31: begin // 1
        case (glyph_y)
          3'd0: glyph_row = 8'b00110000;
          3'd1: glyph_row = 8'b01110000;
          3'd2: glyph_row = 8'b00110000;
          3'd3: glyph_row = 8'b00110000;
          3'd4: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b11111100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h32: begin // 2
        case (glyph_y)
          3'd0: glyph_row = 8'b01111000;
          3'd1: glyph_row = 8'b11001100;
          3'd2: glyph_row = 8'b00001100;
          3'd3: glyph_row = 8'b00111000;
          3'd4: glyph_row = 8'b01100000;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b11111100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h33: begin // 3
        case (glyph_y)
          3'd0: glyph_row = 8'b01111000;
          3'd1: glyph_row = 8'b11001100;
          3'd2: glyph_row = 8'b00001100;
          3'd3: glyph_row = 8'b00111000;
          3'd4: glyph_row = 8'b00001100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h34: begin // 4
        case (glyph_y)
          3'd0: glyph_row = 8'b00011100;
          3'd1: glyph_row = 8'b00111100;
          3'd2: glyph_row = 8'b01101100;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11111110;
          3'd5: glyph_row = 8'b00001100;
          3'd6: glyph_row = 8'b00011110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h35: begin // 5
        case (glyph_y)
          3'd0: glyph_row = 8'b11111100;
          3'd1: glyph_row = 8'b11000000;
          3'd2: glyph_row = 8'b11111000;
          3'd3: glyph_row = 8'b00001100;
          3'd4: glyph_row = 8'b00001100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h36: begin // 6
        case (glyph_y)
          3'd0: glyph_row = 8'b00111000;
          3'd1: glyph_row = 8'b01100000;
          3'd2: glyph_row = 8'b11000000;
          3'd3: glyph_row = 8'b11111000;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h37: begin // 7
        case (glyph_y)
          3'd0: glyph_row = 8'b11111100;
          3'd1: glyph_row = 8'b11001100;
          3'd2: glyph_row = 8'b00001100;
          3'd3: glyph_row = 8'b00011000;
          3'd4: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b00110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h38: begin // 8
        case (glyph_y)
          3'd0: glyph_row = 8'b01111000;
          3'd1: glyph_row = 8'b11001100;
          3'd2: glyph_row = 8'b11001100;
          3'd3: glyph_row = 8'b01111000;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h39: begin // 9
        case (glyph_y)
          3'd0: glyph_row = 8'b01111000;
          3'd1: glyph_row = 8'b11001100;
          3'd2: glyph_row = 8'b11001100;
          3'd3: glyph_row = 8'b01111100;
          3'd4: glyph_row = 8'b00001100;
          3'd5: glyph_row = 8'b00011000;
          3'd6: glyph_row = 8'b01110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h3A: begin // :
        case (glyph_y)
          3'd1: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b00110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h3B: begin // ;
        case (glyph_y)
          3'd1: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b00110000;
          3'd7: glyph_row = 8'b01100000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h3C: begin // <
        case (glyph_y)
          3'd0: glyph_row = 8'b00011000;
          3'd1: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b01100000;
          3'd3: glyph_row = 8'b11000000;
          3'd4: glyph_row = 8'b01100000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b00011000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h3D: begin // =
        case (glyph_y)
          3'd2: glyph_row = 8'b11111100;
          3'd5: glyph_row = 8'b11111100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h3E: begin // >
        case (glyph_y)
          3'd0: glyph_row = 8'b01100000;
          3'd1: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b00011000;
          3'd3: glyph_row = 8'b00001100;
          3'd4: glyph_row = 8'b00011000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b01100000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h3F: begin // ?
        case (glyph_y)
          3'd0: glyph_row = 8'b01111000;
          3'd1: glyph_row = 8'b11001100;
          3'd2: glyph_row = 8'b00001100;
          3'd3: glyph_row = 8'b00011000;
          3'd4: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b00110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h40: begin // @
        case (glyph_y)
          3'd0: glyph_row = 8'b01111100;
          3'd1: glyph_row = 8'b11000110;
          3'd2: glyph_row = 8'b11011110;
          3'd3: glyph_row = 8'b11011110;
          3'd4: glyph_row = 8'b11011110;
          3'd5: glyph_row = 8'b11000000;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h41: begin // A
        case (glyph_y)
          3'd0: glyph_row = 8'b00110000;
          3'd1: glyph_row = 8'b01111000;
          3'd2: glyph_row = 8'b11001100;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11111100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b11001100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h42: begin // B
        case (glyph_y)
          3'd0: glyph_row = 8'b11111100;
          3'd1: glyph_row = 8'b01100110;
          3'd2: glyph_row = 8'b01100110;
          3'd3: glyph_row = 8'b01111100;
          3'd4: glyph_row = 8'b01100110;
          3'd5: glyph_row = 8'b01100110;
          3'd6: glyph_row = 8'b11111100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h43: begin // C
        case (glyph_y)
          3'd0: glyph_row = 8'b00111100;
          3'd1: glyph_row = 8'b01100110;
          3'd2: glyph_row = 8'b11000000;
          3'd3: glyph_row = 8'b11000000;
          3'd4: glyph_row = 8'b11000000;
          3'd5: glyph_row = 8'b01100110;
          3'd6: glyph_row = 8'b00111100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h44: begin // D
        case (glyph_y)
          3'd0: glyph_row = 8'b11111000;
          3'd1: glyph_row = 8'b01101100;
          3'd2: glyph_row = 8'b01100110;
          3'd3: glyph_row = 8'b01100110;
          3'd4: glyph_row = 8'b01100110;
          3'd5: glyph_row = 8'b01101100;
          3'd6: glyph_row = 8'b11111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h45: begin // E
        case (glyph_y)
          3'd0: glyph_row = 8'b11111110;
          3'd1: glyph_row = 8'b01100010;
          3'd2: glyph_row = 8'b01101000;
          3'd3: glyph_row = 8'b01111000;
          3'd4: glyph_row = 8'b01101000;
          3'd5: glyph_row = 8'b01100010;
          3'd6: glyph_row = 8'b11111110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h46: begin // F
        case (glyph_y)
          3'd0: glyph_row = 8'b11111110;
          3'd1: glyph_row = 8'b01100010;
          3'd2: glyph_row = 8'b01101000;
          3'd3: glyph_row = 8'b01111000;
          3'd4: glyph_row = 8'b01101000;
          3'd5: glyph_row = 8'b01100000;
          3'd6: glyph_row = 8'b11110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h47: begin // G
        case (glyph_y)
          3'd0: glyph_row = 8'b00111100;
          3'd1: glyph_row = 8'b01100110;
          3'd2: glyph_row = 8'b11000000;
          3'd3: glyph_row = 8'b11000000;
          3'd4: glyph_row = 8'b11001110;
          3'd5: glyph_row = 8'b01100110;
          3'd6: glyph_row = 8'b00111110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h48: begin // H
        case (glyph_y)
          3'd0: glyph_row = 8'b11001100;
          3'd1: glyph_row = 8'b11001100;
          3'd2: glyph_row = 8'b11001100;
          3'd3: glyph_row = 8'b11111100;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b11001100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h49: begin // I
        case (glyph_y)
          3'd0: glyph_row = 8'b01111000;
          3'd1: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b00110000;
          3'd3: glyph_row = 8'b00110000;
          3'd4: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h4A: begin // J
        case (glyph_y)
          3'd0: glyph_row = 8'b00011110;
          3'd1: glyph_row = 8'b00001100;
          3'd2: glyph_row = 8'b00001100;
          3'd3: glyph_row = 8'b00001100;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h4B: begin // K
        case (glyph_y)
          3'd0: glyph_row = 8'b11100110;
          3'd1: glyph_row = 8'b01100110;
          3'd2: glyph_row = 8'b01101100;
          3'd3: glyph_row = 8'b01111000;
          3'd4: glyph_row = 8'b01101100;
          3'd5: glyph_row = 8'b01100110;
          3'd6: glyph_row = 8'b11100110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h4C: begin // L
        case (glyph_y)
          3'd0: glyph_row = 8'b11110000;
          3'd1: glyph_row = 8'b01100000;
          3'd2: glyph_row = 8'b01100000;
          3'd3: glyph_row = 8'b01100000;
          3'd4: glyph_row = 8'b01100010;
          3'd5: glyph_row = 8'b01100110;
          3'd6: glyph_row = 8'b11111110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h4D: begin // M
        case (glyph_y)
          3'd0: glyph_row = 8'b11000110;
          3'd1: glyph_row = 8'b11101110;
          3'd2: glyph_row = 8'b11111110;
          3'd3: glyph_row = 8'b11111110;
          3'd4: glyph_row = 8'b11010110;
          3'd5: glyph_row = 8'b11000110;
          3'd6: glyph_row = 8'b11000110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h4E: begin // N
        case (glyph_y)
          3'd0: glyph_row = 8'b11000110;
          3'd1: glyph_row = 8'b11100110;
          3'd2: glyph_row = 8'b11110110;
          3'd3: glyph_row = 8'b11011110;
          3'd4: glyph_row = 8'b11001110;
          3'd5: glyph_row = 8'b11000110;
          3'd6: glyph_row = 8'b11000110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h4F: begin // O
        case (glyph_y)
          3'd0: glyph_row = 8'b00111000;
          3'd1: glyph_row = 8'b01101100;
          3'd2: glyph_row = 8'b11000110;
          3'd3: glyph_row = 8'b11000110;
          3'd4: glyph_row = 8'b11000110;
          3'd5: glyph_row = 8'b01101100;
          3'd6: glyph_row = 8'b00111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h50: begin // P
        case (glyph_y)
          3'd0: glyph_row = 8'b11111100;
          3'd1: glyph_row = 8'b01100110;
          3'd2: glyph_row = 8'b01100110;
          3'd3: glyph_row = 8'b01111100;
          3'd4: glyph_row = 8'b01100000;
          3'd5: glyph_row = 8'b01100000;
          3'd6: glyph_row = 8'b11110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h51: begin // Q
        case (glyph_y)
          3'd0: glyph_row = 8'b01111000;
          3'd1: glyph_row = 8'b11001100;
          3'd2: glyph_row = 8'b11001100;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11011100;
          3'd5: glyph_row = 8'b01111000;
          3'd6: glyph_row = 8'b00011100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h52: begin // R
        case (glyph_y)
          3'd0: glyph_row = 8'b11111100;
          3'd1: glyph_row = 8'b01100110;
          3'd2: glyph_row = 8'b01100110;
          3'd3: glyph_row = 8'b01111100;
          3'd4: glyph_row = 8'b01101100;
          3'd5: glyph_row = 8'b01100110;
          3'd6: glyph_row = 8'b11100110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h53: begin // S
        case (glyph_y)
          3'd0: glyph_row = 8'b01111000;
          3'd1: glyph_row = 8'b11001100;
          3'd2: glyph_row = 8'b11100000;
          3'd3: glyph_row = 8'b01110000;
          3'd4: glyph_row = 8'b00011100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h54: begin // T
        case (glyph_y)
          3'd0: glyph_row = 8'b11111100;
          3'd1: glyph_row = 8'b10110100;
          3'd2: glyph_row = 8'b00110000;
          3'd3: glyph_row = 8'b00110000;
          3'd4: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h55: begin // U
        case (glyph_y)
          3'd0: glyph_row = 8'b11001100;
          3'd1: glyph_row = 8'b11001100;
          3'd2: glyph_row = 8'b11001100;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b11111100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h56: begin // V
        case (glyph_y)
          3'd0: glyph_row = 8'b11001100;
          3'd1: glyph_row = 8'b11001100;
          3'd2: glyph_row = 8'b11001100;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b01111000;
          3'd6: glyph_row = 8'b00110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h57: begin // W
        case (glyph_y)
          3'd0: glyph_row = 8'b11000110;
          3'd1: glyph_row = 8'b11000110;
          3'd2: glyph_row = 8'b11000110;
          3'd3: glyph_row = 8'b11010110;
          3'd4: glyph_row = 8'b11111110;
          3'd5: glyph_row = 8'b11101110;
          3'd6: glyph_row = 8'b11000110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h58: begin // X
        case (glyph_y)
          3'd0: glyph_row = 8'b11000110;
          3'd1: glyph_row = 8'b11000110;
          3'd2: glyph_row = 8'b01101100;
          3'd3: glyph_row = 8'b00111000;
          3'd4: glyph_row = 8'b00111000;
          3'd5: glyph_row = 8'b01101100;
          3'd6: glyph_row = 8'b11000110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h59: begin // Y
        case (glyph_y)
          3'd0: glyph_row = 8'b11001100;
          3'd1: glyph_row = 8'b11001100;
          3'd2: glyph_row = 8'b11001100;
          3'd3: glyph_row = 8'b01111000;
          3'd4: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h5A: begin // Z
        case (glyph_y)
          3'd0: glyph_row = 8'b11111110;
          3'd1: glyph_row = 8'b11000110;
          3'd2: glyph_row = 8'b10001100;
          3'd3: glyph_row = 8'b00011000;
          3'd4: glyph_row = 8'b00110010;
          3'd5: glyph_row = 8'b01100110;
          3'd6: glyph_row = 8'b11111110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h5B: begin // [
        case (glyph_y)
          3'd0: glyph_row = 8'b01111000;
          3'd1: glyph_row = 8'b01100000;
          3'd2: glyph_row = 8'b01100000;
          3'd3: glyph_row = 8'b01100000;
          3'd4: glyph_row = 8'b01100000;
          3'd5: glyph_row = 8'b01100000;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h5C: begin // \\
        case (glyph_y)
          3'd0: glyph_row = 8'b11000000;
          3'd1: glyph_row = 8'b01100000;
          3'd2: glyph_row = 8'b00110000;
          3'd3: glyph_row = 8'b00011000;
          3'd4: glyph_row = 8'b00001100;
          3'd5: glyph_row = 8'b00000110;
          3'd6: glyph_row = 8'b00000010;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h5D: begin // ]
        case (glyph_y)
          3'd0: glyph_row = 8'b01111000;
          3'd1: glyph_row = 8'b00011000;
          3'd2: glyph_row = 8'b00011000;
          3'd3: glyph_row = 8'b00011000;
          3'd4: glyph_row = 8'b00011000;
          3'd5: glyph_row = 8'b00011000;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h5E: begin // ^
        case (glyph_y)
          3'd0: glyph_row = 8'b00010000;
          3'd1: glyph_row = 8'b00111000;
          3'd2: glyph_row = 8'b01101100;
          3'd3: glyph_row = 8'b11000110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h5F: begin // _
        case (glyph_y)
          3'd7: glyph_row = 8'b11111111;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h60: begin // `
        case (glyph_y)
          3'd0: glyph_row = 8'b00110000;
          3'd1: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b00011000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h61: begin // a
        case (glyph_y)
          3'd2: glyph_row = 8'b01111000;
          3'd3: glyph_row = 8'b00001100;
          3'd4: glyph_row = 8'b01111100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b01110110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h62: begin // b
        case (glyph_y)
          3'd0: glyph_row = 8'b11100000;
          3'd1: glyph_row = 8'b01100000;
          3'd2: glyph_row = 8'b01100000;
          3'd3: glyph_row = 8'b01111100;
          3'd4: glyph_row = 8'b01100110;
          3'd5: glyph_row = 8'b01100110;
          3'd6: glyph_row = 8'b11011100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h63: begin // c
        case (glyph_y)
          3'd2: glyph_row = 8'b01111000;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11000000;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h64: begin // d
        case (glyph_y)
          3'd0: glyph_row = 8'b00011100;
          3'd1: glyph_row = 8'b00001100;
          3'd2: glyph_row = 8'b00001100;
          3'd3: glyph_row = 8'b01111100;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b01110110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h65: begin // e
        case (glyph_y)
          3'd2: glyph_row = 8'b01111000;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11111100;
          3'd5: glyph_row = 8'b11000000;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h66: begin // f
        case (glyph_y)
          3'd0: glyph_row = 8'b00111000;
          3'd1: glyph_row = 8'b01101100;
          3'd2: glyph_row = 8'b01100000;
          3'd3: glyph_row = 8'b11110000;
          3'd4: glyph_row = 8'b01100000;
          3'd5: glyph_row = 8'b01100000;
          3'd6: glyph_row = 8'b11110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h67: begin // g
        case (glyph_y)
          3'd2: glyph_row = 8'b01110110;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b01111100;
          3'd6: glyph_row = 8'b00001100;
          3'd7: glyph_row = 8'b11111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h68: begin // h
        case (glyph_y)
          3'd0: glyph_row = 8'b11100000;
          3'd1: glyph_row = 8'b01100000;
          3'd2: glyph_row = 8'b01101100;
          3'd3: glyph_row = 8'b01110110;
          3'd4: glyph_row = 8'b01100110;
          3'd5: glyph_row = 8'b01100110;
          3'd6: glyph_row = 8'b11100110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h69: begin // i
        case (glyph_y)
          3'd0: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b01110000;
          3'd3: glyph_row = 8'b00110000;
          3'd4: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h6A: begin // j
        case (glyph_y)
          3'd0: glyph_row = 8'b00001100;
          3'd2: glyph_row = 8'b00001100;
          3'd3: glyph_row = 8'b00001100;
          3'd4: glyph_row = 8'b00001100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b11001100;
          3'd7: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h6B: begin // k
        case (glyph_y)
          3'd0: glyph_row = 8'b11100000;
          3'd1: glyph_row = 8'b01100000;
          3'd2: glyph_row = 8'b01100110;
          3'd3: glyph_row = 8'b01101100;
          3'd4: glyph_row = 8'b01111000;
          3'd5: glyph_row = 8'b01101100;
          3'd6: glyph_row = 8'b11100110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h6C: begin // l
        case (glyph_y)
          3'd0: glyph_row = 8'b01110000;
          3'd1: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b00110000;
          3'd3: glyph_row = 8'b00110000;
          3'd4: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h6D: begin // m
        case (glyph_y)
          3'd2: glyph_row = 8'b11001100;
          3'd3: glyph_row = 8'b11111110;
          3'd4: glyph_row = 8'b11111110;
          3'd5: glyph_row = 8'b11010110;
          3'd6: glyph_row = 8'b11000110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h6E: begin // n
        case (glyph_y)
          3'd2: glyph_row = 8'b11111000;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b11001100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h6F: begin // o
        case (glyph_y)
          3'd2: glyph_row = 8'b01111000;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b01111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h70: begin // p
        case (glyph_y)
          3'd2: glyph_row = 8'b11011100;
          3'd3: glyph_row = 8'b01100110;
          3'd4: glyph_row = 8'b01100110;
          3'd5: glyph_row = 8'b01111100;
          3'd6: glyph_row = 8'b01100000;
          3'd7: glyph_row = 8'b11110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h71: begin // q
        case (glyph_y)
          3'd2: glyph_row = 8'b01110110;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b01111100;
          3'd6: glyph_row = 8'b00001100;
          3'd7: glyph_row = 8'b00011110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h72: begin // r
        case (glyph_y)
          3'd2: glyph_row = 8'b11011100;
          3'd3: glyph_row = 8'b01110110;
          3'd4: glyph_row = 8'b01100110;
          3'd5: glyph_row = 8'b01100000;
          3'd6: glyph_row = 8'b11110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h73: begin // s
        case (glyph_y)
          3'd2: glyph_row = 8'b01111100;
          3'd3: glyph_row = 8'b11000000;
          3'd4: glyph_row = 8'b01111000;
          3'd5: glyph_row = 8'b00001100;
          3'd6: glyph_row = 8'b11111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h74: begin // t
        case (glyph_y)
          3'd0: glyph_row = 8'b00010000;
          3'd1: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b01111100;
          3'd3: glyph_row = 8'b00110000;
          3'd4: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b00110100;
          3'd6: glyph_row = 8'b00011000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h75: begin // u
        case (glyph_y)
          3'd2: glyph_row = 8'b11001100;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b11001100;
          3'd6: glyph_row = 8'b01110110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h76: begin // v
        case (glyph_y)
          3'd2: glyph_row = 8'b11001100;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b01111000;
          3'd6: glyph_row = 8'b00110000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h77: begin // w
        case (glyph_y)
          3'd2: glyph_row = 8'b11000110;
          3'd3: glyph_row = 8'b11010110;
          3'd4: glyph_row = 8'b11111110;
          3'd5: glyph_row = 8'b11111110;
          3'd6: glyph_row = 8'b01101100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h78: begin // x
        case (glyph_y)
          3'd2: glyph_row = 8'b11000110;
          3'd3: glyph_row = 8'b01101100;
          3'd4: glyph_row = 8'b00111000;
          3'd5: glyph_row = 8'b01101100;
          3'd6: glyph_row = 8'b11000110;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h79: begin // y
        case (glyph_y)
          3'd2: glyph_row = 8'b11001100;
          3'd3: glyph_row = 8'b11001100;
          3'd4: glyph_row = 8'b11001100;
          3'd5: glyph_row = 8'b01111100;
          3'd6: glyph_row = 8'b00001100;
          3'd7: glyph_row = 8'b11111000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h7A: begin // z
        case (glyph_y)
          3'd2: glyph_row = 8'b11111100;
          3'd3: glyph_row = 8'b10011000;
          3'd4: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b01100100;
          3'd6: glyph_row = 8'b11111100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h7B: begin // {
        case (glyph_y)
          3'd0: glyph_row = 8'b00011100;
          3'd1: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b00110000;
          3'd3: glyph_row = 8'b11100000;
          3'd4: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b00011100;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h7C: begin // |
        case (glyph_y)
          3'd0: glyph_row = 8'b00011000;
          3'd1: glyph_row = 8'b00011000;
          3'd2: glyph_row = 8'b00011000;
          3'd4: glyph_row = 8'b00011000;
          3'd5: glyph_row = 8'b00011000;
          3'd6: glyph_row = 8'b00011000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h7D: begin // }
        case (glyph_y)
          3'd0: glyph_row = 8'b11100000;
          3'd1: glyph_row = 8'b00110000;
          3'd2: glyph_row = 8'b00110000;
          3'd3: glyph_row = 8'b00011100;
          3'd4: glyph_row = 8'b00110000;
          3'd5: glyph_row = 8'b00110000;
          3'd6: glyph_row = 8'b11100000;
          default: glyph_row = 8'h00;
        endcase
      end
      8'h7E: begin // ~
        case (glyph_y)
          3'd0: glyph_row = 8'b01110110;
          3'd1: glyph_row = 8'b11011100;
          default: glyph_row = 8'h00;
        endcase
      end
      default: glyph_row = 8'h00;
    endcase
  end
endmodule
