module cmd_cfg_tb();

logic clk, rst_n;                      // system clock and active low reset

logic RX, TX;                          // bit recieved and transmitted by UART

logic strt_cal, cal_done;              // status signals for calibration

logic inertial_cal, motors_off;        // status signals from command configuration

logic [15:0] d_ptch, d_roll, d_yaw;    // pitch, roll, and yaw readings from qaudcopter
logic [8:0] thrst;                     // thrust from quadcopter

logic [7:0] cmd, resp;                 // command opcode and response back to remote
logic [15:0] data;                     // data to accompany command

logic [7:0] comm_cmd, comm_resp;       // stimulus command opcode and response for remote comm
logic [15:0] comm_data;                // stimulus data to accompany stimulus command

logic send_cmd, cmd_sent;              // begins and signifies the end of transmission of command
logic cmd_rdy, clr_cmd_rdy;            // indicates and clears when the command has been received 

logic send_resp, resp_sent;            // begins and signifies the end of of transmission of response
logic resp_rdy, clr_resp_rdy;          // indicates and clears when the response has been received

localparam SET_PTCH = 8'h02;           // set desired pitch as a signed 16-bit number
localparam SET_ROLL = 8'h03;           // set desired roll as a signed 16-bit number
localparam SET_YAW = 8'h04;            // set desired yaw as a signed 16-bit number
localparam SET_THRST = 8'h05;          // set desired thrust as an unsigned 9-bit number
localparam CAL = 8'h06;                // calibrate quadcopter and causes gyro calibration to occur
localparam EMER_LAND = 8'h07;          // emergency land that sets all speeds to zero
localparam MTRS_OFF = 8'h08;           // turn motors off until we receive a calibration
 
localparam pos_ack = 8'ha5;            // response used for positive acknowledgement
 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// RemoteComm DUT which receives stimulus from testbench and sends data back and forth with UART_comm through UART DUT //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
RemoteComm iRMT(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .cmd(comm_cmd), .data(comm_data), .send_cmd(send_cmd), 
                .cmd_sent(cmd_sent), .resp_rdy(resp_rdy), .resp(comm_resp), .clr_resp_rdy(1'b0));

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// UART_comm DUT which sends data back and forth with RemoteComm through UART and receives responses and sends command from cmd_cfg //
/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
UART_comm iCOMM(.clk(clk), .rst_n(rst_n), .RX(TX), .TX(RX), .resp(resp), .send_resp(send_resp), .resp_sent(resp_sent), 
                .cmd_rdy(cmd_rdy), .cmd(cmd), .data(data), .clr_cmd_rdy(clr_cmd_rdy));

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// cmd_cfg DUT which receives command and data from UART_comm and outputs control signals and desired pitch, roll, yaw, and thrust //
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
cmd_cfg iCFG(.clk(clk), .rst_n(rst_n), .cmd_rdy(cmd_rdy), .cmd(cmd), .cal_done(cal_done), .data(data), .clr_cmd_rdy(clr_cmd_rdy), 
             .resp(resp), .send_resp(send_resp), .d_ptch(d_ptch), .d_roll(d_roll), .d_yaw(d_yaw), .thrst(thrst),
             .strt_cal(strt_cal), .inertial_cal(inertial_cal), .motors_off(motors_off));

///////////////////////////////////////////////
// generate clock signal to run all modules //
///////////////////////////////////////////// 
 
always begin
   #5 clk = ~clk;
end

///////////////////////////////////////////////////////
// run task suite going through all command opcodes //
///////////////////////////////////////////////////// 

initial begin
 
   // set input values to avoid irregular propagation
	  clk = 1'b0;
	  rst_n = 1'b1;
	
   // assert and deassert reset to cover a positive and negative edge
   rst_n = 1'b0;
   @(posedge clk);
   @(negedge clk);
   rst_n = 1'b1;
    
   // checking command for pitch
   @(posedge clk);
   send_test_cmd(SET_PTCH, 16'h5632);
   check_resp();
   test_ptch(16'h5632);

   // checking command for roll
   send_test_cmd(SET_ROLL, 16'h3214);
   check_resp();
   test_roll(16'h3214);

   // checking command for yaw
   send_test_cmd(SET_YAW, 16'h7877);
   check_resp();
   test_yaw(16'h7877);

   // checking command for thrust
   send_test_cmd(SET_THRST, 16'h343x);
   check_resp();
   test_thrst(16'h343x);
   
   // checking command for calibration
   send_test_cmd(CAL, 16'h8136);

   // checking if strt_cal is indeed asserted
   wait_strt_cal();
   @(posedge clk);
   @(negedge clk);
   test_inertial_cal(1'b1);

   // need to manually assert and deassert cal done with no integreator yet
   @(posedge clk);
   cal_done = 1'b1;
   @(posedge clk);
   @(negedge clk);
   cal_done = 1'b0;
   
   @(posedge clk);
   test_inertial_cal(1'b0);
   check_resp();

   @(posedge clk);
   @(negedge clk);
   test_motors_on();
   
   // checking if emergency landing works properly by setting values to 0
   send_test_cmd(EMER_LAND, 16'h5757); 
   check_resp();
   test_emer_land();

   // checks if the motors are asserted as off wehn values are set to 0
   send_test_cmd(MTRS_OFF, 16'h3339); 
   check_resp();
   test_motors_off();
      
   $display("cmd_cfg passses all tests.");
   $stop();
   
end


//////////////////////////////////////////////////////////////
// task: test_motors_on - check if the motors are still on //
////////////////////////////////////////////////////////////

task test_motors_on;
   fork
      begin : timeout_motors_on
         repeat(80000) @(posedge clk);
         disable motors_on_setup;
         $display("test_motors_on: failed.");
         $stop();
      end
      begin : motors_on_setup
         if(!motors_off) begin
            disable timeout_motors_on;
            $display("test_motors_on: passed.");
         end
      end
   join
endtask

////////////////////////////////////////////////////////////////
// task: test_motors_off - check if the motors are still off //
//////////////////////////////////////////////////////////////

task test_motors_off;
   fork
      begin : timeout_motors_off
         repeat(80000) @(posedge clk);
         disable motors_off_setup;
         $display("test_motors_off: failed.");
         $stop();
      end
      begin : motors_off_setup
         if(motors_off) begin
            disable timeout_motors_off;
            $display("test_motors_off: passed.");
         end
      end
   join
endtask

//////////////////////////////////////////////////////////
// task: send_test_cmd - send a command to remote comm //
////////////////////////////////////////////////////////
 
task send_test_cmd;
   input [7:0] t_cmd;
   input [15:0] t_data;  
   // assigns inputs UART_comm
   comm_cmd = t_cmd;
   comm_data = t_data;  
   // signal sent to UART_comm
   send_cmd = 1'b1; 
   $display("Sending command: %h", t_cmd, " and data: %h.", t_data);
   @(posedge clk);
   send_cmd = 1'b0;
   @(posedge clk);
endtask
 
/////////////////////////////////////////////////////////////////////
// task: check_resp - check response received from command config //
///////////////////////////////////////////////////////////////////
 
task check_resp;
   fork
      begin : resp_rdy_timeout
         repeat (8000000) @(posedge clk);
         disable wait_for_resp_rdy;
         $display("check_resp: failed timeout for resp_rdy.");
         $stop();
      end	    
      begin : wait_for_resp_rdy
         @(posedge resp_rdy);
         if (resp == pos_ack) begin
            disable resp_rdy_timeout;
            $display("Acknowledged: %h.", resp);
         end
         else begin
            $display("check_resp: failed positive acknowledgement not sent in response.");
            $stop();
         end
      end
   join    
endtask

/////////////////////////////////////////////////////////////////
// task: test_ptch - test to make sure pitch is set correctly //
///////////////////////////////////////////////////////////////
 
task test_ptch;
   input [15:0] t_ptch; 
   if(t_ptch !== d_ptch) begin
      $display("test_ptch: failed pitch is incorrect value: %h instead of correct value: %h.", t_ptch, d_ptch);
      $stop();
   end
   else
      $display("test_pitch passed.");
endtask
 
////////////////////////////////////////////////////////////////
// task: test_roll - test to make sure roll is set correctly //
//////////////////////////////////////////////////////////////
 
task test_roll;
   input [15:0] t_roll;
   if(t_roll !== d_roll) begin
      $display("test_roll: failed roll is incorrect value: %h instead of correct value: %h.", t_roll, d_roll);
      $stop;
   end
   else
      $display("test_roll: passed.");
endtask
 
//////////////////////////////////////////////////////////////
// task: test_yaw - test to make sure yaw is set correctly //
////////////////////////////////////////////////////////////
 
task test_yaw;
   input [15:0] t_yaw;
   begin
      if (t_yaw !== d_yaw)
         $display("test_yaw: failed yaw is incorrect value: %h instead of correct value: %h.", t_yaw, d_yaw);
      else
         $display("test_yaw: passed.");
   end
endtask

//////////////////////////////////////////////////////////////////
// task: test_thrst - test to make sure thrst is set correctly //
////////////////////////////////////////////////////////////////
 
task test_thrst;
   input [8:0] t_thrst;
   begin
      if(t_thrst !== thrst) begin
         $display("test_thrst: failed thrst is incorrect value: %h instead of correct value: %h.", t_thrst, thrst);
         $stop();
      end
      else
         $display("test_thrst: passed.");
   end
endtask

//////////////////////////////////////////////////////////////////
// task: test_emer_land - make sure all speeds are set to zero //
////////////////////////////////////////////////////////////////
 
task test_emer_land; 
   begin
      if(d_ptch !== 16'b0) begin
         $display("test_emergency_land: failed incorrect value for d_ptch: %h.", d_ptch);
         $stop();
      end
      if(d_roll !== 16'b0) begin
         $display("test_emergency_land: failed incorrect value for d_roll: %h.", d_roll);
         $stop();
      end
      if(d_yaw !== 16'b0) begin
         $display("test_emergency_land: failed incorrect value for d_yaw: %h.", d_yaw);
         $stop();
      end
      if(thrst !== 8'b0) begin
         $display("test_emergency_land: failed incorrect value for thrst: %h.", thrst);
         $stop();
      end
      else 
         $display("test_emergency_land: passed.");
   end
endtask
 

///////////////////////////////////////////////////////
// task: wait_strt_cal - used to wait for start_cal //
/////////////////////////////////////////////////////

task wait_strt_cal;
   fork
      begin : strt_cal_error
         repeat(800000000) @(posedge clk);
         disable wait_for_strt_cal;
         $display("cmd_cfg never asserts start cal.");
      end
      begin : wait_for_strt_cal
         @(posedge strt_cal);
         disable strt_cal_error;
         $display("strt_cal asserted.");
      end
   join
   test_motors_on();
endtask

////////////////////////////////////////////////////////////
// task: test_inertial_cal - check if inertial_cal holds //
//////////////////////////////////////////////////////////

task test_inertial_cal;
   input t_inertial_cal;
   if (inertial_cal !== t_inertial_cal) begin
      $display("test_inertial_cal: failed inertial_cal is not held.");
      $stop();
   end
   $display("test_inertial_cal: passed.");
   /*
   fork
      begin : inertial_cal_timeout
         repeat(800000000) @(posedge clk);
         disable wait_for_inertial_cal;
         $display("test_inertial_cal: failed inertial_cal is not held.");
         $stop();
      end
      begin : wait_for_inertial_cal
         if (inertial_cal == t_inertial_cal) begin
            disable inertial_cal_timeout;
            $display("test_inertial_cal: passed.");
         end   
      end
   join
   */
endtask
   
endmodule
