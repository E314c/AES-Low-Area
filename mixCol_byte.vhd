----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:20:54 03/23/2016 
-- Design Name: 
-- Module Name:    mixCol_byte - Behavioral 
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

entity mixCol_byte is
    Port ( Byte_In : in  STD_LOGIC_VECTOR (7 downto 0);
           Byte_Out : out  STD_LOGIC_VECTOR (7 downto 0);
           CLK : in  STD_LOGIC;
           Decrypt : in  STD_LOGIC;
           Reset : in  STD_LOGIC;
			  Resync : in STD_LOGIC);
end mixCol_byte;

architecture Behavioral of mixCol_byte is

COMPONENT ParallelToSerial is
    Port ( ONEByte_In : in  STD_LOGIC_VECTOR (7 downto 0);
			  TWOByte_In : in  STD_LOGIC_VECTOR (7 downto 0);
			  THREEByte_In : in  STD_LOGIC_VECTOR (7 downto 0);
			  FOURByte_In : in  STD_LOGIC_VECTOR (7 downto 0);
           Byte_Out : out  STD_LOGIC_VECTOR (7 downto 0);
           CLK : in  STD_LOGIC;
           Reset : in  STD_LOGIC;
           Load : in  STD_LOGIC);
end COMPONENT;

--GaloisxTWO Function
function GaloisxTwo (Data_Byte : BYTE) return std_logic_vector is 
	--signals
	variable GaloisTWO : std_logic_vector(Data_Byte'range);
	--function
	begin
	
		IF (Data_Byte(7) = '1') then    ---Each byte  is it's own conditin
			GaloisTWO :=(Data_Byte(6 downto 0) & '0') XOR X"1B";
	   ELSE
			GaloisTWO := Data_Byte(6 downto 0) & '0';
	   END IF;
							
	return GaloisTWO;
end function;


--Reg Signals
signal Reg_1 : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal Reg_2 : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal Reg_3 : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal Reg_4 : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
--AND Output Signals 
signal AND_1 : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal AND_2 : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal AND_3 : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal AND_4 : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
--XOR Input Signals
signal XOR_1 : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal XOR_2 : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal XOR_3 : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal XOR_4 : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
--Load Signal
signal Load : STD_LOGIC := '0';
--Enable Signal
signal Enable : STD_LOGIC_VECTOR (7 downto 0) := (others => '1');
--Clock Count
signal count : integer range 0 to 4 := 0;
--Galois Signals
signal GaloisTWO : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal GaloisTHREE : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal GaloisNINE : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal GaloisELEVEN : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal GaloisTHIRTEEN : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
signal GaloisFOURTEEN : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
--Byte_In Signal
signal BYTE_in_V : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');

--Begin 
begin

--Port Map Parallel to Serial
PtS: ParallelToSerial Port Map (
			  ONEByte_In => Reg_1,
			  TWOByte_In => Reg_2,
			  THREEByte_In => Reg_3,
			  FOURByte_In => Reg_4,
           Byte_Out => Byte_Out,
           CLK => CLK,
           Reset => Reset,
           Load => Load);
			  
			  
--Main Process for assigning			  
MixCol : process(Clk, Reset)
begin
if (reset = '1') then 
    Reg_1 <= (others => '0');
	 Reg_2 <= (others => '0');
	 Reg_3 <= (others => '0');
	 Reg_4 <= (others => '0');
	 count <= 0;
else if (rising_edge (CLK)) then 
	 if Resync = '1' then 
		 Enable <= (others => '0');
		 count <= 1;
	 else 
	 Enable  <= (others => '1'); 
    Load <= '0';
	 count <= count +1;
	 
    Reg_1 <= XOR_1;
	 Reg_2 <= XOR_2;
	 Reg_3 <= XOR_3;
	 Reg_4 <= XOR_4;
	 
	 if (count = 4) then 
	   count <= 1;
		Load <= '1';
		Enable <= (others => '0');
		end if; 
		
		
		end if;
	 end if;
 end if;
end process;

--Assign Input Vector
Byte_in_v <= Byte_In;

--AND Feedback
AND_1 <= Reg_2 AND Enable;
AND_2 <= Reg_3 AND Enable;
AND_3 <= Reg_4 AND Enable;
AND_4 <= Reg_1 AND Enable;

----Decrypt Process
Decrypt_Process : process (clk)
begin
		if (Decrypt = '1') then 
			--assign XOR Outputs
			XOR_1 <= GaloisNINE XOR AND_1;
			XOR_2 <= GaloisTHIRTEEN XOR AND_2;
			XOR_3 <= GaloisELEVEN XOR AND_3;
			XOR_4 <= GaloisFOURTEEN XOR AND_4;
		else if (Decrypt = '0' ) then 
			--Assign XOR Outputs
			XOR_1 <= Byte_In_V XOR AND_1;
			XOR_2 <= Byte_In_V XOR AND_2;
			XOR_3 <= GaloisTHREE XOR AND_3;
			XOR_4 <= GaloisTWO XOR AND_4;
		end if;
end if;
end process;


--Galois Multiplications
GaloisNINE      <= GaloisxTWO( GaloisxTWO( GaloisxTWO( Byte_in_v ))) XOR Byte_in_v;
GaloisTHIRTEEN  <= GaloisxTWO( GaloisxTWO( GaloisxTWO( Byte_in_v ) XOR Byte_in_v)) XOR Byte_in_v;
GaloisELEVEN    <= GaloisxTWO( GaloisxTWO( GaloisxTWO( Byte_in_v )) XOR Byte_in_v ) XOR Byte_in_v;
GaloisFOURTEEN  <= GaloisxTWO( GaloisxTWO( GaloisxTWO( Byte_in_v) XOR Byte_in_v ) XOR Byte_in_v );
GaloisTWO <= GaloisxTWO(Byte_in_v);
GaloisTHREE <= GaloisTWO XOR Byte_in_v;



end Behavioral;

