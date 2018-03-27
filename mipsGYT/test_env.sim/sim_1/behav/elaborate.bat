@echo off
set xv_path=C:\\Xilinx\\Vivado\\2016.4\\bin
call %xv_path%/xelab  -wto 0bc377f08480400dbd0942f116e1cf72 -m64 --debug typical --relax --mt 2 -L xil_defaultlib -L secureip --snapshot test_env_behav xil_defaultlib.test_env -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
