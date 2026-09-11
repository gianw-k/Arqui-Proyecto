//32-bit top module: shift + ALU
module top(input  [31:0] a, b,
           input  [1:0]  bshift,
           input  [2:0]  ALUControl,
           output wire [31:0] Result,
           output wire [3:0]  ALUFlags);

  wire [31:0] a_desplazado;

  shift shift1(a, bshift, a_desplazado);
  alu alu1(a_desplazado, b, ALUControl, Result, ALUFlags);

endmodule
