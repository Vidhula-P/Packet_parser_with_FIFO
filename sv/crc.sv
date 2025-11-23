module crc(
  input  logic         clk,
  input  logic         rst,
	input  logic				 valid,
  input  logic [767:0] data_raw,
  output logic [31:0]  crc,
  output logic         done
);
  logic [31:0] temp_crc, CRCPOLY;
  logic [7:0]  data_byte;
  logic [6:0]  byte_cnt; // enough to count 0..95

	//Timescale
	timeunit 10ns; timeprecision 100ps;

	// FSM for multicycle CRC
  typedef enum logic [1:0] {IDLE, COMPUTE, FINISH} state_t;
  state_t curr_state, next_state;

	initial CRCPOLY = 32'hEDB88320; //IEEE standard polynomial for LSb-first CRC-32

	// ----------------------------------------
  // State update
  // ----------------------------------------
	always_ff @(posedge clk or posedge rst) begin
		if (rst) begin
    	curr_state <= IDLE;
    end else begin
    	curr_state <= next_state;
		end
  end

  // ----------------------------------------
  // Next-state logic
  // ----------------------------------------
	always_comb begin
		next_state = curr_state; //in case of unexpected situation
		if (rst) begin
      next_state = IDLE;
    end else begin
      case(curr_state)
        IDLE:
					if (valid)
          	next_state = COMPUTE;
				COMPUTE: begin
          if (byte_cnt == 7'd95)
           next_state = FINISH;
				end
				FINISH:
            next_state = IDLE;
      endcase
    end
	end

  // ----------------------------------------
  // Data output
  // ----------------------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      temp_crc <= 32'hFFFFFFFF;
			byte_cnt <= 0;
			done <= 0;
    end else begin
      case(curr_state)
        IDLE: begin
          temp_crc <= 32'hFFFFFFFF;
					byte_cnt <= 0;
					done <= 0;
        end //end of IDLE

				COMPUTE: begin
					data_byte = data_raw[(767 - 8*byte_cnt) -: 8]; //extract 1B of data at a time
          // bit-level loop
          for (int i = 0; i < 8; i++) begin
          	if ((temp_crc ^ data_byte) & 1)	
            	temp_crc = (temp_crc >> 1) ^ CRCPOLY;
            else
              temp_crc >>= 1;
						data_byte >>= 1;
					end
          byte_cnt <= byte_cnt + 1;
				end //end of COMPUTE

				FINISH: begin
          	crc <= temp_crc ^ 32'hFFFFFFFF;
            done <= 1;
        end //end of FINISH
      endcase
    end //end of else
	end //end of always

endmodule

