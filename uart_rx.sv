// uart_rx.sv
// Rajan Patel

// Simple UART receiver
// Fixed 8n1 scheme, LSB first

module uart_rx
  #(parameter CLKS_PER_BIT = 2) (
    input wire clk,
    input wire rst,

    input wire i_rx_data,

    output reg o_rx_valid = 0,
    output reg o_rx_busy = 0,
    output reg [7:0] o_rx_data = 1
  );
  
  localparam CNT_BITS = $clog2(CLKS_PER_BIT+1);

  typedef enum {IDLE, RX_ALIGN, RX_DATA, RX_STOP} state_t;
  state_t state = IDLE;
  
  reg [CNT_BITS-1:0] clk_cnt = 0;

  reg unsigned [2:0] rx_cnt = 0;
  reg [7:0] rx_data_reg = 0;
  reg rx_d1 = 1;
  reg rx_d2 = 1;

  always_ff @(posedge clk) begin
    if(rst) begin
      {rx_d2, rx_d1} <= 2'b11;
    end else begin
      {rx_d2, rx_d1} <= {rx_d1, i_rx_data};
    end
  end

  always @(*) begin
    case(state)
      default : begin
        o_rx_busy = 0;
        o_rx_valid = 0;
        o_rx_data = 0;
      end
      RX_ALIGN : begin
        o_rx_busy = 1;
        o_rx_valid = 0;
        o_rx_data = 0;
      end
      RX_DATA : begin
        o_rx_busy = 1;
        o_rx_valid = 0;
        o_rx_data = 0;
      end
      RX_STOP : begin
        o_rx_busy = 0;
        if(clk_cnt == 0) begin
          o_rx_valid = 1;
          o_rx_data = rx_data_reg;
        end else begin
          o_rx_valid = 0;
          o_rx_data = 0;
        end
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
          if(rx_d2 == 0) begin
            state <= RX_ALIGN;
            clk_cnt <= CNT_BITS'(CLKS_PER_BIT/2-1);
            rx_cnt <= 0;
          end
        end
        RX_ALIGN : begin
          if(clk_cnt == 0) begin
            clk_cnt <= CNT_BITS'(CLKS_PER_BIT-1);
            state <= RX_DATA;
          end else begin
            clk_cnt <= clk_cnt - 1;
          end
        end
        RX_DATA : begin
          if(clk_cnt == 0) begin
            clk_cnt <= CNT_BITS'(CLKS_PER_BIT-1);
            rx_data_reg[rx_cnt] <= rx_d2;
            if(rx_cnt == 7) begin
              state <= RX_STOP;
            end else begin
              rx_cnt <= rx_cnt + 1;
              state <= RX_DATA;
            end
          end else begin
            clk_cnt <= clk_cnt - 1;
          end
        end
        RX_STOP : begin
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