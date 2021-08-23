--  Execute module (implements the data ALU and Branch Address Adder for the MIPS computer)
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_SIGNED.ALL;

ENTITY Execute IS
	PORT(
		Read_data_1     : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Read_data_2     : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		sign_extend     : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Opcode          : IN  STD_LOGIC_VECTOR( 5 DOWNTO 0 );
		function_opcode : IN  STD_LOGIC_VECTOR( 5 DOWNTO 0 );
		ALUOp           : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
		ALUSrc          : IN  STD_LOGIC;
		Zero            : OUT STD_LOGIC;
		ALU_Result      : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
		Add_Result      : OUT STD_LOGIC_VECTOR( 8 DOWNTO 0 );
		PC_plus_4       : IN  STD_LOGIC_VECTOR( 10 DOWNTO 0 );
		clock, reset    : IN  STD_LOGIC
	);
END Execute;

ARCHITECTURE behavior OF Execute IS
	SIGNAL Ainput, Binput : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL ALU_output_mux : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Branch_Add     : STD_LOGIC_VECTOR( 8 DOWNTO 0 );
	SIGNAL ALU_ctl        : STD_LOGIC_VECTOR( 2 DOWNTO 0 );
	SIGNAL ctl_R_format   : STD_LOGIC_VECTOR( 2 DOWNTO 0 );
	SIGNAL ctl_I_format   : STD_LOGIC_VECTOR( 2 DOWNTO 0 );
	SIGNAL shamt          : STD_LOGIC_VECTOR( 4 DOWNTO 0 );
	SIGNAL shifted_out    : std_logic_vector( 31 DOWNTO 0 );

	COMPONENT Shifter IS
		GENERIC (
			n : INTEGER := 8;
			k : INTEGER := 3 ); -- k=log2(n)
		PORT (
			shft_in     : IN  std_logic_vector (n-1 DOWNTO 0); -- Input to be shifted
			ShiftAmount : IN  std_logic_vector (k-1 DOWNTO 0); -- How much the input must be shifted (between 0 and 2^k-1)
			left_right  : IN  std_logic;                       -- 0: shift left, 1: shift right
			shft_out    : OUT std_logic_vector (n-1 DOWNTO 0);
			cout        : OUT std_logic ); -- Carry out
	END COMPONENT;
BEGIN
	----------------------------------------------------------------------------
	shift : Shifter
		GENERIC MAP (
			n => 32,
			k => 5 -- k=log2(n)
		)
		PORT MAP (
			shft_in     => Binput,             -- Input to be shifted
			ShiftAmount => shamt,              -- How much the input must be shifted (between 0 and 2^k-1)
			left_right  => function_opcode(1), -- 0: shift left, 1: shift right
			shft_out    => shifted_out,        -- res
			cout        => open                -- Carry out (not needed)
		);
	----------------------------------------------------------------------------
	Ainput <= Read_data_1;

	-- ALU input mux
	Binput <= Read_data_2 WHEN (ALUSrc = '0') ELSE
		sign_extend( 31 DOWNTO 0 );

	-- Generate ALU control bits
	ctl_R_format( 0 ) <= (function_opcode(0) OR function_opcode(3)) AND ALUOp(1);
	ctl_R_format( 1 ) <= (NOT function_opcode(2)) OR (NOT ALUOp(1));
	ctl_R_format( 2 ) <= (function_opcode(1) AND ALUOp(1)) OR ALUOp(0);

	ctl_I_format <=
		"000" WHEN Opcode = "001100" ELSE -- andi
		"001" WHEN Opcode = "001101" ELSE -- ori
		"010" WHEN Opcode = "001000" ELSE -- addi
		"100" WHEN Opcode = "001110" ELSE -- xori
		"111" WHEN Opcode = "001010" ELSE -- slti
		"101" WHEN Opcode = "011100" ELSE -- mul (although not an immediate it is considered as so because opcode not 0)
		"ZZZ";                            -- others

	ALU_ctl <=
		"010"        WHEN ALUOp = "00" ELSE -- lw/sw/lui
		"110"        WHEN ALUOp = "01" ELSE -- br
		ctl_R_format WHEN ALUOp = "10" ELSE -- r_format
		ctl_I_format WHEN ALUOp = "11" ELSE -- immediate
		"ZZZ";

		-- Generate Zero Flag
		Zero <= '1' WHEN ALU_output_mux( 31 DOWNTO 0 ) = X"00000000" ELSE '0';

		-- Adder to compute Branch Address
		Branch_Add <= PC_plus_4( 10 DOWNTO 2 ) + sign_extend( 8 DOWNTO 0 ) ;
		Add_result <= 
			Branch_Add( 8 DOWNTO 0 ) WHEN ALUOp = "01" ELSE -- br
			sign_extend( 8 DOWNTO 0 ); -- jump

		-- Shamt for sll and srl
		shamt <= sign_extend( 10 DOWNTO 6);

		-- Select ALU output        
		ALU_result <=
			X"0000000" & B"000" & ALU_output_mux(31) WHEN ALU_ctl = "111" ELSE
			shifted_out                              WHEN ALUOp = "10" AND (function_opcode = "000000" OR function_opcode = "000010") ELSE
			ALU_output_mux( 31 DOWNTO 0 );

		-------------------------------------------------------------------------	
		PROCESS ( ALU_ctl, Ainput, Binput )
			VARIABLE mult : STD_LOGIC_VECTOR( 63 DOWNTO 0 );
		BEGIN
			-- Select ALU operation
			CASE ALU_ctl IS
				-- ALU performs ALUresult = A_input AND B_input
				WHEN "000" => ALU_output_mux <= Ainput AND Binput;

				-- ALU performs ALUresult = A_input OR B_input
				WHEN "001" => ALU_output_mux <= Ainput OR Binput;

				-- ALU performs ALUresult = A_input + B_input
				WHEN "010" => ALU_output_mux <= Ainput + Binput;

				-- ALU performs ADDU
				WHEN "011" => ALU_output_mux <= UNSIGNED(Ainput) + UNSIGNED(Binput);

				-- ALU performs XOR
				WHEN "100" => ALU_output_mux <= Ainput XOR Binput;

				-- ALU performs MUL
				WHEN "101" => 
					mult           := Ainput * Binput;
					ALU_output_mux <= mult( 31 DOWNTO 0 );

				-- ALU performs ALUresult = A_input -B_input
				WHEN "110" => ALU_output_mux <= Ainput - Binput;

				-- ALU performs SLT
				WHEN "111" => ALU_output_mux <= Ainput - Binput ;

				WHEN OTHERS => ALU_output_mux <= X"00000000" ;
			END CASE;
		END PROCESS;
		END behavior;