module stationAdders(clock, reset, CDBin, reg1, reg2, reg1Index, reg2Index, OP, CDBout);
  input wire clock, reset;                  // clock
  input wire [21:0] CDBin;                  // barramento CDB
  input wire [15:0] reg1, reg2;             // registrador do banco de registradores
  input wire OP;                            // operação a ser realizada
  output wire [21:0]CDBout;
  //CDB[15:0] = DADO
  //CDB[18:16] = ENDEREÇO REGISTRADOR DESTINO
  //CDB[19] = LABEL DA ESTACAO DE RESERVA
  //CDB[20] = ESTAÇAO DE RESERVA DE SOMA OU DE MULT
  //CDB[21] = CDB OCUPADO OU NAO (1 ocupado 0 nao)
  reg [15:0]Qj1, Qk1, Vj1, Vk1;
  reg [15:0]Qj2, Qk2, Vj2, Vk2;
  reg [1:0]Busy;
  reg Label;
  reg done;

  // inicializa zerando o busy e todos os valores de controle;
  initial begin
    Qj1 = 'b0;
    Qk1 = 'b0;
    Vj1 = 'b0;
    Vk2 = 'b0;
    Qj2 = 'b0;
    Qk2 = 'b0;
    Label = 'b0;
    Done1 = 'b0;
    Done2 = 'b0;
    Busy[0] = 'b0;
    Busy[1] = 'b0;
  end

  //tbm devo chamar o adders para realizar a operacao
  always @(posedge clock) begin
    if(Busy[0] == 0)begin
      Busy[0] == 1;
      Vj2 = reg1;
      Vk2 = reg2;
      if(CDBin[19] == 0)begin//label
        if(Qj1 == CDBin[15:0])begin
          Qj1 = 'b0;
          Vj1 = CDBin[15:0];
        end
        if(Qk1 == CDBin[15:0]) begin
          Qj1 = 'b0;
          Vj1 = CDBin[15:0];
        end
        adders ad1(clock, CDBout[15:0], Vj1, Vk1, OP, Done1);
        if(Done1 == 1)begin
          Busy[0] = 0;
        end
      end//label
    end

    else if (Busy[1] == 0)begin
      Busy[1] = 1;
      Vj2 = reg1;
      Vk2 = reg2;
      if(CDBin[19] == 1) begin//label
        if(Qj2 == CDBin[15:0])begin
          Qj2 = 'b0;
          Vj2 = CDBin[15:0];
        end
        if(Qk2 == CDBin[15:0]) begin
          Qk2 = 'b0;
          Vk2 = CDBin[15:0];
        end
        adders ad2(clock, CDBout[15:0], Vj2, Vk2, OP, Done2);
        if(Done2 == 1)begin
          Busy[1] = 0;
        end
      end //label
    end

    else begin//caso em que todos os espaços da estacao estao ocupados
    end//last else
  end // always

  //zera os valores com reset
  always @(posedge reset)begin
  initial begin
    Qj1 = 'b0;
    Qk1 = 'b0;
    Vj1 = 'b0;
    Vk2 = 'b0;
    Qj2 = 'b0;
    Qk2 = 'b0;
    Label = 'b0;
    Done1 = 'b0;
    Done2 = 'b0;
    Busy[0] = 'b0;
    Busy[1] = 'b0;
  end
endmodule
