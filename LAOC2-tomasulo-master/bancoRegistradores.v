module bancoRegistradores(clock, reset, aluOP, regWrite, 
						  reg1In, reg2In, regDest, data, 
						  reg1Out, reg2Out, endBase);

	input clock, reset;
	input regWrite;
	input regDest;
	input [1:0]reg1In;
	input [1:0]reg2In;
	input [3:0]regDest;
	input aluOP;
	input [7:0]data;
	output reg[7:0]reg1Out;
	output reg[7:0]reg2Out;
	output reg[7:0]endBase;
	
	reg[7:0]banco1[1:0];
	reg[7:0]banco2[1:0];
	
	always @(posedge clock) 
	begin
	  endBase = banco2[10];
		reg1Out=banco1[reg1In];
		reg2Out=banco2[reg2In];
		if(regWrite==1)
		begin
			if(aluOP==1)
			banco1[regDest[3:2]]=data;
			else banco2[regDest[1:0]]=data;	
		end
		if (reset)
		begin
			reg1Out=8'b00000000;
			reg2Out=8'b00000000;
		end
		endBase = banco2[10];
	end

endmodule


