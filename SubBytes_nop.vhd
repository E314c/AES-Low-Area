----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:28:26 12/08/2015 
-- Design Name: 
-- Module Name:    subBytes - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
   use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.AES_types.all;

entity subBytes_nop is
	Generic ( N : natural := 1);	-- eg N=1, 2,4,8,16,20...
    Port ( Input_data : in BYTE_BUS(N-1 downto 0);
           Output_data : out BYTE_BUS(N-1 downto 0);
           Clk : in  STD_LOGIC;
			  Decrypt: in STD_LOGIC;
			  reset: in STD_LOGIC;
			  enable: in STD_LOGIC);
end subBytes_nop;

architecture  subBytes_nop_Behavioral of subBytes_nop is

-------------------------------------- SIGNALS ----------------------------------------------------
signal SubBytes_v : BYTE_BUS(N-1 downto 0) := (OTHERS=> (others => '0'));
signal Init_map   : BYTE_BUS(N-1 downto 0);
signal Inv_Out    : BYTE_BUS(N-1 downto 0);



-----------------------------------END SIGNALS ----------------------------------------------------

-------------------------------------COMPONENTS----------------------------------------------------
component MultInverse_nop is
    Port ( Byte_In : in  BYTE;
           Byte_Out : out  BYTE
			  );
end component;
-----------------------------------END COMPONENTS--------------------------------------------------

-------------------------------------- FUNCTIONS --------------------------------------------------

--Function to calculate Isomorphic Transform-------------------------------------------------------
function ISO_TRANSFORM (Data_Byte : BYTE) return std_logic_vector is 
	--signals
	variable isomorph_map : std_logic_vector(Data_Byte'range);
	--function
	begin
	
	isomorph_map :=   (Data_Byte(7) XOR Data_Byte(5))&
							(Data_Byte(7) XOR Data_Byte(6) XOR Data_Byte(4) XOR Data_Byte(3) XOR Data_Byte(2) XOR Data_Byte(1))&
							(Data_Byte(7) XOR Data_Byte(5) XOR Data_Byte(3) XOR Data_Byte(2))&
							(Data_Byte(7) XOR Data_Byte(5) XOR Data_Byte(3) XOR Data_Byte(2) XOR Data_Byte(1))&
							(Data_Byte(7) XOR Data_Byte(6) XOR Data_Byte(2) XOR Data_Byte(1))&
							(Data_Byte(7) XOR Data_Byte(4) XOR Data_Byte(3) XOR Data_Byte(2) XOR Data_Byte(1))&
							(Data_Byte(6) XOR Data_Byte(4) XOR Data_Byte(1))&
							(Data_Byte(6) XOR Data_Byte(1) XOR Data_Byte(0));
							
	return isomorph_map;
end function;
---------------------------------------------------------------------------------------------------

--Function to Calculate Inverse Isomorphic Transform-----------------------------------------------
function INVERSE_ISO_TRANSFORM (Data_Byte : BYTE) return std_logic_vector is 
	--signals
	variable inv_iso_map : std_logic_vector(Data_Byte'range);
	
	--function
	begin
	
	inv_iso_map :=    (Data_Byte(7) XOR Data_Byte(6) XOR Data_Byte(5) XOR Data_Byte(1))&
							(Data_Byte(6) XOR Data_Byte(2))&
							(Data_Byte(6) XOR Data_Byte(5) XOR Data_Byte(1))&
							(Data_Byte(6) XOR Data_Byte(5) XOR Data_Byte(4) XOR Data_Byte(2) XOR Data_Byte(1))&
							(Data_Byte(5) XOR Data_Byte(4) XOR Data_Byte(3) XOR Data_Byte(2) XOR Data_Byte(1))&
							(Data_Byte(7) XOR Data_Byte(4) XOR Data_Byte(3) XOR Data_Byte(2) XOR Data_Byte(1))&
							(Data_Byte(5) XOR Data_Byte(4))&
							(Data_Byte(6) XOR Data_Byte(5) XOR Data_Byte(4) XOR Data_Byte(2) XOR Data_Byte(0));
							
	return inv_iso_map;
end function;
---------------------------------------------------------------------------------------------------

--Function to calculate Inverse Isomorphic & Affine Transformation---------------------------------
function INVERSE_ISO_AFFINE (Data_Byte : BYTE) return std_logic_vector is 
	--signals
	variable inv_iso_affine : std_logic_vector(Data_Byte'range);
	
	--function
	begin
	
	inv_iso_affine :=    (Data_Byte(7) XOR Data_Byte(3) XOR Data_Byte(2) XOR '0')&
							(Data_Byte(7) XOR Data_Byte(6) XOR Data_Byte(5) XOR Data_Byte(4) XOR '1')&
							(Data_Byte(7) XOR Data_Byte(2) XOR '1')&
							(Data_Byte(7) XOR Data_Byte(4) XOR Data_Byte(1) XOR Data_Byte(0) XOR '0')&
							(Data_Byte(2) XOR Data_Byte(1) XOR Data_Byte(0) XOR '0')&
							(Data_Byte(6) XOR Data_Byte(5) XOR Data_Byte(4) XOR Data_Byte(3) XOR Data_Byte(2) XOR Data_Byte(0) XOR '0' )&
							(Data_Byte(7) XOR Data_Byte(0) XOR '1')&
							(Data_Byte(7) XOR Data_Byte(6) XOR Data_Byte(2) XOR Data_Byte(1) XOR Data_Byte(0) XOR '1');
							
	return inv_iso_affine;
end function;
---------------------------------------------------------------------------------------------------

--Function to calculate Isomorphic & Inverse Affine Transformation---------------------------------
function ISO_INVERSE_AFFINE (Data_Byte : BYTE) return std_logic_vector is 
	--signals
	variable iso_inv_affine : std_logic_vector(Data_Byte'range);
	
	--function
	begin
	
	iso_inv_affine :=    (Data_Byte(7) XOR Data_Byte(6) XOR Data_Byte(2) XOR Data_Byte(1) XOR '0')&
								(Data_Byte(7) XOR Data_Byte(6) XOR Data_Byte(3) XOR Data_Byte(2) XOR Data_Byte(1) XOR Data_Byte(0) XOR '1')&
								(Data_Byte(6) XOR Data_Byte(5) XOR Data_Byte(4) XOR Data_Byte(0) XOR '1')&
								(Data_Byte(5) XOR Data_Byte(4) XOR Data_Byte(3) XOR '1')&
								(Data_Byte(7) XOR Data_Byte(5) XOR '1')&
								(Data_Byte(7) XOR Data_Byte(6) XOR Data_Byte(5) XOR Data_Byte(2) XOR Data_Byte(1) XOR '1' )&
								(Data_Byte(5) XOR Data_Byte(3) XOR Data_Byte(1) XOR '0')&
								(Data_Byte(7) XOR Data_Byte(6) XOR Data_Byte(2) XOR '1');
							
	return 	iso_inv_affine;
end function;
---------------------------------------------------------------------------------------------------

--------------------------------Entity Architecture Description-----------------------------------
begin

-- Does this process when Clk changes state - rising edge
-- Does this process when Clk changes state - rising edge
Byte_SUB : process(clk,reset)
begin
			if (reset = '1') then 
				Output_data <= (OTHERS=> (others => '0'));
			else if rising_edge(clk) then
				if enable = '1' then
					Output_data <= SubBytes_v;
				end if;
			end if;
		end if;
end process;



-- For loop Generator for doing each byte---
SUB_V : for k in 0 to N-1 generate

		--Port mapping for the multiplicative Inverse
		Mul_Inv : MultInverse_nop port map(
					Byte_In  => Init_map(k),
					Byte_Out => Inv_Out(k)
			  );

		Init_map(k)		<= ISO_INVERSE_AFFINE(Input_data(k))	WHEN Decrypt= '1' ELSE ISO_TRANSFORM(Input_data(k));
		SubBytes_v(k)	<= INVERSE_ISO_TRANSFORM(Inv_Out(k))	WHEN Decrypt= '1' ELSE INVERSE_ISO_AFFINE(Inv_Out(k));
		
end generate SUB_V ;

end subBytes_nop_Behavioral;
