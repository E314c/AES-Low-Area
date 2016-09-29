----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.AES_types.all;


entity shift_reg is
	Generic(N : natural);
   Port (	Byte_in : in  BYTE;
				Byte_out : out BYTE;
				Clk : in  STD_LOGIC);
end shift_reg;

architecture Behavioral of shift_reg is
	signal Bytes : BYTE_BUS( N-1 downto 0);

begin
	Byte_out <= Bytes(0);
	process(clk)
	begin
		if rising_edge(clk) then
			Bytes <=  Byte_in & Bytes(N-1 downto 1);
		end if;
	
	end process;
	
	
end Behavioral;

