//
//    Copyright (C) 2025 The University of Tokyo
//    
//    File:          /vivado/ip_repo/usb_interface_1_0/hdl/cdc_pulse.v
//    Project:       cw305-shell
//    Author:        Takuya Kojima in The University of Tokyo (tkojima@hal.ipc.i.u-tokyo.ac.jp)
//    Created Date:  23-01-2025 07:01:25
//    Last Modified: 23-01-2025 07:01:27
//

module cdc_pulse #(
	parameter SYNC_DEPTH = 2
)(
	input wire reset_n,
	// src channel
	input wire clk_src,
	input wire src_pulse,
	// dst channel
	input wire clk_dst,
	output wire dst_pulse,
	input wire dst_ready
);

	wire w_async_req;
	wire w_async_ack;

	cdc_pulse_sender #(
		.SYNC_DEPTH(SYNC_DEPTH)
	) sender0 (
		.reset_n(reset_n),
		.clk(clk_src),
		.i_pulse(src_pulse),
		.o_async_req(w_async_req),
		.i_async_ack(w_async_ack)
	);

	cdc_pulse_receiver #(
		.SYNC_DEPTH(SYNC_DEPTH)
	) receiver0 (
		.reset_n(reset_n),
		.clk(clk_dst),
		.o_pulse(dst_pulse),
		.i_ready(dst_ready),
		.i_async_req(w_async_req),
		.o_async_ack(w_async_ack)
	);
endmodule


module cdc_pulse_sender #(
	parameter SYNC_DEPTH = 2
) (
	input wire reset_n,
	input wire clk,
	input wire i_pulse,
	// domain crossing signals
	output wire o_async_req,
	input wire i_async_ack
);

	reg r_req;

	// ack signal synchronizer
	wire w_synced_ack;

	(* ASYNC_REG = "TRUE" *)
	(* DONT_TOUCH = "TRUE" *)
	reg [SYNC_DEPTH-1:0] r_ack_sync_stage;

	always @(posedge clk or negedge reset_n) begin
		if (~reset_n) begin
			r_ack_sync_stage <= {SYNC_DEPTH{1'b0}};
		end else begin
			r_ack_sync_stage <= {r_ack_sync_stage[SYNC_DEPTH-2:0], i_async_ack};
		end
	end
	assign w_synced_ack = r_ack_sync_stage[SYNC_DEPTH-1];

	// edge detection
	reg r_pulse;
	always @(posedge clk or negedge reset_n) begin
		if (~reset_n) begin
			r_pulse <= 1'b0;
		end else begin
			r_pulse <= i_pulse;
		end
	end
	// rising edge detection
	wire w_pulse_edge = !r_pulse && i_pulse;

	// state
	reg r_wait_ack_trans;
	always @(posedge clk or negedge reset_n) begin
		if (~reset_n) begin
			r_wait_ack_trans <= 1'b0;
		end else begin
			if (!r_wait_ack_trans && w_pulse_edge) begin
				// start transaction
				r_wait_ack_trans <= 1'b1;
			end else if (r_wait_ack_trans && r_req == w_synced_ack) begin
				// ack received
				r_wait_ack_trans <= 1'b0;
			end
		end
	end

	// latch input data
	always @(posedge clk or negedge reset_n) begin
		if (~reset_n) begin
			r_req <= 1'b0;
		end else begin
			if (!r_wait_ack_trans && w_pulse_edge) begin
				r_req <= ~r_req; // toggle req signal
			end
		end
	end

	// output signals
	assign o_async_req = r_req;


endmodule

module cdc_pulse_receiver #(
	parameter SYNC_DEPTH = 2
) (
	input wire reset_n,
	input wire clk,
	output wire o_pulse,
	input wire i_ready,
	// domain crossing signals
	input wire i_async_req,
	output wire o_async_ack
);

	// req signal synchronizer
	wire w_synced_req;
	reg r_synced_req; // 1 cycle delayed w_synced_req

	(* ASYNC_REG = "TRUE" *)
	(* DONT_TOUCH = "TRUE" *)
	reg [SYNC_DEPTH-1:0] r_req_sync_stage;

	always @(posedge clk or negedge reset_n) begin
		if (~reset_n) begin
			r_req_sync_stage <= {SYNC_DEPTH{1'b0}};
		end else begin
			r_req_sync_stage <= {r_req_sync_stage[SYNC_DEPTH-2:0], i_async_req};
		end
	end
	assign w_synced_req = r_req_sync_stage[SYNC_DEPTH-1];

	// ack signal
	reg r_ack, r_ack_delay;
	wire w_toggle_ack;
	always @(posedge clk or negedge reset_n) begin
		if (~reset_n) begin
			r_ack <= 1'b0;
			r_ack_delay <= 1'b0;
		end else begin
			r_ack_delay <= r_ack;
			if (r_ack != r_synced_req && i_ready) begin
				r_ack <= ~r_ack;
			end
		end
	end
	assign w_toggle_ack = r_ack != r_ack_delay;


	// latch req signal
	always @(posedge clk or negedge reset_n) begin
		if (~reset_n) begin
			r_synced_req <= 1'b0;
		end else begin
			r_synced_req <= w_synced_req;
		end
	end

	// output signals
	assign o_pulse = w_toggle_ack;
	assign o_async_ack = r_ack;

endmodule