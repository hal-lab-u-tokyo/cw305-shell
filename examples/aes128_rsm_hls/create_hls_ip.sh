#!/bin/sh

make -C ../ip_repo/aes128_rsm_hls genmask
vitis_hls -f ../ip_repo/aes128_rsm_hls/create_ip.tcl target-board=cw305 target-freq=20MHz
