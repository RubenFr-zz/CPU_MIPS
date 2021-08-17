-- Address Decoder
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY AddressDecoder IS

	PORT(
		Address : IN STD_LOGIC_VECTOR( 9 DOWNTO 0 );

		HEX0_ena : OUT STD_LOGIC;
		HEX1_ena : OUT STD_LOGIC;
		HEX2_ena : OUT STD_LOGIC;
		HEX3_ena : OUT STD_LOGIC;
		LEDG_ena : OUT STD_LOGIC;
		LEDR_ena : OUT STD_LOGIC;
		SW_ena   : OUT STD_LOGIC
	);
END AddressDecoder;

ARCHITECTURE structure OF AddressDecoder IS
BEGIN

	LEDG_ena <= '1' WHEN Address = "10" & X"00" ELSE '0'; -- 0x800
	LEDR_ena <= '1' WHEN Address = "10" & X"01" ELSE '0'; -- 0x804
	HEX0_ena <= '1' WHEN Address = "10" & X"02" ELSE '0'; -- 0x808
	HEX1_ena <= '1' WHEN Address = "10" & X"03" ELSE '0'; -- 0x80C
	HEX2_ena <= '1' WHEN Address = "10" & X"04" ELSE '0'; -- 0x810
	HEX3_ena <= '1' WHEN Address = "10" & X"05" ELSE '0'; -- 0x814
	SW_ena   <= '1' WHEN Address = "10" & X"06" ELSE '0'; -- 0x818

END structure;

