
--=================================================================
-- Este codigo le o teclado e devolve um codigo de 8 bit conforme 
-- a tecla premida. 
-- A saida key-code foi modificada e basta usar os 4bits menos 
-- significativos para obter as teclas que precisamos, as restantes
--	ficam a zero.
-- Vamos precisar de 12 teclas:
-- jogador A   letras a,d,w,s,v e b
-- jogador B  up,down,left,right,0 e .
-- podemos usar outras teclas para restart e ou alterar dificuldade
--=================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity kb_code is
   
   port (
      clk, reset: in  std_logic;
      ps2d, ps2c: in  std_logic;
      key_code: out std_logic_vector(3 downto 0)
      
   );
end kb_code;

architecture arch of kb_code is
   constant BRK: std_logic_vector(7 downto 0):="11110000";
   -- F0 (break code)
   type statetype is (wait_brk, get_code);
   signal state_reg, state_next: statetype;
   signal scan_out: std_logic_vector(7 downto 0);
   signal scan_done_tick: std_logic;

begin
   --=======================================================
   -- instantiation
   --=======================================================
   ps2_rx_unit: entity work.ps2_rx(arch)
      port map(clk=>clk, reset=>reset, rx_en=>'1',
               ps2d=>ps2d, ps2c=>ps2c,
               rx_done_tick=>scan_done_tick,
               dout=>scan_out);



   --=======================================================
   -- FSM to get the scan code after F0 received
   --=======================================================
   process (clk, reset)
   begin
      if reset='1' then
         state_reg <= wait_brk;
      elsif (clk'event and clk='1') then
         state_reg <= state_next;
      end if;
   end process;


   process(state_reg, scan_done_tick, scan_out)
   begin
      
      state_next <= state_reg;
      case state_reg is
         when wait_brk => -- wait for F0 of break code
			--testes
				key_code<=(others=>'0');
            if scan_done_tick='1' and scan_out=BRK then
               state_next <= get_code;
            end if;
         when get_code => -- get the following scan code
            if scan_done_tick='1' then
               if scan_out="00011100" then --a
						key_code<="0001";
					elsif scan_out="00100011" then --d
						key_code<="0010";
					elsif scan_out="00011101" then --w
						key_code<="0011";
					elsif scan_out="00011011" then --s
						key_code<="0100";
					elsif scan_out="00101010" then --v left punch player1
						key_code<="0101";
					elsif scan_out="00110001" then --n right punch player1
						key_code<="0110";
					elsif scan_out="01110101" then --up
						key_code<="0111";
					elsif scan_out="01110010" then --down
						key_code<="1000";					
					elsif scan_out="01110100" then --right 
						key_code<="1001";
					elsif scan_out="01101011" then --left
						key_code<="1010";
					elsif scan_out="01101001" then --1  left punch player2
						key_code<="1011";
					elsif scan_out="01111010" then --3   right punch player2
						key_code<="1100";
					elsif scan_out="00110010" then -- b defesa player1 
						key_code<="1101";
					elsif scan_out="01110011" then -- 5 defesa player2
						key_code<="1110";

					end if;
               state_next <= wait_brk;
            end if;
      end case;
   end process;
end arch;