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

  // Valor absoluto de un real
  function real absr(input real v);
    absr = (v < 0.0) ? -v : v;
  endfunction

  // Imprime una fila de la tabla de errores
  // obtenido: salida del CORDIC en Q2.30, real_val: valor matematico exacto
  task reporte(input integer grados, input [8*3-1:0] fn, input real real_val,
               input signed [31:0] obtenido);
    real obt, err_abs, err_rel;
    begin
      obt = obtenido / conversion;
      err_abs = absr(obt - real_val);
      if (real_val != 0.0) begin
        err_rel = err_abs / absr(real_val) * 100.0;
        $display("| %3d | %s | %14d | %13.10f | %13.10f | %.3e | %.3e %% |",
                 grados, fn, obtenido, obt, real_val, err_abs, err_rel);
      end
      else
        $display("| %3d | %s | %14d | %13.10f | %13.10f | %.3e |      -      |",
                 grados, fn, obtenido, obt, real_val, err_abs);
    end
  endtask

  // Calcula cos y sin de un angulo y reporta ambos
  task probar(input integer grados, input real cos_real, input real sin_real);
    begin
      a = grados; b = 0; bshift = 2'b00;
      start = 1; @(posedge clk); #1 start = 0;  // el CORDIC entra a INIT en este flanco
      @(posedge done);                          // esperamos a que terminen las 16 iteraciones
      #1;
      ALUControl = 3'b101; #1;  // coseno
      reporte(grados, "cos", cos_real, Result);
      ALUControl = 3'b110; #1;  // seno
      reporte(grados, "sin", sin_real, Result);
    end
  endtask

  initial begin
    // Reset
    clk = 0; reset = 1; start = 0;
    a = 0; b = 0; ALUControl = 3'b000; bshift = 2'b00;
    #20 reset = 0;

    // Operaciones basicas
    a = 3; b = 5; ALUControl = 3'b000; bshift = 2'b00; #10;  // add: 3 + 5 = 8
    $display("add 3+5       = %0d", Result);
    a = 5; b = 5; ALUControl = 3'b001; bshift = 2'b00; #10;  // sub: 5 - 5 = 0
    $display("sub 5-5       = %0d  NZCV=%b", Result, ALUFlags);
    a = 8; b = 1; ALUControl = 3'b010; bshift = 2'b00; #10;  // and: 1000 & 0001 = 0000
    $display("and 8&1       = %0d", Result);
    a = 5; b = 7; ALUControl = 3'b011; bshift = 2'b00; #10;  // or:  0101 | 0111 = 0111
    $display("or  5|7       = %0d", Result);
    a = 9; b = 6; ALUControl = 3'b100; bshift = 2'b00; #10;  // xor: 1001 ^ 0110 = 1111
    $display("xor 9^6       = %0d", Result);

    // Shift + suma
    a = 3; b = 0; ALUControl = 3'b000; bshift = 2'b01; #10;  // shl: 3 << 1 = 6
    $display("(3<<1)+0      = %0d", Result);
    a = 3; b = 0; ALUControl = 3'b000; bshift = 2'b10; #10;  // shl: 3 << 2 = 12
    $display("(3<<2)+0      = %0d", Result);
    a = 3; b = 0; ALUControl = 3'b000; bshift = 2'b11; #10;  // shl: 3 << 3 = 24
    $display("(3<<3)+0      = %0d", Result);

    // Seno y coseno por CORDIC: tabla de errores
    // Obtenido en Q2.30 -> valor = Result / 2^30
    $display("");
    $display("Tabla de errores CORDIC");
    $display("| ang | fn  | obtenido Q2.30 |   obtenido    |  valor real   | error abs | error rel   |");
    probar(0,  1.0,                0.0);                 // cos 0  = 1,    sin 0  = 0
    probar(30, 0.8660254037844386, 0.5);                 // cos 30 = V3/2, sin 30 = 1/2
    probar(45, 0.7071067811865476, 0.7071067811865476);  // cos 45 = V2/2, sin 45 = V2/2
    probar(60, 0.5,                0.8660254037844386);  // cos 60 = 1/2,  sin 60 = V3/2
    probar(90, 0.0,                1.0);                 // cos 90 = 0,    sin 90 = 1

    $finish;
  end

endmodule
