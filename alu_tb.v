`timescale 1ns/1ps

module alu_tb;
  reg  [4:0] a, b;
  reg  [2:0]  ALUControl;
  reg  [1:0]  bshift;
  wire [4:0] Result;
  wire [3:0]  ALUFlags;

  top top1(a, b, bshift, ALUControl, Result, ALUFlags);

  initial begin
    a = 3; b = 5; ALUControl = 3'b000; bshift = 2'b00; // 3 + 5 = 1000
    #10;

    a = 5; b = 5; ALUControl = 3'b001; bshift = 2'b00; // 5 - 5 = 0000
    #10;

    a = 8; b = 1; ALUControl = 3'b010; bshift = 2'b00; // 1000 and 0001 -> 0000
    #10;

    a = 5; b = 7; ALUControl = 3'b011; bshift = 2'b00; // 0101 or 0111 -> 0111
    #10;

    a = 9; b = 6; ALUControl = 3'b100; bshift = 2'b00; // 1001 xor 0110 -> 1111
    #10;

    a = 3; b = 0; ALUControl = 3'b000; bshift = 2'b01; // 0011 << 1 pos -> 0110
    #10;

    a = 3; b = 0; ALUControl = 3'b000; bshift = 2'b10; // 0011 << 2 pos -> 1100
    #10;

    a = 3; b = 0; ALUControl = 3'b000; bshift = 2'b11; // 00011 << 3 pos -> 11000
    #10;

    $finish;
  end

  initial begin
    $dumpfile("alu_tb.vcd");
    $dumpvars;
  end

  initial
  $monitor("t=%0t a=%0d b=%0d bshift=%b ALUControl=%b Result=%0d NZCV=%b",
  $time, a, b, bshift, ALUControl, Result, ALUFlags);

endmodule
