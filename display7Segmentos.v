module display7Segmentos(Entrada, SaidaDisplay); //visual output
	input [4:0]Entrada;
	output reg [0:6]SaidaDisplay;
	
//      0
//     ---
//  5 |   | 1
//     --- <--6
//  4 |   | 2
//     ---
//      3

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