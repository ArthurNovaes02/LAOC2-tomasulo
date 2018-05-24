module pratica3(SW[17:0], HEX0, LEDG[7:0]);
 input[17:0] SW;
 output[7:0] LEDG;
 output wire [0:6]HEX0;
 wire [15:0]value;


 Tomasulo tomas(  SW[16],	  // clock
                  LEDG[0],  // done
                  SW[17],	  // enable
                  SW[3:0],	// escolher registrador
                  value);	  // valor do registrador escolhido
endmodule

module display7Segmentos(Entrada, SaidaDisplay); //visual output
	input [15:0]Entrada;
	output reg [0:6]SaidaDisplay;

	always begin
		case(Entrada)
			0:SaidaDisplay = 7'b0000001; //0
			1:SaidaDisplay = 7'b1001111; //1
			2:SaidaDisplay = 7'b0010010; //2
			3:SaidaDisplay = 7'b0000110; //3
			4:SaidaDisplay = 7'b1001100; //4
			5:SaidaDisplay = 7'b0100100; //5
			6:SaidaDisplay = 7'b0100000; //6
			7:SaidaDisplay = 7'b0001111; //7
			8:SaidaDisplay = 7'b0000000; //8
			9:SaidaDisplay = 7'b0001100; //9
			10:SaidaDisplay = 7'b0001000;//A
			11:SaidaDisplay = 7'b1100000;//B
			12:SaidaDisplay = 7'b0110001;//C
			13:SaidaDisplay = 7'b1000010;//D
			14:SaidaDisplay = 7'b0110000;//E
			15:SaidaDisplay = 7'b0111000;//F
		endcase
	end
endmodule

module Tomasulo (Clock, done, enable, select, regValue);
// tamanho do ROB = 4
// tamanho da estação de reserva = 2

 input Clock, enable;
 input[3:0] select;     // seleciona o registrador que será mostrado na placa
 output[15:0] regValue;  //
 output reg done;       // indica se a instrucao foi concluida, quando for, acendera um led na placa

 // Instrucoes
 reg [15:0] instrucao[0:63];//instructions mem
 reg [5:0] pc;    // program counter
 reg [5:0] PCnext;  // endereco da ultima instrucao + 1
 reg [15:0] count;// contador de clocks

 // Banco de registadores
 reg [15:0] bancoReg [0:15];
 reg [10:0] bancoRegLabel [0:15]; // Guarda a instrucao que precisa do valor
 reg bancoRegLabelPres [0:15];    // Indica se hÃ¡ label em determinada posicao

 // ROB
 reg [2:0] BufferReorderIndex; // Indicador do index do ROB
 reg BufferReorderBusy [0:3];	// Indica se a posicao esta cheia
 reg [3:0] BufferReorderOp [0:3];  // Indica a operacao da instrucao do ROB
 reg [3:0] BufferReorderDST [0:3];  // Indica o destino da instrucao do ROB
 reg [10:0] BufferReorderLabel [0:3]; // Indica a label da instrucao do ROB que tambem serve para indicar o (pc-1) se o desvio n for tomado
 reg [15:0] BufferReorderValue [0:3]; // Indica o valor da instrucao do ROB se for o mesmo da label o desvio foi tomado
 reg BufferReorderPres [0:3]; // Indica se o valore da instrucao ja foi gravado

 // Estacao de reserva de soma
 reg [3:0] EstacaoReservaAddOp [0:1]; // Indica operacao que existe na Estacao de reserva
 reg [10:0] EstacaoReservaAddLabel [0:1]; // Indica o label da operacao da estacao de reserva
 reg EstacaoReservaAddBusy [0:1]; // Indica se hÃ¡ instrucao na Estacao de reserva
 reg [15:0] EstacaoReservaAddVj [0:1]; // Operando 1 se nao houver dependencia
 reg [10:0] EstacaoReservaAddQj [0:1]; // Operando 1 se houver dependencia
 reg EstacaoReservaAddJusy [0:1]; // Indica se hÃ¡ dependencia no Op 1
 reg [15:0] EstacaoReservaAddVk [0:1]; // Operando 2 se nao houver dependencia
 reg [10:0] EstacaoReservaAddQk [0:1]; // Operando 2 se houver dependencia
 reg EstacaoReservaAddKusy [0:1]; // Indica se hÃ¡ dependencia no Op 2

 // Estacao de reserva de multiplicacao
 reg [3:0] EstacaoReservaMulOp [0:1]; // Indica operacao que existe na Estacao de reserva
 reg [10:0] EstacaoReservaMulLabel [0:1]; // Indica o label da operacao da estacao de reserva
 reg EstacaoReservaMulBusy [0:1]; // Indica se hÃ¡ instrucao na Estacao de reserva
 reg [15:0] EstacaoReservaMulVj [0:1]; // Operando 1 se nao houver dependencia
 reg [10:0] EstacaoReservaMulQj [0:1]; // Operando 1 se houver dependencia
 reg EstacaoReservaMulJusy [0:1]; // Indica se hÃ¡ dependencia no Op 1
 reg [15:0] EstacaoReservaMulVk [0:1]; // Operando 2 se nao houver dependencia
 reg [10:0] EstacaoReservaMulQk [0:1]; // Operando 2 se houver dependencia
 reg EstacaoReservaMulKusy [0:1]; // Indica se hÃ¡ dependencia no Op 2

 // CDB Unit
  reg CDBusy; // Indica se o CDB esta ocupado

 // SUM Unit
   reg SumBusy;           // Indica se a unidade de soma esta ocupada
   reg[15:0] SumParamB;   // Operando 1
   reg[15:0] SumParamC;   // Operando 2
   reg[15:0] SumValue;    // Guarda o resultado da operacao
   reg[1:0] SumState;     // Estado da operacao
   reg SumDone;           // Operacao de soma/sub acabou
   reg[0:2] SumIndex;     // Indica o index da operacao na estacao de reserva
   reg[1:0] SumOp;        // Indica o tipo de operacao som/sub

 // MUL Unit
   reg MulBusy;           // Indica se a unidade de soma esta ocupada
   reg[15:0] MulParamB;   // operando 1
   reg[15:0] MulParamC;   // Operando 2
   reg[15:0] MulValue;    // Guarda o resultado da operacao
   reg[2:0] MulState;     // Estado da operacao
   reg MulDone;           // Operacao de mul/dive acabou
   reg[0:1] MulIndex;     // Indica o index da operacao na estacao de reserva
   reg MulOp;             // Indica o tipo de operacao mul/div


   // modelo da instrução
   /* 0000 | 0000 | 0000 | 0000
    * 1) Operação
    *   - STALL - 0 - Stall used splash... Nothing happens!
    *   - ADD - 1 - 0001
    *   - SUB - 2 - 0010
    *   - MUL - 3 - 0011
    *   - DIV - 4 - 0100
    * 2) Destino
    * 3) Reg 1
    * 4) Reg 2
    *   - 0000 R0
    *   - 0001 R1
    *   - 0010 R2
    *   - 0011 R3
    *   - 0100 R4
    *   - 0101 R5
    *   - ...
    */

   reg [3:0]Op0;          // Operacao 0
   reg [3:0]Op0ParamA;    // reg destino
   reg [3:0]Op0ParamB;    // reg 1
   reg [3:0]Op0ParamC;    // reg 2

   reg [3:0]Op1;          // Operacao 1
   reg [3:0]Op1ParamA;    // reg destino
   reg [3:0]Op1ParamB;    // reg 1
   reg [3:0]Op1ParamC;    // reg 2

   reg[2:0] ROBSlots;
   integer i,j;           // iteradores
   reg breakLoop;	        // para os loops
   assign regValue=bancoReg[select]; // para visualizar os registradores na placa

   always @(posedge Clock)
   begin
     if (enable)
     begin
       // primeira instrucao
       Op0 = instrucao[pc][15:12];
         Op0ParamA = instrucao[pc][11:8];
         Op0ParamB = instrucao[pc][7:4];
         Op0ParamC = instrucao[pc][3:0];
       // segunda instrucao
       Op1 = instrucao[PCnext][15:12];
         Op1ParamA = instrucao[PCnext][11:8];
         Op1ParamB = instrucao[PCnext][7:4];
         Op1ParamC = instrucao[PCnext][3:0];
       breakLoop=1;
       ROBSlots=0;
       for(i=0;i<4;i=i+1)
         if(BufferReorderBusy[i]==0)
           ROBSlots=ROBSlots+1;


       /*************************** S T E P  2 ********************************/
       // Passo 2 - Coloca intrucoes nas unides funcionais
       if(SumBusy==0)
       begin
         for (i=0; i<2; i=i+1)
         begin
           if(SumBusy==0)
           if (EstacaoReservaAddBusy[i] == 1'b1) // Indices que estao ocupados
           begin
             if(EstacaoReservaAddJusy[i]==0 & EstacaoReservaAddKusy[i]==0) // Nao hÃ¡ dependencia
             begin
               SumBusy=1;
               SumParamB=EstacaoReservaAddVj[i];
               SumParamC=EstacaoReservaAddVk[i];
               SumIndex=i;
               SumState=0;
               SumDone=0;
               if(EstacaoReservaAddOp[i]==4'b0001) // soma
                 SumOp=1;
               else if(EstacaoReservaAddOp[i]==4'b0010) // subtracao
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
           if (EstacaoReservaMulBusy[i] == 1'b1) // Indices que estao ocupados
           begin
             if(EstacaoReservaMulJusy[i]==0 & EstacaoReservaMulKusy[i]==0) // Nao hÃ¡ dependencia
             begin
               MulBusy=1;
               MulParamB=EstacaoReservaMulVj[i];
               MulParamC=EstacaoReservaMulVk[i];
               MulIndex=i;
               MulState=0;
               MulDone=0;
               if(EstacaoReservaMulOp[i]==4'b0011)
                 MulOp=1;
               else
                 MulOp=0;
             end
           end
         end
       end


       /*************************** S T E P  1 ********************************/
       // Passo 1 - Despacho (todas as instrucÃµes em um clock)
       if(ROBSlots>0&pc<PCnext) // Ve se ha espaco no ROB
       begin
         if(Op0 == 4'b0001 | Op0 == 4'b0010) // Estacao de reserva ADD SUB
         begin
           breakLoop=1;
           for (i=0; i<2; i=i+1)
           begin
             if(breakLoop)
             begin
               if (EstacaoReservaAddBusy[i] == 1'b0) // Primeiro indice vazio
               begin
                 EstacaoReservaAddBusy[i]=1'b1; // Ocupa a posicao
                 EstacaoReservaAddOp[i]=Op0; // Indica operacao da estacao de reserva
                 EstacaoReservaAddLabel[i]={count[4:0],pc[5:0]}; // Coloca a label na estacao de reserva
                 if (bancoRegLabelPres[Op0ParamB]) // Verifica se hÃ¡ dependencia de dados em B
                 begin
                   EstacaoReservaAddJusy[i]=1'b1; // Habilita escrita em Qj
                   EstacaoReservaAddQj[i]=bancoRegLabel[Op0ParamB]; // Escreve em Qj a label
                 end
                 else
                 begin
                   EstacaoReservaAddJusy[i]=1'b0; // Habilita escrita em Vj
                   EstacaoReservaAddVj[i]=bancoReg[Op0ParamB]; // Escreve em Vj o valor
                 end

                 if (bancoRegLabelPres[Op0ParamC])// Verifica se hÃ¡ dependencia de dados em C
                 begin
                   EstacaoReservaAddKusy[i]=1'b1; // Habilita escrita em Qk
                   EstacaoReservaAddQk[i]=bancoRegLabel[Op0ParamC]; // Escreve em Qk a label
                 end
                 else
                 begin
                   EstacaoReservaAddKusy[i]=1'b0; // Habilita escrita em Vk
                   EstacaoReservaAddVk[i]=bancoReg[Op0ParamC]; // Escreve em Vk o valor
                 end

                 bancoRegLabelPres[Op0ParamA]=1'b1; // Habilita a label no banco de registradores
                 bancoRegLabel[Op0ParamA] = {count[4:0],pc[5:0]}; // Coloca a label no banco de registradores


                 for(j=0;j<4;j=j+1) // vai pro buffer de reordenacao
                 begin
                   if(breakLoop)
                   begin
                     if(BufferReorderBusy[BufferReorderIndex+j]==0) // Espaco no ROB na posicao mais proxima
                     begin
                       BufferReorderBusy[BufferReorderIndex+j]=1; // Ocupa o espaco
                       BufferReorderOp[BufferReorderIndex+j]=Op0; // identifica a operacao
                       BufferReorderLabel[BufferReorderIndex+j]={count[4:0],pc[5:0]}; // Funciona como a tag
                       BufferReorderPres[BufferReorderIndex+j]=0; // limpa o valor
                       BufferReorderDST[BufferReorderIndex+j]=Op0ParamA; // salva o destino
                       breakLoop=0; // Break
                     end
                   end
                 end
                 breakLoop=0; // Break indicando que houve despacho da primeira instrucao
               end
             end
           end
         end
         else if(Op0 == 4'b0011 | Op0 == 4'b0100) // Estacao de reserva MUL e DIV
         begin
           breakLoop=1;
           for (i=0; i<2; i=i+1)
           begin
             if(breakLoop)
             begin
               if (EstacaoReservaMulBusy[i] == 1'b0) // Primeiro indice vazio
               begin
                 EstacaoReservaMulBusy[i]=1'b1; // Ocupa a posicao
                 EstacaoReservaMulOp[i]=Op0; // Indica operacao da estacao de reserva
                 EstacaoReservaMulLabel[i]={count[4:0],pc[5:0]}; // Coloca a label na estacao de reserva
                 if (bancoRegLabelPres[Op0ParamB]) // Verifica se hÃ¡ dependencia de dados em B
                 begin
                   EstacaoReservaMulJusy[i]=1'b1; // Habilita escrita em Qj
                   EstacaoReservaMulQj[i]=bancoRegLabel[Op0ParamB]; // Escreve em Qj a label
                 end
                 else
                 begin
                   EstacaoReservaMulJusy[i]=1'b0; // Habilita escrita em Vj
                   EstacaoReservaMulVj[i]=bancoReg[Op0ParamB]; // Escreve em Vj o valor
                 end

                 if (bancoRegLabelPres[Op0ParamC])// Verifica se hÃ¡ dependencia de dados em C
                 begin
                   EstacaoReservaMulKusy[i]=1'b1; // Habilita escrita em Qk
                   EstacaoReservaMulQk[i]=bancoRegLabel[Op0ParamC]; // Escreve em Qk a label
                 end
                 else
                 begin
                   EstacaoReservaMulKusy[i]=1'b0; // Habilita escrita em Vk
                   EstacaoReservaMulVk[i]=bancoReg[Op0ParamC]; // Escreve em Vk o valor
                 end
                 bancoRegLabelPres[Op0ParamA]=1'b1; // Habilita a label no banco de registradores
                 bancoRegLabel[Op0ParamA] = {count[4:0],pc[5:0]}; // Coloca a label no banco de registradores
                 for(j=0;j<4;j=j+1) // vai pro buffer de reordenacao
                 begin
                   if(breakLoop)
                   begin
                     if(BufferReorderBusy[BufferReorderIndex+j]==0) // Espaco no ROB na posicao mais proxima
                     begin
                       BufferReorderBusy[BufferReorderIndex+j]=1; // Ocupa o espaco
                       BufferReorderOp[BufferReorderIndex+j]=Op0; // identifica a operacao
                       BufferReorderLabel[BufferReorderIndex+j]={count[4:0],pc[5:0]}; // Funciona como a tag
                       BufferReorderPres[BufferReorderIndex+j]=0; // limpa o valor
                       BufferReorderDST[BufferReorderIndex+j]=Op0ParamA; // salva o destino
                       breakLoop=0; // Break
                     end
                   end
                 end
                 breakLoop=0; // Break indicando que houve despacho da primeira instrucao
               end
             end
           end
         end
         // -------delete
         if(breakLoop == 0) // se despachou
         begin
           pc=PCnext;

           /******************* S E G U N D O  D E S P A C H O ****************/
           if(ROBSlots>1 & pc<PCnext)
           begin
             //--------------------------------
             if(Op1 == 4'b0001 | Op1 == 4'b0010) // Estacao de reserva ADD SUB
             begin
               breakLoop=1;
               for (i=0; i<2; i=i+1)
               begin
                 if(breakLoop)
                 begin
                   if (EstacaoReservaAddBusy[i] == 1'b0) // Primeiro indice vazio
                   begin
                     EstacaoReservaAddBusy[i]=1'b1; // Ocupa a posicao
                     EstacaoReservaAddOp[i]=Op1; // Indica operacao da estacao de reserva
                     EstacaoReservaAddLabel[i]={count[4:0], pc[5:0]}; // Coloca a label na estacao de reserva
                     if (bancoRegLabelPres[Op1ParamB]) // Verifica se hÃ¡ dependencia de dados em B
                     begin
                       EstacaoReservaAddJusy[i]=1'b1; // Habilita escrita em Qj
                       EstacaoReservaAddQj[i]=bancoRegLabel[Op1ParamB]; // Escreve em Qj a label
                     end
                     else
                     begin
                       EstacaoReservaAddJusy[i]=1'b0; // Habilita escrita em Vj
                       EstacaoReservaAddVj[i]=bancoReg[Op1ParamB]; // Escreve em Vj o valor
                     end

                     if (bancoRegLabelPres[Op1ParamC])// Verifica se hÃ¡ dependencia de dados em C
                     begin
                       EstacaoReservaAddKusy[i]=1'b1; // Habilita escrita em Qk
                       EstacaoReservaAddQk[i]=bancoRegLabel[Op1ParamC]; // Escreve em Qk a label
                     end
                     else
                     begin
                       EstacaoReservaAddKusy[i]=1'b0; // Habilita escrita em Vk
                       EstacaoReservaAddVk[i]=bancoReg[Op1ParamC]; // Escreve em Vk o valor
                     end

                     bancoRegLabelPres[Op1ParamA]=1'b1; // Habilita a label no banco de registradores
                     bancoRegLabel[Op1ParamA] = {count[4:0],pc[5:0]}; // Coloca a label no banco de registradores

                     for(j=0;j<4;j=j+1) // vai pro buffer de reordenacao
                     begin
                       if(breakLoop)
                       begin
                         if(BufferReorderBusy[BufferReorderIndex+j]==0) // Espaco no ROB na posicao mais proxima
                         begin
                           BufferReorderBusy[BufferReorderIndex+j]=1; // Ocupa o espaco
                           BufferReorderOp[BufferReorderIndex+j]=Op1; // identifica a operacao
                           BufferReorderLabel[BufferReorderIndex+j]={count[4:0],pc[5:0]}; // Funciona como a tag
                           BufferReorderPres[BufferReorderIndex+j]=0; // limpa o valor
                           BufferReorderDST[BufferReorderIndex+j]=Op1ParamA; // salva o destino
                           breakLoop=0; // Break
                         end
                       end
                     end
                     breakLoop=0; // Break indicando que houve despacho da primeira instrucao
                   end
                 end
               end
             end
             else if(Op1 == 4'b0011 | Op1 == 4'b0100) // Estacao de reserva MUL e DIV
             begin
               breakLoop=1;
               for (i=0; i<2; i=i+1)
               begin
                 if(breakLoop)
                 begin
                   if (EstacaoReservaMulBusy[i] == 1'b0) // Primeiro indice vazio
                   begin
                     EstacaoReservaMulBusy[i]=1'b1; // Ocupa a posicao
                     EstacaoReservaMulOp[i]=Op1; // Indica operacao da estacao de reserva
                     EstacaoReservaMulLabel[i]={count[4:0],pc[5:0]}; // Coloca a label na estacao de reserva
                     if (bancoRegLabelPres[Op1ParamB]) // Verifica se hÃ¡ dependencia de dados em B
                     begin
                       EstacaoReservaMulJusy[i]=1'b1; // Habilita escrita em Qj
                       EstacaoReservaMulQj[i]=bancoRegLabel[Op1ParamB]; // Escreve em Qj a label
                     end
                     else
                     begin
                       EstacaoReservaMulJusy[i]=1'b0; // Habilita escrita em Vj
                       EstacaoReservaMulVj[i]=bancoReg[Op1ParamB]; // Escreve em Vj o valor
                     end

                     if (bancoRegLabelPres[Op1ParamC])// Verifica se hÃ¡ dependencia de dados em C
                     begin
                       EstacaoReservaMulKusy[i]=1'b1; // Habilita escrita em Qk
                       EstacaoReservaMulQk[i]=bancoRegLabel[Op1ParamC]; // Escreve em Qk a label
                     end
                     else
                     begin
                       EstacaoReservaMulKusy[i]=1'b0; // Habilita escrita em Vk
                       EstacaoReservaMulVk[i]=bancoReg[Op1ParamC]; // Escreve em Vk o valor
                     end
                     bancoRegLabelPres[Op1ParamA]=1'b1; // Habilita a label no banco de registradores
                     bancoRegLabel[Op1ParamA] = {count[4:0],pc[5:0]}; // Coloca a label no banco de registradores
                     for(j=0;j<4;j=j+1) // vai pro buffer de reordenacao
                     begin
                       if(breakLoop)
                       begin
                         if(BufferReorderBusy[BufferReorderIndex+j]==0) // Espaco no ROB na posicao mais proxima
                         begin
                           BufferReorderBusy[BufferReorderIndex+j]=1; // Ocupa o espaco
                           BufferReorderOp[BufferReorderIndex+j]=Op1; // identifica a operacao
                           BufferReorderLabel[BufferReorderIndex+j]={count[4:0],pc[5:0]}; // Funciona como a tag
                           BufferReorderPres[BufferReorderIndex+j]=0; // limpa o valor
                           BufferReorderDST[BufferReorderIndex+j]=Op1ParamA; // salva o destino
                           breakLoop=0; // Break
                         end
                       end
                     end
                     breakLoop=0; // Break indicando que houve despacho da primeira instrucao
                   end
                 end
               end
             end
             else if(Op1 == 4'b0000) // Stall
             begin
               breakLoop=0;
             end
             //--------------------------------
             if(breakLoop == 0)
               pc=PCnext;
           end
         end // end if despacho
       end

       /*************************** S T E P  5 ********************************/
       // Passo 5 - Confirma ROB
       if(BufferReorderPres[BufferReorderIndex]==1&BufferReorderBusy[BufferReorderIndex]==1) // Confirma
       begin

         bancoReg[BufferReorderDST[BufferReorderIndex]]=BufferReorderValue[BufferReorderIndex];
         bancoRegLabelPres[BufferReorderDST[BufferReorderIndex]]=0;
           for(i=0;i<2;i=i+1) // percorre estacoes de reserva procurando dependencia
           begin
             if(EstacaoReservaAddJusy[i]==1) //  ha dependencia
             if(EstacaoReservaAddQj[i]==BufferReorderLabel[BufferReorderIndex])
             begin
               EstacaoReservaAddVj[i]=BufferReorderValue[BufferReorderIndex]; // grava o valor
               EstacaoReservaAddJusy[i]=0; // remove a dependencia
             end
             if(EstacaoReservaAddKusy[i]==1) //  ha dependencia
             if(EstacaoReservaAddQk[i]==BufferReorderLabel[BufferReorderIndex])
             begin
               EstacaoReservaAddVk[i]=BufferReorderValue[BufferReorderIndex]; // grava o valor
               EstacaoReservaAddKusy[i]=0; // remove a dependencia
             end
             if(EstacaoReservaMulJusy[i]==1) //  ha dependencia
             if(EstacaoReservaMulQj[i]==BufferReorderLabel[BufferReorderIndex])
             begin
               EstacaoReservaMulVj[i]=BufferReorderValue[BufferReorderIndex]; // grava o valor
               EstacaoReservaMulJusy[i]=0; // remove a dependencia
             end
             if(EstacaoReservaMulKusy[i]==1) //  ha dependencia
             if(EstacaoReservaMulQk[i]==BufferReorderLabel[BufferReorderIndex])
             begin
               EstacaoReservaMulVk[i]=BufferReorderValue[BufferReorderIndex]; // grava o valor
               EstacaoReservaMulKusy[i]=0; // remove a dependencia
             end
           end

         if(BufferReorderBusy[BufferReorderIndex]==1) // evita de limpar e avancar se errou o desvio
         begin
           BufferReorderBusy[BufferReorderIndex]=0; // desocupa o ROB
           BufferReorderIndex=BufferReorderIndex+1; // avanca no ponteiro
         end
         // Confirmacao dupla
         //--------------------------------
           if(BufferReorderPres[BufferReorderIndex]==1&BufferReorderBusy[BufferReorderIndex]==1) // Confirma
           begin
             bancoReg[BufferReorderDST[BufferReorderIndex]]=BufferReorderValue[BufferReorderIndex];
             bancoRegLabelPres[BufferReorderDST[BufferReorderIndex]]=0;
               for(i=0;i<2;i=i+1) // percorre estacoes de reserva procurando dependencia
               begin
                 if(EstacaoReservaAddJusy[i]==1) //  ha dependencia
                 if(EstacaoReservaAddQj[i]==BufferReorderLabel[BufferReorderIndex])
                 begin
                   EstacaoReservaAddVj[i]=BufferReorderValue[BufferReorderIndex]; // grava o valor
                   EstacaoReservaAddJusy[i]=0; // remove a dependencia
                 end
                 if(EstacaoReservaAddKusy[i]==1) //  ha dependencia
                 if(EstacaoReservaAddQk[i]==BufferReorderLabel[BufferReorderIndex])
                 begin
                   EstacaoReservaAddVk[i]=BufferReorderValue[BufferReorderIndex]; // grava o valor
                   EstacaoReservaAddKusy[i]=0; // remove a dependencia
                 end
                 if(EstacaoReservaMulJusy[i]==1) //  ha dependencia
                 if(EstacaoReservaMulQj[i]==BufferReorderLabel[BufferReorderIndex])
                 begin
                   EstacaoReservaMulVj[i]=BufferReorderValue[BufferReorderIndex]; // grava o valor
                   EstacaoReservaMulJusy[i]=0; // remove a dependencia
                 end
                 if(EstacaoReservaMulKusy[i]==1) //  ha dependencia
                 if(EstacaoReservaMulQk[i]==BufferReorderLabel[BufferReorderIndex])
                 begin
                   EstacaoReservaMulVk[i]=BufferReorderValue[BufferReorderIndex]; // grava o valor
                   EstacaoReservaMulKusy[i]=0; // remove a dependencia
                 end
               end

             if(BufferReorderBusy[BufferReorderIndex]==1) // evita de limpar e avancar se errou o desvio
             begin
               BufferReorderBusy[BufferReorderIndex]=0; // desocupa o ROB
               BufferReorderIndex=BufferReorderIndex+1; // avanca no ponteiro
             end
           end
         //--------------------------------
       end


       /*************************** S T E P  4 ********************************/
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
				 if(BufferReorderBusy[i]==1 & BufferReorderLabel[i]==EstacaoReservaMulLabel[MulIndex]) // tag deu match
				 begin
					 BufferReorderValue[i]=MulValue;
					 BufferReorderPres[i]=1;
				 end
			  end

           for(i=0;i<2;i=i+1) // percorre estacoes de reserva procurando dependencia
           begin
             if(EstacaoReservaAddJusy[i]==1) //  ha dependencia
              if(EstacaoReservaAddQj[i]==EstacaoReservaMulLabel[MulIndex])
              begin
                EstacaoReservaAddVj[i]=MulValue; // grava o valor
                EstacaoReservaAddJusy[i]=0; // remove a dependencia
              end
             if(EstacaoReservaAddKusy[i]==1) //  ha dependencia
              if(EstacaoReservaAddQk[i]==EstacaoReservaMulLabel[MulIndex])
              begin
                EstacaoReservaAddVk[i]=MulValue; // grava o valor
                EstacaoReservaAddKusy[i]=0; // remove a dependencia
              end
             if(EstacaoReservaMulJusy[i]==1) //  ha dependencia
              if(EstacaoReservaMulQj[i]==EstacaoReservaMulLabel[MulIndex])
              begin
                EstacaoReservaMulVj[i]=MulValue; // grava o valor
                EstacaoReservaMulJusy[i]=0; // remove a dependencia
                end
             if(EstacaoReservaMulKusy[i]==1) //  ha dependencia
              if(EstacaoReservaMulQk[i]==EstacaoReservaMulLabel[MulIndex])
              begin
                EstacaoReservaMulVk[i]=MulValue; // grava o valor
                EstacaoReservaMulKusy[i]=0; // remove a dependencia
              end
           end
           EstacaoReservaMulBusy[MulIndex]=0; // limpa a estacao de reserva
           MulDone=0; MulBusy=0;// desocupa a unidade
           CDBusy=0; // desocupa o cdb
         end

         /*************************** S U M  e S U B **************************/
         else if(SumDone==1 & CDBusy==0)
         begin
           CDBusy=1;

           for(i=0;i<4;i=i+1) // Grava o resultado no ROB
           begin
             if(BufferReorderBusy[i]==1 & BufferReorderLabel[i]==EstacaoReservaAddLabel[SumIndex]) // tag deu match
             begin
               BufferReorderValue[i]=SumValue;
               BufferReorderPres[i]=1;
             end
           end

           for(i=0;i<2;i=i+1) // percorre estacoes de reserva procurando dependencia
           begin
             if(EstacaoReservaAddJusy[i]==1) //  ha dependencia
             if(EstacaoReservaAddQj[i]==EstacaoReservaAddLabel[SumIndex])
             begin
               EstacaoReservaAddVj[i]=SumValue; // grava o valor
               EstacaoReservaAddJusy[i]=0; // remove a dependencia
             end
             if(EstacaoReservaAddKusy[i]==1) //  ha dependencia
             if(EstacaoReservaAddQk[i]==EstacaoReservaAddLabel[SumIndex])
             begin
               EstacaoReservaAddVk[i]=SumValue; // grava o valor
               EstacaoReservaAddKusy[i]=0; // remove a dependencia
             end
             if(EstacaoReservaMulJusy[i]==1) //  ha dependencia
             if(EstacaoReservaMulQj[i]==EstacaoReservaAddLabel[SumIndex])
             begin
               EstacaoReservaMulVj[i]=SumValue; // grava o valor
               EstacaoReservaMulJusy[i]=0; // remove a dependencia
             end
             if(EstacaoReservaMulKusy[i]==1) //  ha dependencia
             if(EstacaoReservaMulQk[i]==EstacaoReservaAddLabel[SumIndex])
             begin
               EstacaoReservaMulVk[i]=SumValue; // grava o valor
               EstacaoReservaMulKusy[i]=0; // remove a dependencia
             end
           end
           EstacaoReservaAddBusy[SumIndex]=0; // limpa a estacao de reserva
           SumDone=0; SumBusy=0; // desocupa a unidade
           CDBusy=0; // desocupa o cdb
         end
       end


       /*************************** S T E P  3 ********************************/
       // Passo 3 - Executa instrucoes
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

       if(MulBusy==1)
       begin
         if(MulDone==0)
           case(MulState)
             0:MulState=MulState+1; // Comeca a Multiplicar/Dividir
             1:MulState=MulState+1; // Continua a Multiplicar/Dividir
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
             3:// Finaliza a divisao
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
           if(BufferReorderBusy[i]==1 & BufferReorderLabel[i]==EstacaoReservaAddLabel[SumIndex]) // tag deu match
           begin
             BufferReorderValue[i]=SumValue; // valor diferente do endereco de desvio
             BufferReorderPres[i]=1;
           end
         end
         EstacaoReservaAddBusy[SumIndex]=0; // libera a unidade
         SumDone=0; SumBusy=0; // desocupa a unidade
       end
		 if(SumDone==1 & SumOp==2) // BEQ nao usa cdb
       begin
         for(i=0;i<4;i=i+1) // Grava o resultado no ROB
         begin
           if(BufferReorderBusy[i]==1 & BufferReorderLabel[i]==EstacaoReservaAddLabel[SumIndex]) // tag deu match
           begin
             BufferReorderValue[i]=SumValue; // valor diferente do endereco de desvio
             BufferReorderPres[i]=1;
           end
         end
         EstacaoReservaAddBusy[SumIndex]=0; // libera a unidade
         SumDone=0; SumBusy=0; // desocupa a unidade
       end
       if(pc>=PCnext)
         done=1;
       for(i=0;i<2;i=i+1) // verifica se ha algo pra executar
         if(EstacaoReservaAddBusy[i]==1|EstacaoReservaMulBusy[i]==1)
           done=0;

       for(i=0;i<4;i=i+1)
         if(BufferReorderBusy[i]==1)
           done=0;

       if(done==0)
         count=count+1;
     end
   end

   initial begin

   for(i=0;i<64;i=i+1)
   begin
     instrucao[i]=0;
   end

   // PROGRAMA
   instrucao[0]=16'b0011000100100001; // r1=r1/r2
   //instrucao[1]=16'b0001000000000011;	// r0=r0+r3
   PCnext=2;
   // END

   pc=0;
   for(i=0;i<16;i=i+1)
   begin
     bancoReg[i]=i;
     bancoRegLabelPres[i]=0;
   end
   for(i=0;i<2;i=i+1)
   begin
     EstacaoReservaAddBusy[i]=0;
     EstacaoReservaMulBusy[i]=0;
   end
   CDBusy=0;
   SumBusy=0;
   MulBusy=0;

   SumDone=0;
   MulDone=0;

   done=0;

   BufferReorderIndex=0;
   for(i=0; i<4; i=i+1)
   begin
     BufferReorderBusy[i]=0;
     BufferReorderPres[i]=0;
   end
   count=0;
   end
endmodule

//STALL - 0 - Stall used splash... Nothing happens!
//ADD   - 1 - 0001 Destino Operando1 Operando2
//SUB   - 2 - 0010 Destino Operando1 Operando2
//MUL   - 3 - 0011 Destino Operando1 Operando2
//DIV   - 4 - 0100 Destino Operando1 Operando2

/*//Programa 1 - Soma com dependencia verdadeira
 instrucao[0]=16'b0001000000010010; // r0=r1+r2
 instrucao[1]=16'b0001000000000011;	// r0=r0+r3
 PCnext=2;
*///Fim do Programa 1 ---------------

/*//Programa 2 - Soma com hazard estrutural
 instrucao[0]=16'b0001000000010010; // r0=r1+r2
 instrucao[1]=16'b0001000100010011;	// r1=r1+r3
 PCnext=2;
*///Fim do Programa 2 ---------------

/*//Programa 3 - Dependencia CDB
 instrucao[0]=16'b0011000000010010; // r0=r1*r2
 instrucao[1]=16'b0011000100010011;	// r1=r1*r3
 instrucao[2]=16'b0001010001010110;	// r4=r5+r6
 PCnext=3;
*///Fim do Programa 3 ---------------

/*//Programa 4 - Estacao de reserva cheia
 instrucao[0]=16'b0001000000010010; // r0=r1+r2
 instrucao[1]=16'b0001000100010011;	// r1=r1+r3
 instrucao[2]=16'b0001010001010110;	// r4=r5+r6
 PCnext=3;
*///Fim do Programa 4 ---------------
