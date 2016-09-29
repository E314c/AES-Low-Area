----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    23:38:04 03/22/2016 
-- Design Name: 
-- Module Name:    register8 - Behavioral 
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity register8 is
	port( input : in std_logic_vector(7 downto 0);
		   output : out std_logic_vector(7 downto 0);
			enable: in std_logic; --load enable
			reset : in  std_logic; --reset/clear register
			clk : in  std_logic --clock
			);
end register8;

architecture Behavioral of register8 is

begin

process(clk, reset)
    begin
        if reset = '1' then
            output <= x"00";
        elsif rising_edge(clk) then
            if enable = '1' then
                output <= input;
            end if;
        end if;
    end process;

end Behavioral;

