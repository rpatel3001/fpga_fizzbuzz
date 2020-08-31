// uart_tx.sv
// Rajan Patel

// Simple UART transmitter
// Fixed 8n1 scheme, LSB first

module uart_tx #(
    parameter CLKS_PER_BIT = 10)
  ( input wire clk,
    input wire rst,

    input wire [7:0] i_tx_data,
    input wire i_tx_valid,

    output reg o_tx_busy = 0,
    output reg o_tx_data = 1
  );
  
  localparam CNT_BITS = $clog2(CLKS_PER_BIT+1);

  typedef enum {IDLE, TX_START, TX_DATA, TX_STOP} state_t;
  state_t state = IDLE;
  
  reg [CNT_BITS-1:0] clk_cnt = 0;

  reg unsigned [2:0] tx_cnt = 0;
  reg [7:0] tx_data_reg = 0;

  always @(state) begin
    case(state)
      default : begin
        o_tx_data = 1;
        o_tx_busy = 0;
      end
      TX_START : begin
        o_tx_data = 0;
        o_tx_busy = 1;
      end
      TX_DATA : begin
        o_tx_data = tx_data_reg[tx_cnt];
        o_tx_busy = 1;
      end
      TX_STOP : begin
        o_tx_data = 1;
        o_tx_busy = 1;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    if(rst) begin
      state <= IDLE;
    end else begin
      case(state)
        default : begin
          state <= IDLE;
          if(i_tx_valid) begin
            tx_data_reg <= i_tx_data;
            clk_cnt <= CNT_BITS'(CLKS_PER_BIT-1);
            state <= TX_START;
          end
        end
        TX_START : begin
          if(clk_cnt == 0) begin
            clk_cnt <= CNT_BITS'(CLKS_PER_BIT-1);
            state <= TX_DATA;
            tx_cnt <= 0;
          end else begin
            clk_cnt <= clk_cnt - 1;
          end
        end
        TX_DATA : begin
          if(clk_cnt == 0) begin
            clk_cnt <= CNT_BITS'(CLKS_PER_BIT-1);
            if(tx_cnt == 7) begin
              state <= TX_STOP;
            end else begin
              tx_cnt <= tx_cnt + 1;
              state <= TX_DATA;
            end
          end else begin
            clk_cnt <= clk_cnt - 1;
          end
        end
        TX_STOP : begin
          if(clk_cnt == 0) begin
            state <= IDLE;
          end else begin
            clk_cnt <= clk_cnt - 1;
          end
        end
      endcase
    end
  end
endmodule
