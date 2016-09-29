library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.AES_types.all;

entity keySchedule_byte is
    Port ( key_in : in  BYTE;
           key_out : out  BYTE;
			  clk : in STD_LOGIC;
			  start : in  STD_LOGIC;
           key_ready : out  STD_LOGIC;
           reset : in  STD_LOGIC;
			  decrypt: in STD_LOGIC;
			  key_10 : out STD_LOGIC
			  );
end keySchedule_byte;

architecture Behavioral of keySchedule_byte is

--
--begin component declaration
--

--shift register lut, 16 wide, 8 'tall' (i.e. holds 16 bytes)
component SRL16x8 is
		Port ( Byte_In : in  STD_LOGIC_VECTOR (7 downto 0);
			   Carry_out : out  STD_LOGIC_VECTOR (7 downto 0);
			   Addr : in  STD_LOGIC_VECTOR (3 downto 0);
			   Byte_out : out  STD_LOGIC_VECTOR (7 downto 0);
			   Clk : in  STD_LOGIC;
			   Clk_Enable : in  STD_LOGIC
				);
	end component;
	
--2 to 1 multiplexer, used to select desired paths	
component mux2to1 is
		Port ( I0 : in STD_LOGIC_VECTOR(7 downto 0); --input selected when S = 0
				 I1 : in STD_LOGIC_VECTOR (7 downto 0); --input selected when S = 1
				 S : in STD_LOGIC; --select line
				 O : out STD_LOGIC_VECTOR(7 downto 0) --output
		);
	end component;

--byte wide register
component register8
	port( input : in std_logic_vector(7 downto 0);
		   output : out std_logic_vector(7 downto 0);
			enable: in std_logic; --load enable
			reset : in  std_logic; --reset/clear register
			clk : in  std_logic --clock
			);
	end component;

--unpipelined sub-bytes, takes 1 clock cycle
component subBytes_nop
generic ( N : natural);	-- eg N=1, 2,4,8,16,20...
    port ( Input_data : in BYTE_BUS(N-1 downto 0);
           Output_data : out BYTE_BUS(N-1 downto 0);
           Clk : in  STD_LOGIC;
			  Decrypt: in STD_LOGIC;
			  reset: in STD_LOGIC;
			  enable: in STD_LOGIC);
end component;
	
--
--begin signal declaration
--
	signal counter : integer range 0 to 15; --counting clock cycles, should be new key every 16
	signal key_count : integer range 0 to 32; --which key we are on

	signal srl_input : std_logic_vector(7 downto 0); --input to SRL, Q0
	signal srl_carry : std_logic_vector(7 downto 0); --carry output of SRL, Q15
	signal srl_output : std_logic_vector(7 downto 0); --output of SRL depending on the mux
	signal srl_sel : std_logic_vector (3 downto 0); --selects the srl_output
	signal srl_enable : std_logic; --enables the srl
	
	signal rcon : std_logic_vector(7 downto 0); --rcon value
	signal rcon_and_output : std_logic_vector(7 downto 0); --output of the mux, selects either rcon or 0
	signal rcon_and : std_logic_vector(7 downto 0); --mux select line
	
	signal input_mux_output : std_logic_vector(7 downto 0); --this mux chooses if we want external key or feedback key
	signal input_mux_sel : std_logic; --mux select line
	
	signal path_mux_output : std_logic_vector(7 downto 0); --chooses if we want sb value or not
	signal path_mux_sel : std_logic; --mux select line
	
	signal rcon_xor_output : std_logic_vector(7 downto 0); --output of the rcon xor
	
	signal path_reg_output : std_logic_vector(7 downto 0); --register to do delay if not going through sb to keep in sync
	
	signal sb_output : std_logic_vector(7 downto 0); --output of subbytes
	
	signal reg_enable : std_logic; --enable for registers
	
	signal wait_and_input : std_logic_vector(7 downto 0); -- held 0 for first 16 cycles (initial key in)
	signal wait_and_output : std_logic_vector(7 downto 0); --AND gate stops the initial key being xor'd with feedback

	signal decrypt_reg1_output : std_logic_vector(7 downto 0);
	signal decrypt_reg2_output : std_logic_vector(7 downto 0);
	signal decrypt_reg3_output : std_logic_vector(7 downto 0);
	signal decrypt_reg4_output : std_logic_vector(7 downto 0);
	
	signal carry_mux_output : std_logic_vector(7 downto 0);
	signal carry_mux_sel : std_logic;
	
	signal output_mux_output : std_logic_vector(7 downto 0);
	signal output_mux_sel : std_logic;

	signal reg_enable_intermediate : std_logic;
	signal srl_enable_intermediate : std_logic;


begin

--instance of sub-bytes, connected to the srl output, feeds the XOR with rcon 
keySubBytes : subBytes_nop
	generic map(N => 1)
	port map (
		Input_data(0)	=> srl_output,
		Output_data(0) => sb_output,
		Clk 			=> clk,
		Decrypt 		=> '0',
		Reset 		=> reset,
		enable => start
		);
	
--data flows through here instead of going through sb, needs the register to delay by 1 cycle to keep in sync with sb values
path_reg: register8 port map(
	input => srl_output,
	output => path_reg_output,
	enable => start,
	reset => reset,
	clk => clk
	);

decrypt_reg1: register8 port map(
	input => srl_carry,
	output => decrypt_reg1_output,
	enable => reg_enable,
	reset => reset,
	clk => clk
	);
	
decrypt_reg2: register8 port map(
	input => decrypt_reg1_output,
	output => decrypt_reg2_output,
	enable => reg_enable,
	reset => reset,
	clk => clk
	);
	
decrypt_reg3: register8 port map(
	input => decrypt_reg2_output,
	output => decrypt_reg3_output,
	enable => reg_enable,
	reset => reset,
	clk => clk
	);
	
decrypt_reg4: register8 port map(
	input => decrypt_reg3_output,
	output => decrypt_reg4_output,
	enable => reg_enable,
	reset => reset,
	clk => clk
	);

--the srl16x8 
--input from input mux (selects between carry feedback or outside key)
--carry loops back around to input mux
--address used to select which entry goes to the srl_output
--srl output goes to sb/register path
--when clock enable is low, data isn't shifter per clock
key_SRL : SRL16x8
   port map (
      byte_in	=> srl_input,
      carry_out	=> srl_carry,
      addr		=> srl_sel,
      byte_out	=> srl_output,
      clk		=> clk,
      clk_enable 	=> srl_enable
   );
	
--used to select if the input to the XOR that feeds the srl will be from the outside world or the srl carry feedback
--0 for outside world
--1 for srl carry feedback
input_mux : mux2to1
	port map (
		I0 => key_in,
		I1 => carry_mux_output,
		S => input_mux_sel,
		O => input_mux_output
	);

--used to select if we want a sub-byted & rcon'd value or not from the srl
--0 for non-sub-byted and rcon'd
--1 for sb & rcon
path_mux : mux2to1
	port map (
		I0 => path_reg_output,
		I1 => rcon_xor_output,
		S => path_mux_sel,
		O => path_mux_output
	);

--decides whether the carry fed back into the xor gate at the srl_input is from the decrypt registers or not
carry_mux : mux2to1
	port map (
		I0 => srl_carry,
		I1 => decrypt_reg4_output,
		S => carry_mux_sel,
		O => carry_mux_output
	);

output_mux : mux2to1
	port map (
		I0 => srl_input,
		I1 => srl_output,
		S => output_mux_sel,
		O => output_mux_output
	);

--XOR's the sub-byted value with the rcon or 0, depending on the rcon mux output
rcon_xor_output <= rcon_and_output XOR sb_output;

--used to not XOR initial key fed in, held 0 for the first 16 clock cycles
wait_and_output <= wait_and_input AND path_mux_output;

--the srl input is the carry (selected from the input mux) and the (possibly transformed) srl output
srl_input <= input_mux_output XOR wait_and_output;	

key_out <= output_mux_output;

rcon_and_output<=rcon AND rcon_and;

srl_enable <= start AND srl_enable_intermediate;
reg_enable <= start AND reg_enable_intermediate;

	process(clk,reset)
	begin
	
		if reset = '1' then --do reset stuff
		
			counter <= 0;			--start counting from 0
			key_count <= 0;
			rcon <= x"01"; 		--rcon input reset to 01
			srl_sel <= "0001"; 	--srl select where it needs to be
			reg_enable_intermediate <= '1';
			srl_enable_intermediate <= '1';
			output_mux_sel <= '0'; --output goes from srl_input
			key_10 <= '0';
			wait_and_input <= x"ff";
			path_mux_sel <= '0';
			rcon_and <= x"00";
			carry_mux_sel <= '0';
			input_mux_sel <= '0';
			
		elsif rising_edge(clk) then
		if start = '1' then
			
			srl_enable_intermediate <= '1';
			reg_enable_intermediate <= '1';
			
			counter <= counter +1;
				
			if key_count<1 and key_count<10 then
				input_mux_sel <= '0'; --0 is from outside
				path_mux_sel <= '0'; --0 from register path
				rcon_and <= x"00"; --0 selects x"00"
				carry_mux_sel <= '0'; --carry if from srl_carry
				wait_and_input <= x"00"; --doesn't mess with new inputs coming in
				
			end if;
			
			if counter > 14 then
				key_count <= key_count+1;
				counter <= 0;				
				
				if key_count = 9 then
					key_10 <= '1';
				else
					key_10 <= '0';
				end if;
				
				--only really need to do these after first key
				wait_and_input <= x"ff"; --begins to xor with srl_carry
				input_mux_sel <= '1'; --1 cuts off outside, allows feedback
				
				--below has to be done here for every key, not beginning of counter as takes 1 clock cycle to do
				if key_count<11 then
				path_mux_sel <= '1'; --goes through sb path
				rcon_and <= x"ff"; --xor's with rcon
				end if;
				
				if key_count>0 and key_count<10 then --only do rcon manipulation after the first key
			
				--below does the rcon multiply by 2 using GF(2^8)
					if rcon(7)='1' then
							rcon <= (rcon(6 downto 0) & '0') xor "00011011";
						else if rcon(7)='0' then
							rcon <= rcon(6 downto 0) & '0';
						end if;
					end if;
				end if;
				
				if key_count>10 and key_count mod 2 = 1 then
				
				if rcon="00011011" then
					rcon <= "10000000";
				else 
					rcon <= '0' & rcon(7 downto 1);
				end if;
				
				end if;
					
			end if;
			
			if key_count>0 and key_count<11 then --encrypting
			
				if counter = 0 then
					rcon_and <= x"00"; --xor's with 0
				end if;
				 
				if counter = 1 then
					srl_sel <= "0101"; --changes which goes to srl_output, this is done to do the cyclic shift
				end if;
				
				if counter = 2 then
					srl_sel <= "0010"; --points to cyclicly shifted value
				end if;
				
				if counter = 3 then
					path_mux_sel <= '0'; --doesn't go through sbox path
				end if;
			
				if counter > 13 then
					srl_sel <= "0001"; 	--srl select where it needs to be for the next round
				end if;
				
				if key_count=10 and counter>13 then
				srl_sel <= "1010";
				path_mux_sel <= '0';
				end if;
				
			end if; --end of key count >0 
			
			if key_count>10 and key_count mod 2 = 1 and decrypt = '1' then --decrypting
				if counter>2 then
					reg_enable_intermediate <= '0'; --holds column 1 for later use
				end if;
				
				if counter>9 then
					srl_sel <= "0001"; --points srl select line to xor with prev key column 4
					
				end if;
				
				if counter>10 then
					reg_enable_intermediate <= '1'; --uses stored key column 1, held in registers 
					carry_mux_sel <= '1'; --instead of using srl_carry, use stored column 1
					path_mux_sel <= '1'; --goes through sbox path
					rcon_and <= x"ff";
				end if;
				
				if counter>11 then
					rcon_and <= x"00"; --only want to xor with rcon for first byte
				end if;
				
				if counter>12 then
					srl_sel <= "0101"; --select cyclicly shifted value
				end if;
			
				--by this point the srl holds
				--col1, col4, col3, col2 of prev key (in that order)
				--next 16 cycles are spent sending this to key_out whilst also getting it in order:
				--col4, col3, col2, col1
				--this is the position the 10th key is in, allowing you to re-use this code for all decrypt keys
			
				--prepare for shifting to key out
				if counter>14 then
					srl_sel <= "0011"; --points to prev key col1-1
					srl_enable_intermediate <= '0'; --don't want to shift while we do first column out
					output_mux_sel <= '1'; --output now from srl_output
					wait_and_input <= x"00"; --don't want to xor with anything
					carry_mux_sel <= '0'; --want to use srl_carry, not registers
				end if;
				
			end if; --end of key_count = 11 and decrpyt = '1'
			
			if key_count>10 and key_count mod 2 = 0 and decrypt = '1' then
			
				if counter=0 then
					srl_sel<="0010";
					srl_enable_intermediate <= '0';
				end if;
				
				if counter=1 then
					srl_sel<="0001";
					srl_enable_intermediate <= '0';
				end if;
				
				if counter=2 then
					srl_sel<="0000";
					srl_enable_intermediate <= '0';
				end if;
				
				if counter=3 then
				srl_enable_intermediate <= '1';
				output_mux_sel <= '0'; --output back to srl_input
				end if;
				
			--prepare for decrypting next key
			if counter>13 then
				srl_sel <= "1010";
				path_mux_sel <= '0';
				end if;
		
			end if;--end of key_count = 12 and decrypt = '1'
			--else
				--srl_enable_intermediate <= '0';
				--reg_enable_intermediate <= '0';
			end if;
		end if; --end of rising clock edge if
		
	end process;
end Behavioral;