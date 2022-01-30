module ESC_interface_tb();

logic clk_stim, rst_n_stim, wrt_stim;
logic [10:0] SPEED_stim;
logic PWM_stim;
logic [12:0] multiplier;
logic [13:0] adder;
logic [13:0] flop1;
logic [13:0] negcount;
logic rst2_n;

ESC_interface iDUT(.clk(clk_stim), .rst_n(rst_n_stim), .wrt(wrt_stim), .SPEED(SPEED_stim), .PWM(PWM_stim));

initial begin
    ///////Test 1 (tests a high value to make sure the multiplier, adder, and flops work correctly)/////////
    SPEED_stim = 1000;
    clk_stim = 0;
    rst_n_stim = 0;
    wrt_stim = 0;
    #5;

    @(negedge clk_stim);
    @(negedge clk_stim) rst_n_stim = 1;
    @(negedge clk_stim) wrt_stim = 1;
    @(negedge clk_stim) wrt_stim = 0;

    if (multiplier != 3000) begin
        $display("MATH ERROR");
        $stop;
    end

    #5;

    if(adder != 9250) begin
        $display("MATH ERROR");
        $stop;
    end

    if(flop1 != 9250) begin
        $display("MATH ERROR");
        $stop;
    end

    if(negcount != 9249) begin
        $display("Math error");
        $stop;
    end

    repeat(9249) @(posedge clk_stim);

    if(flop1 != 0) begin
        $display("Math error");
        $stop;
    end
    
    if(rst2_n != 0) begin
        $display("Math error");
        $stop;
    end

    if(PWM_stim != 1) begin
        $display("Math error");
        $stop;
    end


/////////Test 2(resets values to check all functions again with smaller values that should not have any chance of creating overflow)/////
    SPEED_stim = 620;
    clk_stim = 0;
    rst_n_stim = 0;
    wrt_stim = 0;
    #5;

    @(negedge clk_stim);
    @(negedge clk_stim) rst_n_stim = 1;
    @(negedge clk_stim) wrt_stim = 1;
    @(negedge clk_stim) wrt_stim = 0;


    if (multiplier != 1860) begin
        $display("MATH ERROR");
        $stop;
    end

    #5;

    if(adder != 8110) begin
        $display("MATH ERROR");
        $stop;
    end

    if(flop1 != 8110) begin
        $display("MATH ERROR");
        $stop;
    end

    if(negcount != 8109) begin
        $display("Math error");
        $stop;
    end

    repeat(8108) @(posedge clk_stim);

    if(flop1 != 0) begin
        $display("Math error");
        $stop;
    end
    
    if(rst2_n != 0) begin
        $display("Math error");
        $stop;
    end

    if(PWM_stim != 1) begin
        $display("Math error");
        $stop;
    end



////////Test 3(Testing with no original value to make the entire system rely on the addition fucntion in order for it to work)//////
    SPEED_stim = 0;
    clk_stim = 0;
    rst_n_stim = 0;
    wrt_stim = 0;
    #5;

    @(negedge clk_stim);
    @(negedge clk_stim) rst_n_stim = 1;
    @(negedge clk_stim) wrt_stim = 1;
    @(negedge clk_stim) wrt_stim = 0;


    if (multiplier != 0) begin
        $display("MATH ERROR");
        $stop;
    end

    #5;

    if(adder != 6250) begin
        $display("MATH ERROR");
        $stop;
    end

    if(flop1 != 6250) begin
        $display("MATH ERROR");
        $stop;
    end

    if(negcount != 6249) begin
        $display("Math error");
        $stop;
    end

    repeat(6248) @(posedge clk_stim);

    if(flop1 != 0) begin
        $display("Math error");
        $stop;
    end
    
    if(rst2_n != 0) begin
        $display("Math error");
        $stop;
    end

    if(PWM_stim != 1) begin
        $display("Math error");
        $stop;
    end
    
$display("tests passed nice poggers");
$stop;

end

always begin
    #5 clk_stim = ~clk_stim;
end


endmodule