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
wire [( NUMBER_OF_COUNTERS * COUNTERS_WIDTH ) - 1:0] counters_output;
wire                      [NUMBER_OF_COUNTERS - 1:0] counters_enable;
wire                                                 counters_reset;
wire                                                 clk_div;
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
  .i_clk           ( i_clk           ),
  .i_rst           ( !i_rst_n        ),
  .o_data_capt_st  ( counters_reset  ),
  .i_TX_buff       ( counters_output ),
  .o_RX_buff       ( counters_enable ),
  .o_miso          ( o_miso          ),
  .i_ssel_n        ( i_ssel_n        ),
  .i_mosi          ( i_mosi          ),
  .i_sck           ( i_sck           )
);
//Counters
genvar i;
generate
  for( i = 0; i < NUMBER_OF_COUNTERS; i = i + 1 ) begin : cnt_gen_block
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
endmodule
