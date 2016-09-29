--------------------------------------------------------------------------------
-- TEST BENCH FOR AES_CHIP_BYTE_PATH
--
--	Authour: Rael Sasiak-Rushby.
--	
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use work.AES_types.all;
use work.TB_funcs.all;
 
ENTITY Chip_testbench IS
END Chip_testbench;
 
ARCHITECTURE behavior OF Chip_testbench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Chip
    PORT(
				Clock : in  STD_LOGIC;			-- System clock signal
				
				--Data
				Input_Data : in BYTE;		-- Data block into the system
				--Input_Key : in  BYTE;		-- Key block into the system
				Output_Data : out BYTE;	-- Data block out of the system
				
				--Flags in
				Reset : in  STD_LOGIC;			-- Signal to reset chip.
				Decrypt: in STD_LOGIC;			-- Input to select decryption mode. 0 = encrypt, 1 = decrypt.
				InputDataReady : in STD_LOGIC;		-- Whether data on Input_Data is valid data to be processed.
				
				-- Flags out
				OutputDataReady : out  STD_LOGIC;		-- Signal to indicate data is ready on Output_Data line
				Accepting_data : out STD_LOGIC	-- Flag to tell user whether chip is accepting data.
        );
    END COMPONENT;
    

   --Inputs
   signal Clock : std_logic := '0';
   signal Input_Data : BYTE := (others => 'U');
   signal Reset : std_logic := '0';
   signal Decrypt : std_logic := '0';
   signal InputDataReady : std_logic := '0';
   signal InputKeyReady : std_logic := '0';

 	--Outputs
   signal Output_Data : BYTE;
   signal OutputDataReady : std_logic;
   signal Accepting_data : std_logic;

	-- TEST SIGNALS ----
	signal clk_enable : std_logic:= '1';
	signal clock_counter : integer := 0;
	signal clk_count : std_logic_vector(15 downto 0); --because simulators don't like changing radix of integer
	
	signal Expected_result : BYTE;	--so the simulation can plot expected values.
	

-----------------------------------------------------------
--CLOCK DEFINITION
-----------------------------------------------------------
   constant Clock_period : time := 10 ns;
  
-----------------------------------------------------------------------
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Chip PORT MAP (
          Clock => Clock,
          Input_Data => Input_Data,
          Output_Data => Output_Data,
          Reset => Reset,
          Decrypt => Decrypt,
          InputDataReady => InputDataReady,
          OutputDataReady => OutputDataReady,
          Accepting_data => Accepting_data
        );


   -- Clock process definitions
   Clock_process :process
   begin
		if clk_enable = '1' then
			Clock <= '0';
			wait for Clock_period/2;
			Clock <= '1';
			clock_counter <= clock_counter + 1;
			wait for Clock_period/2;
		end if ;
   end process;
	clk_count <= std_logic_vector(to_unsigned(clock_counter,clk_count'length));
	
-----------------------------------------------------------
-- Stimulus process
-----------------------------------------------------------
   stim_proc: process
		variable Test_correct_count: integer := 0;	--count number of correct results.
   begin		
	-- Initialise test stuff:
	clk_enable <='1';
	
	-- Cleaup --
	Decrypt <= '0';
	InputDataReady <= '0';	
	Reset <= '1';
	Test_correct_count := 0;
	wait_clocks(Clock, 5);	
	Reset <= '0';
	------------
	
-- FIPS ENCRYPTION TEST ----------------------------------------------------------------------------------------------
		
		report "-- Running FIPs Encryption Test --" severity note;
		
		
		Decrypt <= '0';
		wait until rising_edge(Accepting_data);
		
		--Input Key
		for k in 0 to 15 loop
			wait for Clock_period/10 ;
			Input_data <= FIPs_Key(k);
			InputDataReady <= '1';
				wait_clocks(Clock,1);
			InputDataReady <= '0';
		end loop;
		
		--Pause
		wait until rising_edge(Accepting_data);
		
		--InputData
		for k in 0 to 15 loop
			wait for Clock_period/10 ;
			Input_data <= FIPs_Encryption_Input(k);
			InputDataReady <= '1';
				wait_clocks(Clock,1);
			InputDataReady <= '0';
		end loop;
		Input_data <= (others => 'U'); --rest of input is unspecified.
		
		--Wait for data on output.
			--wait_clocks(Clock, 300);
		wait until rising_edge(OutputDataReady);
		
		--check the output
		for k in 0 to 15 loop
			if Output_data = FIPs_Encryption_Output(k) then
				Test_correct_count := Test_correct_count +1;
			else
				report "Error in Encryption result "&integer'image(k)&". Expected "& byte_to_str(FIPs_Encryption_Output(k)) &" and got " & byte_to_str(Output_data) severity warning;
			end if;
			--assert Output_data = FIPs_Encryption_Output(k) report "Error in Encryption result "&integer'image(k)&". Expected "& byte_to_str(FIPs_Encryption_Output(k)) &" and got " & byte_to_str(Output_data) severity warning;
			
			Expected_result <= FIPs_Encryption_Output(k);
				wait_clocks(Clock,1);
				wait for 5 ps; --small delay to make sure output is set
		end loop;
		wait_clocks(Clock,15);

		-- Announce test results
		if Test_correct_count = 16 then
			report "** Encryption Test passed **" severity note;
		else
			report "** Errors occurred in test, please check previous messages **" severity note;
		end if;
		
		report "-- End of FIPs Encryption Test --" severity note;

----------------------------------------------------------------------------------------------------------------------
	-- Cleaup --
	Decrypt <= '0';
	InputDataReady <= '0';	
	Reset <= '1';
	Test_correct_count := 0;
	wait_clocks(Clock, 5);	
	Reset <= '0';
	------------

--FIPs Decryption Test------------------------------------------------------------------------------------------------------------------
	
	report "-- Running FIPs Decryption Test --" severity note;
		
		
		Decrypt <= '1';
		wait until rising_edge(Accepting_data);
		
		--Input Key
		for k in 0 to 15 loop
			wait for Clock_period/10 ;
			Input_data <= FIPs_Key(k);
			InputDataReady <= '1';
				wait_clocks(Clock,1);
			InputDataReady <= '0';
		end loop;
		
		--Pause
		wait until rising_edge(Accepting_data);
		
		--InputData
		for k in 0 to 15 loop
			wait for Clock_period/10 ;
			Input_data <= FIPs_Encryption_Output(k);
			InputDataReady <= '1';
				wait_clocks(Clock,1);
			InputDataReady <= '0';
		end loop;
		Input_data <= (others => 'U'); --rest of input is unspecified.
		
		--Wait for data on output.
			--wait_clocks(Clock, 300);
		wait until rising_edge(OutputDataReady);
		
		--check the output
		for k in 0 to 15 loop
			--assert Output_data = FIPs_Encryption_Input(k) report "Error in Encryption result "&integer'image(k)&". Expected "& byte_to_str(FIPs_Encryption_Input(k)) &" and got " & byte_to_str(Output_data) severity warning;
			if Output_data = FIPs_Encryption_Input(k) then
				Test_correct_count := Test_correct_count + 1;
			else
				report "Error in Encryption result "&integer'image(k)&". Expected "& byte_to_str(FIPs_Encryption_Input(k)) &" and got " & byte_to_str(Output_data) severity warning;
			end if;
			
			
			Expected_result <= FIPs_Encryption_Input(k);
				wait_clocks(Clock,1);
				wait for 5 ps; --small delay to make sure output is set
		end loop;
		wait_clocks(Clock,15);
		
		
		-- Announce test results
		if Test_correct_count = 16 then
			report "** Decryption Test passed **" severity note;
		else
			report "** Errors occurred in test, please check previous messages **" severity note;
		end if;

		
		report "-- End of FIPs Decryption Test --" severity note;
----------------------------------------------------------------------------------------------------------------------

--End of testing ----
		report "------ End of Testbench ------" severity note;
		wait_clocks(Clock,5);
		clk_enable <= '0';

      wait;

   end process;

END;
