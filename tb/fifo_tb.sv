//testbench to verify FIFO operation in a modular fashion
module fifo_tb;
	timeunit 10ns; timeprecision 100ps;

	localparam WIDTH = 32;
	localparam DEPTH = 16;

	//signals
	logic clk, rst;
	logic [WIDTH-1:0] wdata;
	logic wr_en;
	logic	full_flag;
	logic [WIDTH-1:0] rdata;
	logic rd_en;
	logic	empty_flag;

	//instantiating the DUT
	fifo #(
		.WIDTH(WIDTH),
		.DEPTH(DEPTH)
	) fifo_dut (
		.clk(clk),
		.rst(rst),
		.wdata(wdata),
		.wr_en(wr_en),
		.full_flag(full_flag),
		.rdata(rdata),
		.rd_en(rd_en),
		.empty_flag(empty_flag)
	);

	//clock generation
	initial clk = 1'b0;
	always #5 clk = ~clk; // 100 MHz (10 ns time period)

	//setting reset
	initial begin
		//rst   = 1;
		rst   = 1;
		wr_en = 0;
		rd_en = 0;
		wdata = 0;
		#10
		rst = 0;
	end

	//TEST 1 - SIMPLE CASE
	initial begin
		@(negedge rst); //wait if reset
		//write sample data
		for (int i = 0; i < DEPTH; i++) begin
			@(posedge clk);
			wdata = i;
			wr_en = 1'b1;
		end
		@(posedge clk);
		wr_en = 1'b0;

		// Try writing one more word to test full
    /*@(posedge clk);
    wdata = 99;
    wr_en = 1;
    @(posedge clk);
    wr_en = 0;*/

    // Read all data
    for (int i = 0; i < DEPTH; i++) begin
    	@(posedge clk);
			rd_en = 1;
    end
    @(posedge clk);
    rd_en = 0;

    // Try reading one more to test empty
    /*@(posedge clk);
    rd_en = 1;
    @(posedge clk);
    rd_en = 0;*/
		$finish;
  end

  // Monitor
  always @(posedge clk) begin
    if (wr_en && !full_flag) begin
      $display("Write: %0d, empty_flag=%b, full_flag=%b", wdata, empty_flag, full_flag);
    end if (rd_en && !empty_flag) begin
      $display("Read: %0d, empty_flag=%b, full_flag=%b", rdata, empty_flag, full_flag);
    end
	end

endmodule: fifo_tb
