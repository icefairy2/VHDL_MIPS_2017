----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/27/2017 04:48:42 PM
-- Design Name: 
-- Module Name: test_env - Behavioral
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

entity test_env is
    Port ( clk : in STD_LOGIC;                          --board's clock
           btn : in STD_LOGIC_VECTOR(4 downto 0);       --buttons
           sw : in STD_LOGIC_VECTOR(15 downto 0);       --switches
           led : out STD_LOGIC_VECTOR(15 downto 0);     --leds
           an : out STD_LOGIC_VECTOR(3 downto 0);       --the anodes of the 7 segment display
           cat : out STD_LOGIC_VECTOR(6 downto 0);     --the cathodes of the 7 segment display
           rx : in STD_LOGIC;
           tx : out STD_LOGIC);
end test_env;

architecture Behavioral of test_env is

--The monopulse generator, smoothens out button presses
component monopulse is
    Port ( clk : in STD_LOGIC;
           btn : in STD_LOGIC_VECTOR(4 downto 0);
           outp : out STD_LOGIC_VECTOR(4 downto 0));
end component;

--Seven segment display
component ssd is
    Port ( digits : in STD_LOGIC_VECTOR (15 downto 0);
           clk : in STD_LOGIC;
           an : out STD_LOGIC_VECTOR (3 downto 0);
           cat : out STD_LOGIC_VECTOR (6 downto 0));
end component;

--Register file 
component reg_file is
    Port (  clk : in std_logic;
            ra1 : in std_logic_vector (2 downto 0);
            ra2 : in std_logic_vector (2 downto 0);
            wa : in std_logic_vector (2 downto 0);
            wd : in std_logic_vector (15 downto 0);
            wen : in std_logic;
            rd1 : out std_logic_vector (15 downto 0);
            rd2 : out std_logic_vector (15 downto 0) );
end component;

--Serial transmission FSM
component tx_fsm is
    port ( clk : in STD_LOGIC;                          --board's clock
           tx_data : in STD_LOGIC_VECTOR (7 downto 0);
           tx_en : in STD_LOGIC;
           rst : in STD_LOGIC;
           baud_en : in STD_LOGIC;
           tx : out STD_LOGIC);
end component;

signal count: STD_LOGIC_VECTOR(15 downto 0):= (others=>'0');
signal step: STD_LOGIC_VECTOR(4 downto 0);
signal digits: STD_LOGIC_VECTOR(15 downto 0);

signal rom_data:STD_LOGIC_VECTOR(15 downto 0);

signal reg_read1:STD_LOGIC_VECTOR(15 downto 0);
signal reg_read2:STD_LOGIC_VECTOR(15 downto 0);
signal reg_read_sum:STD_LOGIC_VECTOR(15 downto 0);

signal ram_data:STD_LOGIC_VECTOR(15 downto 0);
signal ram_data_in:STD_LOGIC_VECTOR(15 downto 0);

type mem is array (0 to 255) of STD_LOGIC_VECTOR(15 downto 0);
--Program counts the positive and the negative numbers 
--from the first k memory addresses
signal rom1 : mem := (B"000_010_010_010_0_110",     --xor $2, $2, $2                    x"0926"  0
                      B"000_011_011_011_0_110",     --xor $3, $3, $3                    x"0DB6"  1
                      B"000_100_100_100_0_110",     --xor $4, $4, $4                    x"1246"  2
                      B"000_101_101_101_0_110",     --xor $5, $5, $5                    x"16D6"  3
                      B"001_000_010_0001111",       --addi $2, $0, 15 <-- value of k    x"210F"  4
                      B"100_000_010_0000111",       --beq $2, $0, 7                     x"8107"  5
                      B"000_010_001_010_0_001",     --sub $2, $2, $1                    x"08A1"  6
                      B"010_010_101_0000000",       --lw $5, 0($2)                      x"4A80"  7
                      B"110_101_000_0000010",       --bltz $5, 2                        x"D402"  8
                      B"000_011_001_011_0_000",     --add $3, $3, $1                    x"0CB0"  9
                      B"111_0000000000101",         --j 5                               x"E005"  10
                      B"000_100_001_100_0_000",     --add $4, $4, $1                    x"10C0"  11
                      B"111_0000000000101",         --j 5                               x"E005"  12
                      B"011_000_011_0010100",       --sw $3, 20($0)                     x"6194"  13
                      B"011_000_100_0010101",       --sw $4, 21($0)                     x"6215"  14
                      others => x"0000");

--int n = 0, p = 0;
--int k = 15;
--while (k != 0) {
--    k--;
--    if ( m[k] >= 0)
--        p++;
--    else
--        n++;
--}

signal ram1 : mem := (x"0044", x"0001", x"0002", x"0004", 
                      x"F000", x"00F1", x"0702", x"8004",
                      x"FF00", x"0001", x"0002", x"0B04",
                      x"0340", x"E001", x"A002", x"0004",
                      x"0000", x"0001", x"0002", x"0004",
                      x"0008", x"0012", x"0123", x"1234", others => x"0000");

signal ext_imm: STD_LOGIC_VECTOR(15 downto 0):= (others=>'0'); 
signal aluRes: STD_LOGIC_VECTOR(15 downto 0):= (others=>'0'); 

--Controls
signal control:STD_LOGIC_VECTOR(8 downto 0);
signal PCSrc:STD_LOGIC;
signal muxRegDst:STD_LOGIC_VECTOR(2 downto 0);
signal aluOperand:STD_LOGIC_VECTOR(15 downto 0);
signal aluCtrl:STD_LOGIC_VECTOR(2 downto 0);
signal zeroFlag:STD_LOGIC;
signal regWrite:STD_LOGIC;
signal memWrite:STD_LOGIC;
signal muxMemReg:STD_LOGIC_VECTOR(15 downto 0);

signal fsm_count:STD_LOGIC_VECTOR(15 downto 0):= (others=>'0');
signal baud_en:STD_LOGIC;

begin

    monop: monopulse port map (clk => clk,
                               btn => btn,
                               outp => step);
    ssdunit: ssd port map (digits => digits,
                           clk => clk,
                           an => an,
                           cat =>cat);
                           
    fsm: tx_fsm port map (clk => clk,            
                          tx_data => sw(15 downto 8),
                          tx_en => '1',
                          rst => '0',
                          baud_en => baud_en,
                          tx => tx);
                          
    process(clk)
    begin
        if rising_edge(clk) then
            if fsm_count=10416 then
                baud_en <= '1';
                fsm_count <= (others=>'0');
            else
                baud_en <= '0';
                fsm_count <= fsm_count + 1;
            end if;
        end if;
    end process;
    
    --ROM
    rom_data <= rom1(conv_integer(count(7 downto 0)));
    
    --MUX Register Destination 2x1
    muxRegDst <= rom_data(9 downto 7) when control(8) = '0' else rom_data(6 downto 4);
    
    regWrite <= control(7) and step(0);
    
    --Register file
    reg_file1: reg_file port map(clk => clk,
                                 ra1 => rom_data(12 downto 10),
                                 ra2 => rom_data(9 downto 7), 
                                 wa => muxRegDst, 
                                 wd => muxMemReg,
                                 wen => regWrite,
                                 rd1 => reg_read1,
                                 rd2 => reg_read2); 
    reg_read_sum <= reg_read1 + reg_read2;  
    
    memWrite <= control(0) and step(0);
    
    --RAM 
    process (clk, memWrite)
    begin
       if rising_edge(clk) then
          if memWrite = '1' then
             ram1(conv_integer(aluRes)) <= ram_data_in;
          end if;
       end if;
    end process;
    ram_data <= ram1(conv_integer(aluRes));
    ram_data_in <= reg_read2;
       
    --MUX Memory Register 2x1
    muxMemReg <= aluRes when control(6) = '0' else ram_data;
    
--    process (sw(0), sw(1))
--    begin
--      jump <= sw(0); 
--      PCSrc <= sw(1);
--    end process;

    PCSrc <= (control(4) and zeroFlag) or (control(3) and not(aluRes(15))) or (control(2) and aluRes(15)); 
     
    --Sign extension
    process(rom_data(6 downto 0))
    begin
        ext_imm <= (others => rom_data(6));
        ext_imm(6 downto 0) <= rom_data(6 downto 0); 
    end process;
       
    --Instruction Fetch PC
    process (step(0),clk) 
    begin
       if clk='1' and clk'event then
        if step(3)='1' then  
             count <= (others=>'0');          
        elsif step(0)='1' then
          if control(1) = '1' then                          --jump
             count <= "000" & rom_data(12 downto 0);
          elsif PCSrc = '1' then                            --branch
               count <= ext_imm + count + 1;
             else
               count <= count + 1;
             end if;
          end if;
       end if; 
    end process;
    
    --Instruction Decode
    process (rom_data(15 downto 13))
    begin
         case rom_data(15 downto 13) is
           when "000"     => control <= "110000000";
           when "001"     => control <= "010100000";
           when "010"     => control <= "011100000";
           when "011"     => control <= "000100001";
           when "100"     => control <= "000010000";
           when "101"     => control <= "000001000";
           when "110"     => control <= "000000100";
           when others     => control <= "000000010";
         end case;
    end process;
    
--    process (sw(7))
--    begin
--        if sw(7) = '1' then
--            digits <= count + 1;
--        else
--            digits <= rom_data;
--        end if;
--    end process;
       
    led <= rom_data(2 downto 0) & "0000" & control;
    
   --MUX 3x16
   process (sw(2 downto 0))
   begin
        case sw(2 downto 0) is
          when "000"     => digits <= rom_data;
          when "001"     => digits <= count;
          when "010"     => digits <= reg_read1;
          when "011"     => digits <= reg_read2;
          when "100"     => digits <= ext_imm;
          when "101"     => digits <= aluRes;
          when "110"     => digits <= ram_data;
          when others     => digits <= ram_data_in;
        end case;
   end process;
   
--Hex conversion
--    process(tmp)
--    begin
--        case tmp(3 downto 0) is
--            when "0000"     => led <= x"0001";
--            when "0001"     => led <= x"0002";
--            when "0010"     => led <= x"0004";
--            when "0011"     => led <= x"0008";
--            when "0100"     => led <= x"0010";
--            when "0101"     => led <= x"0020";
--            when "0110"     => led <= x"0040";
--            when "0111"     => led <= x"0080";
--            when "1000"     => led <= x"0100";
--            when "1001"     => led <= x"0200";
--            when "1010"     => led <= x"0400";
--            when "1011"     => led <= x"0800";
--            when "1100"     => led <= x"1000";
--            when "1101"     => led <= x"2000";
--            when "1110"     => led <= x"4000";
--            when others     => led <= x"8000"; 
--        end case;
--    end process;

    --MUX ALU Source 2x1
    aluOperand <= reg_read2 when control(5) = '0' else ext_imm;

    --ALU Control
    process(rom_data(15 downto 13), rom_data(2 downto 0))
    begin
    case rom_data(15 downto 13) is
        when "000" => aluCtrl <= rom_data(2 downto 0);
        when "100" => aluCtrl <= "001";
        when others => aluCtrl <= "000";
    end case;
    end process;

    --ALU
    process(reg_read1, aluOperand, aluCtrl)
    begin
    case aluCtrl is
        when "000" => aluRes <= reg_read1 + aluOperand;
        when "001" => aluRes <= reg_read1 - aluOperand;
        when "010" => aluRes <= aluOperand (14 downto 0) & '0';
        when "011" => aluRes <= '0' & aluOperand (15 downto 1);
        when "100" => aluRes <= reg_read1 and aluOperand;
        when "101" => aluRes <= reg_read1 or aluOperand;
        when "110" => aluRes <= reg_read1 xor aluOperand;
        when others => if reg_read1 < aluOperand then
                         aluRes <= conv_std_logic_vector(1, 16);
                       else
                         aluRes <= conv_std_logic_vector(0, 16);
                       end if;                 
    end case;
    end process;
    
    --ALU zero flag
    zeroFlag <= '1' when aluRes = 0 else '0';

end Behavioral;
