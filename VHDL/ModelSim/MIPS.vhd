-- Top Level Structural Model for MIPS Processor Core
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY MIPS IS

	PORT(
		rst_in          : IN  STD_LOGIC;
		clk_24MHz             : IN  STD_LOGIC;
		SW   : IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
		LEDG : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		LEDR : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		HEX0 : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);   -- converted to 7-seg
		HEX1 : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);   -- converted to 7-seg
		HEX2 : OUT STD_LOGIC_VECTOR (6 DOWNTO 0);   -- converted to 7-seg
		HEX3 : OUT STD_LOGIC_VECTOR (6 DOWNTO 0) -- converted to 7-seg	
	);
END MIPS;

ARCHITECTURE structure OF MIPS IS

	COMPONENT Ifetch
		PORT(
			Instruction   : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			PC_plus_4_out : OUT STD_LOGIC_VECTOR( 9 DOWNTO 0 );
			Add_result    : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			Branch        : IN  STD_LOGIC;
			Jump          : IN  STD_LOGIC;
			JumpReg       : IN  STD_LOGIC;
			Zero          : IN  STD_LOGIC;
			read_data_1   : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			PC_out        : OUT STD_LOGIC_VECTOR( 9 DOWNTO 0 );
			clock, reset  : IN  STD_LOGIC
		);
	END COMPONENT;

	COMPONENT Idecode
		PORT(
			read_data_1      : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			read_data_2      : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			Instruction      : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			read_data        : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			ALU_result       : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			RegWrite         : IN  STD_LOGIC;
			PC_plus_4        : IN  STD_LOGIC_VECTOR( 9 DOWNTO 0 );
			RegDst, MemtoReg : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
			Sign_extend      : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			clock, reset     : IN  STD_LOGIC
		);
	END COMPONENT;

	COMPONENT control
		PORT(
			Opcode       : IN  STD_LOGIC_VECTOR( 5 DOWNTO 0 );
			Func         : IN  STD_LOGIC_VECTOR( 5 DOWNTO 0 );
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
			clock, reset : IN  STD_LOGIC
		);
	END COMPONENT;

	COMPONENT Execute
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
			Add_Result      : OUT STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			PC_plus_4       : IN  STD_LOGIC_VECTOR( 9 DOWNTO 0 );
			clock, reset    : IN  STD_LOGIC
		);
	END COMPONENT;

	COMPONENT dmemory
		PORT(
			read_data         : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			address           : IN  STD_LOGIC_VECTOR( 7 DOWNTO 0 );
			write_data        : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			MemRead, Memwrite : IN  STD_LOGIC;
			clock,reset       : IN  STD_LOGIC
		);
	END COMPONENT;

	COMPONENT hex_to_7_segment is
		PORT(
			hex    : in  std_logic_vector(3 downto 0);
			output : out std_logic_vector (6 downto 0)
		);
	END COMPONENT;

	COMPONENT AddressDecoder is
		PORT(
			Address  : IN  STD_LOGIC_VECTOR( 9 DOWNTO 0 );
			HEX0_ena : OUT STD_LOGIC;
			HEX1_ena : OUT STD_LOGIC;
			HEX2_ena : OUT STD_LOGIC;
			HEX3_ena : OUT STD_LOGIC;
			LEDG_ena : OUT STD_LOGIC;
			LEDR_ena : OUT STD_LOGIC;
			SW_ena   : OUT STD_LOGIC
		);
	END COMPONENT;

	----------------------------------------------------------------------------
	-- SIGNAL ADDED
	----------------------------------------------------------------------------
	SIGNAL HEX0_reg : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
	SIGNAL HEX1_reg : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
	SIGNAL HEX2_reg : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
	SIGNAL HEX3_reg : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
	SIGNAL LEDG_reg : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL LEDR_reg : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');

	SIGNAL data_from_memory : STD_LOGIC_VECTOR (31 DOWNTO 0);

	SIGNAL ioWrite : STD_LOGIC;
	SIGNAL ioRead  : STD_LOGIC;
	SIGNAL MEM_IO  : STD_LOGIC;
	SIGNAL write_to_memory_ena : STD_LOGIC;

	SIGNAL HEX0_ena, HEX1_ena, HEX2_ena, HEX3_ena : STD_LOGIC;
	SIGNAL LEDG_ena, LEDR_ena, SW_ena             : STD_LOGIC;
	SIGNAL rst : STD_LOGIC;
	SIGNAL clk: std_LOGIC := '0';

	----------------------------------------------------------------------------
	-- declare signals used to connect VHDL components
	----------------------------------------------------------------------------
	SIGNAL PC_plus_4   : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	SIGNAL read_data_1 : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_data_2 : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Sign_Extend : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Add_result  : STD_LOGIC_VECTOR( 7 DOWNTO 0 );
	SIGNAL ALU_result  : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_data   : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL ALUSrc      : STD_LOGIC;
	SIGNAL Branch      : STD_LOGIC;
	SIGNAL Jump        : STD_LOGIC;
	SIGNAL JumpReg     : STD_LOGIC;
	SIGNAL RegDst      : STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL Regwrite    : STD_LOGIC;
	SIGNAL Zero        : STD_LOGIC;
	SIGNAL MemWrite    : STD_LOGIC;
	SIGNAL MemtoReg    : STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL MemRead     : STD_LOGIC;
	SIGNAL ALUop       : STD_LOGIC_VECTOR( 1 DOWNTO 0 );
	SIGNAL Instruction : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	
	
	SIGNAL 	PC              : STD_LOGIC_VECTOR( 9 DOWNTO 0 );
	SIGNAL	ALU_result_out  : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL	read_data_1_out : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL	read_data_2_out : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL	write_data_out  : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL	Instruction_out : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL	Branch_out      : STD_LOGIC;
	SIGNAL	Jump_out        : STD_LOGIC;
	SIGNAL	JumpReg_out     : STD_LOGIC;
	SIGNAL	Zero_out        : STD_LOGIC;
	SIGNAL	Memwrite_out    : STD_LOGIC;
	SIGNAL	Regwrite_out    : STD_LOGIC;
	

BEGIN
	-- copy important signals to output pins for easy display in Simulator
	Instruction_out <= Instruction;
	ALU_result_out  <= ALU_result;
	read_data_1_out <= read_data_1;
	read_data_2_out <= read_data_2;
	write_data_out  <= read_data WHEN MemtoReg(0) = '1' ELSE ALU_result;
	Branch_out      <= Branch;
	Jump_out        <= Jump;
	JumpReg_out     <= JumpReg;
	Zero_out        <= Zero;
	RegWrite_out    <= RegWrite;
	MemWrite_out    <= MemWrite;
	

	----------------------------------------------------------------------------
	-- connect the 5 MIPS components 
	----------------------------------------------------------------------------  
	IFE : Ifetch
		PORT MAP (
			Instruction   => Instruction,
			PC_plus_4_out => PC_plus_4,
			Add_result    => Add_result,
			Branch        => Branch,
			Jump          => Jump,
			JumpReg       => JumpReg,
			Zero          => Zero,
			read_data_1   => read_data_1,
			PC_out        => PC,
			clock         => clk,
			reset         => rst
		);

	ID : Idecode
		PORT MAP (
			read_data_1 => read_data_1,
			read_data_2 => read_data_2,
			Instruction => Instruction,
			read_data   => read_data,
			ALU_result  => ALU_result,
			PC_plus_4   => PC_plus_4,
			RegWrite    => RegWrite,
			MemtoReg    => MemtoReg,
			RegDst      => RegDst,
			Sign_extend => Sign_extend,
			clock       => clk,
			reset       => rst
		);

	CTL : control
		PORT MAP (
			Opcode   => Instruction( 31 DOWNTO 26 ),
			Func     => Instruction( 5 DOWNTO 0 ),
			RegDst   => RegDst,
			ALUSrc   => ALUSrc,
			MemtoReg => MemtoReg,
			RegWrite => RegWrite,
			MemRead  => MemRead,
			MemWrite => MemWrite,
			Branch   => Branch,
			Jump     => Jump,
			JumpReg  => JumpReg,
			ALUop    => ALUop,
			clock    => clk,
			reset    => rst
		);

	EXE : Execute
		PORT MAP (
			read_data_1     => read_data_1,
			read_data_2     => read_data_2,
			Sign_extend     => Sign_extend,
			Function_opcode => Instruction( 5 DOWNTO 0 ),
			ALUOp           => ALUop,
			ALUSrc          => ALUSrc,
			Opcode          => Instruction( 31 DOWNTO 26 ),
			Zero            => Zero,
			ALU_Result      => ALU_Result,
			Add_Result      => Add_Result,
			PC_plus_4       => PC_plus_4,
			clock           => clk,
			Reset           => rst
		);

	MEM : dmemory
		PORT MAP (
			read_data  => data_from_memory,
			address    => ALU_Result (9 DOWNTO 2),
			write_data => read_data_2,
			MemRead    => MemRead,
			Memwrite   => write_to_memory_ena,
			clock      => clk,
			reset      => rst
		);

	----------------------------------------------------------------------------
	-- other instances
	----------------------------------------------------------------------------
	HEX0_conv : hex_to_7_segment
		PORT MAP (
			hex    => HEX0_reg,
			output => HEX0
		);

	HEX1_conv : hex_to_7_segment
		PORT MAP (
			hex    => HEX1_reg,
			output => HEX1
		);

	HEX2_conv : hex_to_7_segment
		PORT MAP (
			hex    => HEX2_reg,
			output => HEX2
		);

	HEX3_conv : hex_to_7_segment
		PORT MAP (
			hex    => HEX3_reg,
			output => HEX3
		);

	AddDec : AddressDecoder
		PORT MAP (
			Address  => ALU_Result (11 DOWNTO 2),
			HEX0_ena => HEX0_ena,
			HEX1_ena => HEX1_ena,
			HEX2_ena => HEX2_ena,
			HEX3_ena => HEX3_ena,
			LEDG_ena => LEDG_ena,
			LEDR_ena => LEDR_ena,
			SW_ena   => SW_ena
		);

	----------------------------------------------------------------------------
	read_data <= X"000000" & SW        WHEN SW_ena = '1' AND MemRead = '1' ELSE (OTHERS    => 'Z'); -- SW
	read_data <= X"000000" & LEDG_reg  WHEN LEDG_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');       -- LEDG
	read_data <= X"000000" & LEDR_reg  WHEN LEDR_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');       -- LEDR
	read_data <= X"0000000" & HEX0_reg WHEN HEX0_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');        -- HEX0
	read_data <= X"0000000" & HEX1_reg WHEN HEX1_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');        -- HEX1
	read_data <= X"0000000" & HEX2_reg WHEN HEX2_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');        -- HEX2
	read_data <= X"0000000" & HEX3_reg WHEN HEX3_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');        -- HEX3
	read_data <= data_from_memory      WHEN MEM_IO = '0' AND MemRead = '1' ELSE (OTHERS  => 'Z');   -- DMEMORY

	PROCESS (clk)
	BEGIN
		IF falling_edge(clk) THEN
			IF MemWrite = '1' THEN
				IF LEDG_ena = '1' THEN
					LEDG_reg <= read_data_2(7 DOWNTO 0);
				ELSIF LEDR_ena = '1' THEN
					LEDR_reg <= read_data_2(7 DOWNTO 0);
				ELSIF HEX0_ena = '1' THEN
					HEX0_reg <= read_data_2(3 DOWNTO 0);
				ELSIF HEX1_ena = '1' THEN
					HEX1_reg <= read_data_2(3 DOWNTO 0);
				ELSIF HEX2_ena = '1' THEN
					HEX2_reg <= read_data_2(3 DOWNTO 0);
				ELSIF HEX3_ena = '1' THEN
					HEX3_reg <= read_data_2(3 DOWNTO 0);
				END IF;
			END IF;
		END IF;
	END PROCESS;

	MEM_IO     <= ALU_Result(11); -- Read from 0: Memory, 1: IO
	write_to_memory_ena <= MemWrite AND (NOT MEM_IO) AND rst_in;

	LEDG <= LEDG_reg;
	LEDR <= LEDR_reg;
	
	rst <= not rst_in;
	
	process (clk_24MHz)
	begin
		if rising_edge(clk_24MHz) then
			clk <= NOT clk;
		end if;
	end process;
	
END structure;

