//
//    Copyright (C) 2025 The University of Tokyo
//    
//    File:          /vivado/ip_repo/usb_interface_1_0/hdl/def.v
//    Project:       cw305-shell
//    Author:        Takuya Kojima in The University of Tokyo (tkojima@hal.ipc.i.u-tokyo.ac.jp)
//    Created Date:  23-01-2025 07:01:46
//    Last Modified: 23-01-2025 07:01:47
//


// active high signals
`define ENABLE 1'b1
`define DISABLE 1'b0
`define TRUE 1'b1
`define FALSE 1'b0

// active low signals
`define ENABLE_ 1'b0
`define DISABLE_ 1'b1
`define TRUE_ 1'b0
`define FALSE_ 1'b1

// data width
`define BYTE_W 8
`define BYTE_B (`BYTE_W - 1):0
`define HALF_W 16
`define HALF_B (`HALF_W - 1):0
`define HALF_ZERO 16'h0000
`define WORD_W 32
`define WORD_B (`WORD_W - 1):0


// Commnad packet is composed of multiple flits
// Address bus and data bus are combined into one bus to transfer the flits
// The flit format is as follows:
// ----------------------------------------------------------------------------------
// | even parity (1bit) | flit type (4bits) | data length (4bit) | payload (16bits) |
// ----------------------------------------------------------------------------------
// The data length is biased by 1, i.e., 0 means 1 byte, 15 means 16 bytes

`define PARITY_W 1
`define FLIT_TYPE_W 4
`define FLIT_DATA_LEN_W 4
`define FLIT_PAYLOAD_W 16
`define FLIT_W (`PARITY_W + `FLIT_TYPE_W + `FLIT_DATA_LEN_W + `FLIT_PAYLOAD_W)
`define FLIT_B (`FLIT_W - 1):0

// reset stuck state in a FSM by read enable signal with the following flit
`define RESET_STUCK_STATE 17'h0FF_FF

// flit type
// read request packet: 2 flits (lower addr, upper addr)
`define FLIT_READ_ADDR_UPPER 4'h0
`define FLIT_READ_ADDR_LOWER 4'h1 // ignore data length
// write request packet: 2 flits (lower addr, data) and N * 2 flits (upper data, lower data)
`define FLIT_WRITE_ADDR_UPPER 4'h2
`define FLIT_WRITE_ADDR_LOWER 4'h3 // ignore data length
`define FLIT_WRITE_DATA_UPPER 4'h4 // ignore data length
`define FLIT_WRITE_DATA_LOWER 4'h5
// reset packet: head flit only
`define FLIT_RESET 4'h6 // ignore data length, payload

// 1 byte response for ask packet
`define RESPONSE_CMD_OK 8'h00
`define RESPONSE_PACKET_ERR 8'h01
`define RESPONSE_CMD_ERR 8'h02
`define RESPONSE_READY 8'h03
`define RESPONSE_NOT_READY 8'hff


