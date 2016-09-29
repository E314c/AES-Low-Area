----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:24:44 03/23/2016 
-- Design Name: 
-- Module Name:    ParallelToSerial - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use work.AES_types.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ParallelToSerial is
    Port ( ONEByte_In : in  STD_LOGIC_VECTOR (7 downto 0);
			  TWOByte_In : in  STD_LOGIC_VECTOR (7 downto 0);
			  THREEByte_In : in  STD_LOGIC_VECTOR (7 downto 0);
			  FOURByte_In : in  STD_LOGIC_VECTOR (7 downto 0);
           Byte_Out : out  STD_LOGIC_VECTOR (7 downto 0);
           CLK : in  STD_LOGIC;
           Reset : in  STD_LOGIC;
           Load : in  STD_LOGIC);
end ParallelToSerial;

architecture Behavioral of ParallelToSerial is
----Component
component mux2to1 is
port ( 
		I0 : in STD_LOGIC_VECTOR(7 downto 0);
		I1 : in STD_LOGIC_VECTOR (7 downto 0);
		S : in STD_LOGIC;
		O : out STD_LOGIC_VECTOR(7 downto 0)
		);
end component;

---- Register Signals-----------------------
signal STAGE_1 : STD_LOGIC_VECTOR (7 downto 0):= (others => '0');
signal STAGE_2 : STD_LOGIC_VECTOR (7 downto 0):= (others => '0');
signal STAGE_3 : STD_LOGIC_VECTOR (7 downto 0):= (others => '0');


begin

out_mux : mux2to1
	port map (
		I0 => STAGE_3,
		I1 => OneByte_In,
		S => load,
		O => Byte_Out
	);

Byte_Shift : process(clk,reset,load,FOURByte_In,THREEByte_In,TWOByte_In)
begin 
if rising_edge(clk) then 
		   if (reset = '1') then 
					STAGE_1 <= (others => '0');
					STAGE_2 <= (others => '0');
					STAGE_3 <= (others => '0');
			else if (load = '1') then 
					STAGE_1 <= FOURByte_In ( 7 downto 0 );
					STAGE_2 <= THREEByte_In ( 7 downto 0 );
					STAGE_3 <= TWOByte_In ( 7 downto 0  );
			else if (load ='0') then 
						STAGE_3 <= STAGE_2;
						STAGE_2 <= STAGE_1;
						STAGE_1 <= (others => '0');
					end if;
	      end if;
			end if;
			end if;
end process;

--Byte_Out <= STAGE_OUT;


end Behavioral;

