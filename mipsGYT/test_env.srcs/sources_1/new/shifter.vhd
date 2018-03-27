----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 03/15/2017 11:59:01 PM
-- Design Name: 
-- Module Name: shifter - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity shifter is
Port ( clk : in STD_LOGIC;
           btn : in STD_LOGIC_VECTOR(4 downto 0);
           sw : in STD_LOGIC_VECTOR(15 downto 0);
           led : out STD_LOGIC_VECTOR(15 downto 0);
           an : out STD_LOGIC_VECTOR(3 downto 0);
           cat : out STD_LOGIC_VECTOR(6 downto 0));
end shifter;

architecture Behavioral of shifter is

signal shift1: STD_LOGIC_VECTOR(4 downto 0);
signal shift2: STD_LOGIC_VECTOR(4 downto 0);

begin

    process(sw)
    begin
        if sw(5) = '1' then -- shift with 1 position
            if sw(7) = '0' then
                shift1 <= sw(3 downto 0) & '0'; -- shift left
            else
                shift1 <= sw(4) & sw(4 downto 1); -- shift right arithmetic
            end if;
         else
        shift1 <= sw(4 downto 0);
        end if;
    end process;
    
    process(sw, shift1)
    begin
        if sw(6) = '1' then -- shift with 2 position
            if sw(7) = '0' then
                shift2 <= shift1(2 downto 0) & "00"; -- shift left
            else
                shift2 <= shift1(4) & shift1(4) & shift1(4 downto 2); -- shift right arithmetic
            end if;
        else
            shift2 <= shift1;
        end if;
    end process;
    led <= shift2 & "00000000000";

end Behavioral;
