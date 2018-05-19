module adders(Clock, CDB, reg1, reg2, OP);
  input wire Clock;                        // clock
  input wire [15:0] reg1, reg2;  // saida da estacao de reserva
  input wire OP;                           // operação a ser realizada
  output reg [15:0] CDB;                  // barramento CDB
  reg [1:0]latencia;

  initial begin
    latencia = 2'b00;
  end

  always @(posedge Clock) begin
    latencia = latencia + 1'b1;
    case (OP)
      1'b0:
        if(latencia == 2'b10)begin
          CDB <= reg1 + reg2;// soma
          latencia = 2'b00;
        end
      1'b1:
        if(latencia == 2'b10)begin
          CDB <= reg1 - reg2;// subtracao
          latencia = 2'b00;
        end
    endcase
  end // always

endmodule
