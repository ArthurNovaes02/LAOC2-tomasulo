module FPadders(Clock, CDB, resv_out1, resv_out2, OP);
  input Clock;                        // clock
  output [15:0] CDB;                  // barramento CDB
  input [15:0] resv_out1, resv_out2;  // saida da estacao de reserva

  input OP;                           // operação a ser realizada

  always @(posedge Clock) begin
    case (OP) begin
      1: // soma
        CDB <= resv_out1 + resv_out2;
      2: // subtracao
        CDB <= resv_out1 - resv_out2;

    endcase
  end // always

end module
