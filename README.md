# Packet Parser with DMA Engine
*(DMA Engine pending)*

This project implements a system that parses **96 B input data** and forwards the payload with added redundant CRC bits to a FIFO buffer. The system structure is as follows.

## Data Structure
The input data consists of:

- Ethernet header (16 B) {Testbench input-  A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1}
- IP header (20 B)       {Testbench input-  B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2}
- TCP header (20 B)      {Testbench input-  C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3}
- Payload (40 B)         {Testbench input-  D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099}
- CRC (1 B)              {Testbench output- 281B86C4}


## System Description
- The parser extracts header information and forwards ** the payload** to a `32x16` FIFO buffer.
- The parser, FIFO and CRC unit were individually tested:
- `tb/fifo_tb.sv`
- `tb/parser_tb.sv`
- `tb/crc_tb.sv`
- Integration testing was done in `tb/tb.sv`.

## Simulation & Debugging
Simulation outputs were verified using **SimVision**, ensuring correct handshake signals and data flow. ![Waveform debugging screenshot](output waveforms/simvision_waveform.png)


## Conclusion
The code successfully parses the headers and forwards the payload to the FIFO buffer.  
