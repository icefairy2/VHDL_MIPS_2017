# 
# Synthesis run script generated by Vivado
# 

set_param xicom.use_bs_reader 1
set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000
create_project -in_memory -part xc7a35tcpg236-1

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir {D:/Desktop/Computer Science year 2 sem II/VHDL programs/OneDrive-2017-05-03/mipsGYT/test_env.cache/wt} [current_project]
set_property parent.project_path {D:/Desktop/Computer Science year 2 sem II/VHDL programs/OneDrive-2017-05-03/mipsGYT/test_env.xpr} [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language Verilog [current_project]
set_property ip_cache_permissions disable [current_project]
read_vhdl -library xil_defaultlib {
  {D:/Desktop/Computer Science year 2 sem II/VHDL programs/OneDrive-2017-05-03/mipsGYT/test_env.srcs/sources_1/imports/OneDrive-2017-05-03/tx_fsm.vhd}
  {D:/Desktop/Computer Science year 2 sem II/VHDL programs/OneDrive-2017-05-03/mipsGYT/test_env.srcs/sources_1/new/ssd.vhd}
  {D:/Desktop/Computer Science year 2 sem II/VHDL programs/OneDrive-2017-05-03/mipsGYT/test_env.srcs/sources_1/new/rx_fsm.vhd}
  {D:/Desktop/Computer Science year 2 sem II/VHDL programs/OneDrive-2017-05-03/mipsGYT/test_env.srcs/sources_1/new/reg_file.vhd}
  {D:/Desktop/Computer Science year 2 sem II/VHDL programs/OneDrive-2017-05-03/mipsGYT/test_env.srcs/sources_1/new/monopulse.vhd}
  {D:/Desktop/Computer Science year 2 sem II/VHDL programs/OneDrive-2017-05-03/mipsGYT/test_env.srcs/sources_1/new/test_env.vhd}
}
foreach dcp [get_files -quiet -all *.dcp] {
  set_property used_in_implementation false $dcp
}
read_xdc {{D:/Desktop/Computer Science year 2 sem II/VHDL programs/OneDrive-2017-05-03/mipsGYT/test_env.srcs/constrs_1/new/Basys3_test_env.xdc}}
set_property used_in_implementation false [get_files {{D:/Desktop/Computer Science year 2 sem II/VHDL programs/OneDrive-2017-05-03/mipsGYT/test_env.srcs/constrs_1/new/Basys3_test_env.xdc}}]


synth_design -top test_env -part xc7a35tcpg236-1


write_checkpoint -force -noxdef test_env.dcp

catch { report_utilization -file test_env_utilization_synth.rpt -pb test_env_utilization_synth.pb }