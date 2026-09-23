`timescale 1ns/1ps

module alu_tb;
  reg  clk, reset, start;
  reg  [31:0] a, b;
  reg  [2:0]  ALUControl;
  reg  [1:0]  bshift;
  wire signed [31:0] Result;
  wire [3:0]  ALUFlags;
  wire done;

  top top1(clk, reset, start, a, b, bshift, ALUControl, Result, ALUFlags, done);

  // Reloj: periodo 10 ns
  always #5 clk = ~clk;

  // Para mostrar el resultado despues de recibir el output en su formato Q2.30 original: Result / 2^30 (solo para cos/sin)
  localparam real conversion = 2.0 ** 30;
  real value;
  always @(*) begin
    value = $signed(Result) / conversion;
  end

  initial begin
    // Reset
    clk = 0; reset = 1; start = 0;
    a = 0; b = 0; ALUControl = 3'b000; bshift = 2'b00;
    #20 reset = 0;

    // Operaciones basicas
    a = 3; b = 5; ALUControl = 3'b000; bshift = 2'b00; #10;  // add: 3 + 5 = 8
    a = 5; b = 5; ALUControl = 3'b001; bshift = 2'b00; #10;  // sub: 5 - 5 = 0
    a = 8; b = 1; ALUControl = 3'b010; bshift = 2'b00; #10;  // and: 1000 & 0001 = 0000
    a = 5; b = 7; ALUControl = 3'b011; bshift = 2'b00; #10;  // or:  0101 | 0111 = 0111
    a = 9; b = 6; ALUControl = 3'b100; bshift = 2'b00; #10;  // xor: 1001 ^ 0110 = 1111

    // Shift + suma
    a = 3; b = 0; ALUControl = 3'b000; bshift = 2'b01; #10;  // shl: 3 << 1 = 6
    a = 3; b = 0; ALUControl = 3'b000; bshift = 2'b10; #10;  // shl: 3 << 2 = 12
    a = 3; b = 0; ALUControl = 3'b000; bshift = 2'b11; #10;  // shl: 3 << 3 = 24

    // Seno y coseno por Cordix
    // output: valor * 2^30 -> ej. 0.5 * 1073741824 = 536870912
    a = 0;  b = 0; bshift = 2'b00; start = 1; #10 start = 0; wait (done); // esperamos a que terminen las iteraciones
    ALUControl = 3'b101; #10;  // cos 0  = 1.00000 -> 1073741824
    ALUControl = 3'b110; #10;  // sin 0  = 0.00000 -> 0

    a = 30; start = 1; #10 start = 0; wait (done);
    ALUControl = 3'b101; #10;  // cos 30 = 0.86603 -> 929887697
    ALUControl = 3'b110; #10;  // sin 30 = 0.50000 -> 536870912

    a = 45; start = 1; #10 start = 0; wait (done);
    ALUControl = 3'b101; #10;  // cos 45 = 0.70711 -> 759250125
    ALUControl = 3'b110; #10;  // sin 45 = 0.70711 -> 759250125

    a = 60; start = 1; #10 start = 0; wait (done);
    ALUControl = 3'b101; #10;  // cos 60 = 0.50000 -> 536870912
    ALUControl = 3'b110; #10;  // sin 60 = 0.86603 -> 929887697

    a = 90; start = 1; #10 start = 0; wait (done);
    ALUControl = 3'b101; #10;  // cos 90 = 0.00000 -> 0
    ALUControl = 3'b110; #10;  // sin 90 = 1.00000 -> 1073741824

    $finish;
  end

  // Imprime cada cambio
  initial
  $monitor("t=%0t a=%0d b=%0d bshift=%b ALUControl=%b Result=%0d (%f) NZCV=%b done=%b",
  $time, a, b, bshift, ALUControl, Result, value, ALUFlags, done);

endmodule
