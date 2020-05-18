module counter
#( parameter CNT_WIDTH = 8 )
( input  wire                   i_clk,
  input  wire                   i_rst,
  input  wire                   i_cnt_en,
  input  wire                   i_cnt_clk,
  input  wire                   i_cnt_rst,
  output wire [CNT_WIDTH - 1:0] o_cnt         );
//____________________________________________________________________________//
localparam ACTIVE_CNT_WIDTH = 4;
//____________________________________________________________________________//
reg   [ACTIVE_CNT_WIDTH - 1:0]  act_cnt;
reg          [CNT_WIDTH - 1:0]  cnt;
//____________________________________________________________________________//
wire cnt_inc;
//____________________________________________________________________________//
assign o_cnt   = cnt;
assign cnt_inc = ( act_cnt == {ACTIVE_CNT_WIDTH{1'b1}} )
//____________________________________________________________________________//
always @( posedge i_clk or posedge i_rst ) begin : s_act_lvl_counter
  if( i_rst ) begin
    act_cnt <= {ACTIVE_CNT_WIDTH{1'b0}}
  end
  else if( i_cnt_clk ) begin
    if( act_cnt != {ACTIVE_CNT_WIDTH{1'b1}} ) begin
      act_cnt <= act_cnt + 1'b1;
    end
  end else begin
    act_cnt <= {ACTIVE_CNT_WIDTH{1'b0}}
  end
end
always @( posedge cnt_inc or posedge i_rst or posedge i_cnt_rst ) begin :cnt_inc
  if( i_rst ) begin
    cnt <= { CNT_WIDTH{1'b0} };
  end
  else if( i_cnt_rst ) begin
    cnt <= { CNT_WIDTH{1'b0} };
  end else begin
    if( i_cnt_en ) begin
      cnt <= cnt + 1'b1;
    end  
  end  
end
endmodule
