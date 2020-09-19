// fifo.sv
// Rajan Patel

// Synchronous FIFO

module fifo
  #(parameter DWIDTH = 8) (
    input clk,
    input rst
  );