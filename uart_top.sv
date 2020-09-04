// uart_top.sv
// Rajan Patel

// UART based FizzBuzz

module uart_top(
    input clk,
    input rst,
    input rx_phy,
    output rx_busy,
    output tx_busy,
    output tx_phy);

    localparam CNT_MAX = 8;
    localparam CNT_BITS = $clog2(CNT_MAX + 1);

    wire [7:0] rx_data;
    wire rx_valid;

    reg [7:0] tx_data;
    reg tx_valid;

    reg [CNT_BITS:0] cnt = 0;
    
    uart_rx #(.CLKS_PER_BIT(2)) uart_rx_inst (
        .clk(clk), 
        .rst(rst), 
        .i_rx_data(rx_phy), 
        .o_rx_valid(rx_valid), 
        .o_rx_busy(rx_busy), 
        .o_rx_data(rx_data));

    uart_tx #(.CLKS_PER_BIT(2)) uart_tx_inst (
        .clk(clk), 
        .rst(rst), 
        .i_tx_data(tx_data), 
        .i_tx_valid(tx_valid), 
        .o_tx_busy(tx_busy), 
        .o_tx_data(tx_phy));

    always @(posedge clk) begin
        if(rst) begin
            tx_data <= 0;
            tx_valid <= 0;
            cnt <= 0;
        end else begin
            if(rx_valid) begin
                if(rx_data == "r") begin
                    tx_valid <= 1;
                    tx_data <= "0";
                    cnt <= 1;
                end else if (rx_data == "n") begin
                    tx_valid <= 1;
                    tx_data <= "0" + cnt;
                    if(cnt == CNT_MAX) begin
                        cnt <= 0;
                    end else begin
                        cnt <= cnt + 1;
                    end
                end else begin
                    tx_valid <= 0;
                    tx_data <= 0;
                end
            end else begin
                tx_valid <= 0;
                tx_data <= 0;
            end
        end
    end

endmodule
