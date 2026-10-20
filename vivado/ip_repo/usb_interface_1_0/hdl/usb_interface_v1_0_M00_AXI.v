//
//    Copyright (C) 2026 University of Tsukuba
//    
//    File:          /ip_repo/usb_interface_1_0/hdl/usb_interface_v1_0_M00_AXI.v
//    Project:       cw310-sandbox
//    Author:        Takuya Kojima in University of Tsukuba (tkojima@lila.cs.tsukuba.ac.jp)
//    Created Date:  17-10-2026 18:28:32
//    Last Modified: 19-10-2026 18:16:36
//



`timescale 1 ns / 1 ps

`include "def.v"

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
	reg r_axi_arvalid;
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
	reg r_write_busy;

	// edge detection for read requests
	wire w_raise_read_req;
	assign w_raise_read_req = r_read_req && ~r_read_req_delayed;
	wire w_write_done;
	assign w_write_done = r_write_busy && M_AXI_BVALID && r_axi_bready;

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
	assign o_write_ready = w_write_done;
	assign o_read_data_valid = r_rvalid;
	assign o_read_data = r_read_data;


	// latch the read request signals
	always @(posedge M_AXI_ACLK) begin
		if (M_AXI_ARESETN == 0) begin
			r_read_req <= 0;
			r_read_req_delayed <= 0;
		end else begin
			r_read_req <= i_read_req;
			r_read_req_delayed <= r_read_req;
		end
	end

	//-------------------------
	//Write Transaction control
	//------------------------
	always @(posedge M_AXI_ACLK) begin
		if (!M_AXI_ARESETN) begin
			r_write_busy  <= 1'b0;
			r_axi_awvalid <= 1'b0;
			r_axi_wvalid  <= 1'b0;
			r_axi_bready  <= 1'b0;
			r_axi_awaddr  <= 0;
			r_axi_wdata   <= C_M_START_DATA_VALUE;
		end else if (!r_write_busy) begin
			if (i_write_valid) begin
				r_axi_awaddr  <= i_addr;
				r_axi_wdata   <= i_write_data;
				r_axi_awvalid <= 1'b1;
				r_axi_wvalid  <= 1'b1;
				r_axi_bready  <= 1'b1;
				r_write_busy  <= 1'b1;
			end
		end else begin
			if (r_axi_awvalid && M_AXI_AWREADY)
				r_axi_awvalid <= 1'b0;
			if (r_axi_wvalid && M_AXI_WREADY)
				r_axi_wvalid <= 1'b0;
			if (w_write_done) begin
				r_axi_bready <= 1'b0;
				r_write_busy <= 1'b0;
			end
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
			r_rvalid <= M_AXI_RVALID && M_AXI_RREADY;
			if (M_AXI_RVALID && M_AXI_RREADY) begin
				r_read_data <= M_AXI_RDATA;
			end
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

endmodule