module registers(clock, reset,
				   reg1Index, reg2Index,
				   reg1Out, reg2Out,
			     indexCDB, CDB);

	input wire clock, reset;
	input wire [2:0]indexCDB;
	input wire [2:0]reg1Index;
	input wire [2:0]reg2Index;
	input wire [15:0]CDB;
	output wire [15:0]reg1Out;
	output wire [15:0]reg2Out;
	reg[15:0]banco[0:2];
	integer i;

	assign reg1Out = banco[reg1Index];//realiza a leitura do banco
	assign reg2Out = banco[reg2Index];//de acordo com os reg solicitados

	initial begin
	for(i = 0; i < 8; i=i+1)begin
		banco[i] = 'b0;
	end

	always @(posedge clock)
	begin
		if(indexCDB | CDB)
			banco[indexCDB] = CDB;
	end

	always @ (posedge reset)//zero pelo reset
	begin
		for(i = 0; i < 3 ; i=i+i)
		begin
			banco[i]='b0;
		end
	end
endmodule
