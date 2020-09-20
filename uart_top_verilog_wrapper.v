module uart_top_verilog_wrapper(
    input clk,
    input rst,
    input rx_phy,
    output tx_phy,
    output tx_busy,
    output rx_busy);

    uart_top #(.CLKS_PER_BIT(125000000/115200))
    uart_top_inst (
              .clk(clk),
              .rst(rst),
              .rx_phy(rx_phy),
              .rx_busy(rx_busy),
              .tx_busy(tx_busy),
              .tx_phy(tx_phy));
    
endmodule
