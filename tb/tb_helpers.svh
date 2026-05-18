`ifndef LC3_TB_HELPERS_SVH
`define LC3_TB_HELPERS_SVH

`timescale 1ns/1ps

parameter string TB_GREEN = "\033[32m";
parameter string TB_RED = "\033[31m";
parameter string TB_RESET = "\033[0m";

task automatic print_case_pass(input string name);
  $display("%s[PASS]%s %-14s", TB_GREEN, TB_RESET, name);
endtask

task automatic print_regs5(
  input string label,
  input logic [15:0] r1,
  input logic [15:0] r2,
  input logic [15:0] r3,
  input logic [15:0] r4,
  input logic [15:0] r5
);
  $display("       %-8s R1=%04h R2=%04h R3=%04h R4=%04h R5=%04h",
           label, r1, r2, r3, r4, r5);
endtask

task automatic print_regs2(
  input string label,
  input logic [15:0] r1,
  input logic [15:0] r2
);
  $display("       %-8s R1=%04h R2=%04h", label, r1, r2);
endtask

task automatic print_cc(
  input string label,
  input logic n,
  input logic z,
  input logic p
);
  $display("       %-8s N=%0b Z=%0b P=%0b", label, n, z, p);
endtask

task automatic print_case_fail_regs5(
  input string name,
  input logic [15:0] act_r1,
  input logic [15:0] act_r2,
  input logic [15:0] act_r3,
  input logic [15:0] act_r4,
  input logic [15:0] act_r5,
  input logic act_n,
  input logic act_z,
  input logic act_p,
  input logic [15:0] exp_r1,
  input logic [15:0] exp_r2,
  input logic [15:0] exp_r3,
  input logic [15:0] exp_r4,
  input logic [15:0] exp_r5,
  input logic exp_n,
  input logic exp_z,
  input logic exp_p
);
  $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
  print_regs5("actual", act_r1, act_r2, act_r3, act_r4, act_r5);
  print_regs5("expected", exp_r1, exp_r2, exp_r3, exp_r4, exp_r5);
  print_cc("actual", act_n, act_z, act_p);
  print_cc("expected", exp_n, exp_z, exp_p);
endtask

task automatic print_case_fail_regs2(
  input string name,
  input logic [15:0] act_r1,
  input logic [15:0] act_r2,
  input logic act_n,
  input logic act_z,
  input logic act_p,
  input logic [15:0] exp_r1,
  input logic [15:0] exp_r2,
  input logic exp_n,
  input logic exp_z,
  input logic exp_p
);
  $display("%s[FAIL]%s %-14s", TB_RED, TB_RESET, name);
  print_regs2("actual", act_r1, act_r2);
  print_regs2("expected", exp_r1, exp_r2);
  print_cc("actual", act_n, act_z, act_p);
  print_cc("expected", exp_n, exp_z, exp_p);
endtask

`endif
