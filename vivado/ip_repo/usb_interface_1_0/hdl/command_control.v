//
//    Copyright (C) 2025 The University of Tokyo
//    
//    File:          /vivado/ip_repo/usb_interface_1_0/hdl/command_control.v
//    Project:       cw305-shell
//    Author:        Takuya Kojima in The University of Tokyo (tkojima@hal.ipc.i.u-tokyo.ac.jp)
//    Created Date:  23-01-2025 07:01:37
//    Last Modified: 23-01-2025 07:01:39
//



`include "def.v"

module command_control #(
	parameter RESET_CYCLES = 100
) (
	input wire clk,
	input wire reset_n,

	output wire [10:0] debug_state,
	output wire [31:0] debug_reset_count,

	// internal read/write control
	output wire [`WORD_B] o_addr,
	output wire [`WORD_B] o_write_data,
	output wire o_write_valid,
	input wire i_write_ready,
	input wire [`WORD_B] i_read_data,
	output wire o_read_req,
	input wire i_read_valid,

	// to/from usb
	input wire [`FLIT_B] usb_flit_data,
	output wire [`BYTE_B] o_response,
	input wire usb_rd_n,
	input wire usb_wr_n,
	input wire usb_ce_n,
	output wire usb_isout,

	// soft reset signal
	output wire o_sw_reset_n


);

	// flit fields
	wire w_parity;
	wire [`FLIT_TYPE_W-1:0] w_flit_type;
	wire [`FLIT_DATA_LEN_W-1:0] w_flit_data_len;
	wire [`FLIT_PAYLOAD_W-1:0] w_flit_payload;
	assign {w_parity, w_flit_type, w_flit_data_len, w_flit_payload} = usb_flit_data;
	wire w_parity_error;
	// check if even parity is correct
	assign w_parity_error = ^usb_flit_data != 0;

	// address buffer
	reg [`WORD_B] r_addr;

	// state machine
	localparam STATE_W = 11;
	localparam STATE_WAIT_B = 0;
	localparam STATE_WAIT = 1 << STATE_WAIT_B;				// 0x001
	localparam STATE_READ_ADDR_B = 1;
	localparam STATE_READ_ADDR = 1 << STATE_READ_ADDR_B;	// 0x002
	localparam STATE_WAIT_READ_B = 2;
	localparam STATE_WAIT_READ = 1 << STATE_WAIT_READ_B;	// 0x004
	localparam STATE_SEND_READY_B = 3;
	localparam STATE_SEND_READY = 1 << STATE_SEND_READY_B;	// 0x008
	localparam STATE_SEND_DATA_B = 4;
	localparam STATE_SEND_DATA = 1 << STATE_SEND_DATA_B;	// 0x010
	localparam STATE_WRITE_ADDR_B = 5;
	localparam STATE_WRITE_ADDR = 1 << STATE_WRITE_ADDR_B;	// 0x020
	localparam STATE_WRITE_UPPER_B = 6;
	localparam STATE_WRITE_UPPER = 1 << STATE_WRITE_UPPER_B;// 0x040
	localparam STATE_WRITE_LOWER_B = 7;
	localparam STATE_WRITE_LOWER = 1 << STATE_WRITE_LOWER_B;// 0x080
	localparam STATE_SYNC_WRITE_B = 8;
	localparam STATE_SYNC_WRITE = 1 << STATE_SYNC_WRITE_B;	// 0x100
	localparam STATE_RESET_B = 9;
	localparam STATE_RESET = 1 << STATE_RESET_B;			// 0x200
	localparam STATE_RESPOND_B = 10;
	localparam STATE_RESPOND = 1 << STATE_RESPOND_B;		// 0x400

	reg [STATE_W-1:0] r_state;
	reg [`BYTE_B] r_response;
	reg [`FLIT_PAYLOAD_W-1:0] r_recv_data_count;

	// pulse detection
	wire w_read_enable;
	wire w_write_enable;
	reg r_usb_ce_n;
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			r_usb_ce_n <= `DISABLE_;
		end else begin
			r_usb_ce_n <= usb_ce_n;
		end
	end
	assign w_read_enable = r_usb_ce_n == `DISABLE_ && usb_ce_n == `ENABLE_ && usb_rd_n == `ENABLE_;
	assign w_write_enable = r_usb_ce_n == `DISABLE_ && usb_ce_n == `ENABLE_ && usb_wr_n == `ENABLE_;

	// external->internal write control
	reg [`FLIT_DATA_LEN_W-1:0] r_write_data_len;
	reg [`WORD_B] r_write_data;
	reg [`FLIT_PAYLOAD_W:0] r_write_data_count;
	wire w_write_buf_dequeue;
	reg r_write_buf_enqueue;
	wire w_write_buf_flush;
	wire w_write_buf_empty;
	wire [`WORD_B] w_write_buf_data;

	fifo write_buffer (
		.clk(clk),
		.reset_n(reset_n),
		.i_flush(w_write_buf_flush),
		.i_data(r_write_data),
		.i_write_enable(r_write_buf_enqueue),
		.o_full(),
		.o_data(w_write_buf_data),
		.i_read_enable(w_write_buf_dequeue),
		.o_empty(w_write_buf_empty),
		.o_almost_empty()
	);

	assign w_write_buf_dequeue = o_write_valid && i_write_ready;
	assign w_write_buf_flush = r_state[STATE_WAIT_B] && !w_write_buf_empty;

	// internal->external read control
	reg [`FLIT_DATA_LEN_W-1:0] r_read_data_len;
	reg [`FLIT_PAYLOAD_W:0] r_read_data_count;
	reg r_read_buf_dequeue;

	wire w_read_buf_enqueue;
	wire w_read_buf_empty;
	wire [`WORD_B] w_read_buf_data;
	wire w_read_buf_flush;

	reg r_read_valid; // 1 cycle delayed read valid

	fifo read_buffer (
		.clk(clk),
		.reset_n(reset_n),
		.i_data(i_read_data),
		.i_write_enable(w_read_buf_enqueue),
		.i_flush(w_read_buf_flush),
		.o_full(),
		.o_data(w_read_buf_data),
		.i_read_enable(r_read_buf_dequeue),
		.o_empty(w_read_buf_empty),
		.o_almost_empty()
	);

	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			r_read_valid <= 0;
		end else begin
			r_read_valid <= i_read_valid;
		end
	end

	assign w_read_buf_enqueue = r_state[STATE_WAIT_READ_B] && i_read_valid && r_read_data_count <= r_read_data_len;
	// deassert read request after read data is valid
	assign o_read_req = r_state[STATE_WAIT_READ_B] & !r_read_valid;
	assign w_read_buf_flush = r_state[STATE_WAIT_B] && !w_read_buf_empty;

	// force reset state
	wire w_state_reset;
	assign w_state_reset = usb_flit_data[`FLIT_W-1:`BYTE_W] == `RESET_STUCK_STATE && w_read_enable;

	// reset counter for soft reset
	localparam RESET_COUNT_W = $clog2(RESET_CYCLES);
	reg [RESET_COUNT_W-1:0] r_reset_count;

	// Command handling FSM
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			// reset
			r_state <= STATE_WAIT;
			r_recv_data_count <= 0;
			r_write_data <= 0;
			r_read_data_len <= 0;
			r_write_data_len <= 0;
			r_addr <= 0;
			r_write_buf_enqueue <= 0;
			r_response <= `RESPONSE_NOT_READY;
			r_reset_count <= 0;
		end else begin
			// state machine
			r_write_buf_enqueue <= 0;
			if (w_state_reset) begin
				r_state <= STATE_WAIT;
			end else begin
				case (r_state)
					STATE_WAIT: begin
						if (w_write_enable) begin
							if (w_parity_error) begin
								// respond packet error
								r_response <= `RESPONSE_PACKET_ERR;
								r_state <= STATE_RESPOND;
							end else begin
								case (w_flit_type)
									`FLIT_READ_ADDR_UPPER: begin
										// read request start
										r_state <= STATE_READ_ADDR;
										r_read_data_len <= w_flit_data_len;
										r_addr <= {w_flit_payload, `HALF_ZERO};
									end
									`FLIT_WRITE_ADDR_UPPER: begin
										// write request start
										r_state <= STATE_WRITE_ADDR;
										r_write_data_len <= w_flit_data_len;
										r_recv_data_count <= 0;
										r_addr <= {w_flit_payload, `HALF_ZERO};
									end
									`FLIT_RESET: begin
										// reset
										r_state <= STATE_RESET;
										r_reset_count <= 0;
									end
									default: begin
										// unknown command
										r_response <= `RESPONSE_CMD_ERR;
										r_state <= STATE_RESPOND;
									end
								endcase
							end
						end
					end
					STATE_READ_ADDR: begin
						if (w_write_enable) begin
							if (w_parity_error) begin
								// respond packet error
								r_response <= `RESPONSE_PACKET_ERR;
								r_state <= STATE_RESPOND;
							end else if (w_flit_type == `FLIT_READ_ADDR_LOWER) begin
								r_addr[`HALF_B] <= w_flit_payload;
								r_state <= STATE_WAIT_READ;
							end else begin
								r_response <= `RESPONSE_PACKET_ERR;
								r_state <= STATE_RESPOND;
							end
						end
					end
					STATE_WRITE_ADDR: begin
						if (w_write_enable) begin
							if (w_parity_error) begin
								// respond packet error
								r_response <= `RESPONSE_PACKET_ERR;
								r_state <= STATE_RESPOND;
							end else if (w_flit_type == `FLIT_WRITE_ADDR_LOWER) begin
								r_addr[`HALF_B] <= w_flit_payload;
								r_state <= STATE_WRITE_UPPER;
							end else begin
								r_response <= `RESPONSE_CMD_ERR;
								r_state <= STATE_RESPOND;
							end
						end
					end
					STATE_WRITE_UPPER: begin
						if (w_write_enable) begin
							if (w_parity_error) begin
								// respond packet error
								r_response <= `RESPONSE_PACKET_ERR;
								r_state <= STATE_RESPOND;
							end else if (w_flit_type == `FLIT_WRITE_DATA_UPPER) begin
								r_state <= STATE_WRITE_LOWER;
								r_write_data <= {w_flit_payload, `HALF_ZERO};
							end else begin
								r_response <= `RESPONSE_CMD_ERR;
								r_state <= STATE_RESPOND;
							end
						end
					end
					STATE_WRITE_LOWER: begin
						if (w_write_enable) begin
							if (w_parity_error) begin
								// respond packet error
								r_response <= `RESPONSE_PACKET_ERR;
								r_state <= STATE_RESPOND;
							end else if (w_flit_type == `FLIT_WRITE_DATA_LOWER) begin
								r_write_data[`HALF_B] <= w_flit_payload;
								r_write_buf_enqueue <= 1;
								if (r_recv_data_count == r_write_data_len) begin
									r_state <= STATE_SYNC_WRITE;
								end else begin
									r_recv_data_count <= r_recv_data_count + 1;
									r_state <= STATE_WRITE_UPPER;
								end
							end else begin
								r_response <= `RESPONSE_CMD_ERR;
								r_state <= STATE_RESPOND;
							end
						end
					end
					STATE_SYNC_WRITE: begin
						if (w_write_buf_empty && !r_write_buf_enqueue) begin
							r_response <= `RESPONSE_CMD_OK;
							r_state <= STATE_RESPOND;
						end
					end
					STATE_WAIT_READ: begin
						if (r_read_data_count == r_read_data_len + 1) begin
							r_state <= STATE_SEND_READY;
						end
					end
					STATE_SEND_READY: begin
						// send ready
						if (w_read_enable) begin
							r_state <= STATE_SEND_DATA;
						end
					end
					STATE_SEND_DATA: begin
						if (w_read_buf_empty) begin
							r_response <= `RESPONSE_CMD_OK;
							r_state <= STATE_RESPOND;
						end
					end
					STATE_RESET: begin
						if (r_reset_count == RESET_CYCLES) begin
							r_state <= STATE_RESPOND;
							r_response <= `RESPONSE_CMD_OK;
						end else begin
							r_reset_count <= r_reset_count + 1;
						end
					end
					STATE_RESPOND: begin
						// respond
						if (w_read_enable) begin
							r_state <= STATE_WAIT;
						end
					end
				endcase
			end
		end
	end

	// read data control
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			r_read_data_count <= 0;
		end else begin
			if (r_state[STATE_READ_ADDR_B]) begin
				r_read_data_count <= 0;
			end else if (r_state[STATE_WAIT_READ_B] && r_read_data_count <= r_read_data_len) begin
				if (i_read_valid) begin
					r_read_data_count <= r_read_data_count + 1;
				end
			end
		end
	end

	// write data control
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			r_write_data_count <= 0;
		end else begin
			if (r_state[STATE_WRITE_ADDR_B]) begin
				r_write_data_count <= 0;
			end else if (w_write_buf_dequeue) begin
				r_write_data_count <= r_write_data_count + 1;
			end
		end
	end

	// read data response control
	reg [1:0] r_byte_count;
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			r_byte_count <= 0;
			r_read_buf_dequeue <= 0;
		end else begin
			r_read_buf_dequeue <= 0;
			if (r_state[STATE_SEND_DATA_B]) begin
				if (w_read_enable) begin
					if (r_byte_count == 3) begin
						r_byte_count <= 0;
						r_read_buf_dequeue <= 1;
					end else begin
						r_byte_count <= r_byte_count + 1;
					end
				end
			end
		end
	end

	// response timing control
	// 2 cycle delay for response after rd_n is deasserted
	reg [`BYTE_B] r_response_out;
	reg [1:0] r_isout_pipe;
	always @(posedge clk or negedge reset_n) begin
		if (!reset_n) begin
			r_response_out <= `RESPONSE_NOT_READY;
			r_isout_pipe <= 0;
		end else begin
			r_isout_pipe <= {r_isout_pipe[0], (usb_ce_n == `ENABLE_ && usb_rd_n == `ENABLE_)};
			// latch response data
			if (w_read_enable) begin
				case (r_state)
					STATE_SEND_READY: begin
						r_response_out <= `RESPONSE_READY;
					end
					STATE_SEND_DATA: begin
						r_response_out <= w_read_buf_data[r_byte_count * 8 +: 8];
					end
					STATE_RESPOND: begin
						r_response_out <= r_response;
					end
					default: begin
						r_response_out <= `RESPONSE_NOT_READY;
					end
				endcase
			end
		end
	end

	// output to usb interface
	assign o_response = r_response_out;
	assign usb_isout = r_isout_pipe[1];

	// output to internal bus
	assign o_addr = (r_state[STATE_WAIT_READ_B]) ? r_addr + (r_read_data_count * 4) :
					(o_write_valid) ? r_addr + (r_write_data_count * 4) : 0;
	assign o_write_data = w_write_buf_data;
	assign o_write_valid = (r_state[STATE_WRITE_UPPER_B] || r_state[STATE_WRITE_LOWER_B] ||
							r_state[STATE_SYNC_WRITE_B]) && !w_write_buf_empty;


	// soft reset signal (active low)
	assign o_sw_reset_n = r_state[STATE_RESET_B] ? `ENABLE_ : `DISABLE_;


endmodule