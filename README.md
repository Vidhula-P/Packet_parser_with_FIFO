# Packet Parser with FIFO

This project implements a system that parses **96 B input data** and forwards the payload with added redundant CRC bits (**41 B output data**) to a FIFO buffer. The system structure is as follows.

## Data Structure
The input data consists of:

- Ethernet header (16 B) {Ex input in test1-  A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1}
- IP header (20 B)       {Ex input in test1-  B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2}
- TCP header (20 B)      {Ex input in test1-  C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3}
- Payload (40 B)         {Ex input in test1-  D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099}
- CRC (1 B)              {Ex output in test1- 281B86C4}


## System Description
- The parser extracts header information and forwards ** the payload** to a `32x16` FIFO buffer.
- The parser, FIFO and CRC unit were individually tested:
- `tb/fifo_tb.sv`
- `tb/parser_tb.sv`
- `tb/crc_tb.sv`
- Integration testing was done in `tb/tb.sv`.

## Simulation & Debugging
Simulation outputs were verified using **SimVision**, ensuring correct handshake signals and data flow. 
![Waveform debugging screenshot](images/parser_fifo_crc.png.png)

Description of signals in the image
- data_in         : 32 bit words sent from testbench to parser
- parser_valid_in : testbench tells the parser a data word is available
- parser_valid_out: parser tells the FIFO it wants to send data (in PAYLOAD state)
- parser_ready_in : parser ready to accept data from testbench (ready when FIFO is in PAYLOAD and CRC_WAIT states, otherwise always ready)
- parser_ready_out: FIFO  tells parser it can receive data (if FIFO is not full)
- fifo_empty_flag : 1 if FIFO is empty
- fifo_full_flag  : 1 if FIFO is full (has 16 words)
- fifo_wr_en      : set 1 by parser when it has data to write to FIFO
- fifo_wdata      : data sent to be written in FIFO
- fifo_rd_en      : set by testbench to read FIFO at end of test
- data_out        : words sent by FIFO to testbench in response to above read request


## Conclusion
The code successfully parses the headers and forwards the payload alongwith calculated CRC bits to the FIFO buffer.  
