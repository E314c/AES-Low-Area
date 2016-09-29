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
use IEEE.std_logic_signed.all;

package TB_funcs is

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
procedure wait_clocks(signal clock : std_logic ; cycles : positive);
procedure wait_half_clocks(signal clock : std_logic ; cycles : positive) ;

function byte_to_str(byte : in std_logic_vector(7 downto 0)) return string;

function reverse_vector( vector : in std_logic_vector ) return std_logic_vector;



end TB_funcs;
--------------------------------------------
package body TB_funcs is

  procedure wait_clocks(signal clock : std_logic ; cycles : positive) is
  begin
		for i in 1 to cycles loop
			wait until rising_edge(clock);
		end loop;
  end wait_clocks;
  
  procedure wait_half_clocks(signal clock : std_logic ; cycles : positive) is
  --Purpose:	Cause simulation to wait specfied amount of edges of signal
  begin
		for i in 1 to cycles loop
			wait until ( rising_edge(clock) OR falling_edge(clock) );
		end loop;
  end wait_half_clocks;

	function byte_to_str(byte : in std_logic_vector(7 downto 0)) return string is
	--Purpose:	Takes in a byte wide logic vector and outputs the Integer String representation
	begin
		return integer'image(CONV_INTEGER(byte));
	end byte_to_str;
	
	
	function reverse_vector( vector : in std_logic_vector ) return std_logic_vector is
	--Purpose:	Reverse bit order of signal (change Endian-ness)
		variable return_val : std_logic_vector(vector'length-1 downto 0);
	begin
		for i in 0 to vector'length-1 loop
			return_val(i) := vector(vector'length-1-i);
		end loop;
		
		return return_val;
		
	end reverse_vector;

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
 
end TB_funcs;
