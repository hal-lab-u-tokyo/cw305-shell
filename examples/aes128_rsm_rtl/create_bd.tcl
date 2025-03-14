variable design_name
set design_name main

set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

set scriptPath [file normalize [info script]]
set scriptDir [file dirname $scriptPath]

common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
current_bd_design $design_name

# check IP
set aes_rtl_core_ip "user.org:user:aes128_rsm_rtl:1.0"

set ip_repo_loc [file normalize [file join $scriptDir "../ip_repo"]]
set src_set [current_fileset -quiet]
set current_ip_repo_paths [get_property "ip_repo_paths" $src_set]
# append
set aes_rtl_core_ip_repo "[file join $ip_repo_loc "aes128_rsm_rtl_1_0" ]"
if { [lsearch -exact $current_ip_repo_paths $aes_rtl_core_ip_repo] == -1 } {
	# concat space separated paths
	set current_ip_repo_paths [concat $current_ip_repo_paths $aes_rtl_core_ip_repo]
	set_property "ip_repo_paths" $current_ip_repo_paths $src_set
}
update_ip_catalog -rebuild


# update block design
set parentCell [get_bd_cells /]

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

# change AXI interconect
set usb_interface_0_axi_periph [ get_bd_cells usb_interface_0_axi_periph ]
set_property -dict [list \
	CONFIG.NUM_MI {2} \
] $usb_interface_0_axi_periph

# Create instance: aes_rtl_core_0, and set properties
set aes_rtl_core_0 [ create_bd_cell -type ip -vlnv $aes_rtl_core_ip aes_rtl_core_0 ]

# obtain system reset signal generator
set rst_sys_clk [ get_bd_cells rst_sys_clk ]

# interface connection
connect_bd_intf_net -intf_net usb_interface_0_axi_periph_M01_AXI [get_bd_intf_pins usb_interface_0_axi_periph/M01_AXI] [get_bd_intf_pins aes_rtl_core_0/S_AXI]

# port connections
connect_bd_net -net aes_rtl_core_0_o_running [get_bd_pins aes_rtl_core_0/o_running] [get_bd_ports TIO4]

# connect nets
connect_bd_net [get_bd_pins pll/clk_out1] [get_bd_pins usb_interface_0_axi_periph/M01_ACLK] [get_bd_pins rst_sys_clk/slowest_sync_clk] [get_bd_pins aes_rtl_core_0/s_axi_aclk]

connect_bd_net  [get_bd_pins rst_sys_clk/peripheral_aresetn] [get_bd_pins usb_interface_0_axi_periph/M01_ARESETN] [get_bd_pins aes_rtl_core_0/s_axi_aresetn]


# Create address segments
assign_bd_address -offset 0x8000_0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces usb_interface_0/M00_AXI] [get_bd_addr_segs aes_rtl_core_0/S_AXI/S_AXI_reg] -force

# Restore current instance
current_bd_instance $oldCurInst

save_bd_design
