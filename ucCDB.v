module ucCDB (Clock,
              bancoRegIn,     bancoRegOut,
              registerAddIn,  registerAddOut,
              registerMulIn,  registerMulOut
              instruction);

  input Clock;
  output cdbOut;
  input bancoRegOut, registerAddOut, registerMulOut;
  input instruction;

  always @(posedge Clock)
      //CDB 001/0010/0000
      /*  ADD R2,R1,R3
          ADD R1,R2,R4
          Rótulo da estação de reserva que produziu o dado
          Registrador que irei modificar
          Dado

        Estação de reserva:
                    Busy      Vj   Vk  Qj  Qk
            -  1     0
            -  2             [0]CDB 001  0
            -  3
        E.R multipliers

            - 4
            - 5
            if(busy == 1){
              if(Qj/Qk == [7:5]CDB){
                    meu qj e  Qk tinham o label
                    Qj/Qk = 0;
                    Vj/Vk = [3:0]CDB"Dado do registrador";
                }
          }
            VJ      VK
      */
    ]
  end // always

endmodule
