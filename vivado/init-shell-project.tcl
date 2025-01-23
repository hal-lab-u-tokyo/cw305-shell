#
#    Copyright (C) 2025 The University of Tokyo
#    
#    File:          /vivado/init-shell-project.tcl
#    Project:       cw305-shell
#    Author:        Takuya Kojima in The University of Tokyo (tkojima@hal.ipc.i.u-tokyo.ac.jp)
#    Created Date:  23-01-2025 07:17:57
#    Last Modified: 23-01-2025 16:27:33
#


# default settings
variable design_name
# your preferences
set project_name "proj_shell"
set project_dir "[file normalize "./$project_name"]"
set design_name "main"

set script_file [file tail [info script]]

# Help information for this script
proc print_help {} {
	variable script_file
	puts "\nDescription:"
	puts "This script creates a template Vivado project for SAKURA-X Board."
	puts "This offers two types of project creation: one with MIG and one without MIG."
	puts "Syntax:"
	puts "$script_file"
	puts "$script_file -tclargs \[--project-dir <path>\]"
	puts "$script_file -tclargs \[--project-name <name>\]"
	puts "$script_file -tclargs \[--help\]\n"
	puts "Usage:"
	puts "Name                   Description"
	puts "-------------------------------------------------------------------------"
	puts "\[--project-dir <path>\] Specify the directory where the project will be"
	puts "                         created. Default is the current directory."
	puts "\[--project-name <name>\] Create project with the specified name. Default"
	puts "                          name is \"proj_shell\"."
	puts "\[--with-mig\]           Create project with MIG. Default is without MIG."
	puts "\[--help\]               Print help information for this script"
	puts "-------------------------------------------------------------------------\n"
	exit 0
}

# arg parser
if { $::argc > 0 } {
	for {set i 0} {$i < $::argc} {incr i} {
		set option [string trim [lindex $::argv $i]]
		switch -regexp -- $option {
			"--project-dir"  { incr i; set project_dir [lindex $::argv $i] }
			"--project-name" { incr i; set project_name [lindex $::argv $i] }
			"--help"         { print_help }
			default {
				if { [regexp {^-} $option] } {
					puts "ERROR: Unknown option '$option' specified, please type '$script_file -tclargs --help' for usage info.\n"
					return 1
				}
			}
		}
	}
}


# IP repo path
set scriptPath [file normalize [info script]]
set scriptDir [file dirname $scriptPath]
set ip_repo_loc [file normalize [file join $scriptDir "ip_repo"]]

# create project
create_project $project_name $project_dir -part xc7a100tftg256-2
set proj_dir [get_property directory [current_project]]

# source file set
set src_set [current_fileset -quiet]

# add IP repo
set_property "ip_repo_paths" "[file normalize $ip_repo_loc/usb_interface_1_0]" $src_set
update_ip_catalog -rebuild

# constraint file set
set constr_set [current_fileset -quiet -constrset]

# add a constraint file
import_files -fileset $constr_set [file normalize [file join $scriptDir "cw305_shell.xdc"]]

# create design
create_bd_design $design_name
common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
	 current_bd_design $design_name

# check IP
set bCheckIPsPassed 1
set list_check_ips "\ 
xilinx.com:ip:clk_wiz:6.0\
tkojima.me:user:usb_interface:1.0\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:xlconstant:1.1\
xilinx.com:ip:axi_gpio:2.0\
"

set list_ips_missing ""
common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

foreach ip_vlnv $list_check_ips {
	set ip_obj [get_ipdefs -all $ip_vlnv]
	if { $ip_obj eq "" } {
		lappend list_ips_missing $ip_vlnv
	}
}

if { $list_ips_missing ne "" } {
	catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
	set bCheckIPsPassed 0
}
if { $bCheckIPsPassed != 1 } {
	common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
	return 3
}

proc create_root_design { parentCell } {

	variable script_folder
	variable design_name

	if { $parentCell eq "" } {
		 set parentCell [get_bd_cells /]
	}

	# Get object for parentCell
	set parentObj [get_bd_cells $parentCell]
	if { $parentObj == "" } {
		 catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
		 return
	}

	# Make sure parentObj is hier blk
	set parentType [get_property TYPE $parentObj]
	if { $parentType ne "hier" } {
		 catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
		 return
	}

	# Save current instance; Restore later
	set oldCurInst [current_bd_instance .]

	# Set parent object as current
	current_bd_instance $parentObj

	# Create ports
	set DIP [ create_bd_port -dir I -from 3 -to 0 DIP ]
	set RESET_N [ create_bd_port -dir I RESET_N ]
	set PLL_CLK1 [ create_bd_port -dir I -type clk -freq_hz 100000000 PLL_CLK1 ]
	set USBCK0 [ create_bd_port -dir I -type clk -freq_hz 96000000 USBCK0 ]
	set USB_RD_N [ create_bd_port -dir I USB_RD_N ]
	set USB_WR_N [ create_bd_port -dir I USB_WR_N ]
	set USB_CE_N [ create_bd_port -dir I USB_CE_N ]
	set USB_TRIGGER [ create_bd_port -dir I USB_TRIGGER ]
	set TIO1 [ create_bd_port -dir O -from 0 -to 0 TIO1 ]
	set TIO2 [ create_bd_port -dir O -from 0 -to 0 TIO2 ]
	set TIO3 [ create_bd_port -dir O -from 0 -to 0 TIO3 ]
	set TIO4 [ create_bd_port -dir O -from 0 -to 0 TIO4 ]
	set USB_DATA [ create_bd_port -dir IO -from 7 -to 0 USB_DATA ]
	set USB_ADDR [ create_bd_port -dir I -from 16 -to 0 USB_ADDR ]
	set LED [ create_bd_port -dir O -from 2 -to 0 LED ]

	# Create instance: pll, and set properties
	set pll [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 pll ]
	set_property -dict [list \
		CONFIG.CLKOUT1_JITTER {193.154} \
		CONFIG.CLKOUT1_PHASE_ERROR {109.126} \
		CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {20} \
		CONFIG.CLKOUT2_USED {false} \
		CONFIG.MMCM_CLKFBOUT_MULT_F {8.500} \
		CONFIG.MMCM_CLKOUT0_DIVIDE_F {42.500} \
		CONFIG.MMCM_CLKOUT1_DIVIDE {1} \
		CONFIG.NUM_OUT_CLKS {1} \
		CONFIG.RESET_PORT {resetn} \
		CONFIG.RESET_TYPE {ACTIVE_LOW} \
		CONFIG.USE_LOCKED {false} \
	] $pll

	# Create instance: usb_interface_0, and set properties
	set usb_interface_0 [ create_bd_cell -type ip -vlnv tkojima.me:user:usb_interface:1.0 usb_interface_0 ]
	set_property -dict [list \
		CONFIG.C_M00_AXI_START_DATA_VALUE {0x00000000} \
		CONFIG.C_M00_AXI_TARGET_SLAVE_BASE_ADDR {0x00000000} \
	] $usb_interface_0

	# Create instance: rst_sys_clk, and set properties
	set rst_sys_clk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_sys_clk ]

	# Create instance: rst_usb_clk, and set properties
	set rst_usb_clk [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_usb_clk ]
	# Create instance: const_trig_ready, and set properties
	set const_trig_ready [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_trig_ready ]

	# Create instance: axi_gpio, and set properties
	set axi_gpio [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio ]
	set_property -dict [list \
		CONFIG.C_ALL_INPUTS {1} \
		CONFIG.C_ALL_OUTPUTS_2 {1} \
		CONFIG.C_GPIO2_WIDTH {3} \
		CONFIG.C_GPIO_WIDTH {4} \
		CONFIG.C_IS_DUAL {1} \
		CONFIG.C_DOUT_DEFAULT_2 {0x00000007} \
	] $axi_gpio

	# Create instance: usb_interface_0_axi_periph, and set properties
	set usb_interface_0_axi_periph [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 usb_interface_0_axi_periph ]
	set_property CONFIG.NUM_MI {1} $usb_interface_0_axi_periph

	# Create interface connections
	connect_bd_intf_net -intf_net usb_interface_0_M00_AXI [get_bd_intf_pins usb_interface_0/M00_AXI] [get_bd_intf_pins usb_interface_0_axi_periph/S00_AXI]
	connect_bd_intf_net -intf_net usb_interface_0_axi_periph_M00_AXI [get_bd_intf_pins usb_interface_0_axi_periph/M00_AXI] [get_bd_intf_pins axi_gpio/S_AXI]

	# Create port connections <= check
	connect_bd_net -net DIP_1 [get_bd_ports DIP] [get_bd_pins axi_gpio/gpio_io_i]
	connect_bd_net -net Net [get_bd_ports USB_DATA] [get_bd_pins usb_interface_0/usb_data]
	connect_bd_net -net PLL_CLK1_1 [get_bd_ports PLL_CLK1] [get_bd_pins pll/clk_in1]
	connect_bd_net -net RESET_N_1 [get_bd_ports RESET_N] [get_bd_pins pll/resetn] [get_bd_pins rst_sys_clk/ext_reset_in] [get_bd_pins rst_usb_clk/ext_reset_in]
	connect_bd_net -net USBCK0_1 [get_bd_ports USBCK0] [get_bd_pins rst_usb_clk/slowest_sync_clk] [get_bd_pins usb_interface_0/m00_axi_aclk] [get_bd_pins usb_interface_0_axi_periph/S00_ACLK]
	connect_bd_net -net USB_ADDR_1 [get_bd_ports USB_ADDR] [get_bd_pins usb_interface_0/usb_addr]
	connect_bd_net -net USB_CE_N_1 [get_bd_ports USB_CE_N] [get_bd_pins usb_interface_0/usb_ce_n]
	connect_bd_net -net USB_RD_N_1 [get_bd_ports USB_RD_N] [get_bd_pins usb_interface_0/usb_rd_n]
	connect_bd_net -net USB_TRIGGER_1 [get_bd_ports USB_TRIGGER] [get_bd_pins usb_interface_0/usb_trigger]
	connect_bd_net -net USB_WR_N_1 [get_bd_ports USB_WR_N] [get_bd_pins usb_interface_0/usb_wr_n]
	connect_bd_net -net axi_gpio_gpio2_io_o [get_bd_pins axi_gpio/gpio2_io_o] [get_bd_ports LED]
	connect_bd_net -net sys_clk_1 [get_bd_pins pll/clk_out1] [get_bd_pins rst_sys_clk/slowest_sync_clk] [get_bd_pins usb_interface_0/sys_clk] [get_bd_pins axi_gpio/s_axi_aclk] [get_bd_pins usb_interface_0_axi_periph/ACLK] [get_bd_pins usb_interface_0_axi_periph/M00_ACLK]
	connect_bd_net -net rst_usb_clk_peripheral_aresetn [get_bd_pins rst_usb_clk/peripheral_aresetn] [get_bd_pins usb_interface_0/m00_axi_aresetn] [get_bd_pins usb_interface_0_axi_periph/S00_ARESETN]
	connect_bd_net -net rst_sys_clk_peripheral_aresetn [get_bd_pins rst_sys_clk/peripheral_aresetn] [get_bd_pins axi_gpio/s_axi_aresetn] [get_bd_pins usb_interface_0_axi_periph/M00_ARESETN] [get_bd_pins usb_interface_0_axi_periph/ARESETN]
	connect_bd_net -net usb_interface_0_external_trigger [get_bd_pins usb_interface_0/external_trigger]
	connect_bd_net -net usb_interface_0_sw_reset_n [get_bd_pins usb_interface_0/sw_reset_n] [get_bd_pins rst_sys_clk/aux_reset_in]
	connect_bd_net -net fixed_ready_signal [get_bd_pins const_trig_ready/dout] [get_bd_pins usb_interface_0/trigger_ready]

	# Create address segments
	assign_bd_address -offset 0xC0000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces usb_interface_0/M00_AXI] [get_bd_addr_segs axi_gpio/S_AXI/Reg] -force

	# Restore current instance
	current_bd_instance $oldCurInst

	save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


common::send_gid_msg -ssname BD::TCL -id 2053 -severity "WARNING" "This Tcl script was generated from a block design that has not been validated. It is possible that design <$design_name> may result in errors during validation."

update_compile_order -fileset $src_set

# create HDL wrapper
set wrapper_path [make_wrapper -fileset $src_set -files [get_files $design_name.bd] -top]
add_files -norecurse -fileset $src_set $wrapper_path
set_property -name "top" -value "${design_name}_wrapper" -objects $src_set