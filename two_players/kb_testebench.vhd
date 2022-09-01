--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   12:45:15 12/11/2020
-- Design Name:   
-- Module Name:   D:/Eletr_Programavel/two_players/kb_testebench.vhd
-- Project Name:  two_players
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: kb_code
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
 
ENTITY kb_testebench IS
END kb_testebench;
 
ARCHITECTURE behavior OF kb_testebench IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT kb_code
    PORT(
         clk : IN  std_logic;
         reset : IN  std_logic;
         ps2d : IN  std_logic;
         ps2c : IN  std_logic;
         key_code : OUT  std_logic_vector(3 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal reset : std_logic := '0';
   signal ps2d : std_logic := '0';
   signal ps2c : std_logic := '0';


 -- sinais internos
	signal data_received : std_logic_vector (19 downto 0);
	signal clock_received : std_logic_vector(22 downto 0);
	signal counter : unsigned(4 downto 0);





 	--Outputs
   signal key_code : std_logic_vector(3 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: kb_code PORT MAP (
          clk => clk,
          reset => reset,
          ps2d => ps2d,
          ps2c => ps2c,
          key_code => key_code
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
		reset <= '1';
		
		
		counter<="0000";
      wait for clk_period;
		reset <= '0';
		-- simulate a serial stream being received
		data_received <= "0010000100"; -- start bit + data byte + stop bit
		while counter /= "1001" loop
			wait for clk_period*2*16;
			rx <= data_received(9);
			data_received <= data_received (8 downto 0) & '1';
			counter <= counter+1;
				end loop; 
		btn<='1';
		wait for clk_period*2*16;
		btn<='0';

      wait;

END;
