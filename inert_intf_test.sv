module inert_intf_test(clk, RST_n, NEXT, LED, SS_n, SCLK, MOSI, MISO, INT);

input MISO, INT, NEXT, RST_n, clk;
output SS_n, SCLK, MOSI;
output [7:0] LED;
logic strt_cal, cal_done, vld, rst_n, next, stat;
logic [1:0] sel;                                      // from comand config
logic signed [15:0] ptch, roll, yaw;	                 // fusion corrected angles

rst_synch iSYNCH(.clk(clk), .RST_n(RST_n), .rst_n(rst_n));

PB_release iPB(.PB(NEXT), .clk(clk), .rst_n(rst_n), .released(next));

inert_intf iINERT(.clk(clk), .rst_n(rst_n), .INT(INT), .strt_cal(strt_cal), .MISO(MISO),
                  .cal_done(cal_done), .vld(vld), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), 
                  .ptch(ptch), .yaw(yaw), .roll(roll));

typedef enum reg [2:0] {IDLE, CAL, PITCH, ROLL, YAW} state_t;
state_t state, nxt_state;

always_ff @(posedge clk, negedge rst_n) begin
   if(!rst_n)
      state <= IDLE;
   else
      state <= nxt_state;
end

assign LED = (sel == 2'b00) ? {stat, 7'h00} :
	            (sel == 2'b01) ? (ptch[8:1]) :
	            (sel == 2'b10) ? roll[8:1] :
	             yaw[8:1];

always_comb begin
   stat = 1'b0;
   strt_cal = 1'b0;
   nxt_state = state;
   sel = 2'b00;
   case(state)
      IDLE : begin
         if(next) begin
            strt_cal = 1'b1;
            nxt_state = CAL;
         end
      end
      CAL : begin
         stat = 1'b1;
         if(cal_done)
            nxt_state = PITCH;
      end
      PITCH : begin
         if(next) begin
            nxt_state = ROLL;
            sel = 2'b01;
         end
      end
      ROLL : begin
         if(next) begin
            nxt_state = YAW;
            sel = 2'b10;
         end
      end
      // YAW : 
      default : begin
         if(next) begin
            nxt_state = PITCH;
            sel = 2'b11;
         end
      end
   endcase
end
   
endmodule










