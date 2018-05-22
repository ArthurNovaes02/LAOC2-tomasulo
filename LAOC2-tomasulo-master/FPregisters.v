module FPregisters(clock, reset, 
				   reg1Index, reg2Index, 
				   reg1Out, reg2Out,
			       indexCDB, CDB);

	input wire clock, reset;
	input wire [2:0]reg1Index;
	input wire [2:0]reg2Index;
	input wire [15:0]CDB;
	output wire [15:0]reg1Out;
	output wire [15:0]reg2Out;
	reg[15:0]banco[2:0];
	integer i;
	
	assign reg1Out = banco[reg1Index];
	assign reg2Out = banco[reg2Index];
	
	always @(posedge clock) 
	begin
		reg1Out = banco[indexCDB];
		if(indexCDB or CDB)
		begin
			
		end
	end
	
		always(@posedge reset)
	begin
		for(i = 0; i < 3 ; i++)
		begin
			banco[i]='b0;
		end
			
	end
	

endmodule


