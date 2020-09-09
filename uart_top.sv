// uart_top.sv
// Rajan Patel

// UART based FizzBuzz

module uart_top
  ( input clk,
    input rst,
    input rx_phy,
    output rx_busy,
    output tx_busy,
    output tx_phy
  );

    localparam CNT_MAX = 'd17;
    localparam CNT_DIGITS = int'($ceil($log10(CNT_MAX + 1)));
    localparam BCD_CNT_BITS = int'(CNT_DIGITS * 4);
    localparam [BCD_CNT_BITS-1:0] BCD_CNT_MAX = 'h17;

    wire [7:0] rx_data;
    wire rx_valid;

    reg [7:0] tx_data = 0;
    reg tx_valid = 0;
    reg tx_go = 0;

    reg rst_cnt = 0;
    reg inc_cnt = 0;
    reg [CNT_DIGITS-1:0][3:0] bcd_cnt = 0;

    reg [2:0] tx_cnt = 0;
    reg [CNT_DIGITS-1:0][7:0] tx_buf = 0;
    
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
            bcd_cnt <= 0;
        end else if (rst_cnt) begin
            bcd_cnt <= 1;
        end else if (inc_cnt) begin
            if(bcd_cnt == BCD_CNT_MAX) begin
                bcd_cnt <= 0;
            end else begin
                bcd_cnt[0] <= bcd_cnt[0] + 1;
                for (int i = 0; i < CNT_DIGITS; i++) begin
                    if(bcd_cnt[i] + 1 == 10) begin
                        bcd_cnt[i+1] <= bcd_cnt[i+1] + 1;
                        bcd_cnt[i] <= 0;
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        tx_valid <= 0;
        tx_data <= 0;
        if(!tx_busy) begin
            if(tx_cnt != 0) begin
                tx_data <= tx_buf[tx_cnt - 1];
                tx_valid <= 1;
                tx_cnt <= tx_cnt - 1;
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            tx_buf <= 0;
        end else begin
            if(tx_go) begin
                tx_buf <= 0;
                if(rst_cnt || bcd_cnt == 0) begin
                    tx_cnt <= 1;
                    tx_buf[0] <= "0";
                end else begin
                    for (int i = 0; i < CNT_DIGITS; i++) begin
                        tx_buf[i] <= "0" + bcd_cnt[i];
                        if(bcd_cnt[i] != 0) begin
                            tx_cnt <= i + 1;
                        end
                    end
                end
            end
        end
    end

    always @(posedge clk) begin
        if(rst) begin
            rst_cnt <= 0;
            inc_cnt <= 0;
            tx_go <= 0;
        end else begin
            rst_cnt <= 0;
            inc_cnt <= 0;
            tx_go <= 0;
            if(rx_valid) begin
                if(rx_data == "r") begin
                    tx_go <= 1;
                    rst_cnt <= 1;
                end else if (rx_data == "n") begin
                    tx_go <= 1;
                    inc_cnt <= 1;
                end
            end
        end
    end

endmodule
