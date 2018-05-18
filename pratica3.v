module pratica3(SW, LW, HEX0, HEX1, HEX2, HEX3, HEX4, HEX5, HEX6, HEX7);
	input [17:0]SW;
	output wire [17:0]LW;
	output wire [0:6]HEX5,  HEX7, HEX6, HEX4, HEX3, HEX2, HEX1, HEX0 ;
	wire [15:0]reg1;
	wire [15:0]reg2;
	wire [15:0]CDB;
	wire [15:0]instruction;
	wire [15:0]adders;
	wire [15:0]multipliers;
	
	//LW[] =>
	//SW[] =>
	//HEX0 = reg1
	//HEX1 = reg2
	//HEX2 = adders
	//HEX3 = multipliers
	//HEX4 = 
	//HEX5 = 
	//HEX6 = CDB
	//HEX7 = instruction
	
	
	assign LW = SW;

endmodule