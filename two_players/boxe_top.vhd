----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:55:48 12/10/2020 
-- Design Name: 
-- Module Name:    boxe_top - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity boxe_top is
   port (
      clock,reset: in std_logic;
    --  btn: in std_logic_vector (1 downto 0);
      hsync, vsync: out  std_logic;
      outred: out std_logic_vector(2 downto 0);
	  outgreen: out std_logic_vector(2 downto 0);
	  outblue: out std_logic_vector(1 downto 0);
      ps2d, ps2c: in  std_logic
   );
end boxe_top;

architecture arch of boxe_top is
   signal pixel_x, pixel_y: std_logic_vector (9 downto 0);
   signal video_on, pixel_tick, clk: std_logic;
   signal rgb_reg, rgb_next: std_logic_vector(2 downto 0);
	signal key_code: std_logic_vector(3 downto 0);
	signal timer_tick, timer_start, timer_up: std_logic;
begin

  -- instantiate clock manager unit
	-- this unit converts the 25MHz input clock to the expected 50MHz clock
	clockmanager_unit: entity work.clockmanager 
	  port map(
		CLKIN_IN => clock,
		RST_IN => reset,
		CLK2X_OUT => clk,
		LOCKED_OUT => open);
		
   -- instantiate VGA sync
   vga_sync_unit: entity work.vga_sync
      port map(clk=>clk, reset=>reset,
               video_on=>video_on, p_tick=>pixel_tick,
               hsync=>hsync, vsync=>vsync,
               pixel_x=>pixel_x, pixel_y=>pixel_y);
   -- instantiate graphic generator
   boxe_graph_unit: entity work.pong_graph
      port map (clk=>clk, reset=>reset,
                key_code=>key_code, video_on=>video_on,
                pixel_x=>pixel_x, pixel_y=>pixel_y,
                graph_rgb=>rgb_next,
					 time_start=>timer_start,
                timer_up=>timer_up);					 
					 
	-- instantiate KB_code				 
		   kb_code_unit: entity work.kb_code
      port map (clk=>clk, reset=>reset,
                ps2d=>ps2d, ps2c=>ps2c,
                key_code=>key_code);
					 
	-- instantiate 2 sec timer
   timer_tick <=  -- 60 Hz tick
      '1' when pixel_x="0000000000" and
               pixel_y="0000000000" else
      '0';
   timer_unit: entity work.timer
      port map(clk=>clk, reset=>reset,
               timer_tick=>timer_tick,
               timer_start=>timer_start,
               timer_up=>timer_up);
		
   -- rgb buffer
   process (clk)
   begin
      if (clk'event and clk='1') then
         if (pixel_tick='1') then
            rgb_reg <= rgb_next;
         end if;
      end if;
   end process;
    outred <= rgb_reg(2) & rgb_reg(2) & rgb_reg(2);
	outgreen <= rgb_reg(1) & rgb_reg(1) & rgb_reg(1);
	outblue <= rgb_reg(0) & rgb_reg(0);
end arch;
