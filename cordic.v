// 32 bits sin/cos
// Definiciones utiles:
// QX.Y;  X signo + enteros (1 signo y los demás enteros), Y decimales
// angle; grados enteros (60 = 60 grados), rango valido de -99 hasta 99
// z;     tabla atan: Q8.24 en grados (1 grado = 2^24 = 16777216)
// x;     y, cosine, sine: Q2.30 (1.0 = 2^30 = 1073741824)
module cordic(input  clk, reset, start,
              input  signed [31:0] angle,
              output signed [31:0] cosine, sine,
              output done);

  // Codificación de estados
  localparam IDLE    = 2'd0;
  localparam INIT    = 2'd1;
  localparam ITERATE = 2'd2;
  localparam DONE    = 2'd3;

  // Q2.30, 32'sd = 32 bits signo y decimal
  // K = 1/K16 = 0.607252935 -> 0.607252935 * 2^30 = 652032874
  localparam signed [31:0] K = 32'sd652032874;

  // Registros principales para FSM y para el algoritmo de CORDIC
  reg [1:0] state, next_state;   // Para FSM
  reg signed [31:0] x, y, z;    // Para Cordic
  reg [3:0] i;                  // Para Cordic

  // Tabla Q8.24: atan(2^-i) en grados * 2^24
  reg signed [31:0] atan_i;
  always @(*) begin
    case (i)
      4'd0:  atan_i = 32'sd754974720;  // 45.000000° ej. 754974720/2^24 = 45.000000
      4'd1:  atan_i = 32'sd445687602;  // 26.565051°
      4'd2:  atan_i = 32'sd235489088;  // 14.036243
      4'd3:  atan_i = 32'sd119537938;  //  7.125016
      4'd4:  atan_i = 32'sd60000934;   //  3.576334
      4'd5:  atan_i = 32'sd30029717;   //  1.789911
      4'd6:  atan_i = 32'sd15018523;   //  0.895174
      4'd7:  atan_i = 32'sd7509720;    //  0.447614
      4'd8:  atan_i = 32'sd3754917;    //  0.223811
      4'd9:  atan_i = 32'sd1877466;    //  0.111906
      4'd10: atan_i = 32'sd938734;     //  0.055953
      4'd11: atan_i = 32'sd469367;     //  0.027976
      4'd12: atan_i = 32'sd234684;     //  0.013988
      4'd13: atan_i = 32'sd117342;     //  0.006994
      4'd14: atan_i = 32'sd58671;      //  0.003497
      4'd15: atan_i = 32'sd29335;      //  0.001749
    endcase
  end

  // StateRegister
  always @(posedge clk) begin
    if (reset)
      state <= IDLE;
    else
      state <= next_state;
  end

  // NextState
  always @(*) begin
    case (state)
      IDLE:
        if (start) next_state = INIT;
        else       next_state = IDLE;

      INIT:
        next_state = ITERATE;

      ITERATE:
        if (i == 15) next_state = DONE;     // ultima iteracion
        else         next_state = ITERATE;

      DONE:
        if (start) next_state = INIT;       // nueva operacion
        else       next_state = DONE;       // mantiene resultado

      default:
        next_state = IDLE;
    endcase
  end

  // Asignación en estados
  always @(posedge clk) begin
    if (reset) begin
      x <= 0;
      y <= 0;
      z <= 0;
      i <= 0;
    end
    else
      case (state)
        IDLE: begin
          x <= x;   // espera start
          y <= y;
          z <= z;
          i <= i;
        end

        INIT: begin
          x <= K;             // x0 = 1/K
          y <= 0;             // y0 = 0
          z <= angle <<< 24;  // z0 = angle en Q8.24 (al ser potencia de 2 basta shift de 24)
          i <= 0;
        end

        ITERATE: begin
          if (z >= 0) begin     // d = +1: gira antihorario
            x <= x - (y >>> i);
            y <= y + (x >>> i);
            z <= z - atan_i;
          end
          else begin            // d = -1: gira horario
            x <= x + (y >>> i);
            y <= y - (x >>> i);
            z <= z + atan_i;
          end
          i <= i + 1;
        end

        DONE: begin
          x <= x;   // mantiene resultado
          y <= y;
          z <= z;
          i <= i;
        end
      endcase
  end

  // Salidas (solo dependen del estado)
  assign done = (state == DONE);
  assign cosine = x;
  assign sine = y;

endmodule
