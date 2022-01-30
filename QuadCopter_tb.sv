module QuadCopter_tb();

wire SS_n, SCLK, MOSI, MISO, INT;
wire RX, TX;
wire [7:0] resp;				
wire cmd_sent, resp_rdy;
wire frnt_ESC, back_ESC, left_ESC, rght_ESC;

reg clk, RST_n;
reg [7:0] cmd;
reg [15:0] data;
reg send_cmd;
reg clr_resp_rdy;

CycloneIV iQUAD(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                .MOSI(MOSI),.INT(INT),.frnt_ESC(frnt_ESC),.back_ESC(back_ESC),
				            .left_ESC(left_ESC),.rght_ESC(rght_ESC));				  			

QuadCopter iDUT(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),
                .INT(INT),.RX(RX),.TX(TX),.FRNT(frnt_ESC),.BCK(back_ESC),
				            .LFT(left_ESC),.RGHT(rght_ESC));

RemoteComm iREMOTE(.clk(clk), .rst_n(RST_n), .RX(TX), .TX(RX), .cmd(cmd), .data(data),
                   .send_cmd(send_cmd), .cmd_sent(cmd_sent), .resp_rdy(resp_rdy),
					              .resp(resp), .clr_resp_rdy(clr_resp_rdy));


localparam SET_PTCH = 8'h02;              // set desired pitch as a signed 16-bit number                        
localparam SET_ROLL = 8'h03;              // set desired roll as a signed 16-bit number
localparam SET_YAW = 8'h04;               // set desired yaw as a signed 16-bit number
localparam SET_THRST = 8'h05;             // set desired thrust as an unsigned 9-bit number
localparam CALIBRATE = 8'h06;             // calibrate quadcopter and causes gyro calibration
localparam EMER_LAND = 8'h07;             // emergency land that sets all speeds to zero
localparam MTRS_OFF = 8'h08;              // turn motors off until we receive a calibration
 
localparam pos_ack = 8'ha5;               // response used for positive acknowledgement

localparam tolerance = 5;                 // tolerance between actual and desired ptch, roll, and yaw

always begin
   #10 clk = ~clk;
end


initial begin
   initialize();
   // tests the set commands for ptch, roll, yaw, and thrust
   // before calibration to make sure sending commands work
   test_send_cmd();  
   test_calibrate();
   $display("--------------------------");
   $display("All tests passed!");
   $stop();
end

`include "QuadCopter_tb_tasks.sv"

endmodule