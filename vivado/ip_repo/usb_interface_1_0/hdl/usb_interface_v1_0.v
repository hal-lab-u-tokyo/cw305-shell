//
//    Copyright (C) 2025 The University of Tokyo
//    
//    File:          /vivado/ip_repo/usb_interface_1_0/hdl/usb_interface_v1_0.v
//    Project:       cw305-shell
//    Author:        Takuya Kojima in The University of Tokyo (tkojima@hal.ipc.i.u-tokyo.ac.jp)
//    Created Date:  23-01-2025 07:02:04
//    Last Modified: 23-01-2025 07:02:06
//

`timescale 1 ns / 1 ps

`include "def.v"

module usb_interface_v1_0 #
(
	// Users to add parameters here
	parameter RESET_CYCLES = 100,
	// User parameters ends
	// Do not modify the parameters beyond this line


	// Parameters of Axi Master Bus Interface M00_AXI
	parameter  C_M00_AXI_START_DATA_VALUE	= 32'h00000000,
	parameter  C_M00_AXI_TARGET_SLAVE_BASE_ADDR	= 32'h00000000,
	parameter integer C_M00_AXI_ADDR_WIDTH	= 32,
	parameter integer C_M00_AXI_DATA_WIDTH	= 32,
	parameter integer C_M00_AXI_TRANSACTIONS_NUM	= 4
) (
	// Users to add ports here
	input wire sys_clk,
	inout wire [`BYTE_B] usb_data,
	input wire [`FLIT_W-`BYTE_W-1:0] usb_addr,
	input wire usb_rd_n,
	input wire usb_wr_n,
	input wire usb_ce_n,
	input wire usb_trigger,
	output wire external_trigger,
	output wire sw_reset_n,
	input wire trigger_ready,

	// User ports ends
	// Do not modify the ports beyond this line


	// Ports of Axi Master Bus Interface M00_AXI

	input wire  m00_axi_aclk,
	input wire  m00_axi_aresetn,
	output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_awaddr,
	output wire [2 : 0] m00_axi_awprot,
	output wire  m00_axi_awvalid,
	input wire  m00_axi_awready,
	output wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_wdata,
	output wire [C_M00_AXI_DATA_WIDTH/8-1 : 0] m00_axi_wstrb,
	output wire  m00_axi_wvalid,
	input wire  m00_axi_wready,
	input wire [1 : 0] m00_axi_bresp,
	input wire  m00_axi_bvalid,
	output wire  m00_axi_bready,
	output wire [C_M00_AXI_ADDR_WIDTH-1 : 0] m00_axi_araddr,
	output wire [2 : 0] m00_axi_arprot,
	output wire  m00_axi_arvalid,
	input wire  m00_axi_arready,
	input wire [C_M00_AXI_DATA_WIDTH-1 : 0] m00_axi_rdata,
	input wire [1 : 0] m00_axi_rresp,
	input wire  m00_axi_rvalid,
	output wire  m00_axi_rready
);

	// wires for USB I/F
	wire [`WORD_B] w_addr_from_usb;
	wire [`WORD_B] w_usb_write_data;
	wire w_usb_write_valid;
	wire w_usb_write_ready;
	wire [`WORD_B] w_usb_read_data;
	wire w_usb_read_req;
	wire w_usb_read_valid;
	wire w_is_output;
	wire [`BYTE_B] w_usb_in_data;
	wire [`BYTE_B] w_usb_out_data;

	// Instantiation of Axi Bus Interface M00_AXI
	usb_interface_v1_0_M00_AXI # (
		.C_M_START_DATA_VALUE(C_M00_AXI_START_DATA_VALUE),
		.C_M_TARGET_SLAVE_BASE_ADDR(C_M00_AXI_TARGET_SLAVE_BASE_ADDR),
		.C_M_AXI_ADDR_WIDTH(C_M00_AXI_ADDR_WIDTH),
		.C_M_AXI_DATA_WIDTH(C_M00_AXI_DATA_WIDTH),
		.C_M_TRANSACTIONS_NUM(C_M00_AXI_TRANSACTIONS_NUM)
	) usb_interface_v1_0_M00_AXI_inst (

		.i_addr(w_addr_from_usb),
		.i_write_data(w_usb_write_data),
		.i_write_valid(w_usb_write_valid),
		.o_write_ready(w_usb_write_ready),
		.o_read_data(w_usb_read_data),
		.i_read_req(w_usb_read_req),
		.o_read_data_valid(w_usb_read_valid),

		.M_AXI_ACLK(m00_axi_aclk),
		.M_AXI_ARESETN(m00_axi_aresetn),
		.M_AXI_AWADDR(m00_axi_awaddr),
		.M_AXI_AWPROT(m00_axi_awprot),
		.M_AXI_AWVALID(m00_axi_awvalid),
		.M_AXI_AWREADY(m00_axi_awready),
		.M_AXI_WDATA(m00_axi_wdata),
		.M_AXI_WSTRB(m00_axi_wstrb),
		.M_AXI_WVALID(m00_axi_wvalid),
		.M_AXI_WREADY(m00_axi_wready),
		.M_AXI_BRESP(m00_axi_bresp),
		.M_AXI_BVALID(m00_axi_bvalid),
		.M_AXI_BREADY(m00_axi_bready),
		.M_AXI_ARADDR(m00_axi_araddr),
		.M_AXI_ARPROT(m00_axi_arprot),
		.M_AXI_ARVALID(m00_axi_arvalid),
		.M_AXI_ARREADY(m00_axi_arready),
		.M_AXI_RDATA(m00_axi_rdata),
		.M_AXI_RRESP(m00_axi_rresp),
		.M_AXI_RVALID(m00_axi_rvalid),
		.M_AXI_RREADY(m00_axi_rready)
	);

	// Add user logic here


	// Tri-state buffer for inout usb_data port
	genvar i;
	generate
		for (i = 0; i < 8; i = i + 1) begin : iobufgen
			IOBUF IOBUF_inst (
			.O(w_usb_in_data[i]),  // 1-bit output: Buffer output
			.I(w_usb_out_data[i]),  // 1-bit input: Buffer input
			.IO(usb_data[i]), // 1-bit inout: Buffer inout (connect directly to top-level port)
			.T(!w_is_output)  // 1-bit input: 3-state enable input
			);
		end
	endgenerate


	command_control #(
		.RESET_CYCLES(RESET_CYCLES)
	) command_control_inst (
		.clk(m00_axi_aclk),
		.reset_n(m00_axi_aresetn),

		.o_addr(w_addr_from_usb),
		.o_write_data(w_usb_write_data),
		.o_write_valid(w_usb_write_valid),
		.i_write_ready(w_usb_write_ready),
		.i_read_data(w_usb_read_data),
		.o_read_req(w_usb_read_req),
		.i_read_valid(w_usb_read_valid),
		.o_sw_reset_n(sw_reset_n),

		.o_response(w_usb_out_data),
		.usb_rd_n(usb_rd_n),
		.usb_wr_n(usb_wr_n),
		.usb_ce_n(usb_ce_n),
		.usb_flit_data({usb_addr, w_usb_in_data}),
		.usb_isout(w_is_output)
	);

	cdc_pulse cdc_pulse_inst (
		.reset_n(m00_axi_aresetn),
		.clk_src(m00_axi_aclk),
		.src_pulse(usb_trigger),
		.clk_dst(sys_clk),
		.dst_pulse(external_trigger),
		.dst_ready(trigger_ready)
	);


	// User logic ends


endmodule
