----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 05/04/2017 07:46:40 AM
-- Design Name: 
-- Module Name: rx_fsm - Behavioral
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

entity rx_fsm is
    Port ( rx : in STD_LOGIC;
           rx_rdy : out STD_LOGIC;
           rx_data : out STD_LOGIC_VECTOR (7 downto 0);
           baud_en : in STD_LOGIC;
           rst : in STD_LOGIC;
           clk : in STD_LOGIC);
end rx_fsm;

architecture Behavioral of rx_fsm is
type state_type is (idle, start, bits, stop, waits);
    signal state : state_type;
    
    signal bit_cnt: STD_LOGIC_VECTOR(3 downto 0):= (others=>'0');
    signal baud_cnt: STD_LOGIC_VECTOR(3 downto 0):= (others=>'0');
    
begin

    process(clk, baud_en)
    begin
        if rising_edge(clk) then
            if baud_en='1' then   
                baud_cnt <= baud_cnt + 1;
            end if;
        end if;
    end process;

    process1: process (clk, rst, baud_en)
    begin
        if baud_en='1' then
            if (rst ='1') then
                state <=idle;
            elsif (clk='1' and clk'event) then
                case state is
                        when idle => if rx='0' then
                                        state <= start;
                                     end if;
                                     bit_cnt <= (others=>'0');
                        when start => if rx='1' then
                                        state<=idle;
                                      else
                                        if baud_cnt=7 then
                                            state<=bits;
                                        end if;
                                      end if;
                        when bits => bit_cnt <= bit_cnt + 1;
                                     if bit_cnt=7 then
                                        if baud_cnt=15 then
                                            state <= stop;
                                        end if;
                                     end if;
                        when stop => if baud_cnt=15 then
                                        state<=waits;
                                     end if;
                        when waits => if baud_cnt=7 then
                                        state<=idle;
                                      end if;
                end case;
            end if;
        end if;
    end process process1;
    
    process2: process (state)
    begin
    case state is 
        when idle => rx_rdy <= '0';                    
        when start => rx_rdy <= '0';
        when bits => rx_rdy <= '0';
        when stop => rx_rdy <= '0';
        when waits => rx_rdy <= '1';
    end case;
    end process process2;


end Behavioral;
