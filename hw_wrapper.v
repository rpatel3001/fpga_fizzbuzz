module hw_wrapper(
    input sysclk,
    input [1:0] sw,
    input [3:0] btn,
    input uart_rx,
    output uart_tx,
    output [3:0] led);

    uart_top #(.CLKS_PER_BIT(125000000/115200))
    uart_top_inst (
              .clk(sysclk),
              .rst(btn[0]),
              .rx_phy(uart_rx),
              .rx_busy(led[0]),
              .tx_busy(led[1]),
              .tx_phy(uart_tx));
    
endmodule
