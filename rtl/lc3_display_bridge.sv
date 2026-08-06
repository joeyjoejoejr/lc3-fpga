`timescale 1ns/1ps

module lc3_display_bridge (
  input  logic       sys_clk,
  input  logic       sys_reset,
  input  logic       sys_valid,
  input  logic [7:0] sys_data,
  output logic       sys_ready,

  input  logic       lcd_clk,
  input  logic       lcd_reset,
  output logic       lcd_valid,
  output logic [7:0] lcd_data,
  input  logic       lcd_ready
);
  logic [7:0] sys_data_hold;
  logic sys_req_toggle;
  logic sys_ack_meta;
  logic sys_ack_sync;

  logic lcd_req_meta;
  logic lcd_req_sync;
  logic lcd_ack_toggle;

  assign sys_ready = sys_req_toggle == sys_ack_sync;

  always_ff @(posedge sys_clk) begin
    if (sys_reset) begin
      sys_data_hold <= 8'h00;
      sys_req_toggle <= 1'b0;
      sys_ack_meta <= 1'b0;
      sys_ack_sync <= 1'b0;
    end else begin
      sys_ack_meta <= lcd_ack_toggle;
      sys_ack_sync <= sys_ack_meta;

      if (sys_valid && sys_ready) begin
        sys_data_hold <= sys_data;
        sys_req_toggle <= ~sys_req_toggle;
      end
    end
  end

  always_ff @(posedge lcd_clk) begin
    if (lcd_reset) begin
      lcd_valid <= 1'b0;
      lcd_data <= 8'h00;
      lcd_req_meta <= 1'b0;
      lcd_req_sync <= 1'b0;
      lcd_ack_toggle <= 1'b0;
    end else begin
      lcd_req_meta <= sys_req_toggle;
      lcd_req_sync <= lcd_req_meta;
      lcd_valid <= 1'b0;

      if (lcd_req_sync != lcd_ack_toggle && lcd_ready) begin
        lcd_data <= sys_data_hold;
        lcd_valid <= 1'b1;
        lcd_ack_toggle <= lcd_req_sync;
      end
    end
  end
endmodule
