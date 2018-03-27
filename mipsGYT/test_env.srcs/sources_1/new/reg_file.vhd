----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/16/2017 01:09:24 AM
-- Design Name: 
-- Module Name: reg_file - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity reg_file is
    Port (  clk : in std_logic;                             --clock signal
            ra1 : in std_logic_vector (2 downto 0);         --read address 1
            ra2 : in std_logic_vector (2 downto 0);         --read address 2
            wa : in std_logic_vector (2 downto 0);          --write address
            wd : in std_logic_vector (15 downto 0);         --data to be written on wa
            wen : in std_logic;                             --write enable
            rd1 : out std_logic_vector (15 downto 0);       --data read from ra1
            rd2 : out std_logic_vector (15 downto 0) );     --data read from ra2
end reg_file;

architecture Behavioral of reg_file is

    --16x16 bit register file
    type reg_array is array (0 to 7) of std_logic_vector(15 downto 0);
    --initialize the values
    signal reg_file : reg_array := (x"0000", x"0001", x"0002", x"0003",
                                    x"0004", x"0005", x"0006", others => x"0000");
    
begin

    --One synchronous write
    process(clk)
    begin
        if rising_edge(clk) then
            if wen = '1' then
                reg_file(conv_integer(wa)) <= wd;
            end if;
        end if;
    end process;
    
    --Two asynchronous reads
    rd1 <= reg_file(conv_integer(ra1));
    rd2 <= reg_file(conv_integer(ra2));
    
end Behavioral;
