----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:01:57 12/10/2020 
-- Design Name: 
-- Module Name:    background - Behavioral 
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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity background is
   port(
        clk, reset: in std_logic;
       -- video_on: in std_logic;
        pixel_x,pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0);
	     score_play_1,score_play_2: in std_logic_vector(3 downto 0);
		  winner_show_on: in std_logic
			);
   
end background;

architecture arch of background is
   signal refr_tick: std_logic;
   -- x, y coordinates (0,0) to (639,479)
   signal pix_x, pix_y: unsigned(9 downto 0);
   constant MAX_X: integer:=640;
   constant MAX_Y: integer:=480;
   constant center_x: integer:=320;
   constant center_y: integer:=240;	
   constant N: integer:=4;
	
	--=============================================
   -- ringue de boxe
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
	--cantos do ring
	-----------------------------------------------------------
	--cordenadas dos cantos da bola
	constant ball_x_l: integer:=0;
   constant ball_y_t: integer:=0;
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
   --=======================================================
   -- Titulo
   --=======================================================
    signal titulo_on: std_logic;
	 signal titulo_rgb: std_logic_vector(2 downto 0);
	 signal font_word: std_logic_vector(7 downto 0);
	 signal font_bit: std_logic;
	 signal row_addr_s: std_logic_vector(3 downto 0);
    signal char_addr_s: std_logic_vector(6 downto 0);
    signal bit_addr_s: std_logic_vector(2 downto 0);
	 signal rom_addr: std_logic_vector(10 downto 0);
	
	--=======================================================
   -- Players
   --=======================================================
    signal players_on: std_logic;
	 signal players_rgb: std_logic_vector(2 downto 0);
	 signal players_word: std_logic_vector(7 downto 0);
	 signal players_bit: std_logic;
	 signal row_addr_p: std_logic_vector(3 downto 0);
    signal char_addr_p: std_logic_vector(6 downto 0);
    signal bit_addr_p: std_logic_vector(2 downto 0);
	 signal rom2_addr: std_logic_vector(10 downto 0);

--=======================================================
   -- score
   --=======================================================
    signal score_on: std_logic;
	 signal score_rgb: std_logic_vector(2 downto 0);
	 signal score_word: std_logic_vector(7 downto 0);
	 signal score_bit: std_logic;
	 signal row_addr_score: std_logic_vector(3 downto 0);
    signal char_addr_score: std_logic_vector(6 downto 0);
    signal bit_addr_score: std_logic_vector(2 downto 0);
	 signal rom3_addr: std_logic_vector(10 downto 0);

--=======================================================
   -- winner
--=======================================================
	 signal winner_on: std_logic;
	 signal winner_rgb: std_logic_vector(2 downto 0);
	 signal winner_word: std_logic_vector(7 downto 0);
	 signal winner_bit: std_logic;
	 signal row_addr_winner: std_logic_vector(3 downto 0);
    signal char_addr_winner: std_logic_vector(6 downto 0);
    signal bit_addr_winner: std_logic_vector(2 downto 0);
	 signal rom4_addr: std_logic_vector(10 downto 0);
	 signal player_win: std_logic_vector(3 downto 0);
	

begin
	
   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
	
   -- refr_tick: 1-clock tick asserted at start of v-sync
   --       i.e., when the screen is refreshed (60 Hz)
   refr_tick <= '1' when (pix_y=481) and (pix_x=1) else
                '0';

	
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
	--=======================================================
   --  titulo
   --=======================================================
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

	process(font_bit)
		begin
			titulo_rgb <= "110";
			if font_bit='1' then
				titulo_rgb <= "000";
			end if;
	end process;

	--=======================================================
   --  Players
   --=======================================================
font2_unit: entity work.font_rom
      port map(clk=>clk, reset=>reset, addr=>rom2_addr, data=>players_word);

players_on <=
    '1' when pix_y(9 downto 5)=4 and   -- (9 downto 5) altura    =4 posição
        1<= pix_x(9 downto 4) and pix_x(9 downto 4)<=38 else
      '0';
		
   row_addr_p <= std_logic_vector(pix_y(4 downto 1));
   bit_addr_p <= std_logic_vector(pix_x(3 downto 1));
	
   with pix_x(9 downto 4) select
     char_addr_p <=	  
			-- player 1:
		  
		  "1010000" when "000010", -- P
        "1101100" when "000011", -- L
        "1100001" when "000100", -- a
        "1111001" when "000101", -- y
        "1100101" when "000110", -- e
        "1110010" when "000111", -- r
		  "0100000" when "001000", -- 
        "0110001" when "001001", -- 1
        
		  
		  -- player 2:
		  	  
		  "1010000" when "011101", -- P
        "1101100" when "011110", -- L
        "1100001" when "011111", -- a
        "1111001" when "100000", -- y
        "1100101" when "100001", -- e
		  "1110010" when "100010", -- r
		  "0100000" when "100011", -- space
		  "0110010" when "100100", -- 2
		  "0100000" when  others; -- space


rom2_addr<=char_addr_p & row_addr_p;
players_bit <= players_word(to_integer(unsigned(not bit_addr_p)));

	process(players_bit)
		begin
			players_rgb <= "110";
			if players_bit='1' then
				players_rgb <= "000";
			end if;
	end process;

--**************************************************************************
-- Score
	font3_unit: entity work.font_rom
		port map(clk=>clk, reset=>reset, addr=>rom3_addr, data=>score_word);



		
   row_addr_score <= std_logic_vector(pix_y(4 downto 1));
   bit_addr_score <= std_logic_vector(pix_x(3 downto 1));
		
   with pix_x(9 downto 4) select
     char_addr_score <=	  
			-- player 1 score:
					"011" & score_play_1 when "000101", -- y
		  -- player 2 score:
					"011" & score_play_2 when "100000", -- y
					"0100000" when  others; -- space


score_on <=
    '1' when pix_y(9 downto 5)=6 and   -- (9 downto 5) altura    =12 posição
        5<= pix_x(9 downto 4) and pix_x(9 downto 4)<=32 else
      '0';		  
rom3_addr<=char_addr_score & row_addr_score;
score_bit <= score_word(to_integer(unsigned(not bit_addr_score)));

	process(score_bit)
		begin
			score_rgb <= "110";
			if score_bit='1' then
				score_rgb <= "000";
			end if;
	end process;
	
--	--*************************************************************************** 
--	winner
--*************************************************************************** 
	 
	font4_unit: entity work.font_rom
		port map(clk=>clk, reset=>reset, addr=>rom4_addr, data=>winner_word);

   row_addr_winner <= std_logic_vector(pix_y(4 downto 1));
   bit_addr_winner <= std_logic_vector(pix_x(3 downto 1));
		
   with pix_x(9 downto 4) select
     char_addr_winner <=	  
									"1010000" when "001101", -- P
									"1101100" when "001110", -- L
									"1100001" when "001111", -- a
							      "1111001" when "010000", -- y
							      "1100101" when "010001", -- e
									"1110010" when "010010", -- r
									"0100000" when "010011", -- space
									"011" & player_win when "010100", 
									"0100000" when "010101", -- space
									"1010111" when "010110", -- w x57
									"1101001" when "010111", -- i 69
									"1101110" when "011000", -- n
									"0100000" when  others; -- space

process(score_play_1,score_play_2)
begin
	if score_play_1>score_play_2 then
	player_win<="0001";
	else
	player_win<="0010";
	end if;
end process;
	
	
	winner_on <=
    '1' when pix_y(9 downto 5)=12 and   -- (9 downto 5) altura    =12 posição
        12<= pix_x(9 downto 4) and pix_x(9 downto 4)<=25 else
      '0';		  
rom4_addr<=char_addr_winner & row_addr_winner;
winner_bit <= winner_word(to_integer(unsigned(not bit_addr_winner)));

	process(winner_bit)
		begin
			winner_rgb <= "110";
			if winner_bit='1' then
				winner_rgb <= "000";
			end if;
	end process;	 
--		 
		 

--****************************************************************************************
process(titulo_on,players_on,Ring_in_on,Ring_out_on,titulo_rgb, canto_on, players_rgb, score_on,score_rgb,winner_show_on,
			winner_on, winner_rgb)
   begin
      --if video_on='0' then
      --    graph_rgb <= "000"; --blank
      --else
        	if	titulo_on='1' then
				graph_rgb <= titulo_rgb;
			
			elsif	(winner_show_on='1' and winner_on='1') then
				graph_rgb <= winner_rgb;
		
			elsif	canto_on='1' then
				graph_rgb <= canto_rgb;
			elsif	Ring_in_on='1' then
				graph_rgb <= Ring_in_rgb;
			elsif	Ring_out_on='1' then
				graph_rgb <= Ring_out_rgb;
			elsif	players_on='1' then
				graph_rgb <= players_rgb;	
			elsif score_on='1' then	
				graph_rgb<=score_rgb;				
         else
            graph_rgb <= "110"; -- yellow background
         end if;
    --  end if;
   end process;
end arch;