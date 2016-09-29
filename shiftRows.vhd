----------------------------------------------------------------------------------
--     shiftRows for a Low area AES chip
--	Authour: Rael Sasiak-Rushby
--
-- Based on design by in "LOW AREA MEMORY FREE FPGA IMPLEMENTATION OF THE AES ALGORITHM" 
-- by J.Chu and M.Benaissa of University of Sheffield.
--
-- --Stats--
-- Initial Delay	: 12
-- Data/Clock after	: 1
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VComponents.all;
use work.AES_types.all;

entity shiftRows is
    Port ( Input_data : in  BYTE;
           Output_data : out  BYTE;
			  Decrypt : in STD_LOGIC;
           Clk : in  STD_LOGIC;
			  Resync : in STD_LOGIC);
end shiftRows;

architecture Behavioral of shiftRows is

	component SRL16x8 is
		Port (  Byte_In : in  STD_LOGIC_VECTOR (7 downto 0);
				  Carry_out : out  STD_LOGIC_VECTOR (7 downto 0);
				  Addr : in  STD_LOGIC_VECTOR (3 downto 0);
				  Byte_out : out  STD_LOGIC_VECTOR (7 downto 0);
				  Clk : in  STD_LOGIC;
				  Clk_Enable : in  STD_LOGIC);
	end component;
	
	--Signals
	signal reg_wire : STD_LOGIC_VECTOR (7 downto 0);
	
	signal A : std_logic_vector (2 downto 0);
	--Addressing bits. note: this is condensed from spread sheet analysis as addr(0,1,5) =='0'
	--essentially this is just mapping A 4,3,2 from the spread sheet.
	
	signal reg1out, reg2out : BYTE;
	signal addr : std_logic_vector (3 downto 0);
	
begin
   
   Reg_1 : SRL16x8
   port map (
      Byte_in	=> Input_data,
      Carry_out	=> reg_wire ,
      Addr		=> addr,
      Byte_out	=> reg1out,
      Clk		=> Clk,
      Clk_Enable 	=> '1'
   );
   
   Reg_2: SRL16x8
   port map (
      Byte_in	=> reg_wire,
      Carry_out	=> open,
      Addr		=> addr,
      Byte_out	=> reg2out,
      Clk		=> Clk,
      Clk_Enable	=> '1'
   );
	
	--There must be a better way to do this:
	addr <= A(1) & A(0) & '0' & '0';
	
	--Mux
	Output_data <= reg2out WHEN A(2)='1' ELSE reg1out;	--If A(2) is 1, output is from register 2 , else from register 1
	
	
	Addr_computer : process(Clk)
	--- Encrypt ----
	--A(0) needs pattern: 1010 1010 1010 1010
	--A(1) needs pattern: 1100 1100 1100 1100
	--A(2) needs pattern: 0000 0001 0011 0111

	
	--- Decrypt ---
	--A(0) needs pattern: 1010 1010 1010 1010	<- same as encryption
	--A(1) needs pattern: 1001 1001 1001 1001
	--A(2) needs pattern: 0000 0100 0110 0111
	
	variable counter : integer range 0 to 15;
	begin
		if rising_edge(Clk) then
			if Resync = '1' then
				counter := 1;
				A(0) <= '1'; -- starting pattern for encryption or decryption
				A(1) <= '1';
				A(2) <= '0';
			else
				
				--set A(0)
				if (counter mod 2 = 0) then
					A(0) <= '1';
				else
					A(0) <= '0';
				end if;
				
				--set A(1)
				if Decrypt = '0' then
					if (((counter+2)/2) mod 2 = 1) then
						A(1) <= '1';
					else
						A(1) <= '0';
					end if;
				else
					if (((counter+3)/2) mod 2 = 1) then
						A(1) <= '1';
					else
						A(1) <= '0';
					end if;
				end if;
				
				
				--set A(2)
				if Decrypt = '0' then
					--if (counter = 7) OR (counter = 10) OR (counter = 11) OR (counter = 13) OR (counter = 14) OR (counter = 15) then --orignally I put in 16 and it worked, but it shouldn't have...
					if ((counter mod 4) + (counter/4)) >= 4 then
						A(2) <= '1';
					else
						A(2) <= '0';
					end if;
				else
					--if (counter = 5) OR (counter = 9) OR (counter = 10) OR (counter = 13) OR (counter = 14) OR (counter = 15) then
					if (((16-counter)mod 4) + (counter / 4)) >= 4 then
						A(2) <= '1';
					else
						A(2) <= '0';
					end if;
				end if;
				
				--increment counter
				counter := counter + 1;
				if counter > 15 then
					counter := 0;
				end if;
				
			end if;
		
		end if;
	end process;
	

end Behavioral;

