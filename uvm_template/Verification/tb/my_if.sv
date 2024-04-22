`ifndef MY_IF__SV
`define MY_IF__SV

interface jammer_conv_if(
  input logic clk,           // 时钟信号
  input logic rst_n          // 异步复位信号，低电平有效
);

  parameter WIDTH = 16;      // 数据宽度
  parameter NUM = 8;         // 寄存器数量

  logic [WIDTH-1:0] coe;     // 系数输入
  logic coes_vld;            // 系数有效信号
  logic sig_vld;             // 信号有效信号
  logic last_sig;            // 最后一个信号标志
  logic [WIDTH-1:0] sig_in;  // 信号输入
  logic [2*WIDTH-1:0] sig_out; // 信号输出

  // Modport定义
  modport DUT (
    input clk, rst_n, coe, coes_vld, sig_vld, last_sig, sig_in,
    output sig_out
  );

  modport TB (
    output clk, rst_n, coe, coes_vld, sig_vld, last_sig, sig_in,
    input sig_out
  );

endinterface


`endif
