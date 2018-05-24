module TomasPuto(SW[17:0], LEDR[15:0], LEDG[7:0]); // TOPLEVEL
 output[7:0] LEDG;
 output [15:0] LEDR;
 input[17:0] SW;

 Tomasulo tom( SW[16],	// clock
               LEDG[0], // done
               SW[17],	// enable
               SW[3:0],	// selecionar registrador
               LEDR);	  // valor do registrador
endmodule

module Tomasulo (Clock, done, enable, select, regview);
// tamanho do ROB = 4
// tamanho da estação de reserva = 2

 input Clock, enable;
 input[3:0] select;
 output[15:0] regview;
 output reg done;

 // Instrucoes
 reg [15:0] instrMem[0:63];//instructions mem
 reg [5:0] pc;    // program counter
 reg [5:0] lastPC;  // endereco da ultima instrucao + 1
 reg [15:0] count;// contador de clocks

 // Banco de registadores
 reg [15:0] bancoReg [0:15];
 reg [10:0] bancoRegLabel [0:15]; // Guarda a instrucao que precisa do valor
 reg bancoRegLabelPres [0:15];    // Indica se hÃ¡ label em determinada posicao

 // ROB
 reg [2:0] ReordenationBufferIndex; // Indicador do index do ROB
 reg ReordenationBufferBusy [0:3];	// Indica se a posicao esta cheia
 reg [3:0] ReordenationBufferOp [0:3];  // Indica a operacao da instrucao do ROB
 reg [3:0] ReordenationBufferDST [0:3];  // Indica o destino da instrucao do ROB
 reg [10:0] ReordenationBufferLabel [0:3]; // Indica a label da instrucao do ROB que tambem serve para indicar o (pc-1) se o desvio n for tomado
 reg [15:0] ReordenationBufferValue [0:3]; // Indica o valor da instrucao do ROB se for o mesmo da label o desvio foi tomado
 reg ReordenationBufferHaveValue [0:3]; // Indica se o valore da instrucao ja foi gravado

 // Estacao de reserva de soma
 reg [3:0] reservationStationAddOp [0:1]; // Indica operacao que existe na Estacao de reserva
 reg [10:0] reservationStationAddLabel [0:1]; // Indica o label da operacao da estacao de reserva
 reg reservationStationAddBusy [0:1]; // Indica se hÃ¡ instrucao na Estacao de reserva
 reg [15:0] reservationStationAddVj [0:1]; // Operando 1 se nao houver dependencia
 reg [10:0] reservationStationAddQj [0:1]; // Operando 1 se houver dependencia
 reg reservationStationAddJusy [0:1]; // Indica se hÃ¡ dependencia no Op 1
 reg [15:0] reservationStationAddVk [0:1]; // Operando 2 se nao houver dependencia
 reg [10:0] reservationStationAddQk [0:1]; // Operando 2 se houver dependencia
 reg reservationStationAddKusy [0:1]; // Indica se hÃ¡ dependencia no Op 2

 // Estacao de reserva de multiplicacao
 reg [3:0] reservationStationMulOp [0:1]; // Indica operacao que existe na Estacao de reserva
 reg [10:0] reservationStationMulLabel [0:1]; // Indica o label da operacao da estacao de reserva
 reg reservationStationMulBusy [0:1]; // Indica se hÃ¡ instrucao na Estacao de reserva
 reg [15:0] reservationStationMulVj [0:1]; // Operando 1 se nao houver dependencia
 reg [10:0] reservationStationMulQj [0:1]; // Operando 1 se houver dependencia
 reg reservationStationMulJusy [0:1]; // Indica se hÃ¡ dependencia no Op 1
 reg [15:0] reservationStationMulVk [0:1]; // Operando 2 se nao houver dependencia
 reg [10:0] reservationStationMulQk [0:1]; // Operando 2 se houver dependencia
 reg reservationStationMulKusy [0:1]; // Indica se hÃ¡ dependencia no Op 2

 // Estacao de reserva de memoria
   //reg reservationStationLdBusy [0:RESERVATIONSIZE-1]; // Indica se hÃ¡ instrucao na Estacao de reserva
   //reg [10:0] reservationStationLdLabel [0:RESERVATIONSIZE-1]; // Indica o label da operacao da estacao de reserva
   //reg [15:0] reservationStationLdVj [0:RESERVATIONSIZE-1]; // Operando 1 se nao houver dependencia
   //reg [10:0] reservationStationLdQj [0:RESERVATIONSIZE-1]; // Operando 1 se houver dependencia
   //reg reservationStationLdJusy [0:RESERVATIONSIZE-1]; // Indica se hÃ¡ dependencia no Op 1
   //reg [3:0] reservationStationLdOffset [0:RESERVATIONSIZE-1]; // Indica qual o offset

   // foi criado como forma de otimizacao para evitar adicao de campos no ROB que so seriam usados pelo ROB, na pratica é a mesma coisa
   //reg reservationStationStBusy [0:RESERVATIONSIZE-1]; // Indica se hÃ¡ instrucao na Estacao de reserva
   //reg [10:0] reservationStationStLabel [0:RESERVATIONSIZE-1]; // Indica o label da operacao da estacao de reserva
   //reg [15:0] reservationStationStVj [0:RESERVATIONSIZE-1]; // Operando 1 se nao houver dependencia
   //reg [10:0] reservationStationStQj [0:RESERVATIONSIZE-1]; // Operando 1 se houver dependencia
   //reg reservationStationStJusy [0:RESERVATIONSIZE-1]; // Indica se hÃ¡ dependencia no Op 1
   //reg [3:0] reservationStationStOffset [0:RESERVATIONSIZE-1]; // Indica qual o offset
   //reg [15:0] reservationStationStVk [0:RESERVATIONSIZE-1]; // Valor se nao houver dependencia
   //reg [10:0] reservationStationStQk [0:RESERVATIONSIZE-1]; // Valor se houver dependencia
   //reg reservationStationStKusy [0:RESERVATIONSIZE-1]; // Indica se hÃ¡ dependencia no Valor


 // CDB Unit
   reg CDBusy; // Indica se o CDB esta ocupado

 // SUM Unit
   reg SumBusy; // Indica se a unidade de soma esta ocupada
     reg[15:0] SumParamB; // Indica o operando 1
     reg[15:0] SumParamC; // Indica o operando 2
     reg[15:0] SumValue; // Guarda o resultado da operacao
     reg[1:0] SumState; // Indica o estado da operacao
     reg SumDone; // Indica se a operacao acabou
     reg[0:2] SumIndex; // Indica o index da operacao na estacao de reserva
     reg[1:0] SumOp; // Indica o tipo de operacao

 // MUL Unit
   reg MulBusy; // Indica se a unidade de multipliacao esta ocupada
     reg[15:0] MulParamB; // Indica o operando 1
     reg[15:0] MulParamC; // Indica o operando 2
     reg[15:0] MulValue; // Guarda o resultado da operacao
     reg[2:0] MulState; // Indica o estado da operacao
     reg MulDone; // Indica se a operacao acabou
     reg[0:1] MulIndex; // Indica o index da operacao na estacao de reserva
     reg MulOp; // Indica o tipo de operacao


 // temporaries
 reg [3:0]instr0; // temporarios para melhor legibilidade do codigo
     reg [3:0]instr0ParamA;
     reg [3:0]instr0ParamB;
     reg [3:0]instr0ParamC;
 reg [3:0]instr1;// temporarios para melhor legibilidade do codigO
     reg [3:0]instr1ParamA;
     reg [3:0]instr1ParamB;
     reg [3:0]instr1ParamC;
   reg[2:0] ROBSlots;
   integer i,j; // Iteration var
   reg iHateVerilog666;	// break para os loops
   assign regview=bancoReg[select]; // para visualizar os registradores na placa
	
   always @(posedge Clock)
   begin
     if (enable)
     begin
       instr0 = instrMem[pc][15:12];
         instr0ParamA = instrMem[pc][11:8];
         instr0ParamB = instrMem[pc][7:4];
         instr0ParamC = instrMem[pc][3:0];
       instr1 = instrMem[lastPC][15:12];
         instr1ParamA = instrMem[lastPC][11:8];
         instr1ParamB = instrMem[lastPC][7:4];
         instr1ParamC = instrMem[lastPC][3:0];
       iHateVerilog666=1; // Grrr
       ROBSlots=0;
       for(i=0;i<4;i=i+1)
         if(ReordenationBufferBusy[i]==0)
           ROBSlots=ROBSlots+1;

       // Passo 2 - Coloca instrucÃµes nas unides funcionais
       if(SumBusy==0)
       begin
         for (i=0; i<2; i=i+1)
         begin
           if(SumBusy==0)
           if (reservationStationAddBusy[i] == 1'b1) // Indices que estao ocupados
           begin
             if(reservationStationAddJusy[i]==0 & reservationStationAddKusy[i]==0) // Nao hÃ¡ dependencia
             begin
               SumBusy=1;
               SumParamB=reservationStationAddVj[i];
               SumParamC=reservationStationAddVk[i];
               SumIndex=i;
               SumState=0;
               SumDone=0;
               if(reservationStationAddOp[i]==4'b0001) // soma
                 SumOp=1;
               else if(reservationStationAddOp[i]==4'b0010) // subtracao
                 SumOp=0;
              //--------- delete
             end
           end
         end
       end
       if(MulBusy==0)
       begin
         for (i=0; i<2; i=i+1)
         begin
           if(MulBusy==0)
           if (reservationStationMulBusy[i] == 1'b1) // Indices que estao ocupados
           begin
             if(reservationStationMulJusy[i]==0 & reservationStationMulKusy[i]==0) // Nao hÃ¡ dependencia
             begin
               MulBusy=1;
               MulParamB=reservationStationMulVj[i];
               MulParamC=reservationStationMulVk[i];
               MulIndex=i;
               MulState=0;
               MulDone=0;
               if(reservationStationMulOp[i]==4'b0011)
                 MulOp=1;
               else
                 MulOp=0;
             end
           end
         end
       end

       // Passo 1 - Despacho (todas as instrucÃµes em um clock)
       if(ROBSlots>0&pc<lastPC) // Ve se ha espaco no ROB
       begin
         if(instr0 == 4'b0001 | instr0 == 4'b0010) // Estacao de reserva ADD SUB
         begin
           iHateVerilog666=1;
           for (i=0; i<2; i=i+1)
           begin
             if(iHateVerilog666)
             begin
               if (reservationStationAddBusy[i] == 1'b0) // Primeiro indice vazio
               begin
                 reservationStationAddBusy[i]=1'b1; // Ocupa a posicao
                 reservationStationAddOp[i]=instr0; // Indica operacao da estacao de reserva
                 reservationStationAddLabel[i]={count[4:0],pc[5:0]}; // Coloca a label na estacao de reserva
                 if (bancoRegLabelPres[instr0ParamB]) // Verifica se hÃ¡ dependencia de dados em B
                 begin
                   reservationStationAddJusy[i]=1'b1; // Habilita escrita em Qj
                   reservationStationAddQj[i]=bancoRegLabel[instr0ParamB]; // Escreve em Qj a label
                 end
                 else
                 begin
                   reservationStationAddJusy[i]=1'b0; // Habilita escrita em Vj
                   reservationStationAddVj[i]=bancoReg[instr0ParamB]; // Escreve em Vj o valor
                 end

                 if (bancoRegLabelPres[instr0ParamC])// Verifica se hÃ¡ dependencia de dados em C
                 begin
                   reservationStationAddKusy[i]=1'b1; // Habilita escrita em Qk
                   reservationStationAddQk[i]=bancoRegLabel[instr0ParamC]; // Escreve em Qk a label
                 end
                 else
                 begin
                   reservationStationAddKusy[i]=1'b0; // Habilita escrita em Vk
                   reservationStationAddVk[i]=bancoReg[instr0ParamC]; // Escreve em Vk o valor
                 end

                 bancoRegLabelPres[instr0ParamA]=1'b1; // Habilita a label no banco de registradores
                 bancoRegLabel[instr0ParamA] = {count[4:0],pc[5:0]}; // Coloca a label no banco de registradores


                 for(j=0;j<4;j=j+1) // vai pro buffer de reordenacao
                 begin
                   if(iHateVerilog666)
                   begin
                     if(ReordenationBufferBusy[ReordenationBufferIndex+j]==0) // Espaco no ROB na posicao mais proxima
                     begin
                       ReordenationBufferBusy[ReordenationBufferIndex+j]=1; // Ocupa o espaco
                       ReordenationBufferOp[ReordenationBufferIndex+j]=instr0; // identifica a operacao
                       ReordenationBufferLabel[ReordenationBufferIndex+j]={count[4:0],pc[5:0]}; // Funciona como a tag
                       ReordenationBufferHaveValue[ReordenationBufferIndex+j]=0; // limpa o valor
                       ReordenationBufferDST[ReordenationBufferIndex+j]=instr0ParamA; // salva o destino
                       iHateVerilog666=0; // Break
                     end
                   end
                 end
                 iHateVerilog666=0; // Break indicando que houve despacho da primeira instrucao
               end
             end
           end
         end
         else if(instr0 == 4'b0011 | instr0 == 4'b0100) // Estacao de reserva MUL e DIV
         begin
           iHateVerilog666=1;
           for (i=0; i<2; i=i+1)
           begin
             if(iHateVerilog666)
             begin
               if (reservationStationMulBusy[i] == 1'b0) // Primeiro indice vazio
               begin
                 reservationStationMulBusy[i]=1'b1; // Ocupa a posicao
                 reservationStationMulOp[i]=instr0; // Indica operacao da estacao de reserva
                 reservationStationMulLabel[i]={count[4:0],pc[5:0]}; // Coloca a label na estacao de reserva
                 if (bancoRegLabelPres[instr0ParamB]) // Verifica se hÃ¡ dependencia de dados em B
                 begin
                   reservationStationMulJusy[i]=1'b1; // Habilita escrita em Qj
                   reservationStationMulQj[i]=bancoRegLabel[instr0ParamB]; // Escreve em Qj a label
                 end
                 else
                 begin
                   reservationStationMulJusy[i]=1'b0; // Habilita escrita em Vj
                   reservationStationMulVj[i]=bancoReg[instr0ParamB]; // Escreve em Vj o valor
                 end

                 if (bancoRegLabelPres[instr0ParamC])// Verifica se hÃ¡ dependencia de dados em C
                 begin
                   reservationStationMulKusy[i]=1'b1; // Habilita escrita em Qk
                   reservationStationMulQk[i]=bancoRegLabel[instr0ParamC]; // Escreve em Qk a label
                 end
                 else
                 begin
                   reservationStationMulKusy[i]=1'b0; // Habilita escrita em Vk
                   reservationStationMulVk[i]=bancoReg[instr0ParamC]; // Escreve em Vk o valor
                 end
                 bancoRegLabelPres[instr0ParamA]=1'b1; // Habilita a label no banco de registradores
                 bancoRegLabel[instr0ParamA] = {count[4:0],pc[5:0]}; // Coloca a label no banco de registradores
                 for(j=0;j<4;j=j+1) // vai pro buffer de reordenacao
                 begin
                   if(iHateVerilog666)
                   begin
                     if(ReordenationBufferBusy[ReordenationBufferIndex+j]==0) // Espaco no ROB na posicao mais proxima
                     begin
                       ReordenationBufferBusy[ReordenationBufferIndex+j]=1; // Ocupa o espaco
                       ReordenationBufferOp[ReordenationBufferIndex+j]=instr0; // identifica a operacao
                       ReordenationBufferLabel[ReordenationBufferIndex+j]={count[4:0],pc[5:0]}; // Funciona como a tag
                       ReordenationBufferHaveValue[ReordenationBufferIndex+j]=0; // limpa o valor
                       ReordenationBufferDST[ReordenationBufferIndex+j]=instr0ParamA; // salva o destino
                       iHateVerilog666=0; // Break
                     end
                   end
                 end
                 iHateVerilog666=0; // Break indicando que houve despacho da primeira instrucao
               end
             end
           end
         end
         // -------delete
         if(iHateVerilog666 == 0/* & instr0 != 4'b0111*/) // se despachou
         begin
           pc=lastPC;
           if(ROBSlots>1 & pc<lastPC) // segundo despacho
           begin
             //--------------------------------
             if(instr1 == 4'b0001 | instr1 == 4'b0010) // Estacao de reserva ADD SUB
             begin
               iHateVerilog666=1;
               for (i=0; i<2; i=i+1)
               begin
                 if(iHateVerilog666)
                 begin
                   if (reservationStationAddBusy[i] == 1'b0) // Primeiro indice vazio
                   begin
                     reservationStationAddBusy[i]=1'b1; // Ocupa a posicao
                     reservationStationAddOp[i]=instr1; // Indica operacao da estacao de reserva
                     reservationStationAddLabel[i]={count[4:0],pc[5:0]}; // Coloca a label na estacao de reserva
                     if (bancoRegLabelPres[instr1ParamB]) // Verifica se hÃ¡ dependencia de dados em B
                     begin
                       reservationStationAddJusy[i]=1'b1; // Habilita escrita em Qj
                       reservationStationAddQj[i]=bancoRegLabel[instr1ParamB]; // Escreve em Qj a label
                     end
                     else
                     begin
                       reservationStationAddJusy[i]=1'b0; // Habilita escrita em Vj
                       reservationStationAddVj[i]=bancoReg[instr1ParamB]; // Escreve em Vj o valor
                     end

                     if (bancoRegLabelPres[instr1ParamC])// Verifica se hÃ¡ dependencia de dados em C
                     begin
                       reservationStationAddKusy[i]=1'b1; // Habilita escrita em Qk
                       reservationStationAddQk[i]=bancoRegLabel[instr1ParamC]; // Escreve em Qk a label
                     end
                     else
                     begin
                       reservationStationAddKusy[i]=1'b0; // Habilita escrita em Vk
                       reservationStationAddVk[i]=bancoReg[instr1ParamC]; // Escreve em Vk o valor
                     end

                     bancoRegLabelPres[instr1ParamA]=1'b1; // Habilita a label no banco de registradores
                     bancoRegLabel[instr1ParamA] = {count[4:0],pc[5:0]}; // Coloca a label no banco de registradores

                     for(j=0;j<4;j=j+1) // vai pro buffer de reordenacao
                     begin
                       if(iHateVerilog666)
                       begin
                         if(ReordenationBufferBusy[ReordenationBufferIndex+j]==0) // Espaco no ROB na posicao mais proxima
                         begin
                           ReordenationBufferBusy[ReordenationBufferIndex+j]=1; // Ocupa o espaco
                           ReordenationBufferOp[ReordenationBufferIndex+j]=instr1; // identifica a operacao
                           ReordenationBufferLabel[ReordenationBufferIndex+j]={count[4:0],pc[5:0]}; // Funciona como a tag
                           ReordenationBufferHaveValue[ReordenationBufferIndex+j]=0; // limpa o valor
                           ReordenationBufferDST[ReordenationBufferIndex+j]=instr1ParamA; // salva o destino
                           iHateVerilog666=0; // Break
                         end
                       end
                     end
                     iHateVerilog666=0; // Break indicando que houve despacho da primeira instrucao
                   end
                 end
               end
             end
             else if(instr1 == 4'b0011 | instr1 == 4'b0100) // Estacao de reserva MUL e DIV
             begin
               iHateVerilog666=1;
               for (i=0; i<2; i=i+1)
               begin
                 if(iHateVerilog666)
                 begin
                   if (reservationStationMulBusy[i] == 1'b0) // Primeiro indice vazio
                   begin
                     reservationStationMulBusy[i]=1'b1; // Ocupa a posicao
                     reservationStationMulOp[i]=instr1; // Indica operacao da estacao de reserva
                     reservationStationMulLabel[i]={count[4:0],pc[5:0]}; // Coloca a label na estacao de reserva
                     if (bancoRegLabelPres[instr1ParamB]) // Verifica se hÃ¡ dependencia de dados em B
                     begin
                       reservationStationMulJusy[i]=1'b1; // Habilita escrita em Qj
                       reservationStationMulQj[i]=bancoRegLabel[instr1ParamB]; // Escreve em Qj a label
                     end
                     else
                     begin
                       reservationStationMulJusy[i]=1'b0; // Habilita escrita em Vj
                       reservationStationMulVj[i]=bancoReg[instr1ParamB]; // Escreve em Vj o valor
                     end

                     if (bancoRegLabelPres[instr1ParamC])// Verifica se hÃ¡ dependencia de dados em C
                     begin
                       reservationStationMulKusy[i]=1'b1; // Habilita escrita em Qk
                       reservationStationMulQk[i]=bancoRegLabel[instr1ParamC]; // Escreve em Qk a label
                     end
                     else
                     begin
                       reservationStationMulKusy[i]=1'b0; // Habilita escrita em Vk
                       reservationStationMulVk[i]=bancoReg[instr1ParamC]; // Escreve em Vk o valor
                     end
                     bancoRegLabelPres[instr1ParamA]=1'b1; // Habilita a label no banco de registradores
                     bancoRegLabel[instr1ParamA] = {count[4:0],pc[5:0]}; // Coloca a label no banco de registradores
                     for(j=0;j<4;j=j+1) // vai pro buffer de reordenacao
                     begin
                       if(iHateVerilog666)
                       begin
                         if(ReordenationBufferBusy[ReordenationBufferIndex+j]==0) // Espaco no ROB na posicao mais proxima
                         begin
                           ReordenationBufferBusy[ReordenationBufferIndex+j]=1; // Ocupa o espaco
                           ReordenationBufferOp[ReordenationBufferIndex+j]=instr1; // identifica a operacao
                           ReordenationBufferLabel[ReordenationBufferIndex+j]={count[4:0],pc[5:0]}; // Funciona como a tag
                           ReordenationBufferHaveValue[ReordenationBufferIndex+j]=0; // limpa o valor
                           ReordenationBufferDST[ReordenationBufferIndex+j]=instr1ParamA; // salva o destino
                           iHateVerilog666=0; // Break
                         end
                       end
                     end
                     iHateVerilog666=0; // Break indicando que houve despacho da primeira instrucao
                   end
                 end
               end
             end
             else if(instr1 == 4'b0000) // Stall
             begin
               iHateVerilog666=0;
             end
             //--------------------------------
             if(iHateVerilog666 == 0/* & instr1 != 4'b0111*/)
               pc=lastPC;
           end
         end // end if despacho
       end
       // Passo 5 - Confirma ROB
       if(ReordenationBufferHaveValue[ReordenationBufferIndex]==1&ReordenationBufferBusy[ReordenationBufferIndex]==1) // Confirma
       begin
         /*if(ReordenationBufferOp[ReordenationBufferIndex]==4'b0111) // se for desvio verifica
         begin
           if(ReordenationBufferValue[ReordenationBufferIndex]!=0) // erowww
           begin
             pc=ReordenationBufferLabel[ReordenationBufferIndex][5:0]+1; // coloca o pc certo
             ReordenationBufferIndex=0;
             for(i=0;i<4;i=i+1) // limpa o rob
               ReordenationBufferBusy[i]=0;
             for(i=0;i<2;i=i+1) // limpa as estacoes
             begin
               reservationStationAddBusy[i]=0;
               reservationStationMulBusy[i]=0;
             end
           end
         end*/
         // se nao for store
         bancoReg[ReordenationBufferDST[ReordenationBufferIndex]]=ReordenationBufferValue[ReordenationBufferIndex];
         bancoRegLabelPres[ReordenationBufferDST[ReordenationBufferIndex]]=0;
           for(i=0;i<2;i=i+1) // percorre estacoes de reserva procurando dependencia
           begin
             if(reservationStationAddJusy[i]==1) //  ha dependencia
             if(reservationStationAddQj[i]==ReordenationBufferLabel[ReordenationBufferIndex])
             begin
               reservationStationAddVj[i]=ReordenationBufferValue[ReordenationBufferIndex]; // grava o valor
               reservationStationAddJusy[i]=0; // remove a dependencia
             end
             if(reservationStationAddKusy[i]==1) //  ha dependencia
             if(reservationStationAddQk[i]==ReordenationBufferLabel[ReordenationBufferIndex])
             begin
               reservationStationAddVk[i]=ReordenationBufferValue[ReordenationBufferIndex]; // grava o valor
               reservationStationAddKusy[i]=0; // remove a dependencia
             end
             if(reservationStationMulJusy[i]==1) //  ha dependencia
             if(reservationStationMulQj[i]==ReordenationBufferLabel[ReordenationBufferIndex])
             begin
               reservationStationMulVj[i]=ReordenationBufferValue[ReordenationBufferIndex]; // grava o valor
               reservationStationMulJusy[i]=0; // remove a dependencia
             end
             if(reservationStationMulKusy[i]==1) //  ha dependencia
             if(reservationStationMulQk[i]==ReordenationBufferLabel[ReordenationBufferIndex])
             begin
               reservationStationMulVk[i]=ReordenationBufferValue[ReordenationBufferIndex]; // grava o valor
               reservationStationMulKusy[i]=0; // remove a dependencia
             end
           end
         //se nao for store
         if(ReordenationBufferBusy[ReordenationBufferIndex]==1) // evita de limpar e avancar se errou o desvio
         begin
           ReordenationBufferBusy[ReordenationBufferIndex]=0; // desocupa o ROB
           ReordenationBufferIndex=ReordenationBufferIndex+1; // avanca no ponteiro
         end
         // Confirmacao dupla
         //--------------------------------
           if(ReordenationBufferHaveValue[ReordenationBufferIndex]==1&ReordenationBufferBusy[ReordenationBufferIndex]==1) // Confirma
           begin
            //  if(ReordenationBufferOp[ReordenationBufferIndex]==4'b0111) // se for desvio verifica
            //  begin
            //    if(ReordenationBufferValue[ReordenationBufferIndex]!=0) // erowww
            //    begin
            //      pc=ReordenationBufferLabel[ReordenationBufferIndex][5:0]+1; // coloca o pc certo
            //      ReordenationBufferIndex=0;
            //      for(i=0;i<4;i=i+1) // limpa o rob
            //        ReordenationBufferBusy[i]=0;
            //      for(i=0;i<2;i=i+1) // limpa as estacoes
            //      begin
            //        reservationStationAddBusy[i]=0;
            //        reservationStationMulBusy[i]=0;
            //      end
            //    end
            //  end
             // se nao for store
             bancoReg[ReordenationBufferDST[ReordenationBufferIndex]]=ReordenationBufferValue[ReordenationBufferIndex];
             bancoRegLabelPres[ReordenationBufferDST[ReordenationBufferIndex]]=0;
               for(i=0;i<2;i=i+1) // percorre estacoes de reserva procurando dependencia
               begin
                 if(reservationStationAddJusy[i]==1) //  ha dependencia
                 if(reservationStationAddQj[i]==ReordenationBufferLabel[ReordenationBufferIndex])
                 begin
                   reservationStationAddVj[i]=ReordenationBufferValue[ReordenationBufferIndex]; // grava o valor
                   reservationStationAddJusy[i]=0; // remove a dependencia
                 end
                 if(reservationStationAddKusy[i]==1) //  ha dependencia
                 if(reservationStationAddQk[i]==ReordenationBufferLabel[ReordenationBufferIndex])
                 begin
                   reservationStationAddVk[i]=ReordenationBufferValue[ReordenationBufferIndex]; // grava o valor
                   reservationStationAddKusy[i]=0; // remove a dependencia
                 end
                 if(reservationStationMulJusy[i]==1) //  ha dependencia
                 if(reservationStationMulQj[i]==ReordenationBufferLabel[ReordenationBufferIndex])
                 begin
                   reservationStationMulVj[i]=ReordenationBufferValue[ReordenationBufferIndex]; // grava o valor
                   reservationStationMulJusy[i]=0; // remove a dependencia
                 end
                 if(reservationStationMulKusy[i]==1) //  ha dependencia
                 if(reservationStationMulQk[i]==ReordenationBufferLabel[ReordenationBufferIndex])
                 begin
                   reservationStationMulVk[i]=ReordenationBufferValue[ReordenationBufferIndex]; // grava o valor
                   reservationStationMulKusy[i]=0; // remove a dependencia
                 end
               end
             //se n for store
             if(ReordenationBufferBusy[ReordenationBufferIndex]==1) // evita de limpar e avancar se errou o desvio
             begin
               ReordenationBufferBusy[ReordenationBufferIndex]=0; // desocupa o ROB
               ReordenationBufferIndex=ReordenationBufferIndex+1; // avanca no ponteiro
             end
           end
         //--------------------------------
       end


       // Passo 4 - Escreve no CDB
       if(SumDone==1 | MulDone==1) // se houver alugum dado para ser gravado
       begin

         /************************** M U L  E  D I V **************************/
         // operacao de MUL e DIV e checa se o CDB esta desocupado
         if(MulDone==1 & CDBusy==0)
         begin
           CDBusy=1;  // CDB ocupado
			  
			  for(i=0;i<4;i=i+1) // Grava o resultado no ROB
			  begin
				 if(ReordenationBufferBusy[i]==1 & ReordenationBufferLabel[i]==reservationStationMulLabel[MulIndex]) // tag deu match
				 begin
					 ReordenationBufferValue[i]=MulValue;
					 ReordenationBufferHaveValue[i]=1;
				 end
			  end
		  
           for(i=0;i<2;i=i+1) // percorre estacoes de reserva procurando dependencia
           begin
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
           end
           reservationStationMulBusy[MulIndex]=0; // limpa a estacao de reserva
           MulDone=0; MulBusy=0;// desocupa a unidade
           CDBusy=0; // desocupa o cdb
         end

         /*************************** S U M  e S U B **************************/
         else if(SumDone==1 & CDBusy==0)
         begin
           CDBusy=1;

           for(i=0;i<4;i=i+1) // Grava o resultado no ROB
           begin
             if(ReordenationBufferBusy[i]==1 & ReordenationBufferLabel[i]==reservationStationAddLabel[SumIndex]) // tag deu match
             begin
               ReordenationBufferValue[i]=SumValue;
               ReordenationBufferHaveValue[i]=1;
             end
           end

           for(i=0;i<2;i=i+1) // percorre estacoes de reserva procurando dependencia
           begin
             if(reservationStationAddJusy[i]==1) //  ha dependencia
             if(reservationStationAddQj[i]==reservationStationAddLabel[SumIndex])
             begin
               reservationStationAddVj[i]=SumValue; // grava o valor
               reservationStationAddJusy[i]=0; // remove a dependencia
             end
             if(reservationStationAddKusy[i]==1) //  ha dependencia
             if(reservationStationAddQk[i]==reservationStationAddLabel[SumIndex])
             begin
               reservationStationAddVk[i]=SumValue; // grava o valor
               reservationStationAddKusy[i]=0; // remove a dependencia
             end
             if(reservationStationMulJusy[i]==1) //  ha dependencia
             if(reservationStationMulQj[i]==reservationStationAddLabel[SumIndex])
             begin
               reservationStationMulVj[i]=SumValue; // grava o valor
               reservationStationMulJusy[i]=0; // remove a dependencia
             end
             if(reservationStationMulKusy[i]==1) //  ha dependencia
             if(reservationStationMulQk[i]==reservationStationAddLabel[SumIndex])
             begin
               reservationStationMulVk[i]=SumValue; // grava o valor
               reservationStationMulKusy[i]=0; // remove a dependencia
             end
           end
           reservationStationAddBusy[SumIndex]=0; // limpa a estacao de reserva
           SumDone=0; SumBusy=0; // desocupa a unidade
           CDBusy=0; // desocupa o cdb
         end
       end

       // Passo 3 - Executa InstrucÃµes
       if(SumBusy==1)
       begin
         if(SumDone==0)
           case(SumState)
             0:SumState=SumState+1; // Comeca a somar
             //1:SumState=SumState+1; // Continua a somar
             1:// Termina de somar
             begin
               SumDone=1;
               if(SumOp==1)
                 SumValue=SumParamB+SumParamC;
               else if(SumOp==0)
                 SumValue=SumParamB-SumParamC;
               else if(SumParamB==SumParamC)
                 SumValue=0;
               else
                 SumValue=1;
             end
           endcase
       end
		 //avaliar
       if(MulBusy==1)
       begin
         if(MulDone==0)
           case(MulState)
             0:MulState=MulState+1; // Comeca a Multiplicar/Dividir
             1:MulState=MulState+1; // Continua a Multiplicar/Dividir
             //2:MulState=MulState+1; // Continua a Multiplicar/Dividir
             2:// Termina de Multiplicar ou Continua a Dividir
             begin
               if(MulOp==1)
               begin
                 MulValue=MulParamB*MulParamC;
                 MulDone=1;
               end
               else
                 MulState=MulState+1;
             end
             3:MulState=MulState+1; // Comeca a Dividir
             4:MulState=MulState+1; // Comeca a Dividir
             5:MulState=MulState+1; // Continua a Dividir
             //6:MulState=MulState+1; // Continua a Dividir
             6:// Termina de Dividir
             begin
               if(MulOp==0)
               begin
                 MulValue=MulParamB/MulParamC;
                 MulDone=1;
               end
             end
           endcase
       end
       if(SumDone==1 & SumOp==2) // BEQ nao usa cdb
       begin
         for(i=0;i<4;i=i+1) // Grava o resultado no ROB
         begin
           if(ReordenationBufferBusy[i]==1 & ReordenationBufferLabel[i]==reservationStationAddLabel[SumIndex]) // tag deu match
           begin
             ReordenationBufferValue[i]=SumValue; // valor diferente do endereco de desvio
             ReordenationBufferHaveValue[i]=1;
           end
         end
         reservationStationAddBusy[SumIndex]=0; // libera a unidade
         SumDone=0; SumBusy=0; // desocupa a unidade
       end
		 if(SumDone==1 & SumOp==2) // BEQ nao usa cdb
       begin
         for(i=0;i<4;i=i+1) // Grava o resultado no ROB
         begin
           if(ReordenationBufferBusy[i]==1 & ReordenationBufferLabel[i]==reservationStationAddLabel[SumIndex]) // tag deu match
           begin
             ReordenationBufferValue[i]=SumValue; // valor diferente do endereco de desvio
             ReordenationBufferHaveValue[i]=1;
           end
         end
         reservationStationAddBusy[SumIndex]=0; // libera a unidade
         SumDone=0; SumBusy=0; // desocupa a unidade
       end
       if(pc>=lastPC)
         done=1;
       for(i=0;i<2;i=i+1) // verifica se ha algo pra executar
         if(reservationStationAddBusy[i]==1|reservationStationMulBusy[i]==1)
           done=0;

       for(i=0;i<4;i=i+1)
         if(ReordenationBufferBusy[i]==1)
           done=0;

       if(done==0)
         count=count+1;
     end
   end

   initial begin

   for(i=0;i<64;i=i+1)
   begin
     instrMem[i]=0;
   end

   // PROGRAMA
   instrMem[0]=16'b0011000100100001; // r1=r1/r2
   //instrMem[1]=16'b0001000000000011;	// r0=r0+r3
   lastPC=2;
   // END

   pc=0;
   for(i=0;i<16;i=i+1)
   begin
     bancoReg[i]=i;
     bancoRegLabelPres[i]=0;
   end
   for(i=0;i<2;i=i+1)
   begin
     reservationStationAddBusy[i]=0;
     reservationStationMulBusy[i]=0;
   end
   CDBusy=0;
   SumBusy=0;
   MulBusy=0;

   SumDone=0;
   MulDone=0;

   done=0;

   ReordenationBufferIndex=0;
   for(i=0; i<4; i=i+1)
   begin
     ReordenationBufferBusy[i]=0;
     ReordenationBufferHaveValue[i]=0;
   end
   count=0;
   end
endmodule

//STALL - 0 - Stall used splash... Nothing happens!
//ADD   - 1 - 0001 Destino Operando1 Operando2
//SUB   - 2 - 0010 Destino Operando1 Operando2
//MUL   - 3 - 0011 Destino Operando1 Operando2
//DIV   - 4 - 0100 Destino Operando1 Operando2
//LD    - 5 - 0101 Destino Offset Operando1
//SD    - 6 - 0110 Fonte Offset Operando2
//BEQ  - 7 - 0111 Endereco Operando1 Operando2


/*//Programa 1 - Soma com dependencia verdadeira
 instrMem[0]=16'b0001000000010010; // r0=r1+r2
 instrMem[1]=16'b0001000000000011;	// r0=r0+r3
 lastPC=2;
*///Fim do Programa 1 ---------------

/*//Programa 2 - Soma com hazard estrutural
 instrMem[0]=16'b0001000000010010; // r0=r1+r2
 instrMem[1]=16'b0001000100010011;	// r1=r1+r3
 lastPC=2;
*///Fim do Programa 2 ---------------

/*//Programa 3 - Dependencia CDB
 instrMem[0]=16'b0011000000010010; // r0=r1*r2
 instrMem[1]=16'b0011000100010011;	// r1=r1*r3
 instrMem[2]=16'b0001010001010110;	// r4=r5+r6
 lastPC=3;
*///Fim do Programa 3 ---------------

/*//Programa 4 - Estacao de reserva cheia
 instrMem[0]=16'b0001000000010010; // r0=r1+r2
 instrMem[1]=16'b0001000100010011;	// r1=r1+r3
 instrMem[2]=16'b0001010001010110;	// r4=r5+r6
 lastPC=3;
*///Fim do Programa 4 ---------------

/*//Programa 5 - Load/Store
 instrMem[0]=16'b0101001100000010; // ld r3 0(r2)
 instrMem[1]=16'b0001001100110111; // r3=r3+r7
 instrMem[2]=16'b0110001100010001; // sd r3 1(r1)
 instrMem[3]=16'b0101000000100000; // ld r0 2(r0)
 lastPC=4;
*///Fim do Programa 5 ---------------

/*//Programa 6 - BEQ
 instrMem[0]=16'b0001000100010001; // r1=r1+r1
 instrMem[1]=16'b0111000000010010; // beq 0 r1==r2
 lastPC=2;
*///Fim do Programa 6 ---------------
