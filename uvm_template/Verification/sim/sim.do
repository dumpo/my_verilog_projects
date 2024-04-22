setenv WORK_AERA "D:/software/uvm_template"

#testcase name
set TEST "my_case0"

#name related to the the dut
set TOP "top_tb"
set DUT_LIST "dut.f"
set FILE_LIST "filelist.f"


set WAVE_TOP "sim:/top_tb/*"


#PLI for dump fsdb
set PLI ""

#the uvm 
set  UVM_DPI_HOME  D:/software/questasim64_2020.1/uvm-1.1d/win64
set UVM_HOME D:/software/questasim64_2020.1/verilog_src/uvm-1.1d
set WORK_HOME "D:/software/uvm_template/Verification/sim"

quit -sim  
cd ${WORK_HOME}
  
if [file exists work] {  
  vdel -all  
}  
vlib work  
vlog  -L mtiAvm -L mtiOvm -L mtiUvm -L mtiUPF -f ${DUT_LIST} -f ${FILE_LIST}
vsim -c +notimingchecks -t 1ps ${TOP} +UVM_TESTNAME=${TEST} +UVM_VERBOSITY=UVM_FULL -voptargs=+acc \
-solvefaildebug -uvmcontrol=all -classdebug -l sim.log -pli ${PLI} \
-sv_lib ${UVM_DPI_HOME}/uvm_dpi 
add log  -r /*
add wave ${WAVE_TOP}
run -all