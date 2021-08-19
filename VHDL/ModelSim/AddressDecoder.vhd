-- Address Decoder
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY AddressDecoder IS

	PORT(
		Address : IN STD_LOGIC_VECTOR( 11 DOWNTO 0 );

		HEX0_ena : OUT STD_LOGIC;
		HEX1_ena : OUT STD_LOGIC;
		HEX2_ena : OUT STD_LOGIC;
		HEX3_ena : OUT STD_LOGIC;
		LEDG_ena : OUT STD_LOGIC;
		LEDR_ena : OUT STD_LOGIC;
		SW_ena   : OUT STD_LOGIC;
		KEY_ena  : OUT STD_LOGIC;
		UCTL_ena : OUT STD_LOGIC;
		RXBF_ena : OUT STD_LOGIC;
		TXBF_ena : OUT STD_LOGIC;
		BTCTL_ena: OUT STD_LOGIC;
		BTCNT_ena: OUT STD_LOGIC;
		IE_ena 	 : OUT STD_LOGIC;
		IFG_ena  : OUT STD_LOGIC;
		TYPE_ena : OUT STD_LOGIC
	);
END AddressDecoder;

ARCHITECTURE structure OF AddressDecoder IS
BEGIN

	LEDG_ena <= '1' WHEN Address = X"800" ELSE '0'; -- 0x800
	LEDR_ena <= '1' WHEN Address = X"804" ELSE '0'; -- 0x804
	HEX0_ena <= '1' WHEN Address = X"808" ELSE '0'; -- 0x808
	HEX1_ena <= '1' WHEN Address = X"80C" ELSE '0'; -- 0x80C
	HEX2_ena <= '1' WHEN Address = X"810" ELSE '0'; -- 0x810
	HEX3_ena <= '1' WHEN Address = X"814" ELSE '0'; -- 0x814
	SW_ena   <= '1' WHEN Address = X"818" ELSE '0'; -- 0x818
	KEY_ena  <= '1' WHEN Address = X"81C" ELSE '0'; -- 0x81C
	UCTL_ena <= '1' WHEN Address = X"820" ELSE '0'; -- 0x820
	RXBF_ena <= '1' WHEN Address = X"821" ELSE '0'; -- 0x821
	TXBF_ena <= '1' WHEN Address = X"822" ELSE '0'; -- 0x822
	BTCTL_ena<= '1' WHEN Address = X"824" ELSE '0'; -- 0x824
	BTCNT_ena<= '1' WHEN Address = X"828" ELSE '0'; -- 0x828
	IE_ena   <= '1' WHEN Address = X"82C" ELSE '0'; -- 0x82C
	IFG_ena  <= '1' WHEN Address = X"82D" ELSE '0'; -- 0x82D
	TYPE_ena <= '1' WHEN Address = X"82E" ELSE '0'; -- 0x82E
	

END structure;

