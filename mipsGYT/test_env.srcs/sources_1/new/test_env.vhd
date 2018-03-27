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

--Serial transmission TX FSM
component tx_fsm is
    port ( clk : in STD_LOGIC;                          --board's clock
           tx_data : in STD_LOGIC_VECTOR (7 downto 0);
           tx_en : in STD_LOGIC;
           rst : in STD_LOGIC;
           baud_en : in STD_LOGIC;
           tx : out STD_LOGIC;
           tx_rdy: out STD_LOGIC);
end component;

--Serial transmission RX FSM
component rx_fsm is
    Port ( rx : in STD_LOGIC;
           rx_rdy : out STD_LOGIC;
           rx_data : out STD_LOGIC_VECTOR (7 downto 0);
           baud_en : in STD_LOGIC;
           rst : in STD_LOGIC;
           clk : in STD_LOGIC);
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
signal tx_rdy:STD_LOGIC;
signal rx_rdy:STD_LOGIC;

signal Dnew, Dold:STD_LOGIC;
signal tx_sel:STD_LOGIC;
signal tx_en:STD_LOGIC;
signal tx_count:STD_LOGIC_VECTOR(2 downto 0):= (others=>'0');
signal tx_data:STD_LOGIC_VECTOR(7 downto 0):= (others=>'0');
signal rx_data:STD_LOGIC_VECTOR(7 downto 0):= (others=>'0');

signal dcd_enter:STD_LOGIC_VECTOR(3 downto 0):= (others=>'0');

signal D1count: STD_LOGIC_VECTOR(15 downto 0):= (others=>'0');
signal D2count: STD_LOGIC_VECTOR(15 downto 0):= (others=>'0');
signal D3count: STD_LOGIC_VECTOR(15 downto 0):= (others=>'0');
signal D1rom_data:STD_LOGIC_VECTOR(15 downto 0);
signal D2rom_data:STD_LOGIC_VECTOR(15 downto 0);
signal D2regWrite:STD_LOGIC;
signal D2memWrite:STD_LOGIC;
signal D2regDst:STD_LOGIC;
signal D3regWrite:STD_LOGIC;
signal D3memWrite:STD_LOGIC;
signal D4regWrite:STD_LOGIC;
signal D3muxRegDst:STD_LOGIC_VECTOR(2 downto 0);
signal D4muxRegDst:STD_LOGIC_VECTOR(2 downto 0);
signal D4ram_data:STD_LOGIC_VECTOR(15 downto 0);
signal D3aluRes: STD_LOGIC_VECTOR(15 downto 0):= (others=>'0'); 
signal D4aluRes: STD_LOGIC_VECTOR(15 downto 0):= (others=>'0'); 
signal D2ext_imm: STD_LOGIC_VECTOR(15 downto 0):= (others=>'0'); 
signal D2reg_read1:STD_LOGIC_VECTOR(15 downto 0);
signal D2reg_read2:STD_LOGIC_VECTOR(15 downto 0);
signal D3reg_read2:STD_LOGIC_VECTOR(15 downto 0);
signal D2memReg:STD_LOGIC;
signal D3memReg:STD_LOGIC;
signal D4memReg:STD_LOGIC;
signal D2control:STD_LOGIC_VECTOR(8 downto 0);
signal D3control:STD_LOGIC_VECTOR(8 downto 0);

begin

    monop: monopulse port map (clk => clk,
                               btn => btn,
                               outp => step);
    ssdunit: ssd port map (digits => digits,
                           clk => clk,
                           an => an,
                           cat =>cat);
                           
    fsmTX: tx_fsm port map (clk => clk,            
                          tx_data => tx_data,
                          tx_en => tx_en,
                          rst => '0',
                          baud_en => baud_en,
                          tx => tx,
                          tx_rdy => tx_rdy);
    
    fsmRX: rx_fsm port map (rx => rx,
                            rx_rdy => rx_rdy,
                            rx_data => rx_data,
                            baud_en => baud_en,
                            rst => '0',
                            clk => clk); 
   
    --Baud enable                                                       
    process(clk)
    begin
        if rising_edge(clk) then
            if fsm_count=10415 then    --tx10416  rx651
                baud_en <= '1';
                fsm_count <= (others=>'0');
            else
                baud_en <= '0';
                fsm_count <= fsm_count + 1;
            end if;
        end if;
    end process;
    
    --2 bit shift register
    process(clk)
    begin
        if rising_edge(clk) then
            Dnew <= tx_rdy;
            Dold <= Dnew;
        end if;
    end process;
    
    tx_sel <= Dnew and (not Dold);
    
    --Counter 4
    process(clk, tx_sel)
    begin
        if rising_edge(clk) then
            if tx_sel = '1' then
                tx_count <= tx_count + 1;
            else if tx_count = 4 then
                    tx_count <= (others=>'0');
                 end if;
            end if;
        end if;
     end process;
     
     --TX enable
     process(tx_count, clk, step(1))
     begin
         if rising_edge(clk) then
           if tx_count = 4 then
                tx_en <= '0';
           else if step(1) = '1' then
                    tx_en <='1';
                end if;
           end if;
         end if;
     end process;
      
     --4 character MUX
     process(tx_count, sw(15 downto 0))
     begin
        case tx_count is
            when "000" => dcd_enter <= rom_data(15 downto 12);
            when "001" => dcd_enter <= rom_data(11 downto 8);
            when "010" => dcd_enter <= rom_data(7 downto 4);
            when others => dcd_enter <= rom_data(3 downto 0);
        end case;
     end process;  
       
     --Decoder
     process(dcd_enter)
     begin
        if dcd_enter<10 then
            tx_data <= x"30" + dcd_enter;
        else
            tx_data <= x"37" + dcd_enter;
        end if;
     end process;
                    
    --ROM
    rom_data <= rom1(conv_integer(count(7 downto 0)));
    
    --MUX Register Destination 2x1
    muxRegDst <= D2rom_data(9 downto 7) when D2regDst = '0' else D2rom_data(6 downto 4);
    
    regWrite <= D4regWrite and step(0);
    
    --Register file
    reg_file1: reg_file port map(clk => clk,
                                 ra1 => D1rom_data(12 downto 10),
                                 ra2 => D1rom_data(9 downto 7), 
                                 wa => D4muxRegDst, 
                                 wd => muxMemReg,
                                 wen => regWrite,
                                 rd1 => reg_read1,
                                 rd2 => reg_read2); 
    reg_read_sum <= reg_read1 + reg_read2;  
    
    memWrite <= D3memWrite and step(0);
    
    --RAM 
    process (clk, memWrite)
    begin
       if rising_edge(clk) then
          if memWrite = '1' then
             ram1(conv_integer(D3aluRes)) <= ram_data_in;
          end if;
       end if;
    end process;
    ram_data <= ram1(conv_integer(D3aluRes));
    ram_data_in <= D3reg_read2;
       
    --MUX Memory Register 2x1
    muxMemReg <= D4aluRes when D4memReg = '0' else D4ram_data;
    
--    process (sw(0), sw(1))
--    begin
--      jump <= sw(0); 
--      PCSrc <= sw(1);
--    end process;

    PCSrc <= (D3control(4) and zeroFlag) or (D3control(3) and not(D3aluRes(15))) or (D3control(2) and D3aluRes(15)); 
     
    --Sign extension
    process(D1rom_data(6 downto 0))
    begin
        ext_imm <= (others => D1rom_data(6));
        ext_imm(6 downto 0) <= D1rom_data(6 downto 0); 
    end process;
       
    --Instruction Fetch PC
    process (step(0),clk) 
    begin
       if clk='1' and clk'event then
        if step(3)='1' then  
             count <= (others=>'0');          
        elsif step(0)='1' then
          if control(1) = '1' then                          --jump
             count <= "000" & D1rom_data(12 downto 0);
          elsif PCSrc = '1' then                            --branch
               count <= D3count;
             else
               count <= count + 1;
             end if;
          end if;
       end if; 
    end process;
    
    --Instruction Decode
    process (D1rom_data(15 downto 13))
    begin
         case D1rom_data(15 downto 13) is
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
          when "001"     => digits <= D1rom_data;
          when "010"     => digits <= count;
          when "011"     => digits <= reg_read1;
          when "100"     => digits <= D2reg_read1;
          when "101"     => digits <= ram_data;
          when "110"     => digits <= D4ram_data;
          when others     => digits <= x"00" & rx_data;
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
    process(D2rom_data(15 downto 13), D2rom_data(2 downto 0))
    begin
    case D2rom_data(15 downto 13) is
        when "000" => aluCtrl <= D2rom_data(2 downto 0);
        when "100" => aluCtrl <= "001";
        when others => aluCtrl <= "000";
    end case;
    end process;

    --ALU
    process(D2reg_read1, aluOperand, aluCtrl)
    begin
    case aluCtrl is
        when "000" => aluRes <= D2reg_read1 + aluOperand;
        when "001" => aluRes <= D2reg_read1 - aluOperand;
        when "010" => aluRes <= aluOperand (14 downto 0) & '0';
        when "011" => aluRes <= '0' & aluOperand (15 downto 1);
        when "100" => aluRes <= D2reg_read1 and aluOperand;
        when "101" => aluRes <= D2reg_read1 or aluOperand;
        when "110" => aluRes <= D2reg_read1 xor aluOperand;
        when others => if D2reg_read1 < aluOperand then
                         aluRes <= conv_std_logic_vector(1, 16);
                       else
                         aluRes <= conv_std_logic_vector(0, 16);
                       end if;                 
    end case;
    end process;
    
    --ALU zero flag
    zeroFlag <= '1' when D3aluRes = 0 else '0';
    
    --IF/ID
    process(clk)
    begin
        if rising_edge(clk) then
            if step(0)='1' then
                D1count <= count;
                D1rom_data <= rom_data;
            end if;
        end if;
    end process;
    
    --ID/EX
    process(clk)
    begin
        if rising_edge(clk) then
            if step(0)='1' then
                D2rom_data <= D1rom_data;
                D2count <= D1count;
                D2memWrite <= control(0);
                D2memReg <= control(6);
                D2regWrite <= control(7);
                D2regDst <= control(8);
                D2ext_imm <= ext_imm;
                D2reg_read1 <= reg_read1;
                D2reg_read2 <= reg_read2;
                D2control <= control;
            end if;
        end if;
    end process;
    
    --EX/MEM
    process(clk)
    begin
        if rising_edge(clk) then
            if step(0)='1' then
                D3regWrite <= D2regWrite;
                D3memWrite <= D2memWrite;
                D3memReg <= D2memReg;
                D3muxRegDst <= muxRegDst;
                D3count <= D2ext_imm + D2count + 1;
                D3aluRes <= aluRes;
                D3reg_read2 <= D2reg_read2;
                D3control <= D2control;
            end if;
        end if;
    end process;
    
    --MEM/WB
    process(clk)
    begin
        if rising_edge(clk) then
            if step(0)='1' then
                D4regWrite <= D3regWrite;
                D4muxRegDst <= D3muxRegDst;
                D4memReg <= D3memReg;
                D4ram_data <= ram_data;
                D4aluRes <= D3aluRes;
            end if;
        end if;
    end process;
    
end Behavioral;
