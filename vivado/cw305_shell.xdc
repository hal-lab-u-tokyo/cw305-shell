############################
####   Voltage rules    ####
############################
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

############################
####        LEDs        ####
############################
set_property -dict {PACKAGE_PIN T4 DRIVE 8 IOSTANDARD LVCMOS33} [get_ports LED[0]]; # IO_L9P_T1_DQS_34; LED6 (BLUE, right most)
set_property -dict {PACKAGE_PIN T3 DRIVE 8 IOSTANDARD LVCMOS33} [get_ports LED[1]]; # IO_L9N_T1_DQS_34; LED5 (GREEN, center)
set_property -dict {PACKAGE_PIN T2 DRIVE 8 IOSTANDARD LVCMOS33} [get_ports LED[2]]; # IO_L8N_T1_34; LED7 (RED, left most)

############################
####    User switches   ####
############################
# set_property -dict {PACKAGE_PIN J16  IOSTANDARD LVCMOS33} [get_ports DIP[0]];	# IO_L23N_T3_FWE_B_15
# set_property -dict {PACKAGE_PIN K16  IOSTANDARD LVCMOS33} [get_ports DIP[1]];	# IO_L2N_T0_D03_14
# set_property -dict {PACKAGE_PIN K15  IOSTANDARD LVCMOS33} [get_ports DIP[2]];	# IO_L2P_T0_D02_14
# set_property -dict {PACKAGE_PIN L14  IOSTANDARD LVCMOS33} [get_ports DIP[3]];	# IO_L4P_T0_D04_14
set_property -dict {PACKAGE_PIN R1  IOSTANDARD LVCMOS33}  [get_ports RESET_N];		# IO_L7N_T1_34

############################
####   Clock settings   ####
############################
set_property -dict {PACKAGE_PIN N13 IOSTANDARD LVCMOS33} [get_ports PLL_CLK1];	# IO_L11P_T1_SRCC_14
# set_property -dict {PACKAGE_PIN E12 IOSTANDARD LVCMOS33} [get_ports PLL_CLK2];	# IO_L13P_T2_MRCC_15
# set_property -dict {PACKAGE_PIN N11 IOSTANDARD LVCMOS33} [get_ports EXTCLK_IN];	# IO_L13P_T2_MRCC_14; clock input from SMA X7
# set_property -dict {PACKAGE_PIN T13 IOSTANDARD LVCMOS33} [get_ports EXTCLK_OUT];# IO_L16N_T2_A15_D31_14; clock output to SMA X8

############################
####   GPIO Headers     ####
############################
# set_property -dict {PACKAGE_PIN A12 IOSTANDARD LVCMOS33} [get_ports GPIO_J5];	# IO_L5N_T0_AD9N_15
# set_property -dict {PACKAGE_PIN B12 IOSTANDARD LVCMOS33} [get_ports GPIO_J6];	# IO_L5P_T0_AD9P_15
# set_property -dict {PACKAGE_PIN A14 IOSTANDARD LVCMOS33} [get_ports GPIO_J7];	# IO_L7N_T1_AD2N_15
# set_property -dict {PACKAGE_PIN A13 IOSTANDARD LVCMOS33} [get_ports GPIO_J8];	# IO_L7P_T1_AD2P_15
# set_property -dict {PACKAGE_PIN A15 IOSTANDARD LVCMOS33} [get_ports GPIO_J9];	# IO_L9N_T1_DQS_AD3N_15
# set_property -dict {PACKAGE_PIN B15 IOSTANDARD LVCMOS33} [get_ports GPIO_J10];	# IO_L9P_T1_DQS_AD3P_15
# set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports GPIO_J11];	# IO_L11N_T1_SRCC_15
# set_property -dict {PACKAGE_PIN C11 IOSTANDARD LVCMOS33} [get_ports GPIO_J12];	# IO_L11P_T1_SRCC_15
# set_property -dict {PACKAGE_PIN B14 IOSTANDARD LVCMOS33} [get_ports GPIO_J13];	# IO_L8N_T1_AD10N_15
# set_property -dict {PACKAGE_PIN C14 IOSTANDARD LVCMOS33} [get_ports GPIO_J14];	# IO_L8P_T1_AD10P_15
# set_property -dict {PACKAGE_PIN B16 IOSTANDARD LVCMOS33} [get_ports GPIO_J15];	# IO_L10N_T1_AD11N_15
# set_property -dict {PACKAGE_PIN C16 IOSTANDARD LVCMOS33} [get_ports GPIO_J16];	# IO_L10P_T1_AD11P_15
# set_property -dict {PACKAGE_PIN C13 IOSTANDARD LVCMOS33} [get_ports GPIO_J17];	# IO_L12N_T1_MRCC_15
# set_property -dict {PACKAGE_PIN D13 IOSTANDARD LVCMOS33} [get_ports GPIO_J18];	# IO_L12P_T1_MRCC_15

# set_property -dict {PACKAGE_PIN D15  IOSTANDARD LVCMOS33} [get_ports GPIO_J23];	# IO_L15N_T2_DQS_ADV_B_15
# set_property -dict {PACKAGE_PIN D14  IOSTANDARD LVCMOS33} [get_ports GPIO_J24];	# IO_L15P_T2_DQS_15
# set_property -dict {PACKAGE_PIN E15  IOSTANDARD LVCMOS33} [get_ports GPIO_J25];	# IO_L18N_T2_A23_15
# set_property -dict {PACKAGE_PIN D16  IOSTANDARD LVCMOS33} [get_ports GPIO_J26];	# IO_L17N_T2_A25_15
# set_property -dict {PACKAGE_PIN E13  IOSTANDARD LVCMOS33} [get_ports GPIO_J27];	# IO_L13N_T2_MRCC_15
# set_property -dict {PACKAGE_PIN E16  IOSTANDARD LVCMOS33} [get_ports GPIO_J28];	# IO_L17P_T2_A26_15
# set_property -dict {PACKAGE_PIN F15  IOSTANDARD LVCMOS33} [get_ports GPIO_J29];	# IO_L18P_T2_A24_15
# set_property -dict {PACKAGE_PIN F12  IOSTANDARD LVCMOS33} [get_ports GPIO_J30];	# IO_L16P_T2_A28_15
# set_property -dict {PACKAGE_PIN E11  IOSTANDARD LVCMOS33} [get_ports GPIO_J31];	# IO_L14P_T2_SRCC_15
# set_property -dict {PACKAGE_PIN F13  IOSTANDARD LVCMOS33} [get_ports GPIO_J32];	# IO_L16N_T2_A27_15

# set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports IOD_P];	# IO_L22P_T3_A17_15
# set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports IOD_N];	# IO_L22N_T3_A16_15
# set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports EMCCLK];# IO_L3N_T0_DQS_EMCCLK_14


############################
####    Target Header   ####
############################
# set_property -dict {PACKAGE_PIN M16 IOSTANDARD LVCMOS33} [get_ports TIO_HS1];	# IO_L7P_T1_D09_14;   clock out to chipwhisperer
# set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports TIO_HS2];	# IO_L12P_T1_MRCC_14; clock in from chipwhisperer
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports TIO1];		# IO_L8N_T1_D12_14
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports TIO2];		# IO_L9N_T1_DQS_D13_14
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports TIO3];		# IO_L10N_T1_D15_14
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports TIO4];		# IO_L10P_T1_D14_14
# set_property -dict {PACKAGE_PIN N16 IOSTANDARD LVCMOS33} [get_ports TIO_PMISO];	# IO_L7N_T1_D10_14
# set_property -dict {PACKAGE_PIN R15 IOSTANDARD LVCMOS33} [get_ports TIO_CS];	# IO_L9P_T1_DQS_14
# set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports TIO_PSCK];	# IO_L7N_T1_D10_14

############################
####    USB Interface   ####
############################
set_property -dict {PACKAGE_PIN F5  IOSTANDARD LVCMOS33} [get_ports USBCK0];	# IO_L13P_T2_MRCC_35, PCK0
# set_property -dict {PACKAGE_PIN D4  IOSTANDARD LVCMOS33} [get_ports USBCK1];	# IO_L13N_T2_MRCC_35, PCK1

set_property -dict {PACKAGE_PIN A7 IOSTANDARD LVCMOS33} [get_ports {USB_DATA[0]}];	# IO_L1N_T0_AD4N_35
set_property -dict {PACKAGE_PIN B6 IOSTANDARD LVCMOS33} [get_ports {USB_DATA[1]}];	# IO_L2P_T0_AD12P_35
set_property -dict {PACKAGE_PIN D3 IOSTANDARD LVCMOS33} [get_ports {USB_DATA[2]}];	# IO_L11N_T1_SRCC_35
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports {USB_DATA[3]}];	# IO_L11P_T1_SRCC_35
set_property -dict {PACKAGE_PIN F3 IOSTANDARD LVCMOS33} [get_ports {USB_DATA[4]}];	# IO_L14N_T2_SRCC_35
set_property -dict {PACKAGE_PIN B5 IOSTANDARD LVCMOS33} [get_ports {USB_DATA[5]}];	# IO_L2N_T0_AD12N_35
set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVCMOS33} [get_ports {USB_DATA[6]}];	# IO_L22P_T3_35
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {USB_DATA[7]}];	# IO_L24N_T3_35

set_property -dict {PACKAGE_PIN F4 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[0]}];	# IO_L14P_T2_SRCC_35
set_property -dict {PACKAGE_PIN G5 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[1]}];	# IO_L16P_T2_35
set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[2]}];	# IO_L22N_T3_35
set_property -dict {PACKAGE_PIN H1 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[3]}];	# IO_L20N_T3_35
set_property -dict {PACKAGE_PIN H2 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[4]}];	# IO_L20P_T3_35
set_property -dict {PACKAGE_PIN G1 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[5]}];	# IO_L17N_T2_35
set_property -dict {PACKAGE_PIN G2 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[6]}];	# IO_L17P_T2_35
set_property -dict {PACKAGE_PIN F2 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[7]}];	# IO_L15P_T2_DQS_35
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[8]}];	# IO_L15N_T2_DQS_35
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[9]}];	# IO_L10P_T1_AD15P_35
set_property -dict {PACKAGE_PIN D1 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[10]}];	# IO_L10N_T1_AD15N_35
set_property -dict {PACKAGE_PIN C1 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[11]}];	# IO_L9P_T1_DQS_AD7P_35
set_property -dict {PACKAGE_PIN K3 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[12]}];	# IO_L24P_T3_35
set_property -dict {PACKAGE_PIN L2 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[13]}];	# IO_L23N_T3_35
set_property -dict {PACKAGE_PIN J3 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[14]}];	# IO_L21P_T3_DQS_35
set_property -dict {PACKAGE_PIN B2 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[15]}];	# IO_L8P_T1_AD14P_35
set_property -dict {PACKAGE_PIN C7 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[16]}];	# IO_L5P_T0_AD13P_35
# set_property -dict {PACKAGE_PIN C6 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[17]}];	# IO_L5N_T0_AD13N_35
# set_property -dict {PACKAGE_PIN D6 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[18]}];	# IO_L6P_T0_35
# set_property -dict {PACKAGE_PIN C4 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[19]}];	# IO_L12N_T1_MRCC_35
# set_property -dict {PACKAGE_PIN D5 IOSTANDARD LVCMOS33} [get_ports {USB_ADDR[20]}];	# IO_L6N_T0_VREF_35


set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS33} [get_ports USB_RD_N];		# IO_L3N_T0_DQS_AD5N_35
set_property -dict {PACKAGE_PIN C2 IOSTANDARD LVCMOS33} [get_ports USB_WR_N];		# IO_L7N_T1_AD6N_35
set_property -dict {PACKAGE_PIN A3 IOSTANDARD LVCMOS33} [get_ports USB_CE_N];		# IO_L4N_T0_35
# set_property -dict {PACKAGE_PIN A2 IOSTANDARD LVCMOS33} [get_ports USB_ALE_N];		# IO_L8N_T1_AD14N_35

set_property -dict {PACKAGE_PIN A5 IOSTANDARD LVCMOS33} [get_ports USB_TRIGGER];	# IO_L3P_T0_DQS_AD5P_35
# set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS33} [get_ports USB_SPARE1];	# IO_L4P_T0_35
# set_property -dict {PACKAGE_PIN B1 IOSTANDARD LVCMOS33} [get_ports USB_SPARE2];	# IO_L9N_T1_DQS_AD7N_35


############################
#### Timing constraints ####
############################
# # PCK0 clock is programmed to 96MHz in its firmware.
create_clock -period 10.400 -name usb_clk -waveform {0.000 5.200} [get_nets USBCK0];
# # PLL_CLK1, PLL_CLK2 clocks are generated by Texas Instruments CDCE906PWR. The maximum frequency is 167MHz
# create_clock -period 10.000 -name pll_clk1 -waveform {0.000 5.000} [get_nets PLL_CLK1];
## depending on CW board settings. In the case of CW-Lite board, up to 200MHz is possible according to the datasheet.
# create_clock -period 10.000 -name tio_clkin -waveform {0.000 5.000} [get_nets TIO_HS2];

set_input_delay -clock usb_clk -add_delay 2.000 [get_ports USB_ADDR]
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports USB_DATA]
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports USB_RD_N]
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports USB_CE_N]
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports USB_WR_N]
set_input_delay -clock usb_clk -add_delay 2.000 [get_ports USB_TRIGGER]
set_input_delay -clock usb_clk -add_delay 0.5 [get_ports RESET_N]
set_input_delay -add_delay 0.0 [get_ports DIP]

set_output_delay -add_delay 0.0 [get_ports USB_DATA]
set_output_delay -add_delay 0.0 [get_ports TIO1]
set_output_delay -add_delay 0.0 [get_ports TIO2]
set_output_delay -add_delay 0.0 [get_ports TIO3]
set_output_delay -add_delay 0.0 [get_ports TIO4]
set_output_delay -add_delay 0.0 [get_ports LED]

set_false_path -to [get_ports USB_DATA]
set_false_path -to [get_ports LED]
set_false_path -from [get_ports DIP]


set_property BITSTREAM.CONFIG.USR_ACCESS TIMESTAMP [current_design]

