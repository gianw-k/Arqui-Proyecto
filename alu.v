// 32 bits alu
module alu(input  clk, reset, start,
           input  [31:0] a, b,
           input  [2:0]  ALUControl,
           output reg [31:0] Result,
           output wire [3:0]  ALUFlags,
           output wire done);

  wire neg, zero, carry, overflow;
  wire [31:0] condinvb;
  wire [32:0] sum;
  wire signed [31:0] cosine, sine;

  assign condinvb = ALUControl[0] ? ~b : b;
  assign sum = a + condinvb + ALUControl[0];

  // Cordic calcula cos y sin a la vez, ALUControl elige cual sale
  cordic cordic1(clk, reset, start, a, cosine, sine, done);

  always @(*) begin
    case (ALUControl[2:0])
      3'b000: Result = sum;      // suma
      3'b001: Result = sum;      // resta
      3'b010: Result = a & b;    // and
      3'b011: Result = a | b;    // or
      3'b100: Result = a ^ b;    // xor
      3'b101: Result = cosine;   // coseno (Q2.30)
      3'b110: Result = sine;     // seno   (Q2.30)
      default: Result = 32'b0;
    endcase
  end

  assign neg = Result[31];
  assign zero = (Result == 32'b0);
  assign carry = (ALUControl[2:1] == 2'b00) & sum[32];
  assign overflow = (ALUControl[2:1] == 2'b00) & ~(a[31] ^ b[31] ^ ALUControl[0]) & (a[31] ^ sum[31]);
  assign ALUFlags = {neg, zero, carry, overflow};

endmodule
