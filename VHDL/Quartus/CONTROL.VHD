-- control module (implements MIPS control unit)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY control IS
	PORT(
		Opcode       : IN  STD_LOGIC_VECTOR( 5 DOWNTO 0 );
		func         : IN  STD_LOGIC_VECTOR( 5 DOWNTO 0 );
		RegDst       : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		ALUSrc       : OUT STD_LOGIC;
		MemtoReg     : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		RegWrite     : OUT STD_LOGIC;
		MemRead      : OUT STD_LOGIC;
		MemWrite     : OUT STD_LOGIC;
		Branch       : OUT STD_LOGIC;
		Jump         : OUT STD_LOGIC;
		JumpReg      : OUT STD_LOGIC;
		ALUop        : OUT STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		clock, reset : IN  STD_LOGIC );

END control;

ARCHITECTURE behavior OF control IS

	SIGNAL R_format, Lw, Sw, Lui, Beq, Bne, j, jal, jr, mult, immediate : STD_LOGIC;

BEGIN
	-- Code to generate control signals using opcode bits
	R_format  <= '1' WHEN Opcode = "000000" ELSE '0';
	Lw        <= '1' WHEN Opcode = "100011" ELSE '0';
	Sw        <= '1' WHEN Opcode = "101011" ELSE '0';
	Lui       <= '1' WHEN Opcode = "001111" ELSE '0';
	Beq       <= '1' WHEN Opcode = "000100" ELSE '0';
	Bne       <= '1' WHEN Opcode = "000101" ELSE '0';
	j         <= '1' WHEN Opcode = "000010" ELSE '0';
	jal       <= '1' WHEN Opcode = "000011" ELSE '0';
	jr        <= '1' WHEN func = "001000" AND Opcode = "000000" ELSE '0';
	mult      <= '1' WHEN opcode = "011100" AND func = "000010" ELSE '0';
	immediate <= '1' WHEN opcode = "001000" OR
		Opcode = "001101" OR
		Opcode = "001100" OR
		Opcode = "001110" OR
		Opcode = "001010" OR
		Opcode = "011100" ELSE '0';


	RegDst(0)   <= R_format OR mult;
	RegDst(1)   <= jal;
	ALUSrc      <= NOT (R_format OR mult OR beq OR bne); -- 1 if immediate value is taken, 0 if register value
	MemtoReg(0) <= Lw;
	MemtoReg(1) <= jal;
	RegWrite    <= R_format OR lw OR jal OR immediate OR Lui;
	MemRead     <= Lw;
	MemWrite    <= Sw;
	Branch      <= Beq OR Bne;
	ALUOp       <=
		"00" WHEN (Lw OR Sw OR j OR jal OR Lui) = '1' ELSE -- load/store word/jump/jump and link
		"01" WHEN (Beq OR Bne) = '1' ELSE                  -- branch
		"10" WHEN R_format = '1' ELSE                      -- R_type
		"11";                                              -- Immediate
	Jump    <= j OR jal;
	JumpReg <= jr;
END behavior;


