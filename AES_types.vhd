--
--	Package File Template
--
--	Purpose: This package defines supplemental types, subtypes, 
--		 constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
--------------------------------------------------------------------------------------------------------------------
package AES_types is
-------------------------------------------------------------------------
-- type <new_type> is
--  record
--    <type_name>        : std_logic_vector( 7 downto 0);
--    <type_name>        : std_logic;
-- end record;
--
-- Declare constants
--
-- constant <constant_name>		: time := <time_unit> ns;
-- constant <constant_name>		: integer := <value;
--
-- Declare functions and procedure
--
-- function <function_name>  (signal <signal_name> : in <type_declaration>) return <type_declaration>;

-- procedure <procedure_name> (<type_declaration> <constant_name>	: in <type_declaration>);
--
-------------------------------------------------------------------------

--some type definitions:
subtype BYTE is STD_LOGIC_VECTOR(7 downto 0);
type BYTE_BUS is array (natural range <>) of BYTE;
subtype BLOCK_BUS is BYTE_BUS(15 downto 0); --128bit bus (16*8bit)
--Function header
function hex_to_block_bus( conv : std_logic_vector ) return BLOCK_BUS;
function block_bus_to_str(B_Bus : BLOCK_BUS) return string;
function block_transpose(B_bus: BLOCK_BUS) return BLOCK_BUS;


--AES Test data strings:
constant FIPs_Encryption_Input: 	BYTE_BUS(0 to 15):= ( x"00", x"11", x"22", x"33", x"44", x"55", x"66", x"77", x"88", x"99", x"aa", x"bb", x"cc", x"dd", x"ee", x"ff");
constant FIPs_Key:					BYTE_BUS(0 to 15):= ( x"00", x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08", x"09", x"0a", x"0b", x"0c", x"0d", x"0e", x"0f");
constant FIPs_Encryption_Output:	BYTE_BUS(0 to 15):= ( x"69", x"c4", x"e0", x"d8", x"6a", x"7b", x"04", x"30", x"d8", x"cd", x"b7", x"80", x"70", x"b4", x"c5", x"5a");

end AES_types;
--------------------------------------------------------------------------------------------------------------------
package body AES_types is

function hex_to_block_bus(conv : std_logic_vector ) return BLOCK_BUS is
--Purpose:	Take in a hex string and return value suitable for assigning a BLOCK_BUS signal
	variable return_val : BLOCK_BUS;	
begin

	--report integer'image(conv'length);
	--loop through each byte and assign.
	for i in 0 to ((conv'length)/8)-1 loop
		for j in 0 to 7 loop
			return_val(i)(j) := conv(conv'length-1-((8*i)+j)); --conv( ((i+1)*8)-1 downto i*8); 
		end loop;
	end loop;
	
	return return_val;
	
end hex_to_block_bus;

function block_bus_to_str(B_Bus : BLOCK_BUS) return string is
--Purpose:	 Create a string to represent the value of a block bus, useful for use in 'report' functions in testbenches.
	variable str : string(1 to 36) := (others => '0'); --2 chars per byte, plus space for seperators if wanted.
begin

	--loop through each byte in block bus.
	for i in 1 to B_Bus'length loop
		--str := str & STD_LOGIC_VECTOR'image(B_Bus(i));
	end loop;

return str;
end block_bus_to_str;


function block_transpose(B_bus: BLOCK_BUS) return BLOCK_BUS is
--Purpose: to convert between column and row major with ease.
	variable return_val : BLOCK_BUS;
begin

	return_val(0)	:= B_Bus(0);
	return_val(1)	:= B_Bus(4);
	return_val(2)	:= B_Bus(8);
	return_val(3)	:= B_Bus(12);
	
	return_val(4)	:= B_Bus(1);
	return_val(5)	:= B_Bus(5);
	return_val(6)	:= B_Bus(9);
	return_val(7)	:= B_Bus(13);
	
	return_val(8)	:= B_Bus(2);
	return_val(9)	:= B_Bus(6);
	return_val(10)	:= B_Bus(10);
	return_val(11)	:= B_Bus(14);
	
	return_val(12)	:= B_Bus(3);
	return_val(13)	:= B_Bus(7);
	return_val(14)	:= B_Bus(11);
	return_val(15)	:= B_Bus(15);
	
	return return_val;
end block_transpose;
---- Example 1
--  function <function_name>  (signal <signal_name> : in <type_declaration>  ) return <type_declaration> is
--    variable <variable_name>     : <type_declaration>;
--  begin
--    <variable_name> := <signal_name> xor <signal_name>;
--    return <variable_name>; 
--  end <function_name>;

---- Example 2
--  function <function_name>  (signal <signal_name> : in <type_declaration>;
--                         signal <signal_name>   : in <type_declaration>  ) return <type_declaration> is
--  begin
--    if (<signal_name> = '1') then
--      return <signal_name>;
--    else
--      return 'Z';
--    end if;
--  end <function_name>;

---- Procedure Example
--  procedure <procedure_name>  (<type_declaration> <constant_name>  : in <type_declaration>) is
--    
--  begin
--    
--  end <procedure_name>;
 
 
 
end AES_types;
--------------------------------------------------------------------------------------------------------------------