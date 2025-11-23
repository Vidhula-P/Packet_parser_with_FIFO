//fifo buffer to send packet parser output to dma
module fifo #(
	//paramters
	parameter WIDTH = 32, //no. of bits the FIFO can hold
	parameter DEPTH = 16  //how many words the FIFO can store
)(
	//ports
	//clock and reset
	input  logic clk,
	input  logic rst, // asynchronous active low
	//write
	input  logic [WIDTH-1:0] wdata,
	input  logic						 wr_en,
	output logic						 full_flag,
	//read
	output logic [WIDTH-1:0] rdata,
	input  logic						 rd_en,
	output logic						 empty_flag
);
	//Timescale
	timeunit 10ns; timeprecision 100ps;

	//local parameters and signals
	localparam ADDR_WIDTH = $clog2(DEPTH); //sythesizable since 
																				 // DEPTH is fixed
	logic [ADDR_WIDTH-1:0] rptr, wptr;
	logic full, empty;
	logic last_op; // 0 -> write, 1 -> read

	//register array (the buffer)
	logic [WIDTH-1:0] mem [0:DEPTH-1];

	//Write Operation
	always_ff @(posedge clk or negedge rst) begin
		if (!rst) begin
			wptr <= 0;
		end else begin
			if (wr_en && !full) begin
				mem[wptr] <= wdata;
				wptr 			<= wptr + 1'b1;
				$display("Writing %h to %d", wdata, wptr);
			end
		end
	end

	//Read Operation
	always_ff @(posedge clk or negedge rst) begin
		if (!rst) begin
			rptr <= 0;
		end else begin
			if (rd_en && !empty) begin
				rptr 	<= rptr + 1'b1; //since non-blocking assign
				rdata <= mem[rptr]; 	//old value of rptr is considered
			end
		end
	end

	//Tracking what the last operation was to determine if FIFO 
	//is empty or full (in both cases rptr =  wptr)
	always_ff @(posedge clk or negedge rst) begin
		if (!rst) begin
			last_op <= 1'b1;
		end else begin
			if (rd_en && !empty) begin
				last_op <= 1'b1; 		//read -> 1
			end else if (wr_en && !full) begin
				last_op <= 1'b0; 		//write -> 0
			end else begin
				last_op <= last_op; //hold
			end
		end
	end

	//setting the flags
	assign full  = (wptr == rptr) && !last_op;
	assign empty = (wptr == rptr) &&  last_op;

	assign full_flag  = full; //using intermediate signals since 'full' and
	assign empty_flag = empty;//'empty' are used in multiple places in code

endmodule
