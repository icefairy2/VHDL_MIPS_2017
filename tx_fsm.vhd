----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/27/2017 07:45:17 AM
-- Design Name: 
-- Module Name: tx_fsm - Behavioral
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

entity tx_fsm is
    Port ( clk : in STD_LOGIC;                          --board's clock
           tx_data : in STD_LOGIC_VECTOR (7 downto 0);
           tx_en : in STD_LOGIC;
           rst : in STD_LOGIC;
           baud_en : in STD_LOGIC;
           tx : out STD_LOGIC);
end tx_fsm;

architecture Behavioral of tx_fsm is

    type state_type is (idle, start, bits, stop);
    signal state : state_type;
    
    signal bit_cnt: STD_LOGIC_VECTOR(3 downto 0):= (others=>'0');
    signal tx_rdy: STD_LOGIC;
begin

    process1: process (clk, rst, tx_en, baud_en)
    begin
        if baud_en='1' then
            if (rst ='1') then
                state <=idle;
            elsif (clk='1' and clk'event) then
                case state is
                        when idle => if tx_en='1' then
                                        state <= start;
                                     end if;
                                     bit_cnt <= (others=>'0');
                        when start => state <= bits;
                        when bits => bit_cnt <= bit_cnt + 1;
                                     if bit_cnt=7 then
                                        state <= stop;
                                     end if;
                        when stop => state <= idle;
                end case;
            end if;
        end if;
    end process process1;
    
    process2: process (state)
    begin
    case state is 
        when idle => tx <= '1'; 
                     tx_rdy <= '1';
        when start => tx <= '0'; 
                      tx_rdy <= '0';
        when bits => tx <= tx_data(conv_integer(bit_cnt));
                     tx_rdy <= '0';
        when stop => tx <= '1'; 
                     tx_rdy <= '0';
    end case;
    end process process2;

end Behavioral;
