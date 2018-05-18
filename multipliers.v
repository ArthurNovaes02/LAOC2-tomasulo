module multipliers (Clock, CDB, resv_out1, resv_out2, OP);
  input wire Clock;                        // clock
  input wire [15:0] resv_out1, resv_out2;  // saida da estacao de reserva
  input wire OP;                 // operação a ser realizada
  output reg [15:0] CDB;                  // barramento CDB

  always @(posedge Clock) 
  begin
    case (OP)
      1'b0: CDB <= resv_out1 * resv_out2; // multiplicacao
      1'b1: CDB <= resv_out1 / resv_out2; // divisao
    endcase
  end // always

endmodule
