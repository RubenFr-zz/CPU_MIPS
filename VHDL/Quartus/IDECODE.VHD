--  Idecode module (implements the register file for
LIBRARY IEEE; -- the MIPS computer)
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

ENTITY Idecode IS
	PORT( read_data_1 : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		read_data_2 : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Instruction : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		read_data   : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		ALU_result  : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		RegWrite    : IN  STD_LOGIC;
		MemtoReg    : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		RegDst      : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		Sign_extend : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		clock,reset : IN  STD_LOGIC;
		PC_plus_4   : IN  STD_LOGIC_VECTOR( 10 DOWNTO 0 );
		PC          : IN  STD_LOGIC_VECTOR( 10 DOWNTO 0 );
		GIE         : OUT STD_LOGIC);
END Idecode;


ARCHITECTURE behavior OF Idecode IS
	TYPE register_file IS ARRAY ( 0 TO 31 ) OF STD_LOGIC_VECTOR( 31 DOWNTO 0 );

	SIGNAL register_array              : register_file;
	SIGNAL write_register_address      : STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL write_data                  : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_register_1_address     : STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL read_register_2_address     : STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL write_register_address_1    : STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL write_register_address_0    : STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL Instruction_immediate_value : STD_LOGIC_VECTOR( 15 DOWNTO 0 );


BEGIN
	read_register_1_address     <= Instruction( 25 DOWNTO 21 );
	read_register_2_address     <= Instruction( 20 DOWNTO 16 );
	write_register_address_1    <= Instruction( 15 DOWNTO 11 );
	write_register_address_0    <= Instruction( 20 DOWNTO 16 );
	Instruction_immediate_value <= Instruction( 15 DOWNTO 0 );

	-- Read Register 1 Operation
	read_data_1 <=
		(OTHERS => '0') WHEN Instruction(31 DOWNTO 26) = "001111" OR Instruction(31 DOWNTO 26) = "000010" ELSE
		register_array(CONV_INTEGER(read_register_1_address));

	-- Read Register 2 Operation		 
	read_data_2 <= register_array(CONV_INTEGER(read_register_2_address));

	-- Mux for Register Write Address
	write_register_address <=
		"11111"                  WHEN RegDst(1) = '1' ELSE --jal
		write_register_address_1 WHEN RegDst(0) = '1' ELSE -- if RegDst(0) = '1' write to register rd, else write to rt
		write_register_address_0;

	-- Mux to bypass data memory for Rformat instructions
	write_data <=
		X"00000" & B"0" & PC_plus_4 WHEN MemtoReg(1) = '1' ELSE -- jal
		ALU_result( 31 DOWNTO 0 )   WHEN MemtoReg(0) = '0' ELSE
		read_data;

	-- Sign Extend 16-bits to 32-bits, shift left
	-- in case of lui
	Sign_extend <=
		Instruction_immediate_value & X"0000" WHEN Instruction(31 DOWNTO 26) = "001111" ELSE
		X"0000" & Instruction_immediate_value WHEN Instruction_immediate_value(15) = '0' ELSE
		X"FFFF" & Instruction_immediate_value;

	PROCESS
	BEGIN
		WAIT UNTIL clock'EVENT AND clock = '1';
		IF reset = '1' THEN
			-- Initial register values on reset are register = reg#
			-- use loop to automatically generate reset logic 
			-- for all registers
			FOR i IN 0 TO 31 LOOP
				register_array(i) <= CONV_STD_LOGIC_VECTOR( i, 32 );
			END LOOP;

		-- When interrupt - write the current PC to register 27 ($k1)
		ELSIF Instruction(31 DOWNTO 26) = "111111" THEN -- opcode=31 means interrupt was recieved
			register_array( 27 ) <= X"00000" & B"0" & PC;

		-- Write back to register - don't write to register 0
		ELSIF RegWrite = '1' AND write_register_address /= 0 THEN
			register_array( CONV_INTEGER( write_register_address)) <= write_data;
		END IF;
	END PROCESS;

	GIE <= register_array(26)(0);

	-- -- calculate GIE from k0
	-- PROCESS (clock, reset)
	-- BEGIN
	-- if reset = '1' then
	-- GIE <= '0';
	-- elsif rising_edge(clock) then
	-- -- if we are writing to $k0
	-- IF RegWrite = '1' AND write_register_address="011010" THEN
	-- -- take $k0[0] as GIE
	-- GIE <= write_data(0);
	-- END IF;
	-- end if;
	-- END PROCESS;

END behavior;


