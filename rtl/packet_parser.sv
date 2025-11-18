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
        PAYLOAD //simulatenously start 
    } state_t;

    state_t curr_state, next_state;

    logic [4:0] word_cnt;

    logic [127:0] ethernet_header;  // 16B  = 128 bits
    logic [159:0] ip_header;        // 20B  = 160 bits
    logic [159:0] tcp_header;       // 20B  = 160 bits
		//The packet buffer (in memory) is padded or aligned to the 
		//data-bus word width, hence the headers are word-aligned

    // ----------------------------------------
    // Handshake logic (minimal behavior)
    // ----------------------------------------
    //assign ready_in  = 1'b1;            // always ready for now
    //assign valid_out = 1'b0;            // not driving FIFO yet
    //assign data_out  = '0;
		assign ready_in  = (curr_state == PAYLOAD) ? ready_out : 1'b1;
		assign valid_out = (curr_state == PAYLOAD) ? valid_in  : 1'b0;

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
            else if (curr_state != next_state)
                word_cnt <= 0;
        end
    end

    // ----------------------------------------
    // Next-state logic
    // ----------------------------------------
    always_comb begin
        next_state = curr_state; //in case of unexpected situation
        case (curr_state)
            IDLE:
                if (valid_in && ready_in)
                    next_state = ETH_HDR;
            ETH_HDR:
                if (valid_in && word_cnt == 4)   // 4 words: 1..4
                    next_state = IP_HDR;
            IP_HDR:
                if (valid_in && word_cnt == 9)   // 5 words: 5..9
                    next_state = TCP_HDR;
            TCP_HDR:
                if (valid_in && word_cnt == 14)   // 5 words: 10..14
                    next_state = PAYLOAD;
            PAYLOAD:
                if (valid_in && word_cnt == 24)
										// (fixed for now) 10 words:15..24
                    next_state = IDLE;
            default:
                next_state = IDLE;
        endcase
    end

    // ----------------------------------------
    // Data capturing
    // ----------------------------------------
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            ethernet_header <= '0;
            ip_header       <= '0;
            tcp_header      <= '0;

        end else begin
						// next_state reflects the new header state in the same cycle as valid_in.
						// curr_state lags by one cycle, so using it would shift each header 
						// by one word.
            case (next_state)
								IDLE:;
                ETH_HDR: begin
										ethernet_header <= {data_in, ethernet_header[127:32]};// 128-32 = 96
								end
                IP_HDR: begin
                    ip_header <= {data_in, ip_header[159:32]}; 					// 160-32 = 128
								end
                TCP_HDR: begin
                    tcp_header <= {data_in, tcp_header[159:32]}; 				// 160-32 = 128
								end
                PAYLOAD: 
										if( valid_in && ready_out) begin
                    	data_out <= data_in; 		// pass through
										end
            endcase
        end
    end

endmodule

