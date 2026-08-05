`timescale 1ns/1ps
`include "tb_helpers.svh"

module lc3_text_console_tb #(
  parameter bit FINISH_ON_PASS = 1'b1
);
  localparam int COLS = 60;
  localparam int ROWS = 34;
  localparam int CELL_COUNT = COLS * ROWS;
  localparam int CELL_ADDR_WIDTH = $clog2(CELL_COUNT);
  localparam int COL_WIDTH = $clog2(COLS);
  localparam int ROW_WIDTH = $clog2(ROWS);

  logic clk = 1'b0;
  logic reset;

  logic char_valid;
  logic [7:0] char_data;
  logic char_ready;

  logic [COL_WIDTH-1:0] cell_read_col;
  logic [ROW_WIDTH-1:0] cell_read_row;
  logic [7:0] cell_read_data;

  always #5 clk = ~clk;

  lc3_text_console #(
    .COLS(COLS),
    .ROWS(ROWS)
  ) dut (
    .clk(clk),
    .reset(reset),
    .char_valid(char_valid),
    .char_data(char_data),
    .char_ready(char_ready),
    .cell_read_col(cell_read_col),
    .cell_read_row(cell_read_row),
    .cell_read_data(cell_read_data)
  );

  task automatic send_char(input logic [7:0] ch);
    begin
      while (!char_ready) @(posedge clk);

      @(negedge clk);
      char_data <= ch;
      char_valid <= 1'b1;
      @(posedge clk);

      @(negedge clk);
      char_valid <= 1'b0;
      char_data <= 8'h00;
      @(posedge clk);
    end
  endtask

  task automatic read_cell_expect(
    input string name,
    input logic [CELL_ADDR_WIDTH-1:0] addr,
    input logic [7:0] expected
  );
    begin
      @(negedge clk);
      cell_read_row <= addr / COLS;
      cell_read_col <= addr % COLS;
      @(posedge clk);
      @(posedge clk);

      if (cell_read_data !== expected) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       cell     %0d", addr);
        $display("       actual   %02h", cell_read_data);
        $display("       expected %02h", expected);
        $fatal(1);
      end
    end
  endtask

  initial begin
    reset = 1'b1;
    char_valid = 1'b0;
    char_data = 8'h00;
    cell_read_col = '0;
    cell_read_row = '0;

    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (2) @(posedge clk);

    read_cell_expect("initial_blank", 0, 8'h00);

    send_char("A");

    read_cell_expect("write_first", 0, "A");

    send_char("B");

    read_cell_expect("first_stays", 0, "A");
    read_cell_expect("cursor_advance", 1, "B");

    print_case_pass("text_console");
    if (FINISH_ON_PASS) $finish;
  end
endmodule

module lc3_text_console_wrap_tb #(
  parameter bit FINISH_ON_PASS = 1'b1
);
  localparam int COLS = 4;
  localparam int ROWS = 2;
  localparam int CELL_COUNT = COLS * ROWS;
  localparam int CELL_ADDR_WIDTH = $clog2(CELL_COUNT);
  localparam int COL_WIDTH = $clog2(COLS);
  localparam int ROW_WIDTH = $clog2(ROWS);

  logic clk = 1'b0;
  logic reset;

  logic char_valid;
  logic [7:0] char_data;
  logic char_ready;

  logic [COL_WIDTH-1:0] cell_read_col;
  logic [ROW_WIDTH-1:0] cell_read_row;
  logic [7:0] cell_read_data;

  always #5 clk = ~clk;

  lc3_text_console #(
    .COLS(COLS),
    .ROWS(ROWS)
  ) dut (
    .clk(clk),
    .reset(reset),
    .char_valid(char_valid),
    .char_data(char_data),
    .char_ready(char_ready),
    .cell_read_col(cell_read_col),
    .cell_read_row(cell_read_row),
    .cell_read_data(cell_read_data)
  );

  task automatic send_char(input logic [7:0] ch);
    begin
      while (!char_ready) @(posedge clk);

      @(negedge clk);
      char_data <= ch;
      char_valid <= 1'b1;
      @(posedge clk);

      @(negedge clk);
      char_valid <= 1'b0;
      char_data <= 8'h00;
      @(posedge clk);
    end
  endtask

  task automatic read_cell_expect(
    input string name,
    input logic [CELL_ADDR_WIDTH-1:0] addr,
    input logic [7:0] expected
  );
    begin
      @(negedge clk);
      cell_read_row <= addr / COLS;
      cell_read_col <= addr % COLS;
      @(posedge clk);
      @(posedge clk);

      if (cell_read_data !== expected) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       cell     %0d", addr);
        $display("       actual   %02h", cell_read_data);
        $display("       expected %02h", expected);
        $fatal(1);
      end
    end
  endtask

  initial begin
    reset = 1'b1;
    char_valid = 1'b0;
    char_data = 8'h00;
    cell_read_col = '0;
    cell_read_row = '0;

    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (2) @(posedge clk);

    send_char("0");
    send_char("1");
    send_char("2");
    send_char("3");
    send_char("4");

    read_cell_expect("wrap_row0_col0", 0, "0");
    read_cell_expect("wrap_row0_col3", 3, "3");
    read_cell_expect("wrap_row1_col0", COLS, "4");
    read_cell_expect("wrap_row1_col1", COLS + 1, 8'h00);

    print_case_pass("text_console_wrap");
    if (FINISH_ON_PASS) $finish;
  end
endmodule

module lc3_text_console_newline_tb #(
  parameter bit FINISH_ON_PASS = 1'b1
);
  localparam int COLS = 4;
  localparam int ROWS = 2;
  localparam int CELL_COUNT = COLS * ROWS;
  localparam int CELL_ADDR_WIDTH = $clog2(CELL_COUNT);
  localparam int COL_WIDTH = $clog2(COLS);
  localparam int ROW_WIDTH = $clog2(ROWS);

  logic clk = 1'b0;
  logic reset;

  logic char_valid;
  logic [7:0] char_data;
  logic char_ready;

  logic [COL_WIDTH-1:0] cell_read_col;
  logic [ROW_WIDTH-1:0] cell_read_row;
  logic [7:0] cell_read_data;

  always #5 clk = ~clk;

  lc3_text_console #(
    .COLS(COLS),
    .ROWS(ROWS)
  ) dut (
    .clk(clk),
    .reset(reset),
    .char_valid(char_valid),
    .char_data(char_data),
    .char_ready(char_ready),
    .cell_read_col(cell_read_col),
    .cell_read_row(cell_read_row),
    .cell_read_data(cell_read_data)
  );

  task automatic send_char(input logic [7:0] ch);
    begin
      while (!char_ready) @(posedge clk);

      @(negedge clk);
      char_data <= ch;
      char_valid <= 1'b1;
      @(posedge clk);

      @(negedge clk);
      char_valid <= 1'b0;
      char_data <= 8'h00;
      @(posedge clk);
    end
  endtask

  task automatic read_cell_expect(
    input string name,
    input logic [CELL_ADDR_WIDTH-1:0] addr,
    input logic [7:0] expected
  );
    begin
      @(negedge clk);
      cell_read_row <= addr / COLS;
      cell_read_col <= addr % COLS;
      @(posedge clk);
      @(posedge clk);

      if (cell_read_data !== expected) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       cell     %0d", addr);
        $display("       actual   %02h", cell_read_data);
        $display("       expected %02h", expected);
        $fatal(1);
      end
    end
  endtask

  initial begin
    reset = 1'b1;
    char_valid = 1'b0;
    char_data = 8'h00;
    cell_read_col = '0;
    cell_read_row = '0;

    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (2) @(posedge clk);

    send_char("A");
    send_char(8'h0A);
    send_char("B");

    read_cell_expect("newline_first", 0, "A");
    read_cell_expect("newline_skips", 1, 8'h00);
    read_cell_expect("newline_next_row", COLS, "B");

    print_case_pass("text_console_newline");
    if (FINISH_ON_PASS) $finish;
  end
endmodule

module lc3_text_console_carriage_return_tb #(
  parameter bit FINISH_ON_PASS = 1'b1
);
  localparam int COLS = 4;
  localparam int ROWS = 2;
  localparam int CELL_COUNT = COLS * ROWS;
  localparam int CELL_ADDR_WIDTH = $clog2(CELL_COUNT);
  localparam int COL_WIDTH = $clog2(COLS);
  localparam int ROW_WIDTH = $clog2(ROWS);

  logic clk = 1'b0;
  logic reset;

  logic char_valid;
  logic [7:0] char_data;
  logic char_ready;

  logic [COL_WIDTH-1:0] cell_read_col;
  logic [ROW_WIDTH-1:0] cell_read_row;
  logic [7:0] cell_read_data;

  always #5 clk = ~clk;

  lc3_text_console #(
    .COLS(COLS),
    .ROWS(ROWS)
  ) dut (
    .clk(clk),
    .reset(reset),
    .char_valid(char_valid),
    .char_data(char_data),
    .char_ready(char_ready),
    .cell_read_col(cell_read_col),
    .cell_read_row(cell_read_row),
    .cell_read_data(cell_read_data)
  );

  task automatic send_char(input logic [7:0] ch);
    begin
      while (!char_ready) @(posedge clk);

      @(negedge clk);
      char_data <= ch;
      char_valid <= 1'b1;
      @(posedge clk);

      @(negedge clk);
      char_valid <= 1'b0;
      char_data <= 8'h00;
      @(posedge clk);
    end
  endtask

  task automatic read_cell_expect(
    input string name,
    input logic [CELL_ADDR_WIDTH-1:0] addr,
    input logic [7:0] expected
  );
    begin
      @(negedge clk);
      cell_read_row <= addr / COLS;
      cell_read_col <= addr % COLS;
      @(posedge clk);
      @(posedge clk);

      if (cell_read_data !== expected) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       cell     %0d", addr);
        $display("       actual   %02h", cell_read_data);
        $display("       expected %02h", expected);
        $fatal(1);
      end
    end
  endtask

  initial begin
    reset = 1'b1;
    char_valid = 1'b0;
    char_data = 8'h00;
    cell_read_col = '0;
    cell_read_row = '0;

    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (2) @(posedge clk);

    send_char("A");
    send_char("B");
    send_char(8'h0D);
    send_char("C");

    read_cell_expect("cr_overwrites_col0", 0, "C");
    read_cell_expect("cr_keeps_col1", 1, "B");
    read_cell_expect("cr_same_row", COLS, 8'h00);

    print_case_pass("text_console_cr");
    if (FINISH_ON_PASS) $finish;
  end
endmodule

module lc3_text_console_backspace_tb #(
  parameter bit FINISH_ON_PASS = 1'b1
);
  localparam int COLS = 4;
  localparam int ROWS = 2;
  localparam int CELL_COUNT = COLS * ROWS;
  localparam int CELL_ADDR_WIDTH = $clog2(CELL_COUNT);
  localparam int COL_WIDTH = $clog2(COLS);
  localparam int ROW_WIDTH = $clog2(ROWS);

  logic clk = 1'b0;
  logic reset;

  logic char_valid;
  logic [7:0] char_data;
  logic char_ready;

  logic [COL_WIDTH-1:0] cell_read_col;
  logic [ROW_WIDTH-1:0] cell_read_row;
  logic [7:0] cell_read_data;

  always #5 clk = ~clk;

  lc3_text_console #(
    .COLS(COLS),
    .ROWS(ROWS)
  ) dut (
    .clk(clk),
    .reset(reset),
    .char_valid(char_valid),
    .char_data(char_data),
    .char_ready(char_ready),
    .cell_read_col(cell_read_col),
    .cell_read_row(cell_read_row),
    .cell_read_data(cell_read_data)
  );

  task automatic send_char(input logic [7:0] ch);
    begin
      while (!char_ready) @(posedge clk);

      @(negedge clk);
      char_data <= ch;
      char_valid <= 1'b1;
      @(posedge clk);

      @(negedge clk);
      char_valid <= 1'b0;
      char_data <= 8'h00;
      @(posedge clk);
    end
  endtask

  task automatic read_cell_expect(
    input string name,
    input logic [CELL_ADDR_WIDTH-1:0] addr,
    input logic [7:0] expected
  );
    begin
      @(negedge clk);
      cell_read_row <= addr / COLS;
      cell_read_col <= addr % COLS;
      @(posedge clk);
      @(posedge clk);

      if (cell_read_data !== expected) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       cell     %0d", addr);
        $display("       actual   %02h", cell_read_data);
        $display("       expected %02h", expected);
        $fatal(1);
      end
    end
  endtask

  initial begin
    reset = 1'b1;
    char_valid = 1'b0;
    char_data = 8'h00;
    cell_read_col = '0;
    cell_read_row = '0;

    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (2) @(posedge clk);

    send_char("A");
    send_char("B");
    send_char(8'h08);
    send_char("C");

    read_cell_expect("bs_keeps_prev", 0, "A");
    read_cell_expect("bs_overwrites", 1, "C");
    read_cell_expect("bs_next_blank", 2, 8'h00);

    print_case_pass("text_console_bs");
    if (FINISH_ON_PASS) $finish;
  end
endmodule

module lc3_text_console_backspace_edge_tb #(
  parameter bit FINISH_ON_PASS = 1'b1
);
  localparam int COLS = 4;
  localparam int ROWS = 2;
  localparam int CELL_COUNT = COLS * ROWS;
  localparam int CELL_ADDR_WIDTH = $clog2(CELL_COUNT);
  localparam int COL_WIDTH = $clog2(COLS);
  localparam int ROW_WIDTH = $clog2(ROWS);

  logic clk = 1'b0;
  logic reset;

  logic char_valid;
  logic [7:0] char_data;
  logic char_ready;

  logic [COL_WIDTH-1:0] cell_read_col;
  logic [ROW_WIDTH-1:0] cell_read_row;
  logic [7:0] cell_read_data;

  always #5 clk = ~clk;

  lc3_text_console #(
    .COLS(COLS),
    .ROWS(ROWS)
  ) dut (
    .clk(clk),
    .reset(reset),
    .char_valid(char_valid),
    .char_data(char_data),
    .char_ready(char_ready),
    .cell_read_col(cell_read_col),
    .cell_read_row(cell_read_row),
    .cell_read_data(cell_read_data)
  );

  task automatic send_char(input logic [7:0] ch);
    begin
      while (!char_ready) @(posedge clk);

      @(negedge clk);
      char_data <= ch;
      char_valid <= 1'b1;
      @(posedge clk);

      @(negedge clk);
      char_valid <= 1'b0;
      char_data <= 8'h00;
      @(posedge clk);
    end
  endtask

  task automatic read_cell_expect(
    input string name,
    input logic [CELL_ADDR_WIDTH-1:0] addr,
    input logic [7:0] expected
  );
    begin
      @(negedge clk);
      cell_read_row <= addr / COLS;
      cell_read_col <= addr % COLS;
      @(posedge clk);
      @(posedge clk);

      if (cell_read_data !== expected) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       cell     %0d", addr);
        $display("       actual   %02h", cell_read_data);
        $display("       expected %02h", expected);
        $fatal(1);
      end
    end
  endtask

  initial begin
    reset = 1'b1;
    char_valid = 1'b0;
    char_data = 8'h00;
    cell_read_col = '0;
    cell_read_row = '0;

    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (2) @(posedge clk);

    send_char(8'h08);
    send_char("A");

    read_cell_expect("bs_edge_writes_col0", 0, "A");
    read_cell_expect("bs_edge_no_skip", 1, 8'h00);

    print_case_pass("text_console_bs_edge");
    if (FINISH_ON_PASS) $finish;
  end
endmodule

module lc3_text_console_scroll_tb #(
  parameter bit FINISH_ON_PASS = 1'b1
);
  localparam int COLS = 4;
  localparam int ROWS = 2;
  localparam int CELL_COUNT = COLS * ROWS;
  localparam int CELL_ADDR_WIDTH = $clog2(CELL_COUNT);
  localparam int COL_WIDTH = $clog2(COLS);
  localparam int ROW_WIDTH = $clog2(ROWS);

  logic clk = 1'b0;
  logic reset;

  logic char_valid;
  logic [7:0] char_data;
  logic char_ready;

  logic [COL_WIDTH-1:0] cell_read_col;
  logic [ROW_WIDTH-1:0] cell_read_row;
  logic [7:0] cell_read_data;

  always #5 clk = ~clk;

  lc3_text_console #(
    .COLS(COLS),
    .ROWS(ROWS)
  ) dut (
    .clk(clk),
    .reset(reset),
    .char_valid(char_valid),
    .char_data(char_data),
    .char_ready(char_ready),
    .cell_read_col(cell_read_col),
    .cell_read_row(cell_read_row),
    .cell_read_data(cell_read_data)
  );

  task automatic send_char(input logic [7:0] ch);
    begin
      while (!char_ready) @(posedge clk);

      @(negedge clk);
      char_data <= ch;
      char_valid <= 1'b1;
      @(posedge clk);

      @(negedge clk);
      char_valid <= 1'b0;
      char_data <= 8'h00;
      @(posedge clk);
    end
  endtask

  task automatic read_cell_expect(
    input string name,
    input logic [CELL_ADDR_WIDTH-1:0] addr,
    input logic [7:0] expected
  );
    begin
      @(negedge clk);
      cell_read_row <= addr / COLS;
      cell_read_col <= addr % COLS;
      @(posedge clk);
      @(posedge clk);

      if (cell_read_data !== expected) begin
        $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
        $display("       cell     %0d", addr);
        $display("       actual   %02h", cell_read_data);
        $display("       expected %02h", expected);
        $fatal(1);
      end
    end
  endtask

  initial begin
    reset = 1'b1;
    char_valid = 1'b0;
    char_data = 8'h00;
    cell_read_col = '0;
    cell_read_row = '0;

    repeat (2) @(posedge clk);
    reset = 1'b0;
    repeat (2) @(posedge clk);

    send_char("A");
    send_char("X");
    send_char(8'h0A);
    send_char("B");
    send_char(8'h0A);
    send_char("C");

    read_cell_expect("scroll_row0_col0", 0, "B");
    read_cell_expect("scroll_row0_col1", 1, 8'h00);
    read_cell_expect("scroll_row1_col0", COLS, "C");
    read_cell_expect("scroll_row1_col1", COLS + 1, 8'h00);

    print_case_pass("text_console_scroll");
    if (FINISH_ON_PASS) $finish;
  end
endmodule

module lc3_text_console_all_tb;
  initial begin
    #5000;
    $finish;
  end

  lc3_text_console_tb #(
    .FINISH_ON_PASS(1'b0)
  ) basic();

  lc3_text_console_wrap_tb #(
    .FINISH_ON_PASS(1'b0)
  ) wrap();

  lc3_text_console_newline_tb #(
    .FINISH_ON_PASS(1'b0)
  ) newline();

  lc3_text_console_carriage_return_tb #(
    .FINISH_ON_PASS(1'b0)
  ) carriage_return();

  lc3_text_console_backspace_tb #(
    .FINISH_ON_PASS(1'b0)
  ) backspace();

  lc3_text_console_backspace_edge_tb #(
    .FINISH_ON_PASS(1'b0)
  ) backspace_edge();

  lc3_text_console_scroll_tb #(
    .FINISH_ON_PASS(1'b0)
  ) scroll();
endmodule
