# Packet_parser_with_DMA_engine
(DMA Engine pending)

This code is for a system that parses 768 input data comprised of the following:
- 16 B of ethernet header (A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1A1)
- 20 B of IP header (B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2B2)
- 20 B of TCP header (C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3C3)
- 40 B of payload (D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099D4F40099)

The parser stores the header information and forwards the payload (only) to a 32x16 FIFO buffer.

The parser and FIFO were induvidually tested (see tb/fifo_tb.sv and tb/parser_tb.sv) before being integrated and tested in tb/tb.sv

The output signals were plotted on SimVision to verify correctness (handshake and the rest). Some debugging statements were also added at important location printing the below self-explanatory debug statements-

Word sent in testbench- a1a1a1a1
Word sent in testbench- a1a1a1a1
Word sent in testbench- a1a1a1a1
Word sent in testbench- a1a1a1a1
Word sent in testbench- b2b2b2b2
Word sent in testbench- b2b2b2b2
Word sent in testbench- b2b2b2b2
Word sent in testbench- b2b2b2b2
Word sent in testbench- b2b2b2b2
Word sent in testbench- c3c3c3c3
Word sent in testbench- c3c3c3c3
Word sent in testbench- c3c3c3c3
Word sent in testbench- c3c3c3c3
Word sent in testbench- c3c3c3c3
Write pointer- 0
Word sent in testbench- d4f40099
Write pointer- 1
Word sent in testbench- d4f40099
Write pointer- 2
Word sent in testbench- d4f40099
Write pointer- 3
Word sent in testbench- d4f40099
Write pointer- 4
Word sent in testbench- d4f40099
Write pointer- 5
Word sent in testbench- d4f40099
Write pointer- 6
Word sent in testbench- d4f40099
Write pointer- 7
Word sent in testbench- d4f40099
Write pointer- 8
Word sent in testbench- d4f40099
Write pointer- 9
Word sent in testbench- d4f40099
Read pointer- 0
FIFO OUT: d4f40099
Read pointer- 1
FIFO OUT: d4f40099
Read pointer- 2
FIFO OUT: d4f40099
Read pointer- 3
FIFO OUT: d4f40099
Read pointer- 4
FIFO OUT: d4f40099
Read pointer- 5
FIFO OUT: d4f40099
Read pointer- 6
FIFO OUT: d4f40099
Read pointer- 7
FIFO OUT: d4f40099
Read pointer- 8
FIFO OUT: d4f40099
Read pointer- 9
FIFO OUT: d4f40099

The code is a success.
