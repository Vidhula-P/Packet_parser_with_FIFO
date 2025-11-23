module crc_tb;
	logic clk;
	logic rst;
	logic valid;
	logic [319:0] data_raw;
	logic [31:0]  crc;
	logic done;

	crc crc_dut (
		.clk(clk),
		.rst(rst),
		.valid(valid),
		.data_raw(data_raw),
		.crc(crc),
		.done(done)
	);

	//Timescale
	timeunit 10ns; timeprecision 100ps;

	//Clock generation
	initial clk = 1'b0;
	always #5 clk = ~clk;

	// Stimulus
	always_ff @(posedge clk) begin
		if (done) begin
			$display("CRC- %h", crc);
		end
	end

	initial begin
		rst = 1;
		#3
		rst = 0;
		valid = 0;
		data_raw = 0;
		#3
		rst = 1;

		// Test Case 1
    $display("--- Test Case 1 ---");
    #7 @(posedge clk);
    valid = 1; 
    data_raw = 320'h0123456789ABCDEF00112233445566778899AABBCCDDEEFF0F1E2D3C4B5A69780123456789ABCDEF; //Expected - 0x639A9721
		@(posedge clk);
    valid = 0;
    
    // Wait for done
    wait(done == 1);
    @(posedge clk);
    
    // Test Case 2
    $display("--- Test Case 2 ---");
    @(posedge clk);
    valid = 1;
    data_raw = 320'hA5DEADBEEF123456789ABCDEF0CAFEBABE0F1E2D3C4B5A69780012345678DAAAA5DEADBEEF123456; //Expected - 0x526589FD
		@(posedge clk);
    valid = 0;
    
    // Wait for done
    wait(done == 1);
    @(posedge clk);
    
    // Test Case 3
    $display("--- Test Case 3 ---");
    @(posedge clk); rst = 0;
		@(posedge clk); rst = 1;
    @(posedge clk); valid = 1;
    data_raw = 320'hFEDCBA987654321000000AAAAAAA555555555555CCCCCCCCCCCC647382914FEDCBA9876; //Expected - 0x3BCA2872
    @(posedge clk);
    valid = 0;
    
    // Wait for done
    wait(done == 1);
    @(posedge clk);
    @(posedge clk);
    
    $display("--- All tests complete ---");
    $finish;
  end
endmodule
