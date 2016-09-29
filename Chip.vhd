----------------------------------------------------------------------------------
--
-- Created by Rael Sasiak-Rushby for EEE6225 module
-- 
-- Main chip design by Rael Sasiak-Rushby
-- Subcomponents by group members:
--	- SubBytes		:	Matthew Fergusson
--	- KeyScheduler	:	Ben Trevett
--	- MixCollumns	:	Domininc Le Blanc
-- - ShiftRows		:	Rael Sasiak-Rushby
--
-- Device aim: Low area implementation of AES encryption and decryption on FPGA.
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;
use work.AES_types.all;

entity Chip is
    Port ( 	 
				--System
				Clock : in  STD_LOGIC;			-- System clock signal
				
				--Data
				Input_Data : in BYTE;		-- Data block into the system
				Output_Data : out BYTE;	-- Data block out of the system
				
				--Flags in
				Reset : in  STD_LOGIC;			-- Signal to reset chip.
				Decrypt: in STD_LOGIC;			-- Input to select decryption mode. 0 = encrypt, 1 = decrypt.
				InputDataReady : in STD_LOGIC;		-- Whether data on Input_Data is valid data to be processed.
				
				-- Flags out
				OutputDataReady : out  STD_LOGIC;		-- Signal to indicate data is ready on Output_Data line
				Accepting_data : out STD_LOGIC	-- Flag to tell user whether chip is accepting data.
				
				);
end Chip;

architecture Chip_Behavioral of Chip is

----------------------------------------------------------------------------------------------
--components--
----------------------------------------------------------------------------------------------
component subBytes_nop is
Generic ( N : natural);
    Port ( Input_data : in BYTE_BUS(N-1 downto 0);
           Output_data : out BYTE_BUS(N-1 downto 0);
           Clk : in  STD_LOGIC;
			  Decrypt: in STD_LOGIC;
			  reset: in STD_LOGIC;
			  enable: in STD_LOGIC
			  );
end component;
--------------------------------------
component mixCol_byte is
	Port (	Byte_In : in  STD_LOGIC_VECTOR (7 downto 0);
				Byte_Out : out  STD_LOGIC_VECTOR (7 downto 0);
				CLK : in  STD_LOGIC;
				Decrypt : in  STD_LOGIC;
				Reset : in  STD_LOGIC;
				Resync : in STD_LOGIC);

end component;
--------------------------------------
component shiftRows is
    Port ( Input_data : in  BYTE;
           Output_data : out  BYTE;
			  Decrypt : in STD_LOGIC;
           Clk : in  STD_LOGIC;
			  Resync : in STD_LOGIC);
end component;
--------------------------------------
component keySchedule_byte is
    Port ( key_in : in  BYTE;
           key_out : out  BYTE;
			  clk : in STD_LOGIC;
			  start : in  STD_LOGIC;
           key_ready : out  STD_LOGIC;
           reset : in  STD_LOGIC;
			  decrypt: in STD_LOGIC;
			  key_10 : out STD_LOGIC
			  );
end component;
--------------------------------------
component  addRoundKey is
    Port ( 
				Input_1 : 		in BYTE;
				Input_2 : 		in BYTE;
				Output_data : 	out BYTE;
				enable : 		in STD_LOGIC;
				clk :				in STD_LOGIC);
end component;
--------------------------------------
component shift_reg is
	Generic(N : natural);
   Port (	Byte_in : in  STD_LOGIC_VECTOR (7 downto 0);
				Byte_out : out  STD_LOGIC_VECTOR (7 downto 0);
				Clk : in  STD_LOGIC);
end component;

---------------------------------------
component SRL16x8 is
    Port ( Byte_In : in  STD_LOGIC_VECTOR (7 downto 0);
           Carry_out : out  STD_LOGIC_VECTOR (7 downto 0);
           Addr : in  STD_LOGIC_VECTOR (3 downto 0);
           Byte_out : out  STD_LOGIC_VECTOR (7 downto 0);
           Clk : in  STD_LOGIC;
           Clk_Enable : in  STD_LOGIC);
end component;
---------------------------------------
---------------------------------------------------------------
--Signals
---------------------------------------------------------------

--Inter block signals:
signal In_buff, AR1_LB, LB_SR, SR_SB, SB_LE, AR2_MC, MC_AR3, AR3_DL, DL_LB, DL2_AR4, mux_AR4: BYTE; --Data and key buses
-- In_buff	is output of the input buffer (goes to KS and AR1)
-- AR1_LB	is between AddRoundkey_1 and Loop_Begin
-- LB_SR		is between Loop_Begin and shiftRows
-- SR_SB		is between shiftRows and subBytes
-- SB_LE		is between subBYtes and Loop_End (which maps to AR2 and DL2)
-- AR2_MC 	is between addRoundKey_2 and mix Columns
-- MC_AR3	is between mixColumns and addRoundKey_3
-- AR3_DL	is between addRoundKey_3 and loop_delay
-- DL_LB		is between loop_delay and Loop_Begin
-- DL2_AR4 	is between delay_block_2 and addRoundKey_4_mux
-- mux_AR4	is the signal into addRoundKey_4

--------------------
--key signals
--------------------
signal round_key, key_sch_out, key_rep_out: BYTE;
-- round_key 		global key for the current round.
--	Key_sch_out		Key from key scheduler
--	Key_rep_out		Key from key repeater
signal start_KS, dataR_KS, key_10_flag: STD_LOGIC;

signal AR1_key, AR2_Key, AR3_Key, AR4_Key : BYTE;
--Individual signals for each use of round key as they require relative delays:
--		AR1 only needs the first round key (input key for encrypt, Key_10 for decrypt)
--		AR3 requires the same key as AR2, but 4 clock cycles later. However, only one is enabled in either encrypt/decrypt
--		AR4 only need the final round key (Key_10 for encrypt, initial key for decrypt)
signal AR1_key_buff_en, AR1_loop : std_logic;
signal AR1_key_buff_in : BYTE;
--		AR1 is loaded from a seperate key storage, which is used so the key schedule can run ahead and get key ready for AR2.


------------------
--Global flags
------------------
signal Decrypt_flag, Inv_Decrypt_flag, Global_reset, Loop_entry : STD_LOGIC;
-- (Inv_)Decrypt_flag		set at the beginning of processing block, these tell the system whether to run encryption/decryption patterns.
-- Global_reset				a global signal to reset components, placing the system into an safe state.
-- Loop_entry					Controls data into/out of the loop

----------------------
--Recync signals
----------------------
signal SR_Resync : std_logic ;
signal MC_Resync : std_logic ; -- Added by Matt 24/03/16
--Some sub components need to be re-synchronised at certain parts of the state.


-------------------------------
--State Machine signals
-------------------------------
type c_state is (RST, IDLE_1, LOAD_KEY, IDLE_2, DECRYPT_WAIT_1, DECRYPT_WAIT_2, PROCESSING);
--	RST				Chip resets to a safe state
--	IDLE_1			Wating for user Key input
--	LOAD_KEY			Loading key into scheduler
--	IDLE_2			Waiting for user data input
--	DECRYPT_WAIT	There is an additional delay before decryption can be processed.
-- PROCESSING		The system is processing Data.
signal chip_state, nxt_chip_state : c_state := RST;

signal counter_1 : integer range 0 to 400;


--Timing Constants
constant OUTPUT_READY_AFTER : integer := 308; --Counter value when output data is ready
constant RESYNC_SR :	integer := 13;	---Counter value when ShiftRows should be re-synced
constant RESYNC_MC : integer := 15;	--Counter value when MixCollumns should be re-synced
constant KEY_START_DELAY : integer := 20;	-- Counter value when key_start should start going high.
														-- this is basically the time between processing going high and data arriving at AR3
														-- (timed for encryption)
constant AR2_AR3_TIME_DIF : integer := 5; --The timing difference between AR2 and AR3. (essentially the delay through MC)

--test signal
--signal counter_1_vector : std_logic_vector(16 downto 0);

----------------------------------------------------------------------------------------------------


---------------- BEGINNING OF CHIP_BEHAVIOURAL -------------------
begin
----------------------------------------------------------------------------------------------------
--Sub component port mapping--
----------------------------------------------------------------------------------------------------

input_delay : shift_reg	--we ned a one clock delay on the input
	Generic map (N => 1)
   Port map (	Byte_in =>Input_Data,
					Byte_out =>In_buff,
					Clk => Clock
				);

addRoundKey_1 :  addRoundKey
port map(
		Input_1 => In_buff,
		Input_2 => AR1_Key,
		Output_data => AR1_LB, 
		enable => '1', --this one will always add the round key
		clk => Clock
);

subBytes_1 : subBytes_nop
generic map(N => 1)
port map (
		Input_data(0)	=> SR_SB,
		Output_data(0) => SB_LE,
		Clk 		=> Clock,
		Decrypt 	=> Decrypt_flag,
		Reset 	=> Global_reset,
		enable	=> '1'
		);
		
shiftRows_1 : shiftRows
port map (
		Input_data => LB_SR,
		Output_data => SR_SB,
		Decrypt => Decrypt_flag,
		Resync => SR_Resync,
		Clk => Clock
		);		  

addRoundKey_2 :  addRoundKey
port map(
		Input_1 => SB_LE,	--data from loop exit point
		Input_2 => AR2_Key,
		Output_data => AR2_MC, 
		enable => Decrypt_flag, --this one is only enabled if we're decrypting
		clk => Clock
);

mixColumns_1 : mixCol_byte
port map (
		Byte_in		=> AR2_MC,
		Byte_out		=> MC_AR3,
		Clk 			=> Clock,
		Decrypt 		=> Decrypt_flag,
		Reset 		=> Global_reset,
		Resync      => MC_Resync
		);

addRoundKey_3 :  addRoundKey
port map(
		Input_1 => MC_AR3,
		Input_2 => AR3_Key,
		Output_data => AR3_DL, 
		enable => Inv_Decrypt_flag,	--(NOT Decrypt_flag), --this one is only enabled if we're NOT decrypting
		clk => Clock
);

loop_delay : shift_reg
	Generic map (N => 12)
   Port map (	Byte_in =>AR3_DL,
					Byte_out =>DL_LB,
					Clk => Clock
				);
delay_block_2 : shift_reg
	Generic map (N => 5)
   Port map (	Byte_in => SB_LE,	--data from loop exit point
					Byte_out =>DL2_AR4,
					Clk => Clock
				);

addRoundKey_4 :  addRoundKey
port map(
		Input_1 => mux_AR4,
		Input_2 => AR4_Key,
		Output_data => Output_data, --output of chip
		enable => '1', --this one will always add the round key
		clk => Clock
);



---Key components ---
keySchedule_1 : keySchedule_byte
port map(
		key_in 		=> In_buff,
		key_out		=>	key_sch_out,
		Clk			=> Clock,
		start			=> start_KS,
		key_ready	=> dataR_KS,
		Reset			=> Global_reset, 
		Decrypt		=> Decrypt_flag,
		key_10		=> key_10_flag
	);
key_repeater : SRL16x8
port map	( Byte_In	=> key_sch_out,
           Carry_out	=> key_rep_out,
           Addr 		=> (others => '0'),
           Byte_out	=> open,
           Clk			=> Clock,
           Clk_Enable	=> '1'
			);
AR1_key_buff : SRL16x8
port map	( Byte_In	=> AR1_key_buff_in,
           Carry_out	=> AR1_key,
           Addr 		=> (others => '0'),
           Byte_out	=> open,
           Clk			=> Clock,
           Clk_Enable	=> AR1_key_buff_en
			);



------------------------------------------------------------------------------------------------
--Concurrent Declarations
-------------------------------------------------------------------------------------------------
Inv_Decrypt_flag <= NOT Decrypt_flag;

--Path muxxers:
	-- Load or loop data.
	LB_SR		<= AR1_LB	WHEN Loop_entry = '1'		ELSE DL_LB;
		
	--AR4 input mux
	mux_AR4 <= SB_LE WHEN Decrypt_flag = '1' ELSE DL2_AR4; --In encrypt mode, AR4 requires data is delayed by 4. In decrypt mode it seems to be automatically synced.
	
	--	AR1_key_buff mux
	AR1_key_buff_in <= key_sch_out WHEN AR1_loop = '0' ELSE AR1_key;
	
	
	--test mapping
	--counter_1_vector <= std_logic_vector(to_unsigned(counter_1,counter_1_vector'length));
	
-------------------------------------------------------------------------------------------------
--Process definitions
-------------------------------------------------------------------------------------------------

--STATE MACHINE
state_machine_driver : process(Clock, Reset)
begin
	if Reset = '1' then
		chip_state <= RST;
	elsif rising_edge(Clock) then
		chip_state <= nxt_chip_state;
	end if;
end process;

state_machine_body : process(chip_state, InputDataReady, counter_1, key_10_flag, Decrypt_Flag)
--Drives: Global_Reset, nxt_chip_state, counter_1
begin
	--Initialise all:
	nxt_chip_state <= chip_state;
	Global_Reset <= '0';
	
	--Case
	--RST, IDLE_1, LOAD_KEY, DECRYPT_WAIT, IDLE_2, PROCESSING
	case(chip_state) is
		when RST =>
		
			Global_Reset <= '1';
			nxt_chip_state  <= IDLE_1;
			
		when IDLE_1 =>
			
			Global_Reset <= '0';
			if InputDataReady = '1' then
				nxt_chip_state <= LOAD_KEY;
			end if;
			
		when LOAD_KEY =>
			
			if counter_1 >= 15 then
				if Decrypt_flag = '1' then
					nxt_chip_state <= DECRYPT_WAIT_1;
				else
					nxt_chip_state <= IDLE_2;
				end if;
			end if;		
		
		when DECRYPT_WAIT_1 =>
			
			if key_10_flag = '1' then -- we move to next state after key_10 has been loaded into AR1 storage
				nxt_chip_state <= DECRYPT_WAIT_2;
			end if;
			
		when DECRYPT_WAIT_2 =>
			if key_10_flag = '0' then -- we move to next state after key_10 has been loaded into AR1 storage
				nxt_chip_state <= IDLE_2;
			end if;
		
		when IDLE_2 =>
			
			if InputDataReady = '1' then
				nxt_chip_state <= PROCESSING;
			end if;
						
		when PROCESSING =>
			
			--Just counting Clocks, probably not best option.
			if counter_1 >= (OUTPUT_READY_AFTER+32) then
				nxt_chip_state <= IDLE_1;
			end if;			
			
		when others =>
			nxt_chip_state  <= RST;
	
	end case;

--end state_machine_body;
end process;

counter_process : process(Clock)
--Drives: counter_1
begin
	if rising_edge(Clock) then	
		if(chip_state = IDLE_1 OR chip_state = IDLE_2) then
			counter_1 <= 0;
		else
			counter_1 <= counter_1 + 1;
		end if;
	end if;
	
--end counter_process;
end process;


loop_control : process(chip_state, counter_1)
--Drives: loop_entry
begin
	if (chip_state = PROCESSING) and (counter_1 >= 33) then
		Loop_entry <= '0'; 
	else
		Loop_entry <= '1';
	end if;
	
--end loop_control;
end process;



accepting_data_proc : process(chip_state)
begin
	if chip_state = IDLE_1 OR chip_state = IDLE_2 then
		Accepting_data <= '1';
	else
		Accepting_data <= '0';
	end if;
end process;

output_ready_proc : process(chip_state, counter_1)
--Drives:	OutputDataReady
begin

	if Decrypt_flag = '0' AND (chip_state = PROCESSING AND counter_1 > OUTPUT_READY_AFTER) then
		OutputDataReady <= '1';
	elsif Decrypt_flag = '1' AND (chip_state = PROCESSING AND counter_1 > OUTPUT_READY_AFTER-5) then	--Decrypt is ready 5 clock cycles earlier (as there isn't the delay before AR4)
		OutputDataReady <= '1';
	else
		OutputDataReady <= '0';
	end if;

end process;

decrypt_flag_proc : process(Clock)
--Purpose:	Setup the decryption flag
begin
	if rising_edge(Clock) AND chip_state = IDLE_1 then
		Decrypt_flag		<= Decrypt;
	end if;
end process;

---------------------------------------
-- Key scheduler handler
---------------------------------------

Key_sched_handler : process(chip_state, counter_1, key_sch_out, key_rep_out, Decrypt_flag)
--Purpose:	signals key_schedule when it should be running and when it should freeze.
--Drives:	 start_KS
begin
	if Decrypt_flag = '1' then
		--Decryption mode:
		if chip_state = PROCESSING OR chip_state = LOAD_KEY or chip_state = DECRYPT_WAIT_1 or chip_state = DECRYPT_WAIT_2 then
			 start_KS	<= '1';
		else
			 start_KS	<= '0';
		end if;
	else
		--Encryption mode:
		if (chip_state = PROCESSING AND ( (32 + counter_1 - KEY_START_DELAY )/16 mod 2 = 0) AND counter_1 >= KEY_START_DELAY ) OR chip_state = LOAD_KEY then
			 start_KS	<= '1';
		else
			 start_KS	<= '0';
		end if;
	end if;
	
end process;

round_key_mux : process(key_rep_out, key_sch_out, start_KS, Clock, Decrypt_flag )
--Purpose:	Mux the round_key
--Drives:	round_key
variable counter : integer :=0;
begin

	if Decrypt_flag = '0' then
		--encryption:
		if start_KS = '1' then
			round_key <= key_sch_out;
		else 
			round_key <= key_rep_out;
		end if;
	else
		--Decryption:
		if (counter_1 - ( KEY_START_DELAY - AR2_AR3_TIME_DIF))/16 mod 2 = 0 then
			round_key <= key_sch_out;
		else 
			round_key <= key_rep_out;
		
		end if;
	end if;
		
end process;

key_distributor : process(round_key, chip_state, Decrypt_flag ,key_10_flag)
--Purpose: Handle the distribution of the round key to the addRoundKey components
--Drives  AR1_key_buff_en, AR1_loop, AR2_Key, AR3_Key, AR4_Key 
begin

--some defaults while I work on the code.
 AR2_Key <= round_key;	-- synced up to the round key using variance in start_KS
 AR3_Key	<= round_key;	-- synced up to the round key using variance in start_KS
 AR4_Key <= round_key;	-- apparently auto-synced due to system delays(found out when i was looking into simulation) 


	--AR1 mapping: if encrypt, copy in first key, if decrypt, load key when key_10 asserted.
	if chip_state = PROCESSING then	--if we've start processing, load starting key out of buffer
		AR1_key_buff_en <= '1';
		AR1_loop <= '1';	--	AR1 loops
	else
		AR1_loop <= '0';	--Don't loop AR1
		if	Decrypt_flag = '0' AND chip_state = LOAD_KEY  then	--if encrypting, take in the key as we load it
			AR1_key_buff_en <= '1';
		
		elsif	Decrypt_flag = '1' AND key_10_flag='1' then		--if decrypting, take in the key when key_10 is being output
			AR1_key_buff_en <= '1';
		
		else
			AR1_key_buff_en <= '0';
		
		end if;
	end if;



end process;

-----------------------------
--Synchronisation processes--
-----------------------------
shiftRows_resync_proc : process(chip_state, counter_1)
begin
	if (chip_state = PROCESSING) and (counter_1 = RESYNC_SR) then
		SR_Resync <= '1';
	else
		SR_Resync <= '0';
	end if;
end process;

MixColumns_resync_proc : process(chip_state, counter_1)
-- The Resync should be asserted one clock pulse, for a clock pulse in length just before MicCol_byte is due to receive a byte
begin
	if (chip_state = PROCESSING) and (counter_1 = RESYNC_MC) then
		MC_Resync <= '1';
	else
		MC_Resync <= '0';
	end if;

end process;

---------- END OF BEHAVIOURAL -----------------------------------------------------------------------------------------
end Chip_Behavioral;

--*******************************************************************************************************************--