----------------------------------------------------------------------------------
--Authour:	Rael Sasiak-Rushby
----------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------
-- AddRoundKey
---------------------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use work.AES_types.all;

entity addRoundKey is
    Port ( 
				Input_1 : 		in BYTE;
				Input_2 : 		in BYTE;
				Output_data : 	out BYTE;
				enable : 		in STD_LOGIC;
				clk :				in STD_LOGIC);
end addRoundKey;

architecture addRound_Behavior of addRoundKey is



begin

process(clk)
begin
	if rising_edge(clk) then
		if enable = '1' then
			Output_data <= Input_1 XOR Input_2;
		else
			Output_data <= Input_1;
		end if;
	end if;
end process;

end addRound_Behavior;
--*******************************************************************************************************************--
