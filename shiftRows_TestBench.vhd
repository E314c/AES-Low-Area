--------------------------------------------------------------------------------
--Authour:	Rael S-R
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
use work.AES_Types.all;
use work.TB_funcs.all;
 
ENTITY shiftRows_TestBench IS
END shiftRows_TestBench;
 
ARCHITECTURE behavior OF shiftRows_TestBench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT shiftRows
    PORT(
         Input_data : IN  std_logic_vector(7 downto 0);
         Output_data : OUT  std_logic_vector(7 downto 0);
         Decrypt : IN  std_logic;
         Clk : IN  std_logic;
         Resync : IN  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal Input_data : std_logic_vector(7 downto 0) := (others => '0');
   signal Decrypt : std_logic := '0';
   signal Clk : std_logic := '0';
   signal Resync : std_logic := '0';

 	--Outputs
   signal Output_data : std_logic_vector(7 downto 0);
	
	
	--Test control signals:
	signal start_input, check_output: STD_LOGIC := '0';	--These allow us to put data input and output checking as functions.

	constant Expected_encrypt_output: BYTE_BUS(0 to 15):= ( x"00", x"05", x"0a", x"0f", x"04", x"09", x"0e", x"03", x"08", x"0d", x"02", x"07", x"0c", x"01", x"06", x"0b");
	constant Expected_decrypt_output: BYTE_BUS(0 to 15):= ( x"00", x"0d", x"0a", x"07", x"04", x"01", x"0e", x"0b", x"08", x"05", x"02", x"0f", x"0c", x"09", x"06", x"03");
	
	signal expected_out : std_logic_vector(7 downto 0);
	
	--debug signals:
	signal clock_counter : integer := 0;
	signal clk_count : std_logic_vector(7 downto 0); --because simulators don't like changing radix of integer
	
   -- Clock period definitions
   constant Clk_period : time := 10 ns;
	signal clk_enable : std_logic := '1';
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: shiftRows PORT MAP (
          Input_data => Input_data,
          Output_data => Output_data,
          Decrypt => Decrypt,
          Clk => Clk,
          Resync => Resync
        );
	clk_count <= std_logic_vector(to_unsigned(clock_counter,clk_count'length));
	
   -- Clock process definitions
   Clk_process :process
   begin
		if clk_enable = '1' then
			Clk <= '0';
			wait for Clk_period/2;
			Clk <= '1';
			clock_counter <= clock_counter + 1;
			wait for Clk_period/2;
		end if ;
   end process;
 
-- Stimulus process --------------------------
   stim_proc: process
   begin		
	--intialise:
	clk_enable <='1';
	Decrypt <= '0';
	start_input<='0';
	check_output <= '0';
	
	
	Resync <= '1';
	wait_clocks(Clk, 5); --wait 5 clocks
	Resync <= '0';

	
	
--------------------------------------------------------------------------------
		
		
		---------- ENCRYPTION TEST ------------
		report "--- Start of Encrpytion test ---";
		Decrypt <= '0';
		
		--start input:
		start_input <= '1';
		
			wait_clocks(Clk, 13); --wait 1 clocks
		Resync <= '1';	-- prepare resync for the 12th clock cycle
		
			wait_clocks(Clk, 1); --wait 1 clock
		Resync <= '0';
		check_output <= '1'; --prepare checking of output for 13th clock cycle.
		

		--Wait for output to finish.
		wait_clocks(Clk, 16);
		
		report "--- End of Encrpytion test ---";
		-------- END OF ENCRYPTION TEST -------
		
		---------------------------------
		start_input <= '0';
		check_output <= '0';
		Decrypt <= '1';
		Resync <= '1';
		wait_clocks(Clk, 5);
		Resync <= '0';
		---------------------------------
		
		---------- DECRYPTION TEST ------------
		report "--- Start of Decrpytion test ---";
		Decrypt <= '1';
		
		--start input: 
		start_input <= '1';
		
			wait_clocks(Clk, 13); --wait 12 clocks
		Resync <= '1';	--resync for the 13th clock cycle
			wait_clocks(Clk, 1); --wait 1 clock
		Resync <= '0';
		
		check_output <= '1';
		
		wait_clocks(Clk, 16);
		report "--- End of Decrpytion test ---";
		-------- END OF DECRYPTION TEST -------
		
		---------------------------------
		start_input <= '0';
		check_output <= '0';
		Decrypt <= '0';
		Resync <= '0';
		---------------------------------
		
		
		
		--
--------------------------------------------------------------------------------
		
		report "----- End of testing -----";
      clk_enable <= '0';
		wait;
		
   end process;
--End of stimulus process-------------------------

	data_in_proc : process(Clk, start_input)
		variable i : integer := 0;
	begin
		if rising_edge(Clk) then
			if start_input = '1' then
				Input_data <= std_logic_vector(to_unsigned(i,Input_data'length));
				i := i+1;
			else
				i := 0;
			end if;
		end if;
	end process;
	
	out_check_proc : process(Clk, check_output)
			variable i : integer := 0;
	begin
		if falling_edge(Clk) then
			if check_output = '1' then
				if Decrypt = '0' then
					assert output_data <= Expected_encrypt_output(i) report "Encryption Error in data check "&integer'image(i)&": Expected "& byte_to_str(Expected_encrypt_output(i)) &" and got "& byte_to_str(output_data) severity warning;
					 report "Expected "& byte_to_str(Expected_encrypt_output(i)) &" and got "& byte_to_str(output_data) severity note;
					expected_out <= Expected_encrypt_output(i);
				else 
					assert output_data <= Expected_decrypt_output(i) report "Decryption Error in data check "&integer'image(i)&": Expected "& byte_to_str(Expected_encrypt_output(i)) &" and got "& byte_to_str(output_data) severity warning;
					expected_out <= Expected_decrypt_output(i);
				end if;
				i := i+1;
				if i > 15 then
					i:= 0;
				end if;
			else
				i := 0;
				expected_out <= (others => 'U');
			end if;
		end if;
	end process;

END;
