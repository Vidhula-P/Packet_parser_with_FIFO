module tb;

  timeunit 10ns; 
  timeprecision 100ps;

	// DUT signals
	logic clk, rst;
	logic [31:0] data_in;
	logic valid_in;
	logic ready_in;
	logic [31:0] data_out;
	logic rd_en;
	logic fifo_empty;

	//input to DUT
	logic [127:0] eth_hdr;
	logic [159:0] ip_hdr;
	logic [159:0] tcp_hdr;
	logic [319:0] payload;
	logic [767:0] full_data;


	top top1 (
	.clk(clk),
	.rst(rst),
	.data_in(data_in),
	.parser_valid_in(valid_in),
	.parser_ready_in(ready_in),
	.data_out(data_out),
	.fifo_rd_en(rd_en),
	.fifo_empty_flag(fifo_empty)
);

  // ---------------------------
  // Clock gen (10 ns period)
  // ---------------------------
  initial clk = 0;
  always #5 clk = ~clk;

  // ---------------------------
  // Reset signals
  // ---------------------------
	task reset_parser;
  	begin
    	rst = 0;
    	valid_in = 0;
			rd_en = 0;
			data_in = 0;
    	repeat (5) @(posedge clk);
    	rst = 1; 
			@(posedge clk); // wait one clock cycle
		end
	endtask

  // -------------------------------------------
  // Send one 32-bit word (task)
  // -------------------------------------------
  task send_word(input logic [31:0] word);
    begin
      valid_in = 1;
      data_in  = word;
    	// wait for a clock edge
  		@(posedge clk);
  		// If parser wasn't ready that clock, wait until it is ready on subsequent clocks
  		while (!ready_in) @(posedge clk);
      valid_in = 0;
			@(posedge clk); 
    end
  endtask

  // -------------------------------------------
  // Tests
  // -------------------------------------------

	// ----------------TEST-1---------------------
	task test1;
		begin
			// Prepare headers 
    	eth_hdr = 128'hA1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1;
			ip_hdr = 160'hB2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2; 
			tcp_hdr = 160'hC3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3; 
			payload = 320'hD4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099;

			full_data = {eth_hdr, ip_hdr, tcp_hdr, payload};

			//$display("Full data- %h", full_data);
			// Send MSB → LSB (matches the parser shift order)
   		for (int i = 767; i >= 0; i -= 32) begin
      	send_word(full_data[i-:32]);  // part-select from i downto i-31
    	end

    	// Give time for parser to finish PAYLOAD
    	repeat (60) @(posedge clk);

			// Start reading FIFO
  		while (!fifo_empty) begin
				$display("Reading FIFO");
    		rd_en = 1;
    		@(posedge clk);
  		end
  		rd_en = 0;
		end
	endtask

	// ----------------TEST-2---------------------
	task test2;
		begin
			// Prepare headers 
    	eth_hdr = 128'h8F3A_9C12_7BD4_E6A0_55CC_11AA_4490_7F3E;
			ip_hdr  = 160'h0011_2233_4455_6677_8899_AABB_CCDD_EEFF_0011_2233; 
			tcp_hdr = 160'hFFEE_DDCC_BBAA_9988_7766_5544_3322_1100_FFEE_DDCC; 
			payload = 320'h0123_4567_89AB_CDEF_0123_4567_89AB_CDEF_0123_4567_89AB_CDEF_0123_4567_89AB_CDEF_0123_4567_89AB_CDEF;

			full_data = {eth_hdr, ip_hdr, tcp_hdr, payload};

			//$display("Full data- %h", full_data);
			// Send MSB → LSB (matches the parser shift order)
   		for (int i = 767; i >= 0; i -= 32) begin
      	send_word(full_data[i-:32]);  // part-select from i downto i-31
    	end

    	// Give time for parser to finish PAYLOAD
    	//repeat (2) @(posedge clk);

			// Start reading FIFO
  		while (!fifo_empty) begin
    		rd_en = 1;
    		@(posedge clk);
  		end
  		rd_en = 0;
		end
	endtask

  // -------------------------------------------
  // Stimulus
  // -------------------------------------------

	initial begin
		reset_parser; wait (rst == 1); // halts the simulation at that point until rst equals 1
		test1;
		/*test2;
		test1;*/

    $finish;
  end

endmodule
