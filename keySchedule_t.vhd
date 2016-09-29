----------------------------------------------------------------------------------
--This is a test Key scheduler that utilises a pre-defined set of the FIPs encryption keys.
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.AES_types.all;

entity keySchedule_T is
    Port ( key_in : in  BYTE;
           key_out : out  BYTE;
			  clk : in STD_LOGIC;
			  start : in  STD_LOGIC;
           key_ready : out  STD_LOGIC;
           reset : in  STD_LOGIC;
			  decrypt: in STD_LOGIC;
			  key_10 : out STD_LOGIC
			  );
end keySchedule_T;




architecture Behavioral of keySchedule_T is
	signal delay : integer;
	
	
	constant FIPs_Encryption_Key : BYTE_BUS(0 to 175) := (	x"00", x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08", x"09", x"0a", x"0b", x"0c", x"0d", x"0e", x"0f", --  0
															x"d6", x"aa", x"74", x"fd", x"d2", x"af", x"72", x"fa", x"da", x"a6", x"78", x"f1", x"d6", x"ab", x"76", x"fe",	--  1
															x"b6", x"92", x"cf", x"0b", x"64", x"3d", x"bd", x"f1", x"be", x"9b", x"c5", x"00", x"68", x"30", x"b3", x"fe", --  2
															x"b6", x"ff", x"74", x"4e", x"d2", x"c2", x"c9", x"bf", x"6c", x"59", x"0c", x"bf", x"04", x"69", x"bf", x"41",	--  3
															x"47", x"f7", x"f7", x"bc", x"95", x"35", x"3e", x"03", x"f9", x"6c", x"32", x"bc", x"fd", x"05", x"8d", x"fd",	--  4
															x"3c", x"aa", x"a3", x"e8", x"a9", x"9f", x"9d", x"eb", x"50", x"f3", x"af", x"57", x"ad", x"f6", x"22", x"aa",	--  5
															x"5e", x"39", x"0f", x"7d", x"f7", x"a6", x"92", x"96", x"a7", x"55", x"3d", x"c1", x"0a", x"a3", x"1f", x"6b",	--  6
															x"14", x"f9", x"70", x"1a", x"e3", x"5f", x"e2", x"8c", x"44", x"0a", x"df", x"4d", x"4e", x"a9", x"c0", x"26",	--  7
															x"47", x"43", x"87", x"35", x"a4", x"1c", x"65", x"b9", x"e0", x"16", x"ba", x"f4", x"ae", x"bf", x"7a", x"d2",	--  8
															x"54", x"99", x"32", x"d1", x"f0", x"85", x"57", x"68", x"10", x"93", x"ed", x"9c", x"be", x"2c", x"97", x"4e",	--  9
															x"13", x"11", x"1d", x"7f", x"e3", x"94", x"4a", x"17", x"f3", x"07", x"a7", x"8b", x"4d", x"2b", x"30", x"c5"	-- 10
														 );
	
	
begin
	process(clk)
	variable key_count : integer := 0;
	begin
		if rising_edge(clk) then	
			if reset = '1' then
				key_count := 0;
			elsif start = '1' then
				key_count := key_count+1;
			end if;
			
			key_out <=  FIPs_Encryption_Key(key_count);
			
			if key_count >= 160 then
				key_10  <= '1';
			else
				key_10  <= '0';
			end if;
			
		end if;
		
	end process;
end Behavioral;

