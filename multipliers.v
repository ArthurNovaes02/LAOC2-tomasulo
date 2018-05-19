module multipliers (Clock, CDB, resv_out1, resv_out2, OP);
  input wire Clock;                        // clock
  input wire [15:0] resv_out1, resv_out2;  // saida da estacao de reserva
  input wire OP;                 // operação a ser realizada
  output reg [15:0] CDB;                  // barramento CDB
  reg [2:0]latencia;

  initial begin
    latencia = 3'b000;
  end

  always @(posedge Clock) begin
    latencia = latencia + 1'b1;
    case (OP)
      1'b0:
        if(latencia == 3'b011)begin
          CDB <= resv_out1 * resv_out2; // multiplicacao
          latencia = 3'b000;
        end
      1'b1:
        if(latencia == 3'b100)begin
          CDB <= resv_out1 / resv_out2; // divisao
          latencia = 3'b000;
        end
    endcase
  end // always

endmodule
