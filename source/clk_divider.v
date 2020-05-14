module clk_divider
#( parameter DIVIDER_CNT_WIDTH = 2 )
( input  i_clk,
  input  i_rst,
  output o_clk );
//Fout = Fin / 2 ** DIVIDER_CNT_WIDTH
reg [DIVIDER_CNT_WIDTH - 1:0] counter;
assign o_clk = counter[DIVIDER_CNT_WIDTH - 1];
always @( posedge i_clk or posedge i_rst ) begin
  if( i_rst )
    counter <= {DIVIDER_CNT_WIDTH{1'b0}};
  else
    counter <= counter + 1'b1;
end
endmodule
