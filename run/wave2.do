onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group miu /testbench/miu/clk
add wave -noupdate -group miu /testbench/miu/reset
add wave -noupdate -group miu /testbench/miu/cpu_req_pkt_xx
add wave -noupdate -group miu /testbench/miu/cpu_req_ack_xx
add wave -noupdate -group miu /testbench/miu/cpu_resp_pkt_xx
add wave -noupdate -group miu /testbench/miu/mem_addr
add wave -noupdate -group miu /testbench/miu/mem_valid
add wave -noupdate -group miu /testbench/miu/mem_wdata
add wave -noupdate -group miu /testbench/miu/mem_wmask
add wave -noupdate -group miu /testbench/miu/mem_rdata
add wave -noupdate -group miu /testbench/miu/mem_ready
add wave -noupdate -group miu /testbench/miu/pkt_t0
add wave -noupdate -group miu /testbench/miu/pkt_t1
add wave -noupdate -group miu /testbench/miu/pkt_t1_r
add wave -noupdate -group miu /testbench/miu/pkt_t2
add wave -noupdate -group miu /testbench/miu/pkt_t2_nx
add wave -noupdate -group miu /testbench/miu/wbyte_shift
add wave -noupdate -group miu /testbench/miu/write_t1
add wave -noupdate -group miu /testbench/miu/read_t2
add wave -noupdate -group tb_mem /testbench/tb_mem/clk
add wave -noupdate -group tb_mem /testbench/tb_mem/rst
add wave -noupdate -group tb_mem /testbench/tb_mem/mem_addr
add wave -noupdate -group tb_mem /testbench/tb_mem/mem_valid
add wave -noupdate -group tb_mem /testbench/tb_mem/mem_wdata
add wave -noupdate -group tb_mem /testbench/tb_mem/mem_wmask
add wave -noupdate -group tb_mem /testbench/tb_mem/mem_rdata
add wave -noupdate -group tb_mem /testbench/tb_mem/mem_ready
add wave -noupdate -group tb_mem /testbench/tb_mem/bus_addr
add wave -noupdate -group tb_mem /testbench/tb_mem/bus_valid
add wave -noupdate -group tb_mem /testbench/tb_mem/bus_wdata
add wave -noupdate -group tb_mem /testbench/tb_mem/bus_wmask
add wave -noupdate -group tb_mem /testbench/tb_mem/bus_rdata
add wave -noupdate -group tb_mem /testbench/tb_mem/bus_ready
add wave -noupdate -group tb_mem /testbench/tb_mem/HCLK
add wave -noupdate -group tb_mem /testbench/tb_mem/HRESETn
add wave -noupdate -group tb_mem /testbench/tb_mem/HADDR
add wave -noupdate -group tb_mem /testbench/tb_mem/HTRANS
add wave -noupdate -group tb_mem /testbench/tb_mem/HSIZE
add wave -noupdate -group tb_mem /testbench/tb_mem/HWRITE
add wave -noupdate -group tb_mem /testbench/tb_mem/HWDATA
add wave -noupdate -group tb_mem /testbench/tb_mem/HRDATA
add wave -noupdate -group tb_mem /testbench/tb_mem/HREADY
add wave -noupdate -group tb_mem /testbench/tb_mem/HRESP
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/clk
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/rst
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/s_addr
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/s_valid
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/s_wdata
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/s_wmask
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/s_rdata
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/s_ready
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/m_addr
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/m_valid
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/m_wdata
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/m_wmask
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/m_rdata
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/m_ready
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/high_part
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/high_part_nx
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/m_transtn
add wave -noupdate -expand -group mem_szdn -radix hexadecimal /testbench/tb_mem/mem_szdn/lower_ldata

add wave -noupdate -group cpu_ahb_master -radix hexadecimal /testbench/tb_mem/cpu_ahb_master/*

add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/HCLK
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/HRESETn
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/HADDR
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/HTRANS
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/HSIZE
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/HWRITE
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/HWDATA
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/HRDATA
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/HREADY
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/HRESP
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/HSEL
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/HREADYOUT
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/wa
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/we
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/wd
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/ra
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/re
add wave -noupdate -group ahb_bram /testbench/tb_mem/ahb_lite_bram/rd
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/HCLK
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/HRESETn
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/HADDR
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/HTRANS
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/HSIZE
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/HWRITE
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/HWDATA
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/HRDATA
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/HREADY
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/HRESP
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/HSEL
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/HREADYOUT
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/wa
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/we
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/wd
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/ra
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/re
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/rd
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/request
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/wmask
add wave -noupdate -group ahb_sdp /testbench/tb_mem/ahb_lite_bram/ahb_lite_sdp/write_first
add wave -noupdate -group bram_sdp /testbench/tb_mem/ahb_lite_bram/bram_sdp/clk
add wave -noupdate -group bram_sdp /testbench/tb_mem/ahb_lite_bram/bram_sdp/wa
add wave -noupdate -group bram_sdp /testbench/tb_mem/ahb_lite_bram/bram_sdp/we
add wave -noupdate -group bram_sdp /testbench/tb_mem/ahb_lite_bram/bram_sdp/wd
add wave -noupdate -group bram_sdp /testbench/tb_mem/ahb_lite_bram/bram_sdp/ra
add wave -noupdate -group bram_sdp /testbench/tb_mem/ahb_lite_bram/bram_sdp/re
add wave -noupdate -group bram_sdp /testbench/tb_mem/ahb_lite_bram/bram_sdp/rd
add wave -noupdate -group bram_sdp /testbench/tb_mem/ahb_lite_bram/bram_sdp/rdata
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1357451 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
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
WaveRestoreZoom {0 ps} {2110500 ps}
