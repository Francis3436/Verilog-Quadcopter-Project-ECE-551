module inert_intf_tb();

logic start_cal, SS_n, SCLK, MISO, MOSI;
logic clk, rst_n, INT, strt_cal, cal_done, vld; // from comand config
logic signed [15:0] ptch, roll, yaw;            // fusion corrected angles

SPI_iNEMO2 iNEMO(.SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(INT));
inert_intf iINERT(.clk(clk), .rst_n(rst_n), .ptch(ptch), .roll(roll), .yaw(yaw), .strt_cal(strt_cal), .cal_done(cal_done),
                .vld(vld), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .INT(INT));

initial begin
 
   clk = 1'b0;

   // reset the interface
   rst_n = 1'b0;
   // assert start calibration
   strt_cal = 1'b0;
   // wait for power on reset to go high
   @(posedge iNEMO.POR_n);
   rst_n = 1'b1;

   ////////////////////////////////////////////////////
   // test 1: check if the NEMO is correctly set up //
   //////////////////////////////////////////////////
    
   fork
      begin : NEMO_setup_error
         repeat(80000) @(posedge clk);
         disable wait_for_NEMO_setup;
         $display("The inertial interface times out for NEMO_setup in test 1.");
         $stop();
      end

      begin : wait_for_NEMO_setup
         @(posedge iNEMO.NEMO_setup);
         disable NEMO_setup_error;
         $display("The inertial interface correctly sets up and NEMO_setup goes high in test 1.");
      end
   join

   ////////////////////////////////////////////////////////////
   // test 2: start calibration and check if done correctly //
   //////////////////////////////////////////////////////////
    
   // assert start calibration for one clock cycle
   @(posedge clk);
   strt_cal = 1'b1;

   @(posedge clk);
   strt_cal = 1'b0;
   
   // test if calibration is done correctly
   fork
      begin : strt_cal_error
         repeat(2000000) @(posedge clk);
         disable wait_for_strt_cal;
         $display("The inertial interface times out for strt_cal in test 2.");
         $stop();
      end

      begin : wait_for_strt_cal
         @(posedge cal_done);
         disable strt_cal_error;
         $display("The inertial interface correctly asserts cal done in test 2.");
      end
   join
    
   //////////////////////////////////////////////////////////////
   // test 3: run 8 sets of data making sure valid is working //
   ////////////////////////////////////////////////////////////
    
   fork
      begin : vld_error
         repeat(18000000) @(posedge clk);
         disable wait_for_vld;
         $display("The inertial interface times out for receiving 8 sets of valid data in test 3.");
         $stop();
      end

      begin : wait_for_vld
         // wait for 8 sets of data to test the analog signals for pitch, roll, and yaw
         repeat(8) @(posedge vld);
         disable vld_error;
         $display("The inertial interface correctly receives 8 sets of valid data in test 3.");
      end
   join

   $display("The inertial interface seems to be working correctly.");
   $stop();

end

always begin
   #5 clk = ~clk;
end

endmodule