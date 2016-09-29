---------------------
--Authour:	Rael S-R
---------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;

entity SRL16x8 is
    Port ( Byte_In : in  STD_LOGIC_VECTOR (7 downto 0);
           Carry_out : out  STD_LOGIC_VECTOR (7 downto 0);
           Addr : in  STD_LOGIC_VECTOR (3 downto 0);
           Byte_out : out  STD_LOGIC_VECTOR (7 downto 0);
           Clk : in  STD_LOGIC;
           Clk_Enable : in  STD_LOGIC);
end SRL16x8;

architecture Behavioral of SRL16x8 is

begin
	Generator : for k in 0 to 7 generate --create 8 instances of SRLC16E

		SRLC16E_inst : SRLC16E
		generic map (
			INIT => X"0000")
		port map (
			Q		=> Byte_out(k),    -- SRL data output
			Q15	=> Carry_out(k),  -- Carry output (connect to next SRL)
			A0		=> Addr(0),    	-- Select[0] input
			A1		=> Addr(1),    	-- Select[1] input
			A2		=> Addr(2),     	-- Select[2] input
			A3		=> Addr(3),     	-- Select[3] input
			CE		=> Clk_Enable,     	-- Clock enable input
			CLK	=> Clk,   			-- Clock input
			D		=> Byte_in(k)    -- SRL data input
		);
	end generate;

end Behavioral;

