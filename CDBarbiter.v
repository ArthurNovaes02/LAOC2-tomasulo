module ucCDB (Clock,
              bancoRegIn,     bancoRegOut,
              registerAddIn,  registerAddOut,
              registerMulIn,  registerMulOut
              instruction);

  input Clock;
  input instruction;
  output cdbOut;
  input bancoRegOut, registerAddOut, registerMulOut;
  reg [23:0]CDB;

  /* Padrão do dado no CDB
   * 0 | 0 | 00 | 000 | 0000000000000
   * 1) [22] CDB ocupado ou não
   *      - 1 ocupado
   *      - 0 desocupado
   * 2) [21] Estacão de reserva MULT ou soma
   *      - 1 MULT e DIV
   *      - 0 ADD e SUB
   * 3) [20:19] Rótulo da estação de reserva que produziu o dados (Qi) (label)
   *      - 00 0(Qi)
   *      - 01 1(Qi)
   * 4) [18:16] Registrador que irei modificar
   *      - 000 R0
   *      - 001 R1
   *      - 010 R2
   *      - 011 R3
   * 5) [15:0] Dado
   *      - 16 bits
   */


  always @(posedge Clock)
    /* decide quem pode escrever no CDB
    * este módulo recebe os dados de todo mundo e decida qual unidade pode
    * escrever efetivamente no CDB
    */


    if (registerAddOut | registerMulOut | bancoRegOut)  // se tiver algum dado para ser ecrito no CDB
    begin
      // em ordem de prioridade mul, add, banco registradores
      if (registerAddOut & [15]CDB == 0)
      begin // se tiver algum dado pronto da multiplicacao e o cdb estiver desocupado
        [22]cdbOut = 1'b1;  // cdb ocupado
        for (se houver dependencias) // percorre estacoes de reserva procurando dependencia
        begin
          // @TODO: concertar os nomes das variaveris e por isso
          if(reservationStationAddJusy[i]==1) //  ha dependencia
           if(reservationStationAddQj[i]==reservationStationMulLabel[MulIndex])
           begin
             reservationStationAddVj[i]=MulValue; // grava o valor
             reservationStationAddJusy[i]=0; // remove a dependencia
           end
          if(reservationStationAddKusy[i]==1) //  ha dependencia
           if(reservationStationAddQk[i]==reservationStationMulLabel[MulIndex])
           begin
             reservationStationAddVk[i]=MulValue; // grava o valor
             reservationStationAddKusy[i]=0; // remove a dependencia
           end
          if(reservationStationMulJusy[i]==1) //  ha dependencia
           if(reservationStationMulQj[i]==reservationStationMulLabel[MulIndex])
           begin
             reservationStationMulVj[i]=MulValue; // grava o valor
             reservationStationMulJusy[i]=0; // remove a dependencia
             end
          if(reservationStationMulKusy[i]==1) //  ha dependencia
           if(reservationStationMulQk[i]==reservationStationMulLabel[MulIndex])
           begin
             reservationStationMulVk[i]=MulValue; // grava o valor
             reservationStationMulKusy[i]=0; // remove a dependencia
             end
          end // for para saber se há dependencia de dados
          // @TODO: limpa a estacao de reserva
          // @TODO: desocupar a unidade
          // @TODO: desocupar o CDB
        end
        [21]cdbOur = 1'b0;  // operacao de ADD ou SUB
        [20:19]cdbOut = ?
        [15:0]cdbOut = registerAddOut;
      end
      else if (registerMulOut & [15]CDB == 0)
      begin
        //@TODO: fazer a mesma coisa para o mul
        [22]cdbOut = 1'b1;  // cdb ocupado
        [21]cdbOur = 1'b1;  // operacao de MUL ou DIV
        [20:19]cdbOut = ?
        [15:0]cdbOut = registerMulOut;
      end
      else if ([0]bancoRegOut & [15]CDB == 0) begin // se tiver dado do
        [22]cdbOut = 1'b1; // cdb ocupado
        [21]cdbOur = ?
        [20:19]cdbOut = ?
        [15:0]cdbOut = bancoRegOut;
      end
    end // end if tiver algum dado para ser escrito no CDB
    }
)
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
