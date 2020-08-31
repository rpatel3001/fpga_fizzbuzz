module uart_top(
    input clk,
    input rst,
    input [7:0] tx_data,
    input tx_valid,
    output tx_busy,
    output rx_valid,
    output rx_busy,
    output [7:0] rx_data);

    wire phy;
    
    uart_tx #(2) uart_tx_inst (clk, rst, tx_data, tx_valid, tx_busy, phy);
    uart_rx #(2) uart_rx_inst (clk, rst, phy, rx_valid, rx_busy, rx_data);

endmodule
