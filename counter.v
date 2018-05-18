module counter (reset, clock, Q);
	input wire reset, clock;
	output reg [3:0] Q;

	always @(posedge clock)
		if (reset)
			Q <= 'b0;
		else
			Q <= Q + 'b1;
endmodule
