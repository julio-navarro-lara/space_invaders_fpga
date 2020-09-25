LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

--Display que representa cualquier número entero (sus decenas y unidades) en dos displays de 7 segmentos
ENTITY display IS
	PORT
	(
		--Número a representar
		numero	: IN INTEGER;
		
		--Salida a display de unidades y de decenas
		vector_out_unidades,
		vector_out_decenas  : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
	);
END display;

ARCHITECTURE arquitectura OF display IS

BEGIN
	--Decodificamos las decenas (división entera entre 10)
	WITH numero/10 SELECT
		vector_out_decenas <= 	"1000000" WHEN 0,
								"1111001" WHEN 1,
								"0100100" WHEN 2,
								"0110000" WHEN 3,
								"0011001" WHEN 4,
								"0010010" WHEN 5,
								"0000010" WHEN 6,
								"1111000" WHEN 7,
								"0000000" WHEN 8,
								"0010000" WHEN OTHERS;
	
	--Decodificamos las unidades (restar al número las decenas multiplicadas por 10)
	WITH numero - (numero/10)*10 SELECT
		vector_out_unidades <= 	"1000000" WHEN 0,
								"1111001" WHEN 1,
								"0100100" WHEN 2,
								"0110000" WHEN 3,
								"0011001" WHEN 4,
								"0010010" WHEN 5,
								"0000010" WHEN 6,
								"1111000" WHEN 7,
								"0000000" WHEN 8,
								"0010000" WHEN OTHERS;							

END arquitectura;
