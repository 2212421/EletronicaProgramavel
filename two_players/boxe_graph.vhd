----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:01:57 12/10/2020 
-- Design Name: 
-- Module Name:    boxe_graph - Behavioral 
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity boxe_graph is
   port(
        clk, reset: in std_logic;
        key_code: in std_logic_vector(3 downto 0);
        video_on: in std_logic;
        pixel_x,pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0)
   );
end boxe_graph;

architecture arch of boxe_graph is
   signal refr_tick: std_logic;
   -- x, y coordinates (0,0) to (639,479)
   signal pix_x, pix_y: unsigned(9 downto 0);
   constant MAX_X: integer:=640;
   constant MAX_Y: integer:=480;
   constant center_x: integer:=320;
   constant center_y: integer:=240;	
   constant N: integer:=4;
	--=============================================
	--       Player 1
	--=============================================

	signal player1_x_L, player1_x_R: unsigned(9 downto 0);
   signal player1_y_T, player1_y_B: unsigned(9 downto 0);
	constant player1_x_SIZE: integer:=40;
   constant player1_y_SIZE: integer:=40;
   -- reg to track top boundary  (x position is fixed)
	signal player1_x_reg, player1_x_next: unsigned(9 downto 0);
   signal player1_y_reg, player1_y_next: unsigned(9 downto 0);


	signal player1_on: std_logic;
   signal player1_rgb: std_logic_vector(2 downto 0);
	--=============================================
	--       Player 2
	--=============================================

	signal player2_x_L, player2_x_R: unsigned(9 downto 0);
   signal player2_y_T, player2_y_B: unsigned(9 downto 0);
	constant player2_x_SIZE: integer:=40;
   constant player2_y_SIZE: integer:=40;
   -- reg to track top boundary  (x position is fixed)
	signal player2_x_reg, player2_x_next: unsigned(9 downto 0);
   signal player2_y_reg, player2_y_next: unsigned(9 downto 0);	
	
	signal player2_on: std_logic;
   signal player2_rgb: std_logic_vector(2 downto 0);
	
	--=============================================
   -- moving velocity when the button are pressed
	--=============================================
   constant BAR_V: integer:=10;
   
		--=============================================
   -- ring
	--=============================================
	constant Ring_in_SIZE: integer:=100;
	constant Ring_out_SIZE: integer:=108;
	
	constant Ring_in_x_L: integer:=center_x-Ring_in_SIZE;
	constant Ring_in_x_R: integer:=center_x+Ring_in_SIZE;
	constant Ring_in_y_T: integer:=center_y-Ring_in_SIZE;
	constant Ring_in_y_B: integer:=center_y+Ring_in_SIZE;
	signal Ring_in_rgb: std_logic_vector(2 downto 0);
	signal Ring_in_on: std_logic;
	--
	constant Ring_out_x_L: integer:=center_x-Ring_out_SIZE;
	constant Ring_out_x_R: integer:=center_x+Ring_out_SIZE;
	constant Ring_out_y_T: integer:=center_y-Ring_out_SIZE;
	constant Ring_out_y_B: integer:=center_y+Ring_out_SIZE;	
	signal Ring_out_rgb: std_logic_vector(2 downto 0);
	signal Ring_out_on: std_logic;
	--
	signal canto_rgb: std_logic_vector(2 downto 0);
	signal canto_on,rd_canto_on: std_logic;
	-----------------------------------------------------------
	--cantos do ring(Constantes associadas
	-----------------------------------------------------------
	--cordenadas dos cantos da bola
	constant ball_x_l: integer:=0;
  -- constant ball_x_r: integer:=DK_X_L+BALL_SIZE-1;
   constant ball_y_t: integer:=0;
   --constant ball_y_b: integer:=DK_Y_U+BALL_SIZE-1;
	
	--signal ball_x_l, ball_y_t: unsigned(9 downto 0);
   constant BALL_SIZE: integer:=16;
	type rom_type is array (0 to 7,0 to 7) of std_logic;
   constant BALL_ROM: rom_type :=
   (
      "00111100", --   ****
      "01111110", --  ******
      "11111111", -- ********
      "11111111", -- ********
      "11111111", -- ********
      "11111111", -- ********
      "01111110", --  ******
      "00111100"  --   ****
   );

   signal rom_addr_bola, rom_col: unsigned(2 downto 0);
   signal rom_data: std_logic_vector(7 downto 0);
   signal rom_bit: std_logic;
---------------------------------------------
    signal titulo_on: std_logic;
	 signal titulo_rgb: std_logic_vector(2 downto 0);
	 signal font_word: std_logic_vector(7 downto 0);
	 signal font_bit: std_logic;
	 signal row_addr_s: std_logic_vector(3 downto 0);
    signal char_addr_s: std_logic_vector(6 downto 0);
    signal bit_addr_s: std_logic_vector(2 downto 0);
	 signal rom_addr: std_logic_vector(10 downto 0);
	   

	 
	 
	 
	 
	 
	 ---------------------------------------
begin
   -- registers
   process (clk,reset)
   begin
      if reset='1' then
         player1_x_reg <= (others=>'0');
			player1_y_reg <= (others=>'0');
         player2_x_reg <= (others=>'0');
			player2_y_reg <= (others=>'0');
      elsif (clk'event and clk='1') then
         player1_x_reg <= player1_x_next;
			player1_y_reg <= player1_y_next;
			player2_x_reg <= player2_x_next;
			player2_y_reg <= player2_y_next;
      end if;
   end process;
	
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
	
   -- refr_tick: 1-clock tick asserted at start of v-sync
   --       i.e., when the screen is refreshed (60 Hz)
   refr_tick <= '1' when (pix_y=481) and (pix_x=1) else
                '0';

	--=============================================
	--       Player 1
	--=============================================

   -- boundary and output
	player1_x_L <= player1_x_reg;
   player1_x_R <= player1_x_L + player1_x_SIZE - 1;
   player1_y_T <= player1_y_reg;
   player1_y_B <= player1_y_T + player1_y_SIZE - 1;
	
   player1_on <=
      '1' when (player1_x_L<=pix_x) and (pix_x<=player1_x_R) and
               (player1_y_t<=pix_y) and (pix_y<=player1_y_b) else
      '0';
   -- player1 output
   player1_rgb <= "010"; --green
	
   -- new bar y-position
   process(player1_x_reg,player1_x_R,player1_x_L,player1_y_reg,player1_y_B,player1_y_T,refr_tick,key_code)
   begin
      player1_x_next <= player1_x_reg; -- no move
		player1_y_next <= player1_y_reg;
      
		--if refr_tick='1' then
         if key_code="1000" and player1_y_B<(MAX_Y-10-BAR_V) then
            player1_y_next <= player1_y_reg + BAR_V; -- move down
         elsif key_code="0111" and player1_y_T > BAR_V+10 then
            player1_y_next <= player1_y_reg - BAR_V; -- move up
			elsif key_code="1001" and player1_x_R<(MAX_X-40-BAR_V) then
            player1_x_next <= player1_x_reg + BAR_V; 
			elsif key_code="1010" and player1_x_L > BAR_V+40 then 
            player1_x_next <= player1_x_reg - BAR_V; 	
         end if;
     -- end if;
   end process;

	--=============================================
	--       Player 2
	--=============================================

   -- boundary and output
	player2_x_L <= player2_x_reg;
   player2_x_R <= player2_x_L + player1_x_SIZE - 1;
   player2_y_T <= player2_y_reg;
   player2_y_B <= player2_y_T + player1_y_SIZE - 1;
	
   player2_on <=
      '1' when (player2_x_L<=pix_x) and (pix_x<=player2_x_R) and
               (player2_y_t<=pix_y) and (pix_y<=player2_y_b) else
      '0';
   -- player1 output
   player2_rgb <= "100"; --red
	
   -- new bar y-position
   process(player2_x_reg,player2_x_R,player2_x_L,player2_y_reg,player2_y_B,player2_y_T,refr_tick,key_code)
   begin
      player2_x_next <= player2_x_reg; -- no move
		player2_y_next <= player2_y_reg;
      
		--if refr_tick='1' then
         if key_code="0100" and player2_y_B<(MAX_Y-10-BAR_V) then
            player2_y_next <= player2_y_reg + BAR_V; -- move down
         elsif key_code="0011" and player2_y_T > BAR_V+10 then
            player2_y_next <= player2_y_reg - BAR_V; -- move up
			elsif key_code="0010" and player2_x_R<(MAX_X-40-BAR_V) then
            player2_x_next <= player2_x_reg + BAR_V; 
			elsif key_code="0001" and player2_x_L > BAR_V+40 then 
            player2_x_next <= player2_x_reg - BAR_V;
         end if;
     -- end if;
   end process;
 --*****************************************************************
 	Ring_in_on <=
      '1' when (Ring_in_x_L<=pix_x) and (pix_x<=Ring_in_x_R-1) and
               (Ring_in_y_T<=pix_y) and (pix_y<=Ring_in_y_B-1) else
      '0';
	   -- ring output
   Ring_in_rgb <= "111"; --whitte
 	Ring_out_on <=
      '1' when (Ring_out_x_L<=pix_x) and (pix_x<=Ring_out_x_R-1) and
               (Ring_out_y_T<=pix_y) and (pix_y<=Ring_out_y_B-1) else
      '0';
	   -- ring output
    Ring_out_rgb <= "001"; --whitte

   -- round ball
	
	rom_addr_bola <= pix_y(3 downto 1) - to_unsigned(Ring_in_y_T+N,8)(3 downto 1);
   rom_col <= pix_x(3 downto 1) - to_unsigned(Ring_out_x_L-N,8)(3 downto 1);
	rom_bit <= BALL_ROM(to_integer(rom_addr_bola),to_integer(rom_col));
	
	 rd_canto_on <=
      '1' when (--canto superior esquerdo
					((Ring_out_x_L-N)<=pix_x) and (pix_x<=Ring_out_x_L-N+BALL_SIZE) and
                (Ring_out_y_T-N-1 <=pix_y) and (pix_y<=Ring_out_y_T-N+BALL_SIZE)) or
					(--canto superior direito
					((Ring_in_x_R-N)<=pix_x) and (pix_x<=Ring_in_x_R-N-1+BALL_SIZE) and 	
                (Ring_out_y_T-N-1<=pix_y) and (pix_y<=Ring_out_y_T-N+BALL_SIZE))or
					(--canto inferior esquerdo
					((Ring_out_x_L-N)<=pix_x) and (pix_x<=Ring_out_x_L-N+BALL_SIZE) and
                (Ring_in_y_B-N  <=pix_y) and (pix_y<=Ring_in_y_B-N+BALL_SIZE)) or
					(--canto inferior direito
					((Ring_in_x_R-N)<=pix_x) and (pix_x<=Ring_in_x_R-N-1+BALL_SIZE) and 	
                (Ring_in_y_B-N <=pix_y) and (pix_y<=Ring_in_y_B-N+BALL_SIZE))	
					else
      '0';

	 canto_on <=
      '1' when (rd_canto_on='1') and (rom_bit='1') else
      '0';

	 canto_rgb <= "100"; --Red
	
--***********************************************************************	
font_unit: entity work.font_rom
      port map(clk=>clk, reset=>reset, addr=>rom_addr, data=>font_word);

titulo_on <=
    '1' when pix_y(9 downto 6)=1 and
        5<= pix_x(9 downto 5) and pix_x(9 downto 5)<=14 else
      '0';
		

  
   row_addr_s <= std_logic_vector(pix_y(5 downto 2));
   bit_addr_s <= std_logic_vector(pix_x(4 downto 2));
	
   with pix_x(8 downto 5) select
     char_addr_s <=	  
			"1010100" when "0101", -- T 
			"1101000" when "0110", -- h
			"1100101" when "0111", -- e
		   "0000000" when "1000",
         "0000000" when "1001",
			"1001101" when "1010", -- M -- code x4d
			"1100001" when "1011", -- a -- code x61
			"1110100" when "1100", -- t
			"1100011" when "1101", -- c -- code x63
			"1101000" when others; -- h

rom_addr<=char_addr_s & row_addr_s;
font_bit <= font_word(to_integer(unsigned(not bit_addr_s)));

process

begin
titulo_rgb <= "110";
if font_bit='1' then
	titulo_rgb <= "000";
end if;
 end process;

--****************************************************************************************
process(video_on,player1_on, player1_rgb)
   begin
      if video_on='0' then
          graph_rgb <= "000"; --blank
      else
         if player1_on='1' then
            graph_rgb <= player1_rgb;
			elsif	player2_on='1' then
				graph_rgb <= player2_rgb;
			elsif	titulo_on='1' then
				graph_rgb <= titulo_rgb;	
			elsif	canto_on='1' then
				graph_rgb <= canto_rgb;
			elsif	Ring_in_on='1' then
				graph_rgb <= Ring_in_rgb;
			elsif	Ring_out_on='1' then
				graph_rgb <= Ring_out_rgb;				
         else
            graph_rgb <= "110"; -- yellow background
         end if;
      end if;
   end process;
end arch;