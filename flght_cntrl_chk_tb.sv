module flght_cntrl_chk_tb();

logic clk;
logic rst_n;
logic vld;
logic inertial_cal;
logic [15:0]d_ptch;
logic [15:0]d_roll;
logic [15:0]d_yaw;
logic [15:0]ptch;
logic [15:0]roll;
logic [15:0]yaw;
logic [8:0]thrst;

logic [10:0]frnt_spd;
logic [10:0]bck_spd;
logic [10:0]lft_spd;
logic [10:0]rght_spd;

logic [11:0]frnt_spd_resp;
logic [11:0]bck_spd_resp;
logic [11:0]lft_spd_resp;
logic [11:0]rght_spd_resp;

// 108 bit wide 2000 entry stimulus vector
reg [107:0]stim_mem[0:1999];
// 108 bit wide single entry stimulus
reg [107:0]stim;
// 44 bit wide 2000 response stimulus vector
reg [43:0]resp_mem[0:1999];
// 44 bit wide single entry response
reg [43:0]resp;

// initialize DUT
flght_cntrl iDUT(.clk(clk),.rst_n(rst_n),.vld(vld),.d_ptch(d_ptch),.d_roll(d_roll),
                 .d_yaw(d_yaw),.ptch(ptch),.roll(roll),.yaw(yaw),.thrst(thrst),
                 .inertial_cal(inertial_cal),.frnt_spd(frnt_spd),.bck_spd(bck_spd),
		 .lft_spd(lft_spd),.rght_spd(rght_spd));

// set up clock
always #5
	clk = ~clk;

initial begin

// read each hex file into memory
$readmemh("flght_cntrl_stim_nq.hex", stim_mem);
$readmemh("flght_cntrl_resp_nq.hex", resp_mem);

// initialize clock
clk = 0;

// loop through the 2000 tests for stim and rsp
for (int i = 0; i < 2000; i++) begin

	// set stim to current vector
	stim = stim_mem[i];
	resp = resp_mem[i];

	// apply stimulus vector to the inputs for our DUT
	rst_n = stim[107];
	vld = stim[106];
	inertial_cal = stim[105];
	d_ptch = stim[104:89];
	d_roll = stim[88:73];
	d_yaw = stim[72:57];
	ptch = stim[56:41];
	roll = stim[40:25];
	yaw = stim[24:9];
	thrst = stim[8:0];

	frnt_spd_resp = resp[43:33];
	bck_spd_resp = resp[32:22];
	lft_spd_resp = resp[21:11];
	rght_spd_resp = resp[10:0];

	// compare the DUT output to the response vectors
	@(posedge clk) begin

		#1;
		
		if (frnt_spd !== frnt_spd_resp) begin
			$display("frnt_spd: %h does not equal the correct response: %h", frnt_spd, frnt_spd_resp);
			$stop;
		end

		if (bck_spd !== bck_spd_resp) begin
			$display("bck_spd: %h does not equal the correct response: %h", bck_spd, bck_spd_resp);
			$stop;
		end
	
		if (lft_spd !== lft_spd_resp) begin
			$display("lft_spd: %h does not equal the correct response: %h", lft_spd, lft_spd_resp);
			$stop;
		end

		if (rght_spd !== rght_spd_resp) begin
			$display("rght_spd: %h does not equal the correct response: %h", rght_spd, rght_spd_resp);
			$stop;
		end

	end
	
end

$display("All stimulus tests passed, flght_cntrl seems to be working.");
$stop;

end

endmodule;
