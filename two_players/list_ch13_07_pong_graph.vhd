-- Listing 13.7
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity pong_graph is
   port(
        clk, reset: in std_logic;
        key_code: in std_logic_vector(3 downto 0);
        video_on: in std_logic;
        pixel_x,pixel_y: in std_logic_vector(9 downto 0);
        graph_rgb: out std_logic_vector(2 downto 0);
		  time_start: out std_logic;
		  timer_up: in std_logic
   );
end pong_graph;

architecture arch of pong_graph is
	type state_type is (newgame, play,new_round, over);
	signal state_reg, state_next: state_type;
   signal pix_x, pix_y: unsigned(9 downto 0);
   constant MAX_X: integer:=640;
   constant MAX_Y: integer:=480;
	signal background_rgb:std_logic_vector(2 downto 0);
	signal score_play_1,score_play_2: std_logic_vector(3 downto 0);
	signal score_play_1_next,score_play_1_reg,score_play_2_next,score_play_2_reg: unsigned(3 downto 0);
	signal ko1_next, ko1_reg,ko2_next, ko2_reg,round_next,round_reg: unsigned(1 downto 0);
	signal rst_player,ko_reset,rst_glove,score_rst,winner_show_on: std_logic;
	--******************************************
	-- limites para score
	constant center_x: integer:=320;
   constant center_y: integer:=240;	
	constant Ring_in_SIZE: integer:=100;	
	constant Ring_in_x_L: integer:=center_x-Ring_in_SIZE;
	constant Ring_in_x_R: integer:=center_x+Ring_in_SIZE;
	constant Ring_in_y_T: integer:=center_y-Ring_in_SIZE;
	constant Ring_in_y_B: integer:=center_y+Ring_in_SIZE;	

	--*********************************************************
	-- PLAYER 1
	--*********************************************************
	
	--cordenadas dos cantos do player 1
   signal player1_x_l, player1_x_r: unsigned(9 downto 0);
   signal player1_y_t, player1_y_b: unsigned(9 downto 0);
	--Cordenadas do canto superior esquerdo do player 1
   signal player1_x_reg, player1_x_next: unsigned(9 downto 0);
   signal player1_y_reg, player1_y_next: unsigned(9 downto 0);
	signal Player1_x_face,Player1_y_face : unsigned(9 downto 0);
	
	
	--cordenadas dos cantos da luva esquerda do player 1
   signal glove_p1L_x_l, glove_p1L_x_r: unsigned(9 downto 0);
   signal glove_p1L_y_t, glove_p1L_y_b: unsigned(9 downto 0);
	--registos do canto da luva esquerda do player 1
   signal glove_p1L_x_reg, glove_p1L_x_next: unsigned(9 downto 0);
   signal glove_p1L_y_reg, glove_p1L_y_next: unsigned(9 downto 0);
	
	
	--cordenadas dos cantos da luva direita do player 1
   signal glove_P1R_x_l, glove_P1R_x_r: unsigned(9 downto 0);
   signal glove_P1R_y_t, glove_P1R_y_b: unsigned(9 downto 0);
	--registos do canto da luva esquerda do player 1
   signal glove_P1R_x_reg, glove_P1R_x_next: unsigned(9 downto 0);
   signal glove_P1R_y_reg, glove_P1R_y_next: unsigned(9 downto 0);
	
	
	--*********************************************************
	-- PLAYER 2
	--*********************************************************
	
	--cordenadas dos cantos do player 2
   signal player2_x_l, player2_x_r: unsigned(9 downto 0);
   signal player2_y_t, player2_y_b: unsigned(9 downto 0);
	--Cordenadas do canto superior esquerdo do player 2
   signal player2_x_reg, player2_x_next: unsigned(9 downto 0);
   signal player2_y_reg, player2_y_next: unsigned(9 downto 0);
	-----------------------------------------------------------
	signal Player2_x_face,Player2_y_face : unsigned(9 downto 0);
	
	
	--cordenadas dos cantos da luva esquerda do player 2
   signal glove_p2L_x_l, glove_p2L_x_r: unsigned(9 downto 0);
   signal glove_p2L_y_t, glove_p2L_y_b: unsigned(9 downto 0);
	--Cordenadas do canto da luva esquerda do player 2
   signal glove_p2L_x_reg, glove_p2L_x_next: unsigned(9 downto 0);
   signal glove_p2L_y_reg, glove_p2L_y_next: unsigned(9 downto 0);
	
	
	--cordenadas dos cantos da luva direita do player 2
   signal glove_P2R_x_l, glove_P2R_x_r: unsigned(9 downto 0);
   signal glove_P2R_y_t, glove_P2R_y_b: unsigned(9 downto 0);
	--Cordenadas do canto da luva esquerda do player 2
   signal glove_P2R_x_reg, glove_P2R_x_next: unsigned(9 downto 0);
   signal glove_P2R_y_reg, glove_P2R_y_next: unsigned(9 downto 0);
	
	
	
	constant PLAYER_SIZE_X: integer:=32;
	constant PLAYER_SIZE_Y: integer:=64;
	--A rom serve para os dois players uma vez que o formato das ROM é igual
	type rom_player_tipe is array (0 to 31, 0 to 15) of std_logic_vector(2 downto 0);
	
	--*********************************************************
	--LUVAS
	--*********************************************************
	
	--Poderá ser necessario criar cordenadas para cada luva
	--As posições devem ser relativas a cada jogador
	
	--cordenadas dos cantos da luva
   signal glove_x_l, glove_x_r: unsigned(9 downto 0);
   signal glove_y_t, glove_y_b: unsigned(9 downto 0);
	--Cordenadas do canto superior esquerdo da luva
   signal glove_x_reg, glove_x_next: unsigned(9 downto 0);
   signal glove_y_reg, glove_y_next: unsigned(9 downto 0);
	
	constant GLOVE_SIZE_X: integer:=16;
	constant GLOVE_SIZE_Y: integer:=16;
	type rom_glove_type is array (0 to 15, 0 to 15) of std_logic_vector(2 downto 0);
	
	--*************************************************************
	--Definição das ROM
	--*************************************************************
	
	constant PLAYER_1_ROM: rom_player_tipe :=
	
	(
		("111","111","111","111","111","111","111","111","000","000","000","111","111","111","111","111"),
		("111","111","111","111","111","111","111","111","000","100","000","111","111","111","111","111"),
		("111","111","111","111","111","111","111","000","010","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","010","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","010","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","010","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","010","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","010","000","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","000","100","000","000","111","111","111","111"),
		("111","111","111","111","111","111","000","010","010","100","100","100","000","111","111","111"),
		("111","111","111","111","111","000","010","010","010","100","100","100","100","000","111","111"),
		("111","111","111","111","000","010","010","010","010","100","100","100","100","100","000","111"),
		("111","111","111","111","000","010","010","010","010","100","100","100","100","100","000","111"),
		("111","111","111","000","010","010","010","010","010","100","100","100","100","100","100","000"),
		("111","111","111","000","010","010","010","010","010","100","100","100","100","000","100","000"),
		("111","111","111","000","010","010","010","010","010","100","100","100","100","100","100","000"),	
		("111","111","111","000","010","010","010","010","010","100","100","100","100","100","100","000"),
		("111","111","111","000","010","010","010","010","010","100","100","100","100","000","100","000"),
		("111","111","111","000","010","010","010","010","010","100","100","100","100","100","100","000"),
		("111","111","111","111","000","010","010","010","010","100","100","100","100","100","000","111"),
		("111","111","111","111","000","010","010","010","010","100","100","100","100","100","000","111"),
		("111","111","111","111","111","000","010","010","010","100","100","100","100","000","111","111"),
		("111","111","111","111","111","111","000","010","010","100","100","100","000","111","111","111"),
		("111","111","111","111","111","111","111","000","000","100","000","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","010","000","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","010","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","010","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","010","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","010","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","010","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","111","000","100","000","111","111","111","111","111"),
		("111","111","111","111","111","111","111","111","000","000","000","111","111","111","111","111")
	);
	
	--permite enderessar a linha ou a coluna do player1
   signal Player1_rom_addr: unsigned(4 downto 0);
	signal Player1_rom_col:unsigned(3 downto 0);
	--quanto se lê uma linha saem 16 bits
   signal Player1_rom_data: std_logic_vector(15 downto 0);
	--referen-se a cada bit da memória
   signal Player1_rom_bit: std_logic_vector(2 downto 0);
	
	
	constant PLAYER_2_ROM: rom_player_tipe :=
	(
		("111","111","111","111","111","111","111","111","000","000","000","111","111","111","111","111"),
		("111","111","111","111","111","111","111","111","000","100","000","111","111","111","111","111"),
		("111","111","111","111","111","111","111","000","100","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","100","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","100","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","100","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","100","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","100","000","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","000","100","000","000","111","111","111","111"),
		("111","111","111","111","111","111","000","100","100","100","100","100","000","111","111","111"),
		("111","111","111","111","111","000","100","100","100","100","100","100","100","000","111","111"),
		("111","111","111","111","000","110","110","110","110","110","110","110","110","110","000","111"),
		("111","111","111","111","000","110","110","110","110","110","110","110","110","110","000","111"),
		("111","111","111","000","110","110","110","110","110","110","110","110","110","110","110","000"),
		("111","111","111","000","110","110","110","110","110","110","110","110","110","000","110","000"),
		("111","111","111","000","110","110","110","110","110","110","110","110","110","110","110","000"),	
		("111","111","111","000","110","110","110","110","110","110","110","110","110","110","110","000"),
		("111","111","111","000","110","110","110","110","110","110","110","110","110","000","110","000"),
		("111","111","111","000","110","110","110","110","110","110","110","110","110","110","110","000"),
		("111","111","111","111","000","110","110","110","110","110","110","110","110","110","000","111"),
		("111","111","111","111","000","110","110","110","110","110","110","110","110","110","000","111"),
		("111","111","111","111","111","000","100","100","100","100","100","100","100","000","111","111"),
		("111","111","111","111","111","111","000","100","100","100","100","100","000","111","111","111"),
		("111","111","111","111","111","111","111","000","000","100","000","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","100","000","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","100","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","100","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","100","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","100","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","000","100","100","100","000","111","111","111","111"),
		("111","111","111","111","111","111","111","111","000","100","000","111","111","111","111","111"),
		("111","111","111","111","111","111","111","111","000","000","000","111","111","111","111","111")
	);
	
	--permite enderessar a linha ou a coluna do player2
   signal Player2_rom_addr: unsigned(4 downto 0);
	signal Player2_rom_col:unsigned(3 downto 0);
	--quanto se lê uma linha saem 16 bits
   signal Player2_rom_data: std_logic_vector(15 downto 0);
	--referen-se a cada bit da memória
   signal Player2_rom_bit: std_logic_vector(2 downto 0);
	
	
	constant GLOVE_ROM: rom_glove_type :=
	(
		("111","111","111","111","111","111","111","111","000","000","000","000","000","000","111","111"),
		("111","111","111","111","111","111","111","000","100","100","000","100","100","100","000","111"),
		("111","000","000","000","000","000","000","100","100","100","000","100","100","100","100","000"),
		("000","000","101","101","000","100","100","100","100","100","000","100","100","100","100","000"),
		("000","000","101","101","000","000","100","100","100","000","100","100","100","100","100","000"),
		("000","000","101","101","000","100","000","000","000","100","100","100","100","100","100","000"),
		("000","000","000","000","000","111","100","100","100","100","100","100","100","100","100","000"),
		("000","000","101","101","000","100","100","100","100","100","100","100","100","100","000","111"),
		("111","000","000","000","000","100","100","100","100","100","100","100","100","000","111","111"),
		("111","111","111","111","111","000","000","000","000","000","000","000","000","111","111","111"),
		("111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111"),
		("111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111"),
		("111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111"),
		("111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111"),
		("111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111"),
		("111","111","111","111","111","111","111","111","111","111","111","111","111","111","111","111")
	);
		
	--permite enderessar a linha ou a coluna da luva esquerda do player 1
   signal Glove_P1L_rom_addr: unsigned(3 downto 0);
	signal Glove_P1L_rom_col:unsigned(3 downto 0);
	--quanto se lê uma linha saem 16 bits
   signal Glove_P1L_rom_data: std_logic_vector(15 downto 0);
	--referen-se a cada bit da memória
   signal Glove_P1L_rom_bit: std_logic_vector(2 downto 0);
	
	
	--permite enderessar a linha ou a coluna da luva direita do player 1
   signal Glove_P1R_rom_addr: unsigned(3 downto 0);
	signal Glove_P1R_rom_col:unsigned(3 downto 0);
	--quanto se lê uma linha saem 16 bits
   signal Glove_P1R_rom_data: std_logic_vector(15 downto 0);
	--referen-se a cada bit da memória
   signal Glove_P1R_rom_bit: std_logic_vector(2 downto 0);
	
	
	
	--permite enderessar a linha ou a coluna da luva esquerda do player 2
   signal Glove_P2L_rom_addr: unsigned(3 downto 0);
	signal Glove_P2L_rom_col:unsigned(3 downto 0);
	--quanto se lê uma linha saem 16 bits
   signal Glove_P2L_rom_data: std_logic_vector(15 downto 0);
	--referen-se a cada bit da memória
   signal Glove_P2L_rom_bit: std_logic_vector(2 downto 0);
	
	--permite enderessar a linha ou a coluna da luva esquerda do player 2
   signal Glove_P2R_rom_addr: unsigned(3 downto 0);
	signal Glove_P2R_rom_col:unsigned(3 downto 0);
	--quanto se lê uma linha saem 16 bits
   signal Glove_P2R_rom_data: std_logic_vector(15 downto 0);
	--referen-se a cada bit da memória
   signal Glove_P2R_rom_bit: std_logic_vector(2 downto 0);
   signal rom_data: std_logic_vector(7 downto 0);

   signal rom_bit: std_logic;
	signal sq_player1_on, sq_player2_on : std_logic;
	signal glove_L_P1_on, glove_R_P1_on, glove_L_P2_on, glove_R_P2_on: std_logic;
   signal refr_tick: std_logic;
	
	
	
begin

	background_unit: entity work.background
      port map (clk=>clk, reset=>reset,
--                video_on=>background_on,
                pixel_x=>pixel_x, pixel_y=>pixel_y,
                graph_rgb=>background_rgb,
					 score_play_1=>score_play_1,
					 score_play_2=>score_play_2,
					 winner_show_on=>winner_show_on
					 );

   -- Players registers
	
	   process (clk,reset,rst_player)
   begin
      if reset='1' or rst_player ='1' then
         player1_x_reg <= to_unsigned(225,10);
			player1_y_reg <= to_unsigned(212,10);
         player2_x_reg <= to_unsigned(384,10);
			player2_y_reg <= to_unsigned(212,10);
      elsif (clk'event and clk='1') then
         player1_x_reg <= player1_x_next;
			player1_y_reg <= player1_y_next;
			player2_x_reg <= player2_x_next;
			player2_y_reg <= player2_y_next;
      end if;
   end process;

   pix_x <= unsigned(pixel_x);
   pix_y <= unsigned(pixel_y);
   refr_tick <= '1' when (pix_y=481) and (pix_x=0) else
                '0';

------------------------------------------------------------------------------
--Posição do player1
------------------------------------------------------------------------------

--coloca o player na posição
	player1_x_l <= player1_x_reg;
   player1_y_t <= player1_y_reg;
   player1_x_r <= player1_x_l + PLAYER_SIZE_X - 1;
   player1_y_b <= player1_y_t + PLAYER_SIZE_Y - 1;
	
	--Player1_x_face<=player1_x_r+48;  -- limite face horizontal do player1
	Player1_x_face<=player1_x_r+4;
	Player1_y_face<=player1_y_t+32;  -- limite face vertical do player1
	
	
	
   sq_player1_on <=
		'1' when	((player1_x_l<=pix_x) and (pix_x<=player1_x_r) and
               (player1_y_t<=pix_y) and (pix_y<=player1_y_b))

			 else
      '0';
		
	process(player1_x_reg,player1_x_r,player1_x_l,player1_y_reg,player1_y_b,player1_y_t,refr_tick,key_code,
				Player2_x_face, Player1_x_face, glove_p2L_x_l, glove_p2L_y_t, glove_p1L_y_t, glove_p1L_y_b, glove_P2R_x_l,
				glove_P2R_y_t,glove_p2L_y_b, glove_P1R_y_t, glove_P2R_y_b, player2_x_l ,ko1_reg)
   begin
      player1_x_next <= player1_x_reg; -- no move
		player1_y_next <= player1_y_reg;
      ko1_next<=ko1_reg;
	--	if refr_tick='1' then
			if (glove_p2L_x_l <= Player1_x_face and glove_p2L_y_t > glove_p1L_y_b and glove_p2L_y_b < glove_p1R_y_t) or
	          (glove_p2R_x_l <= Player1_x_face and glove_p2R_y_t > glove_p1L_y_b and glove_p2R_y_b < glove_p1R_y_t) then
				
				 player1_x_next <= player1_x_reg -16;
				 ko1_next<=ko1_reg+1;
				
				
         elsif key_code="0100" then
            player1_y_next <= player1_y_reg + 16; -- move down
		
         elsif key_code="0011" then
            player1_y_next <= player1_y_reg - 16; -- move up
				
			elsif key_code="0010" then
				if(player1_x_r <= player2_x_l-48) then
						player1_x_next <= player1_x_reg + 16;
				end if;	
			elsif key_code="0001" then 
            player1_x_next <= player1_x_reg - 16; 	
				
         end if;
   --   end if;
   end process;
	
		
	--player round
	--Para alterar o tamanho deslocamos os bits pra a esquerda
   Player1_rom_addr <= pix_y(5 downto 1) - player1_y_t(5 downto 1);
   Player1_rom_col <= pix_x(4 downto 1) - player1_x_l(4 downto 1);
	--ao alterar o "not" lemos os dados ao contrario
	Player1_rom_bit<= PLAYER_1_ROM(to_integer(not Player1_rom_addr), to_integer( Player1_rom_col));
	
		
	
----------------------------------------------------------
--Posição do player 2
----------------------------------------------------------

--coloca o player na posição 100 100
	player2_x_l <= player2_x_reg;
   player2_y_t <= player2_y_reg;
   player2_x_r <= player2_x_l + PLAYER_SIZE_X - 1;
   player2_y_b <= player2_y_t + PLAYER_SIZE_Y - 1;
	
	Player2_x_face<=player2_x_l-4; -- limite face horizontal do player2
	Player2_y_face<=player2_y_t+32;  -- limite face vertical do player2
	
   sq_player2_on <=
		'1' when	((player2_x_l<=pix_x) and (pix_x<=player2_x_r) and
               (player2_y_t<=pix_y) and (pix_y<=player2_y_b))
					
			 else
      '0';
		
		
	process(player2_x_reg,player2_y_reg, glove_p1L_x_r,Player2_x_face, glove_p1L_y_b, glove_p2L_y_t,
		glove_p1L_y_t, glove_P2R_y_b, glove_P1R_x_r, glove_P1R_y_b, glove_P1R_y_t, ko2_reg, key_code, player2_x_l, player1_x_r)
   begin
      player2_x_next <= player2_x_reg; -- no move
		player2_y_next <= player2_y_reg;
		ko2_next<=ko2_reg;
      
--		if refr_tick='1' then
				
			if ((glove_p1L_x_r>= Player2_x_face) and (glove_p1L_y_b <= glove_p2L_y_t) and (glove_p1L_y_t >= glove_p2R_y_b)) or
	          ((glove_p1R_x_r >= Player2_x_face ) and (glove_p1R_y_b <= glove_p2L_y_t) and (glove_p1R_y_t >= glove_p2R_y_b)) then
				 
				 player2_x_next <= player2_x_reg + 16;
				 ko2_next<=ko2_reg+1;
				
				 
         elsif key_code="1000" then
            
				player2_y_next <= player2_y_reg + 16; -- move down
         elsif key_code="0111" then
				
				player2_y_next <= player2_y_reg - 16; -- move up
			elsif key_code="1001" then
            
				player2_x_next <= player2_x_reg + 16; 
			elsif key_code="1010" then 
					if(player2_x_l >= player1_x_r+48) then
						player2_x_next <= player2_x_reg - 16;
					end if;
         end if;
--      end if;
   end process;
		
	--player round
	--Para alterar o tamanho deslocamos os bits pra a esquerda
   Player2_rom_addr <= pix_y(5 downto 1) - player2_y_t(5 downto 1);
   Player2_rom_col <= pix_x(4 downto 1) - player2_x_l(4 downto 1);
	--ao alterar o "not" lemos os dados ao contrario
	Player2_rom_bit<= PLAYER_2_ROM(to_integer(not Player2_rom_addr), to_integer(not Player2_rom_col));
	
	
----------------------------------------------------------
--Posição da luva
----------------------------------------------------------

	glove_L_P1_on <=
		'1' when	((glove_p1L_x_l<=pix_x) and (pix_x<=glove_p1L_x_r) and
               (glove_p1L_y_t<=pix_y) and (pix_y<=glove_p1L_y_b))			
			 else
      '0';
	
   glove_R_P1_on <=
		'1' when	((glove_p1R_x_l<=pix_x) and (pix_x<=glove_p1R_x_r) and
               (glove_p1R_y_t<=pix_y) and (pix_y<=glove_p1R_y_b))			
			 else
      '0';
	
	process (clk,reset)
   begin
      if reset='1' or rst_glove='1' then
         glove_p1L_x_reg <= to_unsigned(32,10);
			glove_p1L_y_reg <= to_unsigned(0,10);
			
			glove_p1R_x_reg <= to_unsigned(32,10);
			glove_p1R_y_reg <= to_unsigned(48,10);
      elsif (clk'event and clk='1') then
         glove_p1L_x_reg <= glove_p1L_x_next;
			glove_p1L_y_reg <= glove_p1L_y_next;
			glove_p1R_x_reg <= glove_p1R_x_next;
			glove_p1R_y_reg <= glove_p1R_y_next;
			
      end if;
   end process;
	
	--Glove_P1R_state_reg
	process ( glove_p1R_x_reg, key_code,glove_P1R_y_reg,glove_p1L_x_reg, glove_p1L_y_reg,glove_p2L_x_l,
		glove_P1R_x_r, glove_p2L_y_t, glove_P1R_y_t, glove_p1L_x_r, glove_p1L_y_t, glove_P2R_x_l,glove_P2R_y_t)
	begin
		glove_p1R_x_next <= glove_p1R_x_reg;
		glove_p1R_y_next <= glove_p1R_y_reg;
		glove_p1L_x_next <= glove_p1L_x_reg;
		glove_p1L_y_next <= glove_p1L_y_reg;
		
		if key_code="1101" and glove_p1L_y_reg = 0 then
					glove_p1L_y_next <= to_unsigned(16,10);
					glove_p1R_y_next <= to_unsigned(32,10);
					glove_p1R_x_next <= to_unsigned(32,10);
					glove_p1L_x_next <= to_unsigned(32,10);	
					
		elsif key_code="1101" then					
					glove_p1R_y_next <= to_unsigned(48,10);
					glove_p1L_y_next <= to_unsigned(0,10);

		elsif	((glove_p2L_x_l= glove_p1R_x_r and glove_p2L_y_t = glove_p1R_y_t)	or  -- luva esquerda com esquerda
				(glove_p2L_x_l= glove_p1L_x_r and glove_p2L_y_t = glove_p1L_y_t)	or	 --luva esquerda com direita
				(glove_p2R_x_l= glove_p1L_x_r and glove_p2R_y_t = glove_p1L_y_t) or 	--luva direita com esquerda
				(glove_p2R_x_l= glove_p1R_x_r and glove_p2R_y_t = glove_p1R_y_t)) then	--luva direita com direita
				
				glove_p1R_x_next <= glove_p1R_x_reg;
				glove_p1R_y_next <= glove_p1R_y_reg;
				glove_p1L_x_next <= glove_p1L_x_reg;
				glove_p1L_y_next <= glove_p1L_y_reg;
				
		elsif key_code="0101" and glove_p1L_x_reg = 32 then -- tecla correspondente à luva esquerda
					glove_p1L_x_next <= to_unsigned(48,10);
					glove_p1R_x_next <= to_unsigned(32,10);
					glove_p1L_y_next <= to_unsigned(0,10);
					glove_p1R_y_next <= to_unsigned(48,10);
		elsif key_code="0101" then
					glove_p1L_x_next <= to_unsigned(32,10); 
					
		elsif key_code="0110" and glove_p1R_x_reg = 32 then --tecla corresponde te à luva direita
					glove_p1R_x_next <= to_unsigned(48,10);
					glove_p1L_x_next <= to_unsigned(32,10);		
					glove_p1L_y_next <= to_unsigned(0,10);
					glove_p1R_y_next <= to_unsigned(48,10);
		elsif key_code="0110" then
					glove_p1R_x_next <= to_unsigned(32,10);
		end if;

	end process;
	
	glove_p1L_x_l <= player1_x_l + glove_p1L_x_reg;
   glove_p1L_y_t <= player1_y_t + glove_p1L_y_reg;
   glove_p1L_x_r <= glove_p1L_x_l + GLOVE_SIZE_X - 1;
   glove_p1L_y_b <= glove_p1L_y_t + GLOVE_SIZE_X - 1;
	
	glove_p1R_x_l <= player1_x_l + glove_p1R_x_reg;
   glove_p1R_y_t <= player1_y_t + glove_p1R_y_reg;
   glove_p1R_x_r <= glove_p1R_x_l + GLOVE_SIZE_X - 1;
   glove_p1R_y_b <= glove_p1R_y_t + GLOVE_SIZE_X - 1;
	
	
   Glove_P1R_rom_addr <= pix_y(3 downto 0) - player1_y_t(3 downto 0);
   Glove_P1R_rom_col <= pix_x(3 downto 0) - player1_x_l(3 downto 0);
	Glove_P1R_rom_bit<= GLOVE_ROM(to_integer( Glove_P1R_rom_addr), to_integer( Glove_P1R_rom_col));

   Glove_P1L_rom_addr <= pix_y(3 downto 0) - player1_y_t(3 downto 0);
   Glove_P1L_rom_col <= pix_x(3 downto 0) - player1_x_l(3 downto 0);
	Glove_P1L_rom_bit<= GLOVE_ROM(to_integer(not Glove_P1L_rom_addr), to_integer( Glove_P1L_rom_col));	


--*******************************   

--*******************************
   glove_L_P2_on <=
		'1' when	((glove_p2L_x_l<=pix_x) and (pix_x<=glove_p2L_x_r) and
               (glove_p2L_y_t<=pix_y) and (pix_y<=glove_p2L_y_b))			
			 else
      '0';
	
   glove_R_P2_on <=
		'1' when	((glove_p2R_x_l<=pix_x) and (pix_x<=glove_p2R_x_r) and
               (glove_p2R_y_t<=pix_y) and (pix_y<=glove_p2R_y_b))			
			 else
      '0';
	
	process (clk,reset)
   begin
      if reset='1' or rst_glove='1' then
         glove_p2L_x_reg <= to_unsigned(16,10);
			glove_p2L_y_reg <= to_unsigned(48,10);
			glove_p2R_x_reg <= to_unsigned(16,10);
			glove_p2R_y_reg <= to_unsigned(0,10);
      elsif (clk'event and clk='1') then
         glove_p2L_x_reg <= glove_p2L_x_next;
			glove_p2L_y_reg <= glove_p2L_y_next;
			glove_p2R_x_reg <= glove_p2R_x_next;
			glove_p2R_y_reg <= glove_p2R_y_next;
			
      end if;
   end process;
	
	--Glove_P2R_state_reg
	process ( glove_p2R_x_reg, key_code,glove_P2R_y_reg,glove_p2L_x_reg, glove_p2L_y_reg,
	glove_p2L_x_l, glove_P1R_x_r, glove_p2L_y_t, glove_P1R_y_t, glove_p1L_x_r, glove_p1L_y_t,glove_P2R_x_l,glove_P2R_y_t)
	begin
		glove_p2R_x_next <= glove_p2R_x_reg;
		glove_p2R_y_next <= glove_p2R_y_reg;
		glove_p2L_x_next <= glove_p2L_x_reg;
		glove_p2L_y_next <= glove_p2L_y_reg;
		
		if  key_code="1110" and glove_p2R_y_reg = 0 then
					glove_p2L_y_next <= to_unsigned(32,10);
					glove_p2R_y_next <= to_unsigned(16,10);
					glove_p2R_x_next <= to_unsigned(16,10);
					glove_p2L_x_next <= to_unsigned(16,10);									
		elsif key_code="1110" then					
					glove_p2R_y_next <= to_unsigned(0,10);
					glove_p2L_y_next <= to_unsigned(48,10);
		
		elsif ((glove_p2L_x_l= glove_p1R_x_r and glove_p2L_y_t = glove_p1R_y_t)	or  -- luva esquerda com esquerda
				(glove_p2L_x_l= glove_p1L_x_r and glove_p2L_y_t = glove_p1L_y_t)	or	 --luva esquerda com direita
				(glove_p2R_x_l= glove_p1L_x_r and glove_p2R_y_t = glove_p1L_y_t) or	--luva direita com esquerda
				(glove_p2R_x_l= glove_p1R_x_r and glove_p2R_y_t = glove_p1R_y_t)) then	--luva direita com direita
			
			glove_p2R_x_next <= glove_p2R_x_reg;
			glove_p2R_y_next <= glove_p2R_y_reg;
			glove_p2L_x_next <= glove_p2L_x_reg;
			glove_p2L_y_next <= glove_p2L_y_reg;

		elsif key_code="1011" and glove_p2L_x_reg = 16 then -- tecla correspondente à luva esquerda
					glove_p2L_x_next <= to_unsigned(32,10);
					glove_p2R_x_next <= to_unsigned(16,10);
					glove_p2L_y_next <= to_unsigned(48,10);
					glove_p2R_y_next <= to_unsigned(0,10);
		elsif key_code="1011" then
					glove_p2L_x_next <= to_unsigned(16,10); 
					
		elsif key_code="1100" and glove_p2R_x_reg = 16 then --tecla corresponde te à luva direita
					glove_p2R_x_next <= to_unsigned(32,10);
					glove_p2L_x_next <= to_unsigned(16,10);		
					glove_p2L_y_next <= to_unsigned(48,10);
					glove_p2R_y_next <= to_unsigned(0,10);
		elsif key_code="1100" then
					glove_p2R_x_next <= to_unsigned(16,10);
		end if;

	end process;
	
	glove_p2L_x_l <= player2_x_l - glove_p2L_x_reg;
   glove_p2L_y_t <= player2_y_t + glove_p2L_y_reg;
   glove_p2L_x_r <= glove_p2L_x_l + GLOVE_SIZE_X - 1;
   glove_p2L_y_b <= glove_p2L_y_t + GLOVE_SIZE_X - 1;
	
	glove_p2R_x_l <= player2_x_l - glove_p2R_x_reg;
   glove_p2R_y_t <= player2_y_t + glove_p2R_y_reg;
   glove_p2R_x_r <= glove_p2R_x_l + GLOVE_SIZE_X - 1;
   glove_p2R_y_b <= glove_p2R_y_t + GLOVE_SIZE_X - 1;
	
	Glove_P2L_rom_addr <= pix_y(3 downto 0) - player2_y_t(3 downto 0);
   Glove_P2L_rom_col <= pix_x(3 downto 0) - player2_x_l(3 downto 0);
	Glove_P2L_rom_bit<= GLOVE_ROM(to_integer( Glove_P2L_rom_addr), to_integer( not Glove_P2L_rom_col));

   Glove_P2R_rom_addr <= pix_y(3 downto 0) - player2_y_t(3 downto 0);
   Glove_P2R_rom_col <= pix_x(3 downto 0) - player2_x_l(3 downto 0);
	Glove_P2R_rom_bit<= GLOVE_ROM(to_integer(not Glove_P2R_rom_addr), to_integer(not Glove_P2R_rom_col));	


--**************************************************
-- counter score and ko
--**************************************************
   -- registers

	
   process (clk,reset,ko_reset)
   begin
      if reset='1' or ko_reset ='1' then
			ko1_reg<= (others=>'0');
			ko2_reg<= (others=>'0');
      elsif (clk'event and clk='1') then
			ko1_reg<= ko1_next;
			ko2_reg<= ko2_next;
      end if;
   end process;


--**************************************************************
-- Estados do jogo
--**************************************************************
process (clk,reset)
   begin
      if reset='1' then
         state_reg <= newgame;
			
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
      end if;
 end process;
 
	process (clk,reset,score_rst)
   begin
      if reset='1' or score_rst='1' then
         score_play_1_reg <= (others=>'0');
         score_play_2_reg <= (others=>'0');
		--	round_next<= (others=>'0');
      elsif (clk'event and clk='1') then
         score_play_1_reg <= score_play_1_next;
         score_play_2_reg <= score_play_2_next;
		--	round_reg<= round_next;
      end if;
   end process;
	
process(state_next,state_reg, score_play_1_reg, score_play_2_reg, Player1_x_face, Player1_y_face, ko2_reg,
			Player2_x_face, Player2_y_face, ko1_reg, score_play_2, score_play_1, timer_up)
begin
	state_next <= state_reg;
	score_play_1_next <= score_play_1_reg;
	score_play_2_next <= score_play_2_reg;
	--round_next<=round_reg;
	
	time_start<='0';
	score_rst<='0';
	ko_reset <='0';
	rst_glove<='0';
	rst_player<='0';
	
	case state_reg is
         when newgame =>
				ko_reset<='1';	 
				score_rst<='1';
				rst_player<='1';
				rst_glove<='1';
				state_next <= play;
			   winner_show_on<='0';
								
         when play =>
				rst_player<='0';
				rst_glove<='0';
				ko_reset <='0';

					if ((Player1_x_face <= Ring_in_x_L or Player1_y_face <= Ring_in_y_T or Player1_y_face >= Ring_in_y_B) or ko1_reg>=3 )then
						
							score_play_2_next<=score_play_2_reg + 1;
							state_next <= new_round;
							
					elsif (( Player2_x_face >= Ring_in_x_R or Player2_y_face <= Ring_in_y_T or Player2_y_face >= Ring_in_y_B) or ko2_reg>=3) then
						   
							score_play_1_next<=score_play_1_reg+1;
							state_next <= new_round;
           
					end if;
				
				when new_round =>
					if score_play_2>="0011" or score_play_1>="0011" then
						ko_reset<='1';
						rst_glove<='1';
						time_start<='1';
						state_next <= over;					
					else
						ko_reset<='1';
						rst_player<='1';
						state_next <= play;
						rst_glove<='1';
					end if;
          
         when over =>
            -- wait for 2 sec to display game over
				winner_show_on<='1';
          if timer_up='1' then
                state_next <= newgame;					 
          end if;
       end case;
   end process;
 
 score_play_1<= std_logic_vector(score_play_1_reg);
 score_play_2<=std_logic_vector(score_play_2_reg);

	--***************************************************************************
		
   -- rgb multiplexing circuit
   process(sq_player1_on,sq_player2_on, glove_L_P1_on, glove_L_P1_on, glove_L_P2_on, glove_R_P2_on,
					Player1_rom_bit,Player2_rom_bit,Glove_P1L_rom_bit,Glove_P1R_rom_bit,Glove_P2L_rom_bit,
					Glove_P2R_rom_bit, background_rgb,video_on,glove_R_P1_on)
   begin
      if video_on='0' then
          graph_rgb <= "000"; --blank
      else
	
			if sq_player1_on='1' and Player1_rom_bit /= "111" then
				graph_rgb <= Player1_rom_bit;
			
			elsif sq_player2_on='1' and Player2_rom_bit /= "111" then
					graph_rgb <= Player2_rom_bit;
					
			elsif glove_L_P1_on='1' and Glove_P1L_rom_bit /= "111" then
					graph_rgb <= Glove_P1L_rom_bit;
					
			elsif glove_R_P1_on='1' and Glove_P1R_rom_bit /= "111" then
					graph_rgb <= Glove_P1R_rom_bit;
					
			elsif glove_L_P2_on='1' and Glove_P2L_rom_bit /= "111" then
				graph_rgb <= Glove_P2L_rom_bit;
				
			elsif glove_R_P2_on='1' and Glove_P2R_rom_bit /= "111" then
				graph_rgb <= Glove_P2R_rom_bit;

			else
				graph_rgb <= background_rgb;
			end if;
      end if;
   end process;
	
end arch;



