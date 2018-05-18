module stationMultipliers(Clock, CDB, reg1, reg2, resv_out1, resv_out2, OP);
  input Clock;                          // clock
  input [15:0] CDB;                     // barramento CDB
  input [2:0] reg1, reg2;             // registrador do banco de registradores
  input OP;                             // operação a ser realizada
  output [2:0] resv_out1, resv_out2;   // saida da unidade de reserva

  reg Qj, Qk; // estacao que produzirao o operando fonte.
  reg Vj, Vk; // valores do operando fonte
  reg [2:0] Busy;   // indica que a estacao de reserva e a unidade funcional estao pontas
  reg A;      // usado no calculo de endereco de memoria em load store
  
  initial begin 
  integer i;
	  // inicializa zerando o busy
	  for (i = 0; i < 3; i=i+1) begin
		 Busy[i] = 'b0;
	  end // for
  end

	always @(posedge Clock) begin
	 if(Busy[0] == 0) begin // se estiver vazio
	 end // if
	 else if (Busy[1] == 0) begin
	 end // else if
	 else if (Busy[2] == 0) begin
	 end // else if
	end // always

endmodule
