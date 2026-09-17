//32-bit ALU for ARM processor
module alu(input  [4:0] a, b, //Entradas de 5 bits
           input  [2:0]  ALUControl,
           output reg [4:0] Result, //Salida de 5 bits
           output wire [3:0]  ALUFlags);

  wire neg, zero, carry, overflow;
  wire [4:0] condinvb;
  wire [5:0] sum;

  assign condinvb = ALUControl[0] ? ~b : b;
  assign sum = {1'b0, a}
           + {1'b0, condinvb}
           + ALUControl[0];

  always @(*)
    begin
      casex (ALUControl[2:0])
        3'b00?: Result = sum;
        3'b010: Result = a & b;
        3'b011: Result = a | b;
        3'b100: Result = a ^ b; //Cambio en la forma de ver si es xor
        default: Result = 5'b0;
      endcase
    end

  assign neg = Result[4];
  assign zero = (Result == 5'b0);
  assign carry = (ALUControl[2:1] == 2'b00) & sum[5]; //ALUControl[2:1] = 00 => aritmetico
  assign overflow = (ALUControl[2:1] == 2'b00) & ~(a[4] ^ b[4] ^ ALUControl[0]) & (a[4] ^ sum[4]);
  assign ALUFlags = {neg, zero, carry, overflow};

endmodule
