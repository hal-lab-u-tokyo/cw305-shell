set_false_path -from [get_pins -hier *r_ack_reg*/C] -to [get_pins -hier *r_ack_sync_stage*/D]
set_false_path -from [get_pins -hier *r_req*/C] -to [get_pins -hier *r_req_sync_stage*/D]
