// CONTROL SIGNALS 
// valid_in  - upstream (packet source) has data available to read
// ready_in  - parser is ready to accept data
// valid_out - parser has data ready to send to FIFO 
// ready_out - FIFO is ready to accept data

module packet_parser #(
    parameter WIDTH = 32
)(
		input  logic              clk,
    input  logic              rst,        // async active-low reset

    // input side
    input  logic [WIDTH-1:0]  data_in,
    input  logic              valid_in,
    output logic              ready_in,

    // output side
    output logic [WIDTH-1:0]  data_out,
    output logic              valid_out,
    input  logic              ready_out
);

    timeunit 10ns; 
    timeprecision 100ps;

    typedef enum logic [2:0] {
        IDLE,
        ETH_HDR,
        IP_HDR,
        TCP_HDR,
        PAYLOAD, //simulatenously start sending to FIFO
				CRC_START,
    		CRC_WAIT,
    		CRC_SEND
    } state_t;

    state_t curr_state, next_state;

    logic [4:0] word_cnt;

    logic [127:0] ethernet_header;  // 16B = 128 bits
    logic [159:0] ip_header;        // 20B = 160 bits
    logic [159:0] tcp_header;       // 20B = 160 bits
		logic [319:0] payload_data;			// 10B = 320 bits
		logic  [31:0] crc;							//  4B =  32 bits
		//The packet buffer (in memory) is padded or aligned to the 
		//data-bus word width, hence the headers are word-aligned

		//Cyclic Redundancy Code: CRC-32 for error checking
		logic 				crc_valid;
		logic [319:0] crc_data_in;
		logic  [31:0] crc_output;
		logic 				crc_done;

		crc crc_dut (
			.clk(clk),
			.rst(rst),
			.valid(crc_valid),
			.data_raw(crc_data_in),
			.crc(crc_output),
			.done(crc_done)
		);

    // ----------------------------------------
    // Handshake logic
    // ----------------------------------------
		assign ready_in = ((curr_state == PAYLOAD) || (curr_state == CRC_SEND)) ? ready_out : 1'b1;

    // ----------------------------------------
    // State + counter update
    // ----------------------------------------
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            curr_state <= IDLE;
            word_cnt   <= 0;
        end else begin
            curr_state <= next_state;

            if (valid_in && ready_in)
                word_cnt <= word_cnt + 1;
            else if (curr_state == IDLE)
                word_cnt <= 0;
        end
    end

    // ----------------------------------------
    // Next-state logic
    // ----------------------------------------
    always_comb begin
        next_state = curr_state; //in case of unexpected situation
				valid_out = 0;
        case (curr_state)
            IDLE: begin
                if (valid_in && ready_in)
                    next_state = ETH_HDR;
						end
            ETH_HDR:
                if (valid_in && word_cnt == 4)   // 4 words: 1..4
                    next_state = IP_HDR;
            IP_HDR:
                if (valid_in && word_cnt == 9)   // 5 words: 5..9
                    next_state = TCP_HDR;
            TCP_HDR:
                if (valid_in && word_cnt == 14)  // 5 words: 10..14
                    next_state = PAYLOAD;
            PAYLOAD: begin
								valid_out = valid_in;
                if ( word_cnt == 24)  // 10 words:15..24
                    next_state = CRC_START;
						end
						CRC_START:
								next_state = CRC_WAIT;
						CRC_WAIT:
								if(crc_done)
									next_state = CRC_SEND;
						CRC_SEND: begin
								valid_out = 1;
								next_state = IDLE;
						end
            default: begin
                next_state = IDLE;
						end
        endcase
    end

    // ----------------------------------------
    // Data capturing
    // ----------------------------------------
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
						data_out				<= '0;
            ethernet_header <= '0;
            ip_header       <= '0;
            tcp_header      <= '0;
						payload_data		<= '0;
						crc_valid			  <=  0;
        		crc_data_in 		<= '0;

        end else begin
						// next_state reflects the new header state in the same cycle as valid_in.
						// curr_state lags by one cycle, so using it would shift each header 
						// by one word.
            case (next_state)
								IDLE:;
                ETH_HDR: begin
									ethernet_header <= {data_in, ethernet_header[127:32]};
									$display("(old) word_cnt inside ETH_HDR - %d", word_cnt);
								end
                IP_HDR: begin
                	ip_header <= {data_in, ip_header[159:32]};
									$display("(old) word_cnt inside IP_HDR - %d", word_cnt);
								end
                TCP_HDR: begin
                	tcp_header <= {data_in, tcp_header[159:32]};
									$display("(old) word_cnt inside TCP_HDR - %d", word_cnt);
								end
                PAYLOAD: begin
									payload_data <= {data_in, payload_data[319:32]};
									if( valid_in && ready_out) begin
                		data_out <= data_in; 		// pass through
									end
									$display("(old) word_cnt inside PAYLOAD - %d", word_cnt);
								end
								CRC_START: begin
									$display("Inside CRC_START");
									crc_valid <= 1;
									crc_data_in <= payload_data;
									$display("payload_data - %h", payload_data);
								end
								CRC_WAIT: begin
									crc_valid <= 0;
								end
								CRC_SEND: begin
									data_out <= crc_output;
									$display("crc_output - %h", crc_output);
								end
										
            endcase
        end
    end

endmodule

