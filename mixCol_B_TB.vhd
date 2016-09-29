--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   23:29:16 03/23/2016
-- Design Name:   
-- Module Name:   Y:/Documents/University/Fourth Year/EEE6225 - System Design/AES_E6225/XlinxProject/mixCol_byte/mixCol_B_TB.vhd
-- Project Name:  mixCol_byte
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: mixCol_byte
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
use work.TB_funcs.all;
use work.AES_types.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY mixCol_B_TB IS
END mixCol_B_TB;
 
ARCHITECTURE behavior OF mixCol_B_TB IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT mixCol_byte
    PORT(
         Byte_In : IN  std_logic_vector(7 downto 0);
         Byte_Out : OUT  std_logic_vector(7 downto 0);
         CLK : IN  std_logic;
         Decrypt : IN  std_logic;
         Reset : IN  std_logic;
			Resync : IN  std_logic);
    END COMPONENT;
    

   --Inputs
   signal Byte_In : std_logic_vector(7 downto 0);
   signal CLK : std_logic := '0';
   signal Decrypt : std_logic := '0';
   signal Reset : std_logic := '0';
	signal clk_enable : std_logic := '1';
	signal Resync : std_logic := '0';

 	--Outputs
   signal Byte_Out : std_logic_vector(7 downto 0);
	signal Correct_Output : std_logic_vector(7 downto 0);

   -- Clock period definitions
    constant PERIOD : time := 100 ns;
	
	--Column_In
	constant MixCol_In: BYTE_BUS(0 to 15):= (X"D4", X"BF", X"5D", X"30", X"E0", X"B4", X"52", X"AE",
														  X"B8", X"41", X"11", X"F1", X"1e", X"27", X"98", X"E5");
	
	--Column_Out
	constant MixCol_Out: BYTE_BUS(0 to 15):= (X"04", X"66", X"81", X"E5", X"E0", X"CB", X"19", X"9A",
														  X"48", X"F8", X"D3", X"7A", X"28", X"06", X"26", X"4C");
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: mixCol_byte PORT MAP (
          Byte_In => Byte_In,
          Byte_Out => Byte_Out,
          CLK => CLK,
          Decrypt => Decrypt,
          Reset => Reset,
			 Resync => Resync
        );

  -- Clock process definitions
	clk_gen: process
	begin
		if clk_enable = '1' then
			clk <= not clk;
			wait for PERIOD;
		else
			wait;
		end if;
	end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
	
	--initialise
	Decrypt <= '0';

	
	
	Resync <= '1';
	wait_clocks(Clk, 5); --wait 5 clocks
	Resync <= '0';
	
	--Encrypt----------------------------
		Decrypt <= '0';
		wait until rising_edge(CLK);
		Byte_In <= X"00";
      wait until rising_edge(CLK);
		Byte_In <= X"00";

	--Resychronise
      Resync <= '1';
		wait until rising_edge(CLK);
		Resync <= '0';
		
		for i in 0 to 15 loop
			Byte_In <= MixCol_In(i);
			wait until rising_edge(CLK);
				if ( i > 2) then 
					Correct_Output <= MixCol_Out(i-3);
				end if;
		end loop;
		
		Byte_In <= X"00";
		
		for i in 12 to 15 loop
			Correct_Output <= MixCol_Out(i);
			wait until rising_edge(CLK);
		end loop;
		
		Correct_Output <= X"00";
		
		wait until rising_edge(CLK);
		wait until rising_edge(CLK);
		wait until rising_edge(CLK);
		wait until rising_edge(CLK);
		
		
	-- Decrypt---------------------------

		Decrypt <= '1';
		Reset <= '1';
		wait until rising_edge(CLK);
		Reset <= '0';
		Byte_In <= X"00";
      wait until rising_edge(CLK);
		Byte_In <= X"00";

	--Resychronise
      Resync <= '1';
		wait until rising_edge(CLK);
		Resync <= '0';
		
		for i in 0 to 15 loop
			Byte_In <= MixCol_Out(i);
			wait until rising_edge(CLK);
				if ( i > 2) then 
					Correct_Output <= MixCol_In(i-3);
				end if;
		end loop;
		
		Byte_In <= X"00";
		
		for i in 12 to 15 loop
			Correct_Output <= MixCol_In(i);
			wait until rising_edge(CLK);
		end loop;
		
		Correct_Output <= X"00";
		
		wait until rising_edge(CLK);
		wait until rising_edge(CLK);
		wait until rising_edge(CLK);
		wait until rising_edge(CLK);

		


     clk_enable <= '0';
      wait;
   end process;

END;
