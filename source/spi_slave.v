module spi_slave
#( parameter TX_BUFF_BITS = 16,
   parameter RX_BUFF_BITS = 2  )
( input  wire                      i_clk,
  input  wire                      i_rst,
  output wire                      o_data_capt_st,
  input  wire [TX_BUFF_BITS - 1:0] i_TX_buff,
  output wire [RX_BUFF_BITS - 1:0] o_RX_buff,
  //SPI Interface
  output wire                      o_miso,
  input  wire                      i_ssel_n,
  input  wire                      i_mosi,
  input  wire                      i_sck      );
//____________________________________________________________________________//
localparam IDLE              = 2'b00;
localparam CAPTURE           = 2'b01;
localparam DATA_RDY          = 2'b10;
localparam TRANSMISSION      = 2'b11;
localparam CLK_COUNTER_WIDTH = 8;
//____________________________________________________________________________//
reg      [TX_BUFF_BITS - 1:0] TX_buff;
reg                           TX_capt;
reg      [RX_BUFF_BITS - 1:0] RX_buff;
reg      [RX_BUFF_BITS - 1:0] RX_shft_reg;
reg [CLK_COUNTER_WIDTH - 1:0] clk_cnt;  
reg                     [1:0] state;
reg                     [1:0] next_state;
//____________________________________________________________________________//
assign o_miso         = ( i_ssel_n )? ( 1'bZ ): 
                                      ( TX_buff[TX_BUFF_BITS - 1] );
assign o_data_capt_st = ( state == DATA_RDY );
assign o_RX_buff      = RX_buff;  
//_________SPI TX shift registers_____________________________________________//
always @( posedge i_sck or posedge i_rst or posedge i_ssel_n) begin : s_TX_capt
  if( i_rst ) begin
    TX_capt <= 1'b0;
  end
  else if ( i_ssel_n ) begin
    TX_capt <= 1'b0;
  end
  else if ( TX_capt == 0 ) begin
    TX_capt <= 1'b1;
  end 
end
always @( posedge i_sck or posedge i_rst ) begin : s_TX_shift_reg
  if( i_rst ) begin
    TX_buff <= {TX_BUFF_BITS{1'b0}};
  end
  else if ( state == CAPTURE ) begin
    TX_buff <= i_TX_buff;
  end
  else if ( state == TRANSMISSION ) begin
    TX_buff <= {TX_buff[TX_BUFF_BITS - 2:0], 1'b1}; //Send MSB first
  end
end
//_________SPI RX shift registers_____________________________________________//
always @( negedge i_sck or posedge i_rst ) begin : s_RX_shift_reg
  if( i_rst ) begin     
    RX_shft_reg <= {RX_BUFF_BITS{1'b0}};
  end
  else if( state == TRANSMISSION ) begin
    //Receive in LSB, shift up to MSB
    RX_shft_reg <= {RX_shft_reg[( RX_BUFF_BITS - 2 ):0], i_mosi};
  end 
end
//_________RX buffer__________________________________________________________//
always @( negedge i_sck or posedge i_rst ) begin : s_RX_clk_counter
  if( i_rst ) begin
     clk_cnt <= {CLK_COUNTER_WIDTH{1'b0}};
  end
  else if( clk_cnt == RX_BUFF_BITS )
    clk_cnt <= {CLK_COUNTER_WIDTH{1'b0}};
  end else begin
    clk_cnt <= clk_cnt + 1'b1;
  end
end
always @( posedge i_clk or posedge i_rst ) begin : s_RX_buff_capture
  if( i_rst ) begin
    RX_buff <= {RX_BUFF_BITS{1'b0}};
  end
  else if( clk_cnt == RX_BUFF_BITS ) begin
    RX_buff <= RX_shft_reg;
  end
end
//_________FSM________________________________________________________________//
always @( posedge i_clk or posedge i_rst ) begin : s_fsm_state_reg
  if( i_rst ) begin
    state <= IDLE;
  end else begin
    state <= next_state;
  end
end
always @* begin : c_fsm_next_state_logic
  case( state )
    IDLE: begin
      if( !i_ssel_n )
        next_state = DATA_REQ;
      else
        next_state = IDLE;
    end
    CAPTURE: begin
      if( i_ssel_n )
        next_state = IDLE;
      else if( TX_capt )
        next_state = DATA_RDY;
      else
        next_state = CAPTURE;
    end
    DATA_RDY: begin
      if( i_ssel_n )
        next_state = IDLE;
      else
        next_state = TRANSMISSION;
    end
    TRANSMISSION: begin
      if( i_ssel_n )
        next_state = IDLE;
      else
        next_state = TRANSMISSION;
    end
    default:
      next_state   = IDLE;
  endcase
end
endmodule
