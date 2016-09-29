--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   18:23:03 03/22/2016
-- Design Name:   
-- Module Name:   C:/Users/bentr_000/Desktop/GitHub/AES_E6225/XlinxProject/AES_LowArea/tb_keySchedule_byte.vhd
-- Project Name:  AES_LowArea
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: keySchedule_byte
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
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_keySchedule_byte IS
END tb_keySchedule_byte;
 
ARCHITECTURE behavior OF tb_keySchedule_byte IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT keySchedule_byte
    PORT(
         key_in : IN  std_logic_vector(7 downto 0);
         key_out : OUT  std_logic_vector(7 downto 0);
         clk : IN  std_logic;
         start : IN  std_logic;
         key_ready : OUT  std_logic;
         reset : IN  std_logic;
         decrypt : IN  std_logic;
         key_10 : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal key_in : std_logic_vector(7 downto 0) := (others => '0');
   signal clk : std_logic := '0';
   signal start : std_logic := '0';
   signal reset : std_logic := '0';
   signal decrypt : std_logic := '0';

 	--Outputs
   signal key_out : std_logic_vector(7 downto 0);
   signal key_ready : std_logic;
   signal key_10 : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: keySchedule_byte PORT MAP (
          key_in => key_in,
          key_out => key_out,
          clk => clk,
          start => start,
          key_ready => key_ready,
          reset => reset,
          decrypt => decrypt,
          key_10 => key_10
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
		wait for 100 ns;	

		reset <= '1';
		start <= '1';
		
      wait for clk_period*10;

		reset <= '0';
		decrypt <= '1';
		
      key_in <= x"2b";
		wait for clk_period;
		key_in <= x"7e";
		wait for clk_period;
		key_in <= x"15";
		wait for clk_period;
		key_in <= x"16";
		wait for clk_period;
		key_in <= x"28";
		wait for clk_period;
		key_in <= x"ae";
		wait for clk_period;
		key_in <= x"d2";
		wait for clk_period;
		key_in <= x"a6";
		wait for clk_period;
		key_in <= x"ab";
		wait for clk_period;
		key_in <= x"f7";
		wait for clk_period;
		key_in <= x"15";
		wait for clk_period;
		key_in <= x"88";
		wait for clk_period;
		key_in <= x"09"; --sub bytes of x"09" to get 01;
		wait for clk_period;
		key_in <= x"cf"; --sub bytes of x"cf" to get 8a;
		wait for clk_period;
		key_in <= x"4f"; --sub bytes of x"4f" to get 84;
		wait for clk_period;
		key_in <= x"3c"; --sub bytes of x"3c" to get eb;
		start<='0';
      wait for clk_period*16;
		start<='1';
		wait;
		
   end process;

END;
