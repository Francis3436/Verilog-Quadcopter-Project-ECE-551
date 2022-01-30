module SPI_mnrch_tb();

// input stimulus with respect to monarch
logic clk;
logic rst_n;
logic wrt;
reg MISO;
logic [15:0] wt_data;
// output stimulus with respect to monarch
logic SS_n;
logic SCLK;
logic MOSI;
logic INT;
reg done;
reg [15:0] rd_data;

// instatiate the DUT for NEMO
SPI_NEMO iNEMO(.SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(INT));

// instatiate the DUT for Monarch
SPI_mnrch iMNRCH(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .wrt(wrt), .cmd(wt_data), .done(done), .rd_data(rd_data));

// test
initial begin
 
   // intialize starting input values to avoid irregular propagation
   clk = 0;
   rst_n = 1;
   wt_data = 0;
   wrt = 0;
   MISO = 0;

   // reset
   @(posedge clk);
   rst_n = 0;
   @(negedge clk);
   rst_n = 1;

   /////////////////////////////////////////////
   // test 1: check the "who am i?" register //
   ///////////////////////////////////////////

   @(posedge clk);
   wt_data = 16'h8fxx;
   wrt = 1;

   @(posedge clk);
   wrt = 0;
   
   @(posedge done);
   if (rd_data[7:0] !== 8'h6a) begin
      $display("Reading from 0x0F returns %h instead of the value of 0x6A in test 1.", rd_data);
      $stop();
   end
   
   $display("SPI_mnrch passes test 1.");
   
   //////////////////////////////////////
   // test 2: configure interrupt pin //
   ////////////////////////////////////
    
   @(posedge clk);
   // set cmd for interrupt pin
   wt_data = 16'h0d02;
   wrt = 1;
   @(posedge clk);
   wrt = 0;

   // test if the NEMO is correctly set up
   fork
      begin : NEMO_setup_error
         repeat(50000) @(posedge clk);
         disable wait_for_NEMO_setup;
         $display("SPI_mnrch times out for NEMO_setup in test 2.");
         $stop();
      end

      begin : wait_for_NEMO_setup
         @(posedge iNEMO.NEMO_setup);
         disable NEMO_setup_error;
         $display("SPI_mnrch correctly sets up and NEMO_setup goes high in test 2.");
      end
   join

   $display("SPI_mnrch passes test 2.");

   /////////////////////////////////////////////
   // test 3: test writing/reading pitch low //
   ///////////////////////////////////////////
    
   @(posedge INT);
   @(posedge clk);
   wt_data = 16'ha2xx;
   wrt = 1;
   @(posedge clk)
   wrt = 0;

   // check if INT drops low
   fork
      begin : INT_error_test3
         repeat(8000000) @(posedge clk);
         disable wait_for_INT_test3;
         $display("Writing and reading data does not drop INT in test 3.");
         $stop();
      end

      begin : wait_for_INT_test3
         @(negedge INT);
         disable INT_error_test3;
         $display("Writing and reading data causes INT to correctly drop in test 3.");
      end
   join
    
   @(posedge done);

   if (rd_data[7:0] !== 8'h63) begin
      $display("wt_data: %h does not yield correct rd_data: 0x63 instead gives incorrect value: %h in test 3.", wt_data, rd_data);
      $stop();
   end
    
   $display("SPI_mnrch passes test 3.");

   //////////////////////////////////////////////
   // test 4: test writing/reading pitch high //
   ////////////////////////////////////////////
    
   @(posedge INT);
   
   @(posedge clk);
   wt_data = 16'ha3xx;
   wrt = 1;
   @(posedge clk);
   wrt = 0;
    
   @(posedge done);

   if (rd_data[7:0] !== 8'hcd) begin
      $display("wt_data: %h does not yield correct rd_data: 0xcd instead gives incorrect value: %h in test 4.", wt_data, rd_data);
      $stop();
   end
   
   $display("SPI_mnrch passes test 4."); 
    
   ////////////////////////////////////////////
   // test 5: test writing/reading roll low //
   //////////////////////////////////////////

   @(posedge clk);
   wt_data = 16'ha4xx;
   wrt = 1;
   @(posedge clk);
   wrt = 0;
    
   @(posedge done);

   if (rd_data[7:0] !== 8'h76) begin
      $display("wt_data: %h does not yield correct rd_data: 0x76 instead gives incorrect value: %h in test 5.", wt_data, rd_data);
      $stop();
   end

   $display("SPI_mnrch passes test 5.");
   
   /////////////////////////////////////////////
   // test 6: test writing/reading roll high //
   ///////////////////////////////////////////

   @(posedge clk);
   wt_data = 16'ha5xx;
   wrt = 1;
   @(posedge clk);
   wrt = 0;

   @(posedge done);

   if (rd_data[7:0] !== 8'hf1) begin
      $display("wt_data: %h does not yield correct rd_data: 0xf1 instead gives incorrect value: %h in test 6.", wt_data, rd_data);
      $stop();
   end

   $display("SPI_mnrch passes test 6.");
   
   ///////////////////////////////////////////
   // test 7: test writing/reading yaw low //
   /////////////////////////////////////////

   @(posedge clk);
   wt_data = 16'ha6xx;
   wrt = 1;
   @(posedge clk);
   wrt = 0;

   @(posedge done);

   if (rd_data[7:0] !== 8'h3d) begin
      $display("wt_data: %h does not yield correct rd_data: 0x3d instead gives incorrect value: %h in test 7.", wt_data, rd_data);
      $stop();
   end

   $display("SPI_mnrch passes test 7.");

   // SPI_mnrch passes all tests
    $display("SPI_mnrch seems to be working.");
   $stop();

   // SPI_mnrch passes all tests
   $display("SPI_mnrch seems to be working.");
   $stop();

end

// generate clk
always #1
   clk = ~clk;

endmodule
