vlib work
#vmap work(�߼�������)  <library name>(���·��)
vlog  ser*.v
onbreak resume
onerror resume
vsim -voptargs=+acc work.DUT2
add wave -position insertpoint  \
sim:/DUT2/out \
sim:/DUT2/clk \
sim:/DUT2/rst_n \
sim:/DUT2/in \
sim:/DUT2/load 
run -all