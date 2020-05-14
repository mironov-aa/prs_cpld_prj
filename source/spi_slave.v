module spi_slave
#( parameter TX_BUFF_BITS = 16,
   parameter RX_BUFF_BITS = 2 )
( input  wire                        i_clk,
  input  wire    			               i_rst,
  output wire    			               o_busy,
  //TX & RX logic
  input  wire [TX_BUFF_BITS - 1:0]   i_TX_buff,
  input  wire                        i_TX_valid,
  output wire                        o_TX_req, 
  output wire [RX_BUFF_BITS - 1:0]   o_RX_buff,
  output wire                        o_RX_valid
  //SPI Interface
  output wire                        o_miso,
  input  wire                        i_ssel_n,
  input  wire                        i_mosi,
  input  wire                        i_sck      );
//____________________________________________________________________________//
localparam IDLE         = 2'b00;
localparam DATA_REQ     = 2'b01;
localparam DATA_WR      = 2'b10;
localparam TRANSMISSION = 2'b11;
//____________________________________________________________________________//
reg [TX_BUFF_BITS - 1:0]  TX_buff;
reg                       TX_rdy;
reg [TX_BUFF_BITS - 1:0]  RX_buff;
reg                       RX_valid;  
reg                [1:0]  state;
reg                [1:0]  next_state;
//____________________________________________________________________________//
assign o_miso     = ( i_ssel_n )? ( 1'bZ ): 
                                  ( TX_buff[TX_BUFF_BITS - 1] );
assign o_busy     = ( state == TRANSMISSION );
assign o_RX_valid = ( state == IDLE );
assign o_TX_req   = ( state == DATA_REQ ) || ( state == DATA_WR);
assign o_RX_buff  = RX_buff;
assign o_RX_valid = RX_valid;
//_________FSM________________________________________________________________//
always @( posedge i_clk or posedge i_rst ) begin
  if( i_rst ) begin
    state <= IDLE;
  end else begin
    state <= next_state;
  end
end
always @* begin
  case( state )
    IDLE: begin
      if( !i_ssel_n )
        next_state = DATA_REQ;
      else
        next_state = IDLE;
    end
    DATA_REQ: begin
      if( i_ssel_n )
        next_state = IDLE;
      else if( i_TX_valid )
        next_state = DATA_WR;
      else
        next_state = DATA_REQ;
    end
    DATA_WR: begin
      if( i_ssel_n )
        next_state = IDLE;
      else if( TX_rdy )
        next_state = TRANSMISSION;
      else
        next_state = DATA_WR;
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
//_________SPI RX shift registers_____________________________________________//
always @( negedge i_sck or posedge i_rst ) begin
  if( i_rst )
    RX_buff <= {RX_BUFF_BITS{1'b0}};
  else if( state == TRANSMISSION ) begin
    //Receive in LSB, shift up to MSB
    RX_buff <= {RX_buff[( RX_BUFF_BITS - 2 ):0], i_mosi}; 
  end
end
//_________SPI TX shift registers_____________________________________________//
always @( posedge i_sck or posedge i_rst ) begin
  if( i_rst ) begin
    TX_rdy  <= 1'b0;
    TX_buff <= {TX_BUFF_BITS{1'b0}};
  else if( (state == DATA_WR) && (TX_rdy == 1'b0) ) begin
    TX_buff <= i_TX_buff;
    TX_rdy  <= 1'b1;
  end 
  else if( state == TRANSMISSION ) begin
    TX_rdy  <= 1'b0;
    //Send MSB first
    TX_buff <= {TX_buff[TX_BUFF_BITS - 2:0], 1'b1};
  end
end
endmodule
