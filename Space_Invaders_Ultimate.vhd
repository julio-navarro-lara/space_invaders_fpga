LIBRARY ieee;
--Importamos las librerías de STD_LOGIC necesarias
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY space_invaders_ultimate IS
	PORT
	(
		--Reloj para temporizar la pantalla VGA
		clk		: IN STD_LOGIC;
		
		--Botones de control de movimiento
		botones	: IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		
		--Salidas VGA
		hsync,
		vsync,
		red, 
		green,
		blue 	: OUT STD_LOGIC;
		
		--Salidas de los display de 7 segmentos
		display_unidades,
		display_decenas  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
	);
END space_invaders_ultimate;


ARCHITECTURE arquitectura OF space_invaders_ultimate IS
	--Señales de sincronización de la pantalla
	SIGNAL 	h_sync, v_sync	:	STD_LOGIC;
			
	--Señales de colores
	SIGNAL	red_signal,
			green_signal,
			blue_signal	: STD_LOGIC;
			
	--Señales para habilitar y deshabilitar la función de vídeo
	SIGNAL 	video_en, 
			horizontal_en, 
			vertical_en	: STD_LOGIC;
	
	--Contadores para determinar la sincronización de la pantalla
	SIGNAL 	h_cnt,
			v_cnt : integer RANGE 0 TO 800;
	
	TYPE elemento IS (nada,marciano,muerto,disparo,nave);
	TYPE lista_elementos IS ARRAY(1 TO 108) OF elemento;
	SIGNAL memoria_video: lista_elementos := (4 TO 9=>marciano,16 TO 21=>marciano,
											28 TO 33=>marciano,103=>nave,OTHERS=>nada); 
	SIGNAL cont_v: integer RANGE 1 TO 5 := 1;
	SIGNAL cont_h: integer RANGE 1 TO 5 := 1;
	SIGNAL indice: integer RANGE 1 TO 108 := 1;
	SIGNAL contador_vga_v: integer RANGE 0 TO 7 := 0;
	SIGNAL contador_vga_h: integer RANGE 0 TO 7 := 0;
	
	--Posición de la nave en la pantalla (12 posibles)
	SIGNAL pos_nave: integer RANGE 0 TO 11 := 6;
	--Reloj para determinar el muestreo de los botones
	SIGNAL reloj_botones: STD_LOGIC := '0';
	--Contador para determinar la frecuencia de muestreo de los botones
	SIGNAL contador_botones: STD_LOGIC_VECTOR(21 DOWNTO 0) := "0000000000000000000000";
	
	--Variable booleana que indica si se acaba de iniciar el programa (por problemas desconocidos de inicialización de variables.
	SIGNAL primera_vez: STD_LOGIC := '1';
BEGIN

	--El vídeo está activo si lo están las filas y las columnas
	video_en <= horizontal_en AND vertical_en;
	
	--Proceso para determinar la frecuencia del reloj de muestreo de los botones
	PROCESS(clk)
	BEGIN
		--Se procede como en reloj_dibujar
		IF (clk'EVENT AND clk = '1') THEN
			IF(contador_botones = "1111111111111111111111") THEN
				reloj_botones <= '1';
				contador_botones <= "0000000000000000000000";
			ELSE
				reloj_botones <= '0';
				contador_botones <= contador_botones + 1;
			END IF; 
		END IF;
	END PROCESS;
	
	--Proceso para mover la nave
	PROCESS(reloj_botones)
		--Variable auxiliar para almacenar la posición de la nave temporalmente
		--Tras muchas pruebas hemos llegado a la conclusión de que es la mejor forma de que funcione, y la redundancia de la
		--variable auxiliar supone poco aumento en puertas lógicas (prácticamente nulo e inferior a otras muchas soluciones sin
		--variable auxiliar que, además, funcionaban peor).
		VARIABLE aux: integer RANGE 0 TO 11;
	BEGIN
		IF (reloj_botones'EVENT AND reloj_botones = '1') THEN	
				
				--Si estamos en el inicio del programa, forzamos a que la nave esté en el centro
				--(había problemas en la inicialización de pos_nave de la forma habitual)
				IF(primera_vez = '1')THEN
					aux := 6;
					primera_vez <= '0';
				ELSE
					aux := pos_nave;	
				END IF;
				
				--Si está pulsado uno de los dos botones solamente, movemos la nave
				IF (botones = "01" OR botones = "10")THEN
					
					--Según qué botón esté pulsado, incrementamos o disminuimos la posición de la nave
					--También controlamos si la nave ha llegado a uno de los extremos de la pantalla
					IF(botones = "01" AND aux>0)THEN
						aux := aux-1;
					ELSIF(botones = "10" AND aux<11)THEN
						aux := aux+1;
					END IF;
					
					CASE aux IS
						WHEN 0 => memoria_video(97 TO 108)<=(97=>nave, OTHERS=>nada);
						WHEN 1 => memoria_video(97 TO 108)<=(98=>nave, OTHERS=>nada);
						WHEN 2 => memoria_video(97 TO 108)<=(99=>nave, OTHERS=>nada);
						WHEN 3 => memoria_video(97 TO 108)<=(100=>nave, OTHERS=>nada);
						WHEN 4 => memoria_video(97 TO 108)<=(101=>nave, OTHERS=>nada);
						WHEN 5 => memoria_video(97 TO 108)<=(102=>nave, OTHERS=>nada);
						WHEN 6 => memoria_video(97 TO 108)<=(103=>nave, OTHERS=>nada);
						WHEN 7 => memoria_video(97 TO 108)<=(104=>nave, OTHERS=>nada);
						WHEN 8 => memoria_video(97 TO 108)<=(105=>nave, OTHERS=>nada);
						WHEN 9 => memoria_video(97 TO 108)<=(106=>nave, OTHERS=>nada);
						WHEN 10 => memoria_video(97 TO 108)<=(107=>nave, OTHERS=>nada);
						WHEN 11 => memoria_video(97 TO 108)<=(108=>nave, OTHERS=>nada);
					END CASE;
					--Actualizamos la posición de la nave
					pos_nave <= aux;
					
					memoria_video(1) <= marciano;

				END IF;	
		memoria_video(1) <= disparo;	
		END IF;
	END PROCESS;
	
	memoria_video(12) <= disparo;
    --Proceso para pasar la información de la memoria de vídeo a la pantalla
	PROCESS
		
	BEGIN
		
		--Esperamos hasta que empieza el reloj
		WAIT UNTIL(clk'EVENT) AND (clk = '1');
		
		--Sincronización horizontal
		
		--Reseteamos el contador de sincronización horizontal o lo aumentamos en 1.
		IF (h_cnt = 799) THEN
			h_cnt <= 0;
			cont_h <= 1;
		ELSE
			h_cnt <= h_cnt + 1;
		END IF;
		
		IF (h_cnt<560)AND(v_cnt<424)AND(h_cnt>=80)AND(v_cnt>=64) THEN
			
			IF(memoria_video(indice) = nada)THEN
				red_signal <= '0';
				green_signal <= '0';
				blue_signal <= '0';
			ELSIF(memoria_video(indice) = marciano)THEN
				IF((cont_h = 2 OR cont_h = 3)AND(cont_v < 4))OR
				((cont_h = 1 OR cont_h = 4)AND(cont_v = 2 OR cont_v = 4))THEN		
					red_signal <= '0';
					green_signal <= '1';
					blue_signal <= '0';
				ELSE
					red_signal <= '0';
					green_signal <= '0';
					blue_signal <= '0';
				END IF;
			ELSIF(memoria_video(indice) = nave)THEN
				IF((cont_v=5)AND(cont_h=2 OR cont_h = 3 OR cont_h = 4))OR
				--((cont_v = 5)AND(cont_h>1 AND cont_h<5))OR
				((cont_h = 1 OR cont_h = 5)AND(cont_v < 4))OR
				((cont_v = 1) AND (cont_h = 2 OR cont_h = 4))THEN
					red_signal <= '0';
					green_signal <= '0';
					blue_signal <= '0';
				ELSE
					red_signal <= '1';
					green_signal <= '0';
					blue_signal <= '0';
				END IF;
			ELSIF(memoria_video(indice) = disparo)THEN
				IF((cont_h = 3)AND(cont_v < 5 AND cont_v >1))THEN
					red_signal <= '0';
					green_signal <= '1';
					blue_signal <= '1';
				ELSE
					red_signal <= '0';
					green_signal <= '0';
					blue_signal <= '0';
				END IF;
			ELSIF(memoria_video(indice) = muerto)THEN
				IF((cont_h = 2 OR cont_h = 4)AND(cont_v = 2 OR cont_v = 4))OR
				((cont_h = 3)AND(cont_v = 3))THEN
					red_signal <= '0';
					green_signal <= '0';
					blue_signal <= '1';
				ELSE
					red_signal <= '0';
					green_signal <= '0';
					blue_signal <= '0';
				END IF;
			END IF;
			
			--IF(indice  = 12) THEN
			--	red_signal <= '1';
			--	green_signal <= '0';
			--	blue_signal <= '0';
			--ELSE
			--	red_signal <= '0';
			--	green_signal <= '0';
			--	blue_signal <= '1';
			--END IF;
			
			IF(contador_vga_h = 7)THEN
				contador_vga_h <= 0;
				IF(cont_h = 5)THEN
					cont_h <= 1;
					IF(indice MOD 12= 0)THEN
						IF(contador_vga_v = 7)THEN
							contador_vga_v <= 0;
							IF(cont_v = 5)THEN
								cont_v <= 1;
								indice <= indice + 1;
							ELSE
								cont_v <= cont_v + 1;
								indice <= indice - 11;
							END IF;
						ELSE
							contador_vga_v <= contador_vga_v + 1;
							indice <= indice - 11;
						END IF;
					ELSE
						indice <= indice + 1;
					END IF;
				ELSE
					cont_h <= cont_h + 1;
				END IF;
			ELSE
				contador_vga_h <= contador_vga_h + 1;
			END IF;
		ELSE
			red_signal <= '0';
			green_signal <= '0';
			blue_signal <= '0';
		END IF;	
		
	    --Generamos la sincronización horizontal
		IF (h_cnt <= 755) AND (h_cnt >= 659) THEN
			h_sync <= '0';
		ELSE
			h_sync <= '1';
		END IF;
		
		--Sincronización vertical

	    --Reseteamos el contador vertical
		IF (v_cnt >= 524) AND (h_cnt >= 699) THEN
			v_cnt <= 0;
			cont_h <= 1;
			cont_v <= 1;
			indice <= 1;
		ELSIF (h_cnt = 699) THEN
			v_cnt <= v_cnt + 1;
		END IF;
		
		--Generamos la sincronización vertical
		IF (v_cnt <= 494) AND (v_cnt >= 493) THEN
			v_sync <= '0';	
		ELSE
			v_sync <= '1';
		END IF;
		
		--Habilitamos la señal horizontal
		IF (h_cnt <= 639) THEN
			horizontal_en <= '1';
		ELSE
			horizontal_en <= '0';
		END IF;
		
	    --Habilitamos la señal vertical
		IF (v_cnt <= 479) THEN
			vertical_en <= '1';
		ELSE
			vertical_en <= '0';
		END IF;
		
		--Asignamos los resultados a los pines (teniendo en cuenta si el vídeo está o no habilitado)
		red		<= red_signal AND video_en;
		green   <= green_signal AND video_en;
		blue	<= blue_signal AND video_en;
		
		--Asignamos también las señales de sincronía
		hsync	<= h_sync;
		vsync	<= v_sync;
		
	END PROCESS;


END arquitectura;