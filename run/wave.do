onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/reset
add wave -noupdate -divider MEM
add wave -noupdate -radix hexadecimal /testbench/uut/biu/mem_req_pkt_xx
add wave -noupdate /testbench/uut/biu/mem_req_ack_xx
add wave -noupdate /testbench/uut/biu/mem_resp_pkt_xx
add wave -noupdate -divider Issue
add wave -noupdate /testbench/uut/ifu/redir_vld
add wave -noupdate /testbench/uut/ifu/redir_addr
add wave -noupdate /testbench/uut/igu/i_issue_id
add wave -noupdate /testbench/uut/idecode/decoded_instn
add wave -noupdate /testbench/uut/igu/instn_pc_id
add wave -noupdate /testbench/uut/ifu/ibuf/instn_opcode_id
add wave -noupdate -divider Grad
add wave -noupdate /testbench/uut/igu/ctu_force_rdr_e1
add wave -noupdate /testbench/uut/mpu_busy_xx
add wave -noupdate /testbench/uut/igu/lsu_valid_e1
add wave -noupdate /testbench/uut/igu/nonsynth_idecode/decoded_instn
add wave -noupdate /testbench/uut/igu/cpu_halt_xx
add wave -noupdate /testbench/uut/igu/instn_pc_e1
add wave -noupdate -divider LSU
add wave -noupdate /testbench/uut/lsu/inst_ld_e0
add wave -noupdate /testbench/uut/lsu/enable
add wave -noupdate /testbench/uut/lsu/lsu_op
add wave -noupdate /testbench/uut/lsu/lsu_busy
add wave -noupdate /testbench/uut/lsu/read_e0
add wave -noupdate /testbench/uut/lsu/va_e0
add wave -noupdate /testbench/uut/lsu/replay
add wave -noupdate /testbench/uut/lsu/req_ld_miss_e1
add wave -noupdate /testbench/uut/lsu/write_xx
add wave -noupdate /testbench/uut/lsu/write_data_xx
add wave -noupdate /testbench/uut/lsu/write_addr_xx
add wave -noupdate /testbench/uut/lsu/read_addr_e0
add wave -noupdate /testbench/uut/lsu/dc_data_e1
add wave -noupdate /testbench/uut/lsu/data_zext_e1
add wave -noupdate /testbench/uut/lsu/rvalid
add wave -noupdate /testbench/uut/igu/instn_cmplt_gr
add wave -noupdate /testbench/uut/igu/squash_result_gr
add wave -noupdate -divider ARF
add wave -noupdate /testbench/uut/regfile/wr_en
add wave -noupdate -radix unsigned /testbench/uut/regfile/wr_addr
add wave -noupdate /testbench/uut/regfile/wr_data
add wave -noupdate -divider Exception
add wave -noupdate /testbench/uut/cpr/e_enter
add wave -noupdate /testbench/uut/cpr/e_exit
add wave -noupdate /testbench/uut/cpr/cpr_epc_xx
add wave -noupdate /testbench/uut/cpr/cpr_inst_xx
add wave -noupdate /testbench/uut/cpr/cpr_cause_xx
add wave -noupdate -radix unsigned /testbench/uut/cpr/cpr_icount_xx
add wave -noupdate -radix unsigned /testbench/uut/cpr/cpr_cc_xx
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {16021039 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 160
configure wave -valuecolwidth 136
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {15907127 ps} {16100559 ps}
