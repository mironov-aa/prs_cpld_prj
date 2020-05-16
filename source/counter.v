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
reg                             act_flg;
reg   [ACTIVE_CNT_WIDTH - 1:0]  act_cnt;
reg          [CNT_WIDTH - 1:0]  cnt;
//____________________________________________________________________________//
assign o_cnt = cnt;
//****************************************************************************//
always @( posedge i_clk or posedge i_rst or posedge i_cnt_rst ) begin
  if( i_rst ) begin
    act_cnt  <= 1'b0;
    act_flg  <= 1'b0;
    cnt      <= { CNT_WIDTH{1'b0} };
  end
  else if( i_cnt_rst ) begin
    cnt <= {CNT_WIDTH{1'b0}};
  end
  else if( i_cnt_en ) begin
    if( (act_cnt == {ACTIVE_CNT_WIDTH{1'b1}}) && (act_flg == 1'b0) ) begin
      act_flg  <= 1'b1;
      cnt      <= cnt + 1'b1;   
    end else begin
      if( i_cnt_clk ) begin
        act_cnt <= act_cnt + 1'b1;
      end else begin
        act_cnt <= 1'b0;
        act_flg <= 1'b0;
      end
    end
  end
end
endmodule
