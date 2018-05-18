module stationAdders(clock, reset, CDB, reg1, reg2, OP, regDest, dataOut);
  input clock, reset;                  // clock
  input [15:0] CDB;                    // barramento CDB
  input [15:0] reg1, reg2;             // registrador do banco de registradores
  input OP;                            // operação a ser realizada
  output [15:0]dataOut;                //saida para o CDB
  output [1:0]Qi; //endereco passado para o banco de registradores
                  //representando em qual posicao da estacao de reserva
  integer i;

  //reg A;      // usado no calculo de endereco de memoria em load store
  reg Busy, Qj, Qk, Vj, Vk;   // indica que a estacao de reserva e a unidade
                              //funcional estao pontas
  // inicializa zerando o busy e todos os valores de controle;
  initial begin
    Busy[i] = 'b00;
    Vj[i] = 'b0;
    Vk[i] = 'b0;
    Qj[i] = 'b0;
    Qk[i] = 'b0;
  end

  reorderBuffer rb(reg1, reg2, regDest, );

  //tbm devo chamar o adders para realizar a operacao
  always @(posedge clock) begin
    if(Busy[0] == 0) begin // se estiver vazio
      adders ad1(clock, dataOut, reg1, reg2, OP);
      Qi = 1'b0;
    end // if
    else if (Busy[1] == 0) begin
      adders ad2(clock, dataOut, reg1, reg2, OP);
      Qi = 1'b1;
    end // else if
    else begin//caso em que todos os espaços da estacao estao ocupados
    end//last else
  end // always

  //zera os valores com reset
  always @(posedge reset)begin
    Busy[i] = 0;
    Vj = 'b0;
    Vk = 'b0;
    Qj = 'b0;
    Qk = 'b0;
endmodule
