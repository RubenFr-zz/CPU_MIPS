-- Top Level Structural Model for MIPS Processor Core
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY MIPS IS

	PORT(
		rst_in          : IN  STD_LOGIC;
		clk_24MHz       : IN  STD_LOGIC;
		SW   			: IN  STD_LOGIC_VECTOR (7 DOWNTO 0);
		KEY	 			: IN  STD_LOGIC_VECTOR (2 DOWNTO 0);
		LEDG 			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		LEDR 			: OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
		HEX0 			: OUT STD_LOGIC_VECTOR (6 DOWNTO 0);   -- converted to 7-seg
		HEX1 			: OUT STD_LOGIC_VECTOR (6 DOWNTO 0);   -- converted to 7-seg
		HEX2 			: OUT STD_LOGIC_VECTOR (6 DOWNTO 0);   -- converted to 7-seg
		HEX3 			: OUT STD_LOGIC_VECTOR (6 DOWNTO 0); -- converted to 7-seg	
		-- UART INTERFACE
        UART_TXD     : out std_logic; -- serial transmit data
        UART_RXD     : in  std_logic; -- serial receive data
		
		-- Debug
		LEDR8, LEDR9			: OUT STD_LOGIC
	);
END MIPS;

ARCHITECTURE structure OF MIPS IS

	COMPONENT Ifetch
		PORT(
			Instruction   : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			PC_plus_4_out : OUT STD_LOGIC_VECTOR( 10 DOWNTO 0 );
			Add_result    : IN  STD_LOGIC_VECTOR( 8 DOWNTO 0 );
			Branch        : IN  STD_LOGIC;
			Jump          : IN  STD_LOGIC;
			JumpReg       : IN  STD_LOGIC;
			Zero          : IN  STD_LOGIC;
			read_data_1   : IN  STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			PC_out        : OUT STD_LOGIC_VECTOR( 10 DOWNTO 0 );
			clock, reset  : IN  STD_LOGIC;
			INTR		  : IN 	STD_LOGIC;
			INTA		  : buffer 	STD_LOGIC;
			ISR_address	  : IN	STD_LOGIC_VECTOR( 8 DOWNTO 0)		-- 9 BITS
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
			PC_plus_4        : IN  STD_LOGIC_VECTOR( 10 DOWNTO 0 );
			RegDst, MemtoReg : IN  STD_LOGIC_VECTOR( 1 DOWNTO 0 );
			Sign_extend      : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			clock, reset     : IN  STD_LOGIC;
			PC   			 : IN  STD_LOGIC_VECTOR( 10 DOWNTO 0 );
			GIE			 : OUT	STD_LOGIC
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
			Add_Result      : OUT STD_LOGIC_VECTOR( 8 DOWNTO 0 );
			PC_plus_4       : IN  STD_LOGIC_VECTOR( 10 DOWNTO 0 );
			clock, reset    : IN  STD_LOGIC
		);
	END COMPONENT;

	COMPONENT dmemory
		PORT(
			read_data         : OUT STD_LOGIC_VECTOR( 31 DOWNTO 0 );
			address           : IN  STD_LOGIC_VECTOR( 10 DOWNTO 0 );
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
	END COMPONENT;
	
	COMPONENT InterruptController is
	port (
		-- Interrupt Request (Hardware)
		RX_irq   : in std_logic; -- RX interrupt request (HW)
		TX_irq   : in std_logic; -- TX interrupt request (HW)
		BT_irq   : in std_logic; -- Basic Timer interrupt request (HW)
		KEY1_irq : in std_logic; -- KEY1 interrupt request (HW)
		KEY2_irq : in std_logic; -- KEY2 interrupt request (HW)
		KEY3_irq : in std_logic; -- KEY3 interrupt request (HW)

		-- Interrupt Registers
		GIE       : in  std_logic;                     -- Global Interrupt Enable (SW) -> $k0(0)
		IE        : in  std_logic_vector (5 downto 0); -- Interrupt Enable Register (SW)
		IFG_in       : in  std_logic_vector (5 downto 0); -- Interrupt Flag Register (SW)
		IFG_out       : out  std_logic_vector (7 downto 0); -- Interrupt Flag Register (SW)
		IFG_write : in  std_logic;                     -- Data in IFG ready to be used
		TYPEx    : out std_logic_vector (8 downto 0); -- Type Register

		-- CPU
		INTA : in  std_logic; -- '0': ACK (Interrupt Acknolwdge)
		INTR : out std_logic;  -- Interrupt request
		
		-- Clear Flag 
		clr_BT, clr_RX, clr_TX : in boolean
		-- clr_KEY1, clr_KEY2, clr_KEY3 : in boolean
	);
	end COMPONENT InterruptController;
	
	
	COMPONENT BasicTimer is
	PORT (
		MCLK, reset : in  std_logic;
		BTCTL       : in  std_logic_vector (7 downto 0);  -- Basic Timer Control Register
		BTCNT       : in  std_logic_vector (31 downto 0); -- Basic Timer Counter (init)
		BTIFG       : out std_logic                       -- Basic Timer Flag
	);
	end COMPONENT BasicTimer;
	
	COMPONENT UART is
    Generic (
        CLK_FREQ      : integer := 50e6;   -- system clock frequency in Hz
        BAUD_RATE     : integer := 115200; -- baud rate value
        USE_DEBOUNCER : boolean := True    -- enable/disable debouncer
    );
    Port (
        -- CLOCK AND RESET
        CLK          : in  std_logic; -- system clock
        RST          : in  std_logic; -- high active synchronous reset
        -- UART INTERFACE
        UART_TXD     : out std_logic; -- serial transmit data
        UART_RXD     : in  std_logic; -- serial receive data
        -- USER DATA INPUT INTERFACE
        DIN          : in  std_logic_vector(7 downto 0); -- input data to be transmitted over UART
        DIN_VLD      : in  std_logic; -- when DIN_VLD = 1, input data (DIN) are valid
        DIN_RDY      : out std_logic; -- when DIN_RDY = 1, transmitter is ready and valid input data will be accepted for transmiting
        -- USER DATA OUTPUT INTERFACE
        DOUT         : out std_logic_vector(7 downto 0); -- output data received via UART
        DOUT_VLD     : out std_logic; -- when DOUT_VLD = 1, output data (DOUT) are valid (is assert only for one clock cycle)
        FRAME_ERROR  : out std_logic; -- when FRAME_ERROR = 1, stop bit was invalid (is assert only for one clock cycle)
        PARITY_ERROR : out std_logic;  -- when PARITY_ERROR = 1, parity bit was invalid (is assert only for one clock cycle)
		
		-- Added
		PARITY_BIT    : in std_logic_vector(1 downto 0); 	-- type of parity: -0: "none", 01: "odd", 11: "even"
		DIN_FINISHED : out std_logic;	-- When TX finishes sending DIN
		RX_BUSY		 : out std_logic
    );
	end COMPONENT UART;

	----------------------------------------------------------------------------
	-- SIGNAL ADDED
	----------------------------------------------------------------------------
	SIGNAL HEX0_reg : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
	SIGNAL HEX1_reg : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
	SIGNAL HEX2_reg : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
	SIGNAL HEX3_reg : STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
	SIGNAL LEDG_reg : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL LEDR_reg : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
	
	-- Added registers for UART support
	SIGNAL UCTL_reg : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL RXBF_reg : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL TXBF_reg : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
	
	-- Added registers for timer support
	SIGNAL BTCTL_reg: STD_LOGIC_VECTOR (7 DOWNTO 0) := (5 => '1', OTHERS => '0');
	SIGNAL BTCNT_reg: STD_LOGIC_VECTOR (31 DOWNTO 0) := (OTHERS => '0');
	
	-- Added registers for interrupt support
	SIGNAL IE_reg   : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL IFG_in  : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL IFG_out  : STD_LOGIC_VECTOR (7 DOWNTO 0) := (OTHERS => '0');
	SIGNAL TYPE_reg : STD_LOGIC_VECTOR (8 DOWNTO 0) := (OTHERS => '0');

	SIGNAL data_from_memory : STD_LOGIC_VECTOR (31 DOWNTO 0);

	SIGNAL ioWrite : STD_LOGIC;
	SIGNAL ioRead  : STD_LOGIC;
	SIGNAL MEM_IO  : STD_LOGIC;
	SIGNAL write_to_memory_ena : STD_LOGIC;

	SIGNAL HEX0_ena, HEX1_ena, HEX2_ena, HEX3_ena : STD_LOGIC;
	SIGNAL LEDG_ena, LEDR_ena, SW_ena             : STD_LOGIC;
	SIGNAL KEY_ena, UCTL_ena, RXBF_ena, TXBF_ena, BTCTL_ena, 
			 BTCNT_ena, IE_ena, IFG_ena, TYPE_ena : STD_LOGIC;
	SIGNAL rst : STD_LOGIC := '1';
	SIGNAL clk: std_LOGIC := '0';

	----------------------------------------------------------------------------
	-- declare signals used to connect VHDL components
	----------------------------------------------------------------------------
	SIGNAL PC_plus_4   : STD_LOGIC_VECTOR( 10 DOWNTO 0 );
	SIGNAL read_data_1 : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL read_data_2 : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Sign_Extend : STD_LOGIC_VECTOR( 31 DOWNTO 0 );
	SIGNAL Add_result  : STD_LOGIC_VECTOR( 8 DOWNTO 0 );
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
	
	
	SIGNAL 	PC              : STD_LOGIC_VECTOR( 10 DOWNTO 0 );
	
	-- Added signals for interrupt support
	
	SIGNAL GIE					: STD_LOGIC := '0';						-- global interrupt enable - inserted from the IDECODE
	SIGNAL INTA					: STD_LOGIC := '1';
	SIGNAL INTR,INTRx					: STD_LOGIC  :='0';
	SIGNAL Next_Address 		: STD_LOGIC_VECTOR(10 DOWNTO 0);
	SIGNAL IFG_write 			: STD_LOGIC := '0';
	
	-- Added signals for timer support
	
	SIGNAL TimerFlag			: STD_LOGIC;
	
	-- Added signals for UART support
	
	SIGNAL TX_VLD,TX_RDY 	: STD_LOGIC;
	SIGNAL RX_irq, TX_irq	: STD_LOGIC := '0';
	-- SIGNAL BAUD_RATE     : integer;
	-- SIGNAL PARITY_BIT    : std_logic_vector ( 1 downto 0 ); 
	-- SIGNAL rst_UART		: std_LOGIC;
	SIGNAL BUSY_UCTL, OE_UCTL: STD_LOGIC := '0';
	SIGNAL RX_BUSY : STD_LOGIC;
	
	-- Added to clear BTIFG 
	signal clr_BT : boolean := false;
	signal clr_RX : boolean := false;
	signal clr_TX : boolean := false;
	-- signal clr_KEY1, clr_KEY2, clr_KEY3 : boolean := false;
	

BEGIN	
	-- make sure next address is ISR address in case of interrupt, or normal address otherwise
	Next_Address <= 	
			"00" & TYPE_reg(8 DOWNTO 2) & "00" WHEN INTRx ='1' 
			ELSE	ALU_Result(10 DOWNTO 2) & "00";	

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
			INTR		  => INTRx,					-- interrupt request (clock synced)
			INTA		  => INTA,						-- INTAck output: if 0 then acknowledge back to the interruptController
			ISR_address	  => data_from_memory(10 DOWNTO 2),	-- the ISR address brought from the dmemory - taken as word
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
			PC			=> PC,
			GIE		=> GIE,
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
			address    => Next_Address,
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
			Address  => ALU_Result (11 DOWNTO 0),
			HEX0_ena => HEX0_ena,
			HEX1_ena => HEX1_ena,
			HEX2_ena => HEX2_ena,
			HEX3_ena => HEX3_ena,
			LEDG_ena => LEDG_ena,
			LEDR_ena => LEDR_ena,
			SW_ena   => SW_ena,
			KEY_ena  => KEY_ena,  
			UCTL_ena => UCTL_ena, 
			RXBF_ena => RXBF_ena, 
			TXBF_ena => TXBF_ena, 
			BTCTL_ena=> BTCTL_ena,
			BTCNT_ena=> BTCNT_ena,
			IE_ena 	 => IE_ena, 	 
			IFG_ena  => IFG_ena,  
			TYPE_ena => TYPE_ena 
			
			
			
		);
		
	IntrptControl : InterruptController
		PORT MAP (
			RX_irq   		=>	RX_irq,		-- When RX_irq is set, that means the Receiver buffer is full
		    TX_irq          =>	TX_irq,		-- When TX_RDY is set, that means the transmitter finished sending
		    BT_irq          =>	TimerFlag,
		    KEY1_irq        =>	not KEY(0),
		    KEY2_irq        =>  not KEY(1),
		    KEY3_irq        =>  not KEY(2),
		    GIE             =>	GIE,
		    IE              =>	IE_reg(5 DOWNTO 0),
		    IFG_in          =>	IFG_in(5 DOWNTO 0),
		    IFG_out         =>	IFG_out,
		    IFG_write       =>	IFG_write,
		    TYPEx           =>	TYPE_reg,
		    INTA 	        =>	INTA,
		    INTR 	        =>	INTR,
		
			clr_BT			=> clr_BT,
			clr_RX			=> clr_RX,
			clr_TX			=> clr_TX
			-- clr_KEY1		=> clr_KEY1,
			-- clr_KEY2		=> clr_KEY2,
			-- clr_KEY3		=> clr_KEY3
			
		);

	Timer : BasicTimer
	PORT MAP (
		MCLK 	=>	clk,
		reset   =>	rst,
		BTCTL   =>  BTCTL_reg,		-- Basic Timer Control Register
		BTCNT   =>  BTCNT_reg,   	-- Basic Timer Counter (init)
		BTIFG   =>  TimerFlag   	-- Basic Timer Flag
	);
	
	UART_inst : UART
	GENERIC MAP(
        CLK_FREQ      => 12e6   -- system clock frequency in Hz
	)
	PORT MAP(
        -- CLOCK AND RESET
        CLK      => clk,    
        RST      => rst,   
        -- UART INTERFACE
        UART_TXD     => UART_TXD,
        UART_RXD     => UART_RXD,
        -- USER DATA INPUT INTERFACE
        DIN          => TXBF_reg,
        DIN_VLD      => TX_VLD,  
        DIN_RDY      => TX_RDY,
        -- USER DATA OUTPUT INTERFACE
        DOUT        => RXBF_reg, 
        DOUT_VLD     => RX_irq,
        FRAME_ERROR  => UCTL_reg(4),
        PARITY_ERROR  => UCTL_reg(5),
		
		-- ADDED
		PARITY_BIT	=> UCTL_reg(2 downto 1),
		DIN_FINISHED => TX_irq,
		RX_BUSY => RX_BUSY
    );
	----------------------------------------------------------------------------
	--READ FROM I/O REGISTERS
	----------------------------------------------------------------------------
	read_data <= X"000000" & SW        		WHEN SW_ena = '1' AND MemRead = '1' ELSE (OTHERS    => 'Z');		 -- SW
	read_data <= X"000000" & LEDG_reg  		WHEN LEDG_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');      	 -- LEDG
	read_data <= X"000000" & LEDR_reg  		WHEN LEDR_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');      	 -- LEDR
	read_data <= X"0000000" & HEX0_reg 		WHEN HEX0_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');       	 -- HEX0
	read_data <= X"0000000" & HEX1_reg 		WHEN HEX1_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');       	 -- HEX1
	read_data <= X"0000000" & HEX2_reg 		WHEN HEX2_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');       	 -- HEX2
	read_data <= X"0000000" & HEX3_reg 		WHEN HEX3_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');       	 -- HEX3
	
	-- read data from keys when required
	read_data <= X"0000000" & B"0" & KEY 	WHEN KEY_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');       	 -- KEY
	
	-- read data from UART when required
	read_data <= X"000000" & UCTL_reg 		WHEN UCTL_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');       	 -- UCTL
	read_data <= X"000000" & RXBF_reg 		WHEN RXBF_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');       	 -- RXBF
	read_data <= X"000000" & TXBF_reg 		WHEN TXBF_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');       	 -- TXBF
	
	-- read data from counter when required
	read_data <= X"000000" & BTCTL_reg 		WHEN BTCTL_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');        -- BTCTL
	read_data <= BTCNT_reg 					WHEN BTCNT_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');        -- BTCNT
	
	-- read data from interrupt controller when required
	read_data <= X"000000" & IE_reg 		WHEN IE_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');       	 -- IE
	read_data <= X"000000" & IFG_out		WHEN IFG_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');       	 -- IFG
	read_data <= X"00000" & b"000" & TYPE_reg 		WHEN TYPE_ena = '1' AND MemRead = '1' ELSE (OTHERS  => 'Z');       	 -- TYPE
	
	
	-- read data from memory as usual when nothing else is required
	read_data <= data_from_memory      WHEN MEM_IO = '0' AND MemRead = '1' ELSE (OTHERS  => 'Z');   -- DMEMORY

	----------------------------------------------------------------------------
	--WRITE TO I/O REGISTERS
	----------------------------------------------------------------------------
	PROCESS (clk, rst)
	BEGIN
		IF rst = '1' then
			BTCTL_reg <= (5 => '1', OTHERS => '0');		-- Hold
			IFG_in <= (others => '0');
		ELSIF falling_edge(clk) THEN
			IFG_write <= '0';
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
				ELSIF UCTL_ena = '1' THEN
					UCTL_reg(3 downto 0) <= read_data_2(3 DOWNTO 0);
				ELSIF TXBF_ena = '1' THEN
					TXBF_reg <= read_data_2(7 DOWNTO 0);
				ELSIF BTCTL_ena = '1' THEN
					BTCTL_reg <= read_data_2(7 DOWNTO 0);
				ELSIF BTCNT_ena = '1' THEN
					BTCNT_reg <= read_data_2(31 DOWNTO 0);
				ELSIF IE_ena = '1' THEN
					IE_reg <= read_data_2(7 DOWNTO 0);
				ELSIF IFG_ena = '1' THEN
					IFG_in <= read_data_2(7 DOWNTO 0);
					IFG_write <= '1';
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
	process (clk, rst)
	begin
		if rst = '1' then
			TX_VLD <= '0';
		elsif falling_edge(CLK) then	
			if TXBF_ena = '1' and MemWrite = '1' then
				TX_VLD <= '1';
			elsif TX_RDY = '0' then
				TX_VLD <= '0';
			end if;
		end if;
	end process;
	
	MEM_IO     <= ALU_Result(11); -- Read from 0: Memory, 1: IO (ALU_Result doesn't start with 8)
	write_to_memory_ena <= MemWrite AND (NOT MEM_IO) AND rst_in;

	LEDG <= LEDG_reg;
	LEDR <= LEDR_reg;
	

	UCTL_reg(6) <= OE_UCTL;
	UCTL_reg(7) <= BUSY_UCTL;
	
	BUSY_UCTL <= TX_RDY or RX_BUSY;
	
	-- PARITY_BIT <=
		-- "none" when UCTL_reg(1) = '0' else
		-- "odd" when UCTL_reg(2) = '0' else
		-- "even";
	
	-- If we are handling a rx interrupt and also a new rx interrupt was received, set uart overrun flag
	process(RX_irq,rst)
	begin
		if rst = '1' then
			OE_UCTL <= '0';
		elsif rising_edge(RX_irq) then
			OE_UCTL <= IFG_out(0);
		end if;
	end process;
	
	
	
	rst <= not rst_in;

	clr_RX <= (INTRx = '0' and INTA = '0' and TYPE_reg = "000001000") or rst = '1';
	clr_TX <= (INTRx = '0' and INTA = '0' and TYPE_reg = "000001100") or rst = '1';
	clr_BT <= (INTRx = '0' and INTA = '0' and TYPE_reg = "000010000") or rst = '1';
	-- clr_KEY1 <= (INTRx = '0' and INTA = '0' and TYPE_reg = "000010100") or rst = '1';
	-- clr_KEY2 <= (INTRx = '0' and INTA = '0' and TYPE_reg = "000011000") or rst = '1';
	-- clr_KEY3 <= (INTRx = '0' and INTA = '0' and TYPE_reg = "000011100") or rst = '1';
	
	LEDR8 <= TX_RDY;
	LEDR9 <= GIE;
	
	process(clk,rst)
	begin
		if rst = '1' then
			INTRx <= '0';
		elsif rising_edge(CLK) then
			INTRx <= INTR;
		end if;
	end process;
	
	process (clk_24MHz)
	begin
		if rising_edge(clk_24MHz) then
			clk <= NOT clk;
		end if;
	end process;
	
END structure;

