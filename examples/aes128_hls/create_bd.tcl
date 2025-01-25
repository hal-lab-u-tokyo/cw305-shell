
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
set aes_hls_core_ip "xilinx.com:hls:AES128Encrypt:1.0"

set aes_hls_core_ip_repo [file normalize [file join $scriptDir "hls_cw305_aes_enc/solution0/impl/ip"]]
set src_set [current_fileset -quiet]
set current_ip_repo_paths [get_property "ip_repo_paths" $src_set]
# append
if { [lsearch -exact $current_ip_repo_paths $aes_hls_core_ip_repo] == -1 } {
	# concat space separated paths
	set current_ip_repo_paths [concat $current_ip_repo_paths $aes_hls_core_ip_repo]
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
	CONFIG.NUM_MI {3} \
] $usb_interface_0_axi_periph

# Create instance: AES128Encrypt_0, and set properties
set AES128Encrypt_0 [ create_bd_cell -type ip -vlnv xilinx.com:hls:AES128Encrypt:1.0 AES128Encrypt_0 ]

# BRAM controller for HLS core
set axi_bram_ctrl_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0 ]
set_property CONFIG.SINGLE_PORT_BRAM {1} $axi_bram_ctrl_0

# BRAM controller for external access
set axi_bram_ctrl_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_1 ]
set_property CONFIG.SINGLE_PORT_BRAM {1} $axi_bram_ctrl_1

# BRAM generation
set axi_bram_ctrl_0_bram [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 axi_bram_ctrl_0_bram ]
set_property CONFIG.Memory_Type {True_Dual_Port_RAM} $axi_bram_ctrl_0_bram

# Create instance: axi_smc, and set properties
set axi_smc [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc ]
set_property CONFIG.NUM_SI {1} $axi_smc

# interface connection
connect_bd_intf_net -intf_net AES128Encrypt_0_m_axi_data [get_bd_intf_pins AES128Encrypt_0/m_axi_data] [get_bd_intf_pins axi_smc/S00_AXI]

connect_bd_intf_net -intf_net axi_bram_ctrl_0_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTA] [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA]

connect_bd_intf_net -intf_net axi_bram_ctrl_1_BRAM_PORTA [get_bd_intf_pins axi_bram_ctrl_0_bram/BRAM_PORTB] [get_bd_intf_pins axi_bram_ctrl_1/BRAM_PORTA]

connect_bd_intf_net -intf_net axi_smc_M00_AXI [get_bd_intf_pins axi_smc/M00_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]

connect_bd_intf_net -intf_net usb_interface_0_axi_periph_M01_AXI [get_bd_intf_pins usb_interface_0_axi_periph/M01_AXI] [get_bd_intf_pins AES128Encrypt_0/s_axi_control]

connect_bd_intf_net -intf_net usb_interface_0_axi_periph_M02_AXI [get_bd_intf_pins usb_interface_0_axi_periph/M02_AXI] [get_bd_intf_pins axi_bram_ctrl_1/S_AXI]

# connect nets
connect_bd_net [get_bd_pins pll/clk_out1] [get_bd_pins rst_sys_clk/slowest_sync_clk] [get_bd_pins usb_interface_0_axi_periph/M01_ACLK] [get_bd_pins axi_smc/aclk] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk] [get_bd_pins AES128Encrypt_0/ap_clk] [get_bd_pins axi_bram_ctrl_1/s_axi_aclk] [get_bd_pins usb_interface_0_axi_periph/M02_ACLK]

connect_bd_net [get_bd_pins rst_sys_clk/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_1/s_axi_aresetn] [get_bd_pins usb_interface_0_axi_periph/M02_ARESETN]  [get_bd_pins usb_interface_0_axi_periph/M01_ARESETN] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn] [get_bd_pins axi_smc/aresetn] [get_bd_pins AES128Encrypt_0/ap_rst_n]

connect_bd_net -net axi_bram_ctrl_0_bram_addr_a [get_bd_pins axi_bram_ctrl_0/bram_addr_a] [get_bd_pins axi_bram_ctrl_0_bram/addra]

connect_bd_net -net axi_bram_ctrl_0_bram_clk_a [get_bd_pins axi_bram_ctrl_0/bram_clk_a] [get_bd_pins axi_bram_ctrl_0_bram/clka]

connect_bd_net -net axi_bram_ctrl_0_bram_douta [get_bd_pins axi_bram_ctrl_0_bram/douta] [get_bd_pins axi_bram_ctrl_0/bram_rddata_a]

connect_bd_net -net axi_bram_ctrl_0_bram_en_a [get_bd_pins axi_bram_ctrl_0/bram_en_a] [get_bd_pins axi_bram_ctrl_0_bram/ena] [get_bd_ports TIO4]

connect_bd_net -net axi_bram_ctrl_0_bram_rst_a [get_bd_pins axi_bram_ctrl_0/bram_rst_a] [get_bd_pins axi_bram_ctrl_0_bram/rsta]

connect_bd_net -net axi_bram_ctrl_0_bram_we_a [get_bd_pins axi_bram_ctrl_0/bram_we_a] [get_bd_pins axi_bram_ctrl_0_bram/wea]

connect_bd_net -net axi_bram_ctrl_0_bram_wrdata_a [get_bd_pins axi_bram_ctrl_0/bram_wrdata_a] [get_bd_pins axi_bram_ctrl_0_bram/dina]

# Create address segments
assign_bd_address -offset 0x40000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces usb_interface_0/M00_AXI] [get_bd_addr_segs axi_gpio/S_AXI/Reg] -force
assign_bd_address -offset 0x80000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces usb_interface_0/M00_AXI] [get_bd_addr_segs AES128Encrypt_0/s_axi_control/Reg] -force
assign_bd_address -offset 0xC0000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces usb_interface_0/M00_AXI] [get_bd_addr_segs axi_bram_ctrl_1/S_AXI/Mem0] -force
assign_bd_address -offset 0xC0000000 -range 0x00002000 -target_address_space [get_bd_addr_spaces AES128Encrypt_0/Data_m_axi_data] [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force


# Restore current instance
current_bd_instance $oldCurInst

save_bd_design
