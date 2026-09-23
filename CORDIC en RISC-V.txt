# ================================================================
# CORDIC seno/coseno en RV32I
# Comentarios largos (##) son explicaciones para quien recien
# empieza con RISC-V / CORDIC, pensados para compartir con el equipo.
# ================================================================

## ¿Por que dos formatos de punto fijo distintos?
## - x, y (las coordenadas del vector) usan Q2.30: 2 bits de parte entera,
##   30 de parte fraccionaria (escala = 2^30). Necesitan poca parte entera
##   porque despues de la compensacion de ganancia, x e y siempre quedan
##   entre -1 y 1 (son cosenos/senos).
## - z, y la tabla de angulos alpha_i, usan Q8.24: 8 bits de parte entera,
##   24 de parte fraccionaria (escala = 2^24), y ademas representan GRADOS,
##   no radianes. Necesitan mas parte entera porque el angulo de entrada
##   puede llegar hasta ~99 (no cabria en Q2.30, que solo llega a ~2).
## Como x/y y z son cantidades distintas (coordenadas vs. angulo), no hay
## problema en que usen escalas distintas: nunca se sumas entre si.

# Uso de stack_pointer. Aseguramos espacio de acuerdo a la cantidad de valores a guardar
    addi sp, sp, -64        # 16 valores alpha_i de 4 bytes = 64 bytes exactos

    ## Estos 16 valores YA vienen multiplicados por 2^24 (formato Q8.24):
    ## son arctan(2^-i) en grados * 2^24, calculados aparte (a mano/con
    ## Python) y pegados aqui como constantes. El shift por 24 no ocurre
    ## en esta parte del codigo -- eso solo pasa mas abajo, en tiempo de
    ## ejecucion, con el angulo de ENTRADA (linea "slli t2, a2, 24").
    li t0, 754974720        # alpha_0 = arctan(2^0)  = 45.000 grados
    sw t0, 0(sp)
    li t0, 445687602        # alpha_1 = arctan(2^-1) = 26.565 grados
    sw t0, 4(sp)
    li t0, 235489088        # alpha_2
    sw t0, 8(sp)
    li t0, 119537938        # alpha_3
    sw t0, 12(sp)
    li t0, 60000934         # alpha_4
    sw t0, 16(sp)
    li t0, 30029717         # alpha_5
    sw t0, 20(sp)
    li t0, 15018523         # alpha_6
    sw t0, 24(sp)
    li t0, 7509720          # alpha_7
    sw t0, 28(sp)
    li t0, 3754917          # alpha_8
    sw t0, 32(sp)
    li t0, 1877466          # alpha_9
    sw t0, 36(sp)
    li t0, 938734           # alpha_10
    sw t0, 40(sp)
    li t0, 469367           # alpha_11
    sw t0, 44(sp)
    li t0, 234684           # alpha_12
    sw t0, 48(sp)
    li t0, 117342           # alpha_13
    sw t0, 52(sp)
    li t0, 58671            # alpha_14
    sw t0, 56(sp)
    li t0, 29335            # alpha_15
    sw t0, 60(sp)

# --------- Programa principal ---------
# Direcciones (offsets desde s2, base):
#   +0  cos obtenido      +4  sin obtenido
#   +8  cos esperado      +12 sin esperado
#   +16 error abs. cos    +20 error abs. sin
main:
    li   s2, 0xFF00          # s2 = direccion base para resultados/casos de prueba
    addi a0, s2, 0            # direccion donde la subrutina guardara el coseno obtenido
    addi a1, s2, 4             # direccion donde la subrutina guardara el seno obtenido
	# En a2 se guardara el grado a procesar

    # ---- Casos de prueba: descomenta solo uno para probar ----

	# ---- Caso de prueba: 0 grados ----
    # addi a2, zero, 0
    # li   t0, 1073741824        # cos(0) esperado
    # li   t1, 0                  # sin(0) esperado
    # sw   t0, 8(s2)			   # se guarda para poder inspeccionarlo/compararlo despues
    # sw   t1, 12(s2)

    # ---- Caso de prueba: 30 grados ----
    addi a2, zero, 30
    li   t0, 929887697            # cos(30) esperado
    li   t1, 536870912             # sin(30) esperado
    sw   t0, 8(s2)
    sw   t1, 12(s2)

	# ---- Caso de prueba: 45 grados ----
    # addi a2, zero, 45
    # li   t0, 759250125          # cos(45) esperado
    # li   t1, 759250125           # sin(45) esperado
    # sw   t0, 8(s2)
    # sw   t1, 12(s2)

	# ---- Caso de prueba: 60 grados ----
    # addi a2, zero, 60
    # li   t0, 536870912           # cos(60) esperado
    # li   t1, 929887697            # sin(60) esperado
    # sw   t0, 8(s2)
    # sw   t1, 12(s2)

	# ---- Caso de prueba: 90 grados ----
    # addi a2, zero, 90
    # li   t0, 0                     # cos(90) esperado
    # li   t1, 1073741824             # sin(90) esperado
    # sw   t0, 8(s2)
    # sw   t1, 12(s2)

    jal  ra, cordic_sincos       # Saltamos a la funcion para usar CORDIC

    ## Ojo: a0, a1, a2 y t0-t6 son registros "caller-saved": cualquier
    ## funcion (como cordic_sincos) puede modificarlos libremente. Por
    ## eso guardamos los valores esperados en MEMORIA antes de llamar, en
    ## vez de dejarlos en un registro. s2, en cambio, es "saved" (s0-s11):
    ## por convencion, una funcion que lo use debe devolverlo intacto, asi
    ## que podemos confiar en que sigue apuntando a 0xFF00 despues del jal.

    # ---- Error absoluto = |obtenido - esperado| (solo resta y shift, sin division) ----
    lw   t0, 0(s2)                # cos obtenido
    lw   t1, 8(s2)                 # cos esperado
    sub  t2, t0, t1                 # diff = obtenido - esperado
    srli t3, t2, 31                  # signo de diff, define si lo negamos
    beq  t3, zero, cos_ok			  # Si diff es positivo, solo lo guardamos
    sub  t2, zero, t2                 # si es negativo, se niega -> valor absoluto
cos_ok:
    sw   t2, 16(s2)                    # error absoluto del coseno = 0xFF10

    lw   t0, 4(s2)                # sin obtenido
    lw   t1, 12(s2)                 # sin esperado
    sub  t2, t0, t1
    srli t3, t2, 31
    beq  t3, zero, sin_ok
    sub  t2, zero, t2
sin_ok:
    sw   t2, 20(s2)                    # error absoluto del seno = 0xFF14

    # Error relativo = error_absoluto / |esperado|. RV32I base no tiene division (eso es
    # extension "M"), asi que igual que el testbench de Verilog (que tampoco calcula el
    # error, solo hace $monitor), lo mas practico es leer estos 3 valores del volcado de
    # memoria (s2+0..+20) y calcular el error relativo a mano/calculadora. Como ambos
    # numeros estan en la misma escala Q2.30, la escala se cancela y puedes usar los
    # enteros guardados directamente: rel = error_absoluto / esperado.

halt:
    j    halt                # fin de programa


# --------- Subrutina CORDIC ---------
# a0 = direccion coseno, a1 = direccion seno, a2 = angulo (grados)
cordic_sincos:
    ## ¿De donde sale 652032874 (x0)?
    ## Cada iteracion de CORDIC no es una rotacion "pura": ademas de girar
    ## el vector, lo ESTIRA por un factor sqrt(1 + 2^-2i), porque en vez
    ## de multiplicar por cos(theta_i) en cada paso (division/multiplicacion
    ## cara), se deja esa escala sin corregir. Despues de las 16 iteraciones,
    ## el vector quedo mas largo por un factor acumulado:
    ##   K16 = producto para i=0..15 de sqrt(1 + 2^-2i)  ~=  1.646760258
    ## Si no se corrige, x16/y16 NO serian cos/sin reales, sino
    ## K16*cos(theta) y K16*sin(theta) (un 64% mas grandes de lo debido).
    ## La forma barata de corregir (sin dividir) es arrancar el vector ya
    ## "encogido" por 1/K16 desde el principio, en vez de dividir al final:
    ##   x0 = 1/K16 ~= 0.607252935
    ## Y para pasarlo a Q2.30 (escala 2^30), se multiplica y se redondea:
    ##   0.607252935 * 2^30 ~= 652032874   <- este es el valor que ves aqui
    li   t0, 652032874      # x0 = 1/K16, Q2.30 (igual que el equipo de Verilog)
    li   t1, 0              # y0
    ## Aqui SI ocurre un shift real en tiempo de ejecucion: convertimos el
    ## angulo de entrada (un entero en grados, ej. 30) a formato Q8.24
    ## multiplicandolo por 2^24 mediante un shift a la izquierda.
    slli t2, a2, 24         # z0 = angulo <<< 24  (grados enteros -> Q8.24)

    li   s0, 0              # s0 = i; el iterador
    li   s1, 16             # limite de iteraciones (N = 16)

iteraciones:
    ## blt/bge SI son instrucciones reales de RV32I (no pseudo), a
    ## diferencia de li/ret/j que son "pseudo-instrucciones" que el
    ## ensamblador traduce a una o mas instrucciones reales.
    bge  s0, s1, fin_iter     # si el iterador es mayor o igual a 16, salimos de iteraciones

    addi t3, t0, 0            # t3 = x_i
    addi t4, t1, 0            # t4 = y_i
    addi t5, t2, 0            # t5 = z_i

    srli t6, t2, 31           # Nos quedamos con el signo de z_i (bit 31): 0 = positivo, 1 = negativo
    ## srli (shift LOGICO, no aritmetico) empuja el bit de signo hasta la
    ## posicion 0 y rellena con ceros el resto, dejando t6 en 0 o 1 sin
    ## necesidad de comparar z_i contra cero con un branch aparte.
    bne  t6, zero, iter_neg   # Si el signo de z_i no es cero, vamos a  trabajar con d_i negativo
	# Recuerda: si z_i es positivo, d_i es positivo; si z_i es negativo, d_i es negativo

    iter_pos:
        sra  t6, t4, s0        # t6 = y_i >>> i
        sub  t0, t3, t6        # x_{i+1} = x_i - (y_i>>>i)
        sra  t6, t3, s0        # x_i >>> i
        add  t1, t4, t6        # y_{i+1} = y_i + (x_i>>>i)
        ## i (s0) hace TRES trabajos a la vez: cuenta las iteraciones,
        ## define cuanto se desplaza (sra ..., s0), y define que alpha_i
        ## se usa (el orden en que se guardaron en la pila es alpha_0,
        ## alpha_1, ..., alpha_15, asi que el offset es simplemente i*4).
        slli t6, s0, 2         # offset = i*4 (acuerdate: i va de 0 a 15 en orden natural)
        add  t6, t6, sp		   # t6 = direccion de stack_pointer + offset
        ## t3 se "recicla" aqui: hasta la linea anterior guardaba x_i, y
        ## de aqui en adelante pasa a guardar alpha_i. Es valido porque ya
        ## no necesitamos x_i (el nuevo x_{i+1} quedo en t0).
        lw   t3, 0(t6)         # t3 = alpha_i
        sub  t2, t5, t3        # z_{i+1} = z_i - alpha_i
        j    next_iter         # Nos saltamos hasta next_iter

    iter_neg:
        sra  t6, t4, s0
        add  t0, t3, t6        # x_{i+1} = x_i + (y_i>>>i)
        sra  t6, t3, s0
        sub  t1, t4, t6        # y_{i+1} = y_i - (x_i>>>i)
        slli t6, s0, 2
        add  t6, t6, sp
        lw   t3, 0(t6)
        add  t2, t5, t3        # z_{i+1} = z_i + alpha_i

    next_iter:
        addi s0, s0, 1         # se incrementa el iterador i
        j    iteraciones       # salto de vuelta al inicio del bucle

fin_iter:
    sw   t0, 0(a0)             # cos(theta) ~ x final
    sw   t1, 0(a1)             # sin(theta) ~ y final
    addi sp, sp, 64            # restauramos el stack pointer
    ret
