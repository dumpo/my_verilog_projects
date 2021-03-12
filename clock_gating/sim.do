onbreak resume
onerror resume
vsim -voptargs=+acc work.clock_delay_tb
add wave -position insertpoint  \
sim:/clock_delay_tb/u1/rst \
sim:/clock_delay_tb/u1/clk_in \
sim:/clock_delay_tb/u1/clk_out \
sim:/clock_delay_tb/u1/carry \
sim:/clock_delay_tb/u1/cnt1 \
sim:/clock_delay_tb/u1/cnt2 \
sim:/clock_delay_tb/u1/clk_EN
run -all