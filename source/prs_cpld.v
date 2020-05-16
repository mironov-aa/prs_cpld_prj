module prs_cpld
#( parameter NUMBER_OF_COUNTERS = 16, 
   parameter COUNTERS_WIDTH     = 8  )
( input  wire [NUMBER_OF_COUNTERS - 1:0] i_cnt_channels,
  input  wire                            i_clk,
  input  wire                            i_rst_n,
  //SPI interface
  output wire                            o_miso,
  input  wire                            i_mosi,
  input  wire                            i_sck,
  input  wire                            i_ssel_n );
//____________________________________________________________________________//
localparam IDLE           = 2'b00;
localparam READ_COUNTERS  = 2'b01;
localparam RESET_COUNTERS = 2'b10;
//____________________________________________________________________________//
reg [NUMBER_OF_COUNTERS - 1:0] counters_enable;
reg                      [1:0] state;
reg                      [1:0] next_state;
//____________________________________________________________________________//
wire [ ( NUMBER_OF_COUNTERS * COUNTERS_WIDTH ) - 1:0] counters_output;
wire                                                  counters_reset;
wire                                                  data_rdy;
wire                       [NUMBER_OF_COUNTERS - 1:0] cmd_data;
wire                                                  cmd_valid;
wire                                                  clk_div;
wire                                                  spi_busy_flg;
wire                                                  spi_idle_flg;
wire                                                  spi_data_req;
//____________________________________________________________________________//
assign data_rdy       = ( state == READ_COUNTERS  );
assign counters_reset = ( state == RESET_COUNTERS );
//____________________________________________________________________________//
//Clk divider
clk_divider #(
  .DIVIDER_CNT_WIDTH ( 4 )
) clk_divider_inst (
  .i_clk            ( i_clk    ),
  .i_rst            ( !i_rst_n ),
  .o_clk            ( clk_div  )     
);
//SPI
spi_slave #( 
  .TX_BUFF_BITS  ( NUMBER_OF_COUNTERS * COUNTERS_WIDTH ),
  .RX_BUFF_BITS  ( NUMBER_OF_COUNTERS                  ) 
) spi_slave_inst (
  .i_clk        ( i_clk           ),
  .i_rst        ( !i_rst_n        ),
  .o_busy       ( spi_busy_flg    ),
  .o_idle       ( spi_idle_flg    ),
  .i_TX_buff    ( counters_output ),
  .i_TX_valid   ( data_rdy        ),
  .o_TX_req     ( spi_data_req    ),
  .o_RX_buff    ( cmd_data        ),
  .o_RX_valid   ( cmd_valid       ),
  .o_miso       ( o_miso          ),
  .i_ssel_n     ( i_ssel_n        ),
  .i_mosi       ( i_mosi          ),
  .i_sck        ( i_sck           )
);
//Counters
genvar i;
generate
  for( i = 0; i < NUMBER_OF_COUNTERS; i = i + 1 ) begin : mdl_inst_gen_block
    counter #( 
      .CNT_WIDTH   ( COUNTERS_WIDTH ) 
    ) counter_inst (
      .i_clk      ( clk_div                              ),
      .i_rst      ( !i_rst_n                             ),
      .i_cnt_en   ( counters_enable[i]                   ),  
      .i_cnt_clk  ( i_cnt_channels[i]                    ),
      .i_cnt_rst  ( counters_reset                       ),
      .o_cnt      ( counters_output[(COUNTERS_WIDTH + (COUNTERS_WIDTH * i)) - 1:
                                     COUNTERS_WIDTH * i] )
    );  
  end
endgenerate
//****************************************************************************//
always @( posedge i_clk or negedge i_rst_n ) begin
  if( !i_rst_n ) begin
    counters_enable <= {NUMBER_OF_COUNTERS{1'b0}};
  end
  else if( cmd_valid ) begin   
    counters_enable <= cmd_data;
  end
end
//state register
always @( posedge i_clk or negedge i_rst_n ) begin
  if( !i_rst_n ) begin
    state <= IDLE;
  end else begin
    state <= next_state;
  end
end
//next state logic
always @* begin
  case( state )
    IDLE: begin
      if( spi_data_req )
        next_state = READ_COUNTERS;
      else
        next_state = IDLE;
    end
    READ_COUNTERS: begin
      if( spi_busy_flg )
        next_state = RESET_COUNTERS;
      else if( spi_idle_flg )
        next_state = IDLE;
      else
        next_state = READ_COUNTERS;
    end
    RESET_COUNTERS: begin
        next_state = IDLE;
    end
    default:
      next_state = IDLE;
  endcase
end
endmodule
