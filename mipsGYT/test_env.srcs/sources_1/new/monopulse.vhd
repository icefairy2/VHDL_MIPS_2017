----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/07/2017 07:29:43 PM
-- Design Name: 
-- Module Name: monopulse - Behavioral
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

entity monopulse is
    Port ( clk : in STD_LOGIC;
           btn : in STD_LOGIC_VECTOR(4 downto 0);
           outp : out STD_LOGIC_VECTOR(4 downto 0));
end monopulse;

architecture Behavioral of monopulse is

signal count: STD_LOGIC_VECTOR(15 downto 0):= (others=>'0');
signal Q1:STD_LOGIC_VECTOR(4 downto 0);
signal Q2:STD_LOGIC_VECTOR(4 downto 0);
signal Q3:STD_LOGIC_VECTOR(4 downto 0);

begin
  process(count,clk)
  begin
	if clk='1' and clk'event then
	   count<=count+1;
	end if;
  end process;
  
  process(count, clk, btn)
  begin
    if clk='1' and clk'event then
        if count=15 then
            Q1<=btn;
        end if;
    end if;
  end process;
  
  process(clk, Q1)
  begin
    if clk='1' and clk'event then
       Q2<=Q1;
    end if;
  end process;
  
  process(clk, Q2)
    begin
      if clk='1' and clk'event then
         Q3<=Q2;
      end if;
   end process;
  
  outp<=(not Q3) and Q2;
end Behavioral;
