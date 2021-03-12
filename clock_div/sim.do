onbreak resume
onerror resume
vsim -voptargs=+acc work.DUT
#vsim
add wave *
add wave -position insertpoint  \
sim:/DUT/div1/clk_n \
sim:/DUT/div1/clk_p \
sim:/DUT/div1/cnt1 \
sim:/DUT/div1/cnt2 


run -all