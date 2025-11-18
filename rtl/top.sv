//[Input packet source] 
//--> top { [Parser] --> [Output FIFO] } 
//--> [Testbench reads from FIFO]

module top( //input to parser, output from FIFO
	input logic 			 	clk,
	input logic 			 	rst,
	//parser input signals
	input logic  [31:0] data_in,
	input logic 			  parser_valid_in, //upstream (packet source) has data available to read
	output logic 			  parser_ready_in, //parser ready to accept data
	//FIFO output signals
	output logic [31:0] data_out, // final data output from parser
	input logic				  fifo_rd_en,
	output logic 				fifo_empty_flag
);

  timeunit 10ns; 
  timeprecision 100ps;

  // Parser output signals (internal)
  logic [31:0] parser_data_out;
  logic parser_valid_out, parser_ready_out;

  // FIFO input signals (internal)
  logic fifo_wr_en, fifo_full_flag;
	logic [31:0] fifo_wdata;


  // Instantiate Parser
  packet_parser #(32) parser_inst (
    .clk(clk),
    .rst(rst),
    .data_in(data_in),
    .valid_in(parser_valid_in),
    .ready_in(parser_ready_in),
    .data_out(parser_data_out),
    .valid_out(parser_valid_out),//parser has data ready to send to FIFO 
    .ready_out(parser_ready_out) //FIFO ready to accept data
  );

  // Instantiate FIFO
  fifo #(32, 16) fifo_inst (
    .clk(clk),
    .rst(rst),
    .wdata(fifo_wdata),
    .wr_en(fifo_wr_en),
    .full_flag(fifo_full_flag),
    .rdata(data_out), //FIFO to outside world
    .rd_en(fifo_rd_en),
    .empty_flag(fifo_empty_flag)
  );

  // Parser --> FIFO interface (internal)
  assign fifo_wdata      = parser_data_out;
  assign fifo_wr_en      = parser_valid_out && !fifo_full_flag; // write only if data is valid & FIFO not full
  assign parser_ready_out= !fifo_full_flag;               			// parser can send data if FIFO has space

endmodule

