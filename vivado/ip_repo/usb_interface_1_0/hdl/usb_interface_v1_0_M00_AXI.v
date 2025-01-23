//
//    Copyright (C) 2025 The University of Tokyo
//    
//    File:          /vivado/ip_repo/usb_interface_1_0/hdl/usb_interface_v1_0_M00_AXI.v
//    Project:       cw305-shell
//    Author:        Takuya Kojima in The University of Tokyo (tkojima@hal.ipc.i.u-tokyo.ac.jp)
//    Created Date:  23-01-2025 07:01:59
//    Last Modified: 23-01-2025 07:01:59
//


`timescale 1 ns / 1 ps

`include "def.v"
`define PULP_CELL

	module usb_interface_v1_0_M00_AXI #
	(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// The master will start generating data from the C_M_START_DATA_VALUE value
		parameter  C_M_START_DATA_VALUE	= 32'h00000000,
		// The master requires a target slave base address.
		// The master will initiate read and write transactions on the slave with base address specified here as a parameter.
		parameter  C_M_TARGET_SLAVE_BASE_ADDR	= 32'h00000000,
		// Width of M_AXI address bus.
		// The master generates the read and write addresses of width specified as C_M_AXI_ADDR_WIDTH.
		parameter integer C_M_AXI_ADDR_WIDTH	= 32,
		// Width of M_AXI data bus.
		// The master issues write data and accept read data where the width of the data bus is C_M_AXI_DATA_WIDTH
		parameter integer C_M_AXI_DATA_WIDTH	= 32,
		// Transaction number is the number of write
		// and read transactions the master will perform as a part of this example memory test.
		parameter integer C_M_TRANSACTIONS_NUM	= 4
	)
	(
		// Users to add ports here
		input wire [`WORD_B] i_addr,
		input wire [`WORD_B] i_write_data,
		input wire i_write_valid,
		output wire o_write_ready,
		output wire [`WORD_B] o_read_data,
		input wire i_read_req,
		output wire o_read_data_valid,

		// User ports ends
		// Do not modify the ports beyond this line

		// AXI clock signal
		input wire  M_AXI_ACLK,
		// AXI active low reset signal
		input wire  M_AXI_ARESETN,
		// Master Interface Write Address Channel ports. Write address (issued by master)
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_AWADDR,
		// Write channel Protection type.
		// This signal indicates the privilege and security level of the transaction,
		// and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_AWPROT,
		// Write address valid.
		// This signal indicates that the master signaling valid write address and control information.
		output wire  M_AXI_AWVALID,
		// Write address ready.
		// This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_AWREADY,
		// Master Interface Write Data Channel ports. Write data (issued by master)
		output wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_WDATA,
		// Write strobes.
		// This signal indicates which byte lanes hold valid data.
		// There is one write strobe bit for each eight bits of the write data bus.
		output wire [C_M_AXI_DATA_WIDTH/8-1 : 0] M_AXI_WSTRB,
		// Write valid. This signal indicates that valid write data and strobes are available.
		output wire  M_AXI_WVALID,
		// Write ready. This signal indicates that the slave can accept the write data.
		input wire  M_AXI_WREADY,
		// Master Interface Write Response Channel ports.
		// This signal indicates the status of the write transaction.
		input wire [1 : 0] M_AXI_BRESP,
		// Write response valid.
		// This signal indicates that the channel is signaling a valid write response
		input wire  M_AXI_BVALID,
		// Response ready. This signal indicates that the master can accept a write response.
		output wire  M_AXI_BREADY,
		// Master Interface Read Address Channel ports. Read address (issued by master)
		output wire [C_M_AXI_ADDR_WIDTH-1 : 0] M_AXI_ARADDR,
		// Protection type.
		// This signal indicates the privilege and security level of the transaction,
		// and whether the transaction is a data access or an instruction access.
		output wire [2 : 0] M_AXI_ARPROT,
		// Read address valid.
		// This signal indicates that the channel is signaling valid read address and control information.
		output wire  M_AXI_ARVALID,
		// Read address ready.
    	// This signal indicates that the slave is ready to accept an address and associated control signals.
		input wire  M_AXI_ARREADY,
		// Master Interface Read Data Channel ports. Read data (issued by slave)
		input wire [C_M_AXI_DATA_WIDTH-1 : 0] M_AXI_RDATA,
		// Read response. This signal indicates the status of the read transfer.
		input wire [1 : 0] M_AXI_RRESP,
		// Read valid. This signal indicates that the channel is signaling the required read data.
		input wire  M_AXI_RVALID,
		// Read ready. This signal indicates that the master can accept the read data and response information.
		output wire  M_AXI_RREADY
	);

	// registers for AXI4LITE
	// write transaction
	reg r_axi_awvalid, r_axi_wvalid, r_axi_bready;
	// read transaction
	reg r_axi_arvalid, r_axi_rready;
	//write address
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	r_axi_awaddr;
	//write data
	reg [C_M_AXI_DATA_WIDTH-1 : 0] 	r_axi_wdata;
	//read addresss
	reg [C_M_AXI_ADDR_WIDTH-1 : 0] 	r_axi_araddr;

	// register for command contorller
	reg [C_M_AXI_DATA_WIDTH-1 : 0] r_read_data;
	reg r_rvalid;
	reg r_read_req, r_read_req_delayed;
	reg r_write_valid, r_write_valid_delayed;
	
	// write ready control
	reg r_axi_awready, r_axi_wready;

	// edge detection for read and write requests
	wire w_raise_read_req;
	wire w_raise_write_valid;
	assign w_raise_read_req = r_read_req && ~r_read_req_delayed;
	assign w_raise_write_valid = r_write_valid && ~r_write_valid_delayed;

	//Adding the offset address to the base addr of the slave
	assign M_AXI_AWADDR	= C_M_TARGET_SLAVE_BASE_ADDR + r_axi_awaddr;
	//AXI 4 write data
	assign M_AXI_WDATA	= r_axi_wdata;
	assign M_AXI_AWPROT	= 3'b000;
	assign M_AXI_AWVALID	= r_axi_awvalid;
	//Write Data(W)
	assign M_AXI_WVALID	= r_axi_wvalid;
	//Set all byte strobes in this example
	assign M_AXI_WSTRB	= 4'b1111;
	//Write Response (B)
	assign M_AXI_BREADY	= r_axi_bready;
	//Read Address (AR)
	assign M_AXI_ARADDR	= C_M_TARGET_SLAVE_BASE_ADDR + r_axi_araddr;
	assign M_AXI_ARVALID	= r_axi_arvalid;
	assign M_AXI_ARPROT	= 3'b001;
	//Read and Read Response (R)
	assign M_AXI_RREADY = i_read_req;


	// output to command controller
	assign o_write_ready = r_axi_awready && r_axi_wready;
	assign o_read_data_valid = r_rvalid;
	assign o_read_data = r_read_data;


	// latch the request signals
	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin
			r_read_req <= 0;
			r_read_req_delayed <= 0;
			r_write_valid <= 0;
			r_write_valid_delayed <= 0;
		end else begin
			r_read_req <= i_read_req;
			r_read_req_delayed <= r_read_req;
			r_write_valid <= i_write_valid;
			r_write_valid_delayed <= r_write_valid;
		end
	end

	//--------------------
	//Write Address Channel
	//--------------------

	// The purpose of the write address channel is to request the address and
	// command information for the entire transaction.  It is a single beat
	// of information.

	// Note for this example the axi_awvalid/axi_wvalid are asserted at the same
	// time, and then each is deasserted independent from each other.
	// This is a lower-performance, but simplier control scheme.

	// AXI VALID signals must be held active until accepted by the partner.

	// A data transfer is accepted by the slave when a master has
	// VALID data and the slave acknoledges it is also READY. While the master
	// is allowed to generated multiple, back-to-back requests by not
	// deasserting VALID, this design will add rest cycle for
	// simplicity.

	// Since only one outstanding transaction is issued by the user design,
	// there will not be a collision between a new request and an accepted
	// request on the same clock cycle.

	always @(posedge M_AXI_ACLK) begin
		//Only VALID signals must be deasserted during reset per AXI spec
		//Consider inverting then registering active-low reset for higher fmax
		if (M_AXI_ARESETN == 0) begin
			r_axi_awvalid <= 1'b0;
		end else begin
			if (w_raise_write_valid) begin
				r_axi_awvalid <= 1'b1;
			end else if (M_AXI_AWREADY && r_axi_awvalid) begin
				//Address accepted by interconnect/slave (issue of M_AXI_AWREADY by slave)
				r_axi_awvalid <= 1'b0;
			end
		end
	end

	//--------------------
	//Write Data Channel
	//--------------------

	//The write data channel is for transfering the actual data.
	//The data generation is speific to the example design, and
	//so only the WVALID/WREADY handshake is shown here

	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin
			r_axi_wvalid <= 1'b0;
		end else if (w_raise_write_valid) begin
			//Signal a new address/data command is available by user logic
			r_axi_wvalid <= 1'b1;
 		end else if (M_AXI_WREADY && r_axi_wvalid) begin
			//Data accepted by interconnect/slave (issue of M_AXI_WREADY by slave)
			r_axi_wvalid <= 1'b0;
		end
	end

	// Write Ready control
	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin
			r_axi_awready <= 1'b0;
			r_axi_wready <= 1'b0;
		end else begin
			if (r_axi_awready && r_axi_wready) begin
				r_axi_awready <= 1'b0;
				r_axi_wready <= 1'b0;
			end else begin
				if (M_AXI_AWREADY) begin
					r_axi_awready <= 1'b1;
				end
				if (M_AXI_WREADY) begin
					r_axi_wready <= 1'b1;
				end
			end
		end
	end

	//----------------------------
	//Write Response (B) Channel
	//----------------------------

	//The write response channel provides feedback that the write has committed
	//to memory. BREADY will occur after both the data and the write address
	//has arrived and been accepted by the slave, and can guarantee that no
	//other accesses launched afterwards will be able to be reordered before it.

	//The BRESP bit [1] is used indicate any errors from the interconnect or
	//slave for the entire write burst. This example will capture the error.

	//While not necessary per spec, it is advisable to reset READY signals in
	//case of differing reset latencies between master/slave.

	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin
			r_axi_bready <= 1'b0;
		end else if (M_AXI_BVALID && ~r_axi_bready) begin
			// accept/acknowledge bresp with r_axi_bready by the master
			// when M_AXI_BVALID is asserted by slave
			r_axi_bready <= 1'b1;
		end else if (r_axi_bready) begin
		// deassert after one clock cycle
			r_axi_bready <= 1'b0;
		end
	end

	//----------------------------
	//Read Address Channel
	//----------------------------

	// A new axi_arvalid is asserted when there is a valid read address
	// available by the master. start_single_read triggers a new read
	// transaction
	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin
			r_axi_arvalid <= 1'b0;
		end else if (w_raise_read_req) begin
			//Signal a new read address command is available by user logic
			r_axi_arvalid <= 1'b1;
		end	else if (M_AXI_ARREADY && r_axi_arvalid) begin
			//RAddress accepted by interconnect/slave (issue of M_AXI_ARREADY by slave)
				r_axi_arvalid <= 1'b0;
		end
		// retain the previous value
	end


	//--------------------------------
	//Read Data (and Response) Channel
	//--------------------------------

	//The Read Data channel returns the results of the read request
	//The master will accept the read data by asserting axi_rready
	//when there is a valid read data available.
	//While not necessary per spec, it is advisable to reset READY signals in
	//case of differing reset latencies between master/slave.



	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin
			r_read_data <= 0;
			r_rvalid <= 0;
		end else begin
			r_rvalid <= M_AXI_RVALID;
			if (M_AXI_RVALID) begin
				r_read_data <= M_AXI_RDATA;
			end
		end
	end


	//Address/data pairs for this example. The read and write values should
	//match.
	//Modify these as desired for different address patterns.

	// Write address
	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin
			r_axi_awaddr <= 0;
		end else if (w_raise_write_valid) begin
			r_axi_awaddr <= i_addr;
		end
	end

	// Write data
	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin
			r_axi_wdata <= C_M_START_DATA_VALUE;
		end else if (w_raise_write_valid) begin
			r_axi_wdata <= i_write_data;
		end
	end

	//Read Addresses
	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin
			r_axi_araddr <= 0;
		end else if (w_raise_read_req) begin
			r_axi_araddr <= i_addr;
		end
	end

	// Crock domain crossing usb_clk -> m00_axi_aclk
	// address and write data
// `ifdef PULP_CELL
// 	pulp_cdc_4phase #(
// 		.T(logic [C_M_AXI_ADDR_WIDTH-1:0])
// 	) cdc_write_addr (
// 		.src_rst_ni(m00_axi_aresetn),
// 		.src_clk_i(usb_clk),
// 		.src_data_i(i_addr),
// 		.src_valid_i(i_write_valid),
// 		.src_ready_o(w_write_addr_ready),

// 		.dst_rst_ni(m00_axi_aresetn),
// 		.dst_clk_i(m00_axi_aclk),
// 		.dst_data_o(w_synced_write_addr),
// 		.dst_valid_o(w_synced_write_addr_valid),
// 		.dst_ready_i(M_AXI_AWREADY)
// 	);

// 	pulp_cdc_4phase #(
// 		.T(logic [C_M_AXI_DATA_WIDTH-1:0])
// 	) cdc_read_addr (
// 		.src_rst_ni(m00_axi_aresetn),
// 		.src_clk_i(usb_clk),
// 		.src_data_i(i_addr),
// 		.src_valid_i(i_read_req),
// 		.src_ready_o(), // not used

// 		.dst_rst_ni(m00_axi_aresetn),
// 		.dst_clk_i(m00_axi_aclk),
// 		.dst_data_o(w_synced_read_addr),
// 		.dst_valid_o(w_synced_read_addr_valid),
// 		.dst_ready_i(M_AXI_ARREADY)
// 	);

// 	pulp_cdc_4phase #(
// 		.T(logic [C_M_AXI_DATA_WIDTH-1:0])
// 	) cdc_write_data (
// 		.src_rst_ni(m00_axi_aresetn),
// 		.src_clk_i(usb_clk),
// 		.src_data_i(i_write_data),
// 		.src_valid_i(i_write_valid),
// 		.src_ready_o(w_write_data_ready),
// 		.dst_rst_ni(m00_axi_aresetn),
// 		.dst_clk_i(m00_axi_aclk),
// 		.dst_data_o(w_synced_write_data),
// 		.dst_valid_o(w_synced_write_data_valid),
// 		.dst_ready_i(M_AXI_WREADY)
// 	);

// 	// Crock domain crossing m00_axi_aclk -> usb_clk
// 	// read data
// 	pulp_cdc_4phase #(
// 		.T(logic [C_M_AXI_DATA_WIDTH-1:0])
// 	) cdc_read_data (
// 		.src_rst_ni(m00_axi_aresetn),
// 		.src_clk_i(m00_axi_aclk),
// 		.src_data_i(r_read_data),
// 		.src_valid_i(r_rvalid),
// 		.src_ready_o(M_AXI_RREADY),
// 		.dst_rst_ni(m00_axi_aresetn),
// 		.dst_clk_i(usb_clk),
// 		.dst_data_o(o_read_data),
// 		.dst_valid_o(o_read_data_valid),
// 		.dst_ready_i(i_read_req)
// 	);

// `else
// 	cdc_4phase #(
// 		.DATA_WIDTH(C_M_AXI_ADDR_WIDTH),
// 		.SYNC_DEPTH(CDC_SYNC_DEPTH)
// 	) cdc_write_addr (
// 		.reset_n(m00_axi_aresetn),
// 		.clk_src(usb_clk),
// 		.i_data(i_addr),
// 		.i_valid(i_write_valid),
// 		.o_ready(w_write_addr_ready),
// 		.clk_dst(m00_axi_aclk),
// 		.o_data(w_synced_write_addr),
// 		.o_valid(w_synced_write_addr_valid),
// 		.i_ready(M_AXI_AWREADY)
// 	);

// 	cdc_4phase #(
// 		.DATA_WIDTH(C_M_AXI_DATA_WIDTH),
// 		.SYNC_DEPTH(CDC_SYNC_DEPTH)
// 	) cdc_read_addr (
// 		.reset_n(m00_axi_aresetn),
// 		.clk_src(usb_clk),
// 		.i_data(i_addr),
// 		.i_valid(i_read_req),
// 		.o_ready(), // not used
// 		.clk_dst(m00_axi_aclk),
// 		.o_data(w_synced_read_addr),
// 		.o_valid(w_synced_read_addr_valid),
// 		.i_ready(M_AXI_ARREADY)
// 	);

// 	cdc_4phase #(
// 		.DATA_WIDTH(C_M_AXI_DATA_WIDTH),
// 		.SYNC_DEPTH(CDC_SYNC_DEPTH)
// 	) cdc_write_data (
// 		.reset_n(m00_axi_aresetn),
// 		.clk_src(usb_clk),
// 		.i_data(i_write_data),
// 		.i_valid(i_write_valid),
// 		.o_ready(w_write_data_ready),
// 		.clk_dst(m00_axi_aclk),
// 		.o_data(w_synced_write_data),
// 		.o_valid(w_synced_write_data_valid),
// 		.i_ready(M_AXI_WREADY)
// 	);

// 	// Crock domain crossing m00_axi_aclk -> usb_clk
// 	// read data
// 	cdc_4phase #(
// 		.DATA_WIDTH(C_M_AXI_DATA_WIDTH),
// 		.SYNC_DEPTH(CDC_SYNC_DEPTH)
// 	) cdc_read_data (
// 		.reset_n(m00_axi_aresetn),
// 		.clk_src(m00_axi_aclk),
// 		.i_data(r_read_data),
// 		.i_valid(r_rvalid),
// 		.o_ready(M_AXI_RREADY),
// 		.clk_dst(usb_clk),
// 		.o_data(o_read_data),
// 		.o_valid(o_read_data_valid),
// 		.i_ready(i_read_req)
// 	);
// `endif


	assign debug_axi_write_addr_valid = r_axi_awready;
	assign debug_axi_write_data_valid = r_axi_wready;

endmodule