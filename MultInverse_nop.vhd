----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:52:17 12/15/2015 
-- Design Name: 
-- Module Name:    MultInverse - Behavioral 
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

entity MultInverse_nop is
    Port ( Byte_In : in  STD_LOGIC_VECTOR (7 downto 0);
           Byte_Out : out  STD_LOGIC_VECTOR (7 downto 0));
end MultInverse_nop;

architecture Behavioral of MultInverse_nop is

--------------------------------SIGNALS------------------------------------------------------------
signal map_top : std_logic_vector (3 downto 0);
signal map_bot : std_logic_vector (3 downto 0);
signal GF_sq   : std_logic_vector (3 downto 0);
signal Lambda  : std_logic_vector (3 downto 0);
signal GF_add1 : std_logic_vector (3 downto 0);
signal GF_add2 : std_logic_vector (3 downto 0);
signal GF_Mult1: std_logic_vector (3 downto 0);
signal GF_Mult3: std_logic_vector (3 downto 0);
signal GF_Mult2: std_logic_vector (3 downto 0);
signal GF_Inv  : std_logic_vector (3 downto 0);

--------------------------------FUNCTIONS----------------------------------------------------------

--Function to calculate GF24 Squared---------------------------------------------------------------
function GF24_SQUARED (Data_Nibble : std_logic_vector(3 downto 0)) return std_logic_vector is 
	--signals
	variable sq_output : std_logic_vector(Data_Nibble'range);
	
	--function
	begin
	
	sq_output :=   (Data_Nibble(3))&
						(Data_Nibble(3) XOR Data_Nibble(2))&
						(Data_Nibble(2) XOR Data_Nibble(1))&
						(Data_Nibble(3) XOR Data_Nibble(1) XOR Data_Nibble(0));
	
	return sq_output;
end function;
---------------------------------------------------------------------------------------------------

--Function to calculate GF24 Multiplication--------------------------------------------------------
--calls: GF2_MULTIPLY
function GF24_MULTIPLY (A_IN : std_logic_vector(3 downto 0); B_IN : std_logic_vector(3 downto 0)) return std_logic_vector is 
	--signals
	variable output    : std_logic_vector(3 downto 0);
	variable Nibblet_1 : std_logic_vector(1 downto 0);
	variable Nibblet_2 : std_logic_vector(1 downto 0);
	variable Nibblet_3 : std_logic_vector(1 downto 0);
	variable Nibblet_4 : std_logic_vector(1 downto 0);
	variable Add_top   : std_logic_vector(1 downto 0);
	variable Add_bot   : std_logic_vector(1 downto 0);
	variable Mult_1    : std_logic_vector(1 downto 0);
	variable Mult_2    : std_logic_vector(1 downto 0);
	variable Mult_3    : std_logic_vector(1 downto 0);
	variable phi       : std_logic_vector(1 downto 0);
	variable out_top   : std_logic_vector(1 downto 0);
	variable out_bot   : std_logic_vector(1 downto 0);
	--function
	begin
	 --Assign the high and low Nibblets
	Nibblet_1 := A_IN(3 downto 2);
	Nibblet_2 := A_IN(1 downto 0);
	Nibblet_3 := B_IN(3 downto 2);
	Nibblet_4 := B_IN(1 downto 0);
	
	-- Do the addition before GF2 Multiplication
	Add_top := Nibblet_1 XOR Nibblet_2;
	Add_bot := Nibblet_3 XOR Nibblet_4;
	--GF2 Top Multiplication--
	Mult_1  := ((Nibblet_1(1) AND Nibblet_3(1)) XOR (Nibblet_1(0) AND Nibblet_3(1)) XOR (Nibblet_1(1) AND Nibblet_3(0)))&
				  ((Nibblet_1(1) AND Nibblet_3(1)) XOR (Nibblet_1(0) AND Nibblet_3(0)));
	--GF2 Mid Multiplication
	Mult_2  := ((Add_top(1) AND Add_bot(1)) XOR (Add_top(0) AND Add_bot(1)) XOR (Add_top(1) AND Add_bot(0)))&
				  ((Add_top(1) AND Add_bot(1)) XOR (Add_top(0) AND Add_bot(0)));
	--GF2 Bottom Multiplication
	Mult_3  := ((Nibblet_2(1) AND Nibblet_4(1)) XOR (Nibblet_2(0) AND Nibblet_4(1)) XOR (Nibblet_2(1) AND Nibblet_4(0)))&
				  ((Nibblet_2(1) AND Nibblet_4(1)) XOR (Nibblet_2(0) AND Nibblet_4(0)));
	--Phi Multiplication
	phi     := (Mult_1(1) XOR Mult_1(0)) & Mult_1(1);
	--output additions
	out_top := Mult_2 XOR Mult_3;
	out_bot := Mult_3 XOR phi;
	--output concatination
	output  := out_top & out_bot; --Unsure whether this concatination will work
	
	return output;
end function;
---------------------------------------------------------------------------------------------------


--Function to calculate Lambda Multiplication------------------------------------------------------
function LAMBDA_MULTIPLY (Data_Nibble : std_logic_vector(3 downto 0)) return std_logic_vector is 
	--signals
	variable Lambda_Output : std_logic_vector(Data_Nibble'range);
	
	--function
	begin
	
	Lambda_Output :=   (Data_Nibble(2) XOR Data_Nibble(0))&
							(Data_Nibble(3) XOR Data_Nibble(2) XOR Data_Nibble(1) XOR Data_Nibble(0))&
							(Data_Nibble(3))&
							(Data_Nibble(2));
	
	return Lambda_Output;
end function;
---------------------------------------------------------------------------------------------------


--Function to calculate GF24 Inversion---------------------------------------------------------
-- DOES NOT WORK AT THE MOMENT, CHECK THE STATEMENTS------------
function GF24_INVERSION (Q : std_logic_vector(3 downto 0)) return std_logic_vector is 
	--signals
	variable inv_output : std_logic_vector(Q'range);
	variable bit0 :std_logic;
	
	--function
	begin
	
	inv_output(0) := ((Q(3) AND Q(2) AND Q(1)) XOR (Q(3) AND Q(2) AND Q(0)) XOR (Q(3) AND Q(1)) XOR (Q(3) AND Q(1) AND Q(0)) XOR (Q(3) AND Q(0)) XOR Q(2) XOR (Q(2) AND Q(1)) XOR (Q(2) AND Q(1) AND Q(0)) XOR Q(1) XOR Q(0));	
   inv_output(1) :=	(Q(3) XOR (Q(3) AND Q(2) AND Q(1)) XOR (Q(3) AND Q(1) AND Q(0)) XOR Q(2) XOR (Q(2) AND Q(0)) XOR Q(1));
   inv_output(2) :=	((Q(3) AND Q(2) AND Q(1)) XOR (Q(3) AND Q(2) AND Q(0)) XOR Q(2) XOR (Q(3) AND Q(0)) XOR (Q(2) AND Q(1)));
   inv_output(3) :=	(Q(3) XOR (Q(3) AND Q(2) AND Q(1)) XOR (Q(3) AND Q(0)) XOR Q(2));
						
	-- if this does not work it is possible to use a LUT although for a small area this is not ideal

	
	return inv_output;
end function;
---------------------------------------------------------------------------------------------------

-------------------------------------------- END FUNCTIONS ----------------------------------------

-------------------------------------------- BEHAVIOURAL ------------------------------------------
begin

-- Split the transformed byte
map_top <= Byte_In(7 downto 4);
map_bot <= Byte_In(3 downto 0);
--First Addition
GF_add1 <= map_top XOR map_bot;
--Galois Squaring of top nibblet
GF_sq   <= GF24_SQUARED( map_top);
--Lambda multiplication after sq
Lambda  <= LAMBDA_MULTIPLY(GF_sq);
--First multiplication
GF_Mult1 <= GF24_MULTIPLY(GF_add1, map_bot);
--Second addition
GF_add2  <= Lambda XOR GF_Mult1;
--Inversion
GF_Inv <=  GF24_INVERSION(GF_add2);
--Both multiplications
GF_Mult2 <= GF24_MULTIPLY(map_top, GF_Inv);
GF_Mult3 <= GF24_MULTIPLY(GF_add1, GF_Inv);
--Assign the output via concatinationS
Byte_Out <= GF_Mult2 & GF_Mult3;

end Behavioral;

