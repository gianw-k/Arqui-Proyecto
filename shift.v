//32-bit left shift unit
module shift(input  [31:0] a,
             input  [1:0]  bshift,
             output wire [31:0] a_desplazado);

  assign a_desplazado = a << bshift;

endmodule
