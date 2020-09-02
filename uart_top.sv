module uart_top(
    input clk,
    input rst,
    input rx_phy,
    output rx_busy,
    output tx_busy,
    output tx_phy);

    wire [7:0] rx_data;
    wire rx_valid;

    reg [7:0] tx_data;
    reg tx_valid;
    
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

    reg [7:0] tx_char = "A";
    always @(posedge clk) begin
        if(rst) begin

        end else begin
            if(rx_valid) begin
                tx_valid <= 1;
                if(rx_data == "c") begin
                    tx_data <= tx_char;
                end else begin
                    tx_data <= rx_data;
                end
            end else begin
                tx_valid <= 0;
                tx_data <= 0;
            end
        end
    end

endmodule
