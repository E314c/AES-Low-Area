--------------------------------------------------------------------------------
-- FIPs Keyschedule test bench --
---------------------------------
--Authour:	Rael Sasiak-Rushby
--
--Purpose:	Test the Key_scheduler using the FIPs data.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use work.AES_types.all;
use work.TB_funcs.all;
 
ENTITY Key_schedule_FIPS_test IS
END Key_schedule_FIPS_test;
 
ARCHITECTURE behavior OF Key_schedule_FIPS_test IS 
 
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
	
	-- Test Signals --
	signal start_input, check_output : std_logic;
	signal expected_out : BYTE;
	
	
	-- Test vectors ---------------------------
	constant FIPs_Encryption_Key : BYTE_BUS(0 to 175) := (	x"00", x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08", x"09", x"0a", x"0b", x"0c", x"0d", x"0e", x"0f", --  0
														x"d6", x"aa", x"74", x"fd", x"d2", x"af", x"72", x"fa", x"da", x"a6", x"78", x"f1", x"d6", x"ab", x"76", x"fe",	--  1
														x"b6", x"92", x"cf", x"0b", x"64", x"3d", x"bd", x"f1", x"be", x"9b", x"c5", x"00", x"68", x"30", x"b3", x"fe", --  2
														x"b6", x"ff", x"74", x"4e", x"d2", x"c2", x"c9", x"bf", x"6c", x"59", x"0c", x"bf", x"04", x"69", x"bf", x"41",	--  3
														x"47", x"f7", x"f7", x"bc", x"95", x"35", x"3e", x"03", x"f9", x"6c", x"32", x"bc", x"fd", x"05", x"8d", x"fd",	--  4
														x"3c", x"aa", x"a3", x"e8", x"a9", x"9f", x"9d", x"eb", x"50", x"f3", x"af", x"57", x"ad", x"f6", x"22", x"aa",	--  5
														x"5e", x"39", x"0f", x"7d", x"f7", x"a6", x"92", x"96", x"a7", x"55", x"3d", x"c1", x"0a", x"a3", x"1f", x"6b",	--  6
														x"14", x"f9", x"70", x"1a", x"e3", x"5f", x"e2", x"8c", x"44", x"0a", x"df", x"4d", x"4e", x"a9", x"c0", x"26",	--  7
														x"47", x"43", x"87", x"35", x"a4", x"1c", x"65", x"b9", x"e0", x"16", x"ba", x"f4", x"ae", x"bf", x"7a", x"d2",	--  8
														x"54", x"99", x"32", x"d1", x"f0", x"85", x"57", x"68", x"10", x"93", x"ed", x"9c", x"be", x"2c", x"97", x"4e",	--  9
														x"13", x"11", x"1d", x"7f", x"e3", x"94", x"4a", x"17", x"f3", x"07", x"a7", x"8b", x"4d", x"2b", x"30", x"c5"	-- 10
													 );
 
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
----------------------------------------------------------------------------------------------------
	
	-- Cleaup --
	Decrypt <= '1';
	Start <= '0';	
	Reset <= '1';
	wait_clocks(clk, 5);	
	Reset <= '0';
	------------

	-- Start Input process
	start <= '1';
	start_input <= '1';
	check_output <= '1';
	
	wait_clocks(clk,16);
	wait for clk_period/10;
	--check pausing:
	start <= '0';
	start_input <= '0';
	check_output <= '0';
	wait_clocks(clk,2);
	start <= '1';
	check_output <= '1';
	
	wait_clocks(clk,160);
	
	-- Check decryption too:
	
	
	
----------------------------------------------------------------------------------------------------
	wait;
   end process;
	
	--Input processes
	data_in_proc : process(Clk, start_input)
		variable i : integer := 0;
	begin
		if falling_edge(Clk) then
			if start_input = '1' then
				key_in <= FIPs_Encryption_Key(i);
				i := i+1;
			else
				i := 0;
				key_in <= (others => 'U');
			end if;
		end if;
	end process;
	
	--Output check process;
	out_check_proc : process(Clk, check_output, start)
			variable i : integer := 0;
			variable k : integer :=0;
	begin
		if falling_edge(Clk) then
			if check_output = '1' then
				if  i <= 175  then
					assert key_out <= FIPs_Encryption_Key(i) report "Encryption Error in data check "&integer'image(i)&": Expected "& byte_to_str(FIPs_Encryption_Key(i)) &" and got "& byte_to_str(key_out) severity warning;
					expected_out <= FIPs_Encryption_Key(i);
				else 
					report "Note: Decryption assert not functional, ignore the following errors" severity warning;
					k := (10 - (i/16))*16;
					assert key_out <= FIPs_Encryption_Key(k) report "Decryption Error in data check "&integer'image(i)&": Expected "& byte_to_str(FIPs_Encryption_Key(k)) &" and got "& byte_to_str(key_out) severity warning;
					expected_out <= FIPs_Encryption_Key(k);
				end if;
				i := i+1;
				if i > 350 then
					i:= 0;
				end if;
			else
				expected_out <= (others => 'U');
			end if;
		end if;
	end process;

END;
