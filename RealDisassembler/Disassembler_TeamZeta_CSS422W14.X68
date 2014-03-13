*-------------------------------------------------------------
* Title      :Team Zeta 68k Disassembler, CSS 422 Winter 2014
* Written by :Brandon Roth, Dwayne Honeycutt, Teresia Djunaedi
* Date       :3/11/2014
* Description:
* This program disassembles a subset of 68k assembly instructions. 
* ***visit this later, describe what it does, how to use it, assumptions, etc.
*-------------------------------------------------------------
ST_ADDR 	EQU $7FC0   *Starting address of input test file
STACK   	EQU $7000   *Stack location
START   	ORG $1000   *Start program at provided location	
			LEA	stack,SP


*-----------------------------------------------------------
* Start of I/O
*-----------------------------------------------------------        	
        	LEA     MESSAGE,A1  *Loads MESSAGE into address register A1
        	MOVE.B  #14,D0      *Moves the number 14 into data register D0
        	TRAP    #15         *Displays Message
        
loop_1     	MOVE	#0,D0		
			LEA		STARTASSEM,A1	*Fix the bug that takes the input but outputs the input back out.
        	MOVE.B	#14,D0
        	TRAP	#15    
        	MOVE	#2,D0
        	LEA		CMD_HLD,A1	*Store the command in a buffer
           	*TRAP	#15
        	BRA		CHECK_UPY

*-----------------------------------------------------------
* I/O: Input check for Y, y, N, n
*-----------------------------------------------------------
CHECK_UPY	CMPI.B	#$59,(A1)	*Checks for uppercase Y
			BNE		CHECK_LOWy
			BEQ		NXT_CMD
			
CHECK_LOWy	CMPI.B	#$79,(A1)	*Checks for lowercase y
			BNE		CHECK_UPN
			BEQ		NXT_CMD
			
CHECK_UPN	CMPI.B	#$4E,(A1)	*Checks for uppercase N
			BEQ		DONE
			BNE		CHECK_LOWn
			
CHECK_LOWn	CMPI.B	#$6E,(A1)	*Checks for lowercase n
			BNE		INVALID1
			BEQ		DONE
			
INVALID1	MOVE	#0,D0		*Prints invalid command msg if not found
			LEA		INV_MSG,A1
			MOVE	#14,D0
			TRAP	#15
			*JMP		loop_1
			
INV_STRT1	LEA		INVSTRTMSG,A1
			MOVE.B	#14,D0
			TRAP	#15
			JMP		NXT_CMD		

*-----------------------------------------------------------
*
* I/O: Check Start Address
*
* Make sure that start address starts after allocated 
* memory addresses. Else, it will print out a message 
* saying that requested address is invalid & prompts the
* user again for the starting address.
*-----------------------------------------------------------
NXT_CMD 	LEA		GETSTRTADDR,A1	*Ask start address once everything is OK.
			MOVE.B	#14,D0
			TRAP	#15
			LEA		CMD_HLD,A1	*Need to change where it can hold the start/end address
			MOVE	#2,D0			*Get start address
        	*TRAP	#15
        	MOVE.L	(A1),D4
        	*JSR		CHECKSTRT1
CHECKSTRT1	CMPI.L	#08,D1		*Check if size 
			BGT		INV_STRT1
			CMPI.L	#00,D1
			*BLS		INV_STRT1
			*RTS			

*-----------------------------------------------------------        
* Start of Disassembler
*-----------------------------------------------------------
        MOVEA.L #ST_ADDR,A0 *Load starting location of test input file into A0
        
GRAB_NEXT_OP
        *Move word data at (A0) into D0. D0 should now hold the entire 16 bits of the
        *next OP CODE instruction to disassemble, EXCLUDING any immediate/absolute 
        *data that may be associated with the instruction.
        *Post increment addr, A0 will point to the start of next instruction or will 
        *point to the start of any immed/abso data with this current instruction
        CLR.L   D0
        MOVE.W  (A0)+,D0
        *Copy the word data we just moved into D0 into D7. We are copying this data
        *So we always have a copy of the WHOLE instruction somewhere
        CLR.L   D7
        MOVE.W  D0,D7
        *Now shift D0 to the right by 12 bit values, so that we can isolate the first
        *four bits of the instruction. Once we have just the first four bits, we can
        *begin to see which 'bucket'/category this instruction falls into. 
        LSR.W   #$08,D0 *The max we can shift at once is 8 bits...
        LSR.W   #$04,D0
        *Now try to figure out what OP CODE this is using these 4 bits. Run down the
        *list of buckets until we find which one this instruction falls into.


*-----------------------------------------------------------        
* Bucket 0000:
* STARTS WITH 0000, ADDI | ANDI | EORI----------------------
*                   BCHG(dynamic) | BCHG (static) | CMPI----
*-----------------------------------------------------------
BUCKET_0000
BUCKET0000_BITS EQU $0
        CLR.L   D1
        *Load the first 4 bits (really a byte) of BUCKET0 into D1
        MOVE.B  #BUCKET0000_BITS,D1
        *Compare the first 4 bits of the CURRENT instruction with first 4 of BUCKET0. 
        *If equal, continue decoding. If not, branch to next bucket.
        CMP.B   D0,D1
        BNE     BUCKET_0001

        *Test the 8th bit in this instruction, if it is 1, then it is a BCHG(dynamic) 
        *The zbit will be 1 if the bit is 0, and 0 if the bit is 1. 
        MOVE.W  D7,D0   *Move the WHOLE instruction back to D0
        BTST.L  #$08,D0
        BNE     IS_BCHG_D  *If the zbit was 0 (the 8th bit is 1), branch to ISBCHG_D
        
        *Now we can check bits 11-8 in the instruction and branch to different op-codes
        *depending on what the bits equal, without ambiguity due to BCHG(dynamic)
        LSR.W   #$08,D0 *Shift the first 8 bits into LSB position
        BCLR.L  #$04,D0 *Set first 4 bits to 0, leaving only bits 11-8 of the instruction
        BCLR.L  #$05,D0
        BCLR.L  #$06,D0
        BCLR.L  #$07,D0
        
        *Perform compares with these 4 bits to see which specific instruction it is.
        CMP.B   #$06,D0 *Is this an ADDI?
        BEQ     IS_ADDI
        CMP.B   #$02,D0 *Is this an ANDI?
        BEQ     IS_ANDI
        CMP.B   #$0A,D0 *Is this an EORI?
        BEQ     IS_EORI
        CMP.B   #$08,D0 *Is this a BCHG(static)?
        BEQ     IS_BCHG_S
        CMP.B   #$0C,D0 *Is this a CMPI?
        BEQ     IS_CMPI
        
        *If we get through all of the compares without finding the specific instruction,
        *then this instruction is either not in our list of OP CODES to decode, or is an
        *invalid instruction/syntax.
        JMP     BADOPCODE   *jump to BADOPCODE, where i/o will take care of it.


*Now we know this instruction is exactly ADDI, lets set everything up for EA.
IS_ADDI
        *Verify the size of this operation. If incorrect size (%11), then bad opcode!
        *Set D0 to the 'size' of the operation located in bits 7 and 6 of the instruction
        MOVE.W  D7,D1       *Move the WHOLE instruction to D1
        AND.W   #$00C0,D1   *Mask out everything but the size bits
        LSR.B   #$06,D1     *Shift the size bits into LSB
        
        CMP.B   #$03,D1     *Compare the size bits to $3
        BEQ     BADOPCODE   *if equal, bad op code, size shouldn't be (%11)
        
        *Output 'ADDI' to console...
        LEA     ADDI,A1  *Loads FNDADDI into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        
        *Should have a valid ADDI op code. Set data up for EA.
         
        *Set D1 to the EA mode of the operation located in bits 5-3 of the instruction
        MOVE.W  D7,D2       *Move the WHOLE instruction to D2
        AND.W   #$003C,D2   *Mask out everything but the EA mode bits
        LSR.B   #$03,D2     *Shift the EA mode bits into LSB
                
        *Set D3 to the EA register of the operation located in bits 2-0 of the instruction
        MOVE.W  D7,D3       *Move the WHOLE instruction to D3
        AND.W   #$0007,D3   *Mask out everything but the EA register bits
        
        JMP     EA_ADDI

EA_ADDI
        *Decode the ea bits of ADDI. Assuming D1 holds the size, D2 holds the EA mode,
        *and D3 holds the EA register.
        
        *Determine how much data to read in, depending on the size of the operation
        *output the size of the operation and the immediate data to console
        JSR     WrapperSizeImmediate
        
        *Determine which EA mode and thus Register/Mem Address this instruction used
        CMP.B   #$00,D2
        BEQ     DataRegMode *If EA mode is a data register, output that
        
        CMP.B   #$02,D2
        BEQ     AddrDirectMode  *If EA mode is an addr indirect, output that
        
        CMP.B   #$03,D2
        BEQ     AddrIndirectPostMode    *If EA mode is an addr indirect postinc, output that
        
        CMP.B   #$04,D2
        BEQ     AddrIndirectPreMode    *If EA mode is an addr indirect predec, output that
        
        CMP.B   #$07,D2
        BEQ     AddrAbsoluteMode    *If EA mode is an addr absolute word/long, output that
        
        *If the ea mode isn't equal to any of these, it is an invalid EA
        JMP     BADEACODE                                


*Now we know this instruction is exactly ANDI, lets set everything up for EA.
IS_ANDI
        *TODO:Verify bits

        *Output 'ANDI' to console...
        LEA     ANDI,A1  *Loads FNDANDI into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        *Should have a valid ANDI op code. Set data up for EA.
        *TODO:
        MOVE.B  #14,D3
        JMP     EA_ANDI

EA_ANDI
        JMP     THEEND  *For now just end


*Now we know this instruction is exactly EORI, lets set everything up for EA.
IS_EORI
		*TODO:Verify bits

		*Output 'EORI' to console...
        LEA     EORI,A1  *Loads FNDEORI into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        *Should have a valid EORI op code. Set data up for EA.
        *TODO:
        MOVE.B  #14,D3
        JMP     EA_EORI

EA_EORI
        JMP     THEEND  *For now just end


*Found a possible BCHG(dynamic) instruction. Verify its bit integrity and then set
* everything up for EA if is a legit instruction. Assuming D0 holds full instruction.
IS_BCHG_D
        MOVE.W  D7,D0   *Move the WHOLE instruction back to D0
        
        *Check bits 7 and 6, these should be 0 and 1. If not, this instruction is
        *invalid, branch to BADOPCODE
        BTST.L  #$07,D0
        BNE     BADOPCODE  *If the zbit was 0 (the 7th bit is 1), branch to BADOPCODE
        BTST.L  #$06,D0
        BEQ     BADOPCODE  *If the zbit was 1 (the 6th bit is 0), branch to BADOPCODE
        
        *Output 'BCHG(dynamic)' to console...
        LEA     BCHG_D,A1    *Loads FNDBCHG_D into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message
                
        *Should have a valid BCHG(dynamic) op code. Set data up for EA.
        *TODO:
        MOVE.B  #14,D3
        JMP     EA_BCHG_D

EA_BCHG_D
        JMP     THEEND  *For now just end


*Now we know this instruction is exactly BCHG(static), lets set everything up for EA.
IS_BCHG_S
		*TODO:Verify bits

		*Output 'BCHG_S' to console...
        LEA     BCHG_S,A1    *Loads FNDBCHG_S into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message
        
        *Should have a valid BCHG_S op code. Set data up for EA.
        *TODO:
        MOVE.B  #14,D3
        JMP     EA_BCHG_S

EA_BCHG_S
        JMP     THEEND  *For now just end


*Now we know this instruction is exactly CMPI, lets set everything up for EA.
IS_CMPI
		*TODO:Verify bits

		*Output 'CMPI' to console...
        LEA     CMPI,A1  *Loads FNDCMPI into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        *Should have a valid CMPI op code. Set data up for EA.
        *TODO:
        MOVE.B  #14,D3
        JMP     EA_CMPI

EA_CMPI
        JMP     THEEND  *For now just end


*STARTS WITH 0001, MOVE.B-----------------------------------
BUCKET_0001
BUCKET0001_BITS EQU $1
        
        *some code...


*STARTS WITH 0010, MOVE.L-----------------------------------
BUCKET_0010
BUCKET0010_BITS EQU $2

        *some code...


*STARTS WITH 0011, MOVE.W-----------------------------------
BUCKET_0011
BUCKET0011_BITS EQU $3

        *some code...


*STARTS WITH 0100, MOVEM | MULS(L) | LEA | CLR | JSR | RTS--
BUCKET_0100
BUCKET0100_BITS EQU $4

        *some code...


*STARTS WITH 0101, SUBQ-------------------------------------
BUCKET_0101
BUCKET0101_BITS EQU $5

        *some code...


*STARTS WITH 0110, BCC--------------------------------------
BUCKET_0110
BUCKET0110_BITS EQU $6

        *some code...


*STARTS WITH 1000, DIVU-------------------------------------
BUCKET_1000
BUCKET1000_BITS EQU $8

        *some code...


*STARTS WITH 1001, SUBA-------------------------------------
BUCKET_1001
BUCKET1001_BITS EQU $9

        *some code...


*STARTS WITH 1011, EOR | CMP | CMPA-------------------------
BUCKET_1011
BUCKET1011_BITS EQU $B

        *some code...


*STARTS WITH 1100, MULS(W) | AND----------------------------
BUCKET_1100
BUCKET1100_BITS EQU $C

        *some code...


*STARTS WITH 1101, ADD | ADDA-------------------------------
BUCKET_1101
BUCKET1101_BITS EQU $D

        *some code...


*STARTS WITH 1110, ASR(REGSHIFT) | ASR(MEMSHIFT)------------
*                  LSL(REGSHIFT) | LSL(MEMSHIFT)------------
*                  ROL/ROR(REGROTATE) | ROLS/ROR(MEMROTATE)-
BUCKET_1110
BUCKET1110_BITS EQU $E     

        *some code...


*The given OP CODE doesn't fall into any buckets, this is an invalid opcode
*for this disassembler, jump to BADOPCODE and let I/O take care of it
        JMP     BADOPCODE  
        

*-----------------------------------------------------------        
* EA operation size decoding functionality
*-----------------------------------------------------------   
*'Wrapper' func used for all ea decoding. Used to do the nasty branching for diff sizes
WrapperSizeImmediate
        CLR.L   D4
        CMP.B   #$00,D1     *If the size of operation is byte, get immediate data/output
        BEQ     ByteSizeImmediate
        
        CMP.B   #$01,D1     *If the size of operation is word, get immediate data/output
        BEQ     WordSizeImmediate

        CMP.B   #$02,D1     *If the size of operation is long, get immediate data/output
        BEQ     LongSizeImmediate
        
*Used to get back to what we were doing, after dealing with the specific size
WrapperSizeImmediateEnd
        RTS
     
ByteSizeImmediate
        MOVE.W  (A0)+,D4    *read in the next word, data is the last 2 chars of word
        
        *Output '.B' to console...
        LEA     ByteSize,A1 *Loads ByteSize into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        *HOW TO OUTPUT THE CONTENTS OF A REGISTER (D4)?
        *Output some message, the immediate data is...
        *LEA     FNDADDI,A1  *Loads FNDADDI into address register A1
        *MOVE.B  #14,D0      *Moves the number 14 into data register D0
        *TRAP    #15         *Displays Message
        
        JMP     WrapperSizeImmediateEnd
                
WordSizeImmediate
        MOVE.W  (A0)+,D4    *read in next word, data is that word
        
        *Output '.W' to console...
        LEA     WordSize,A1 *Loads WordSize into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        *HOW TO OUTPUT THE CONTENTS OF A REGISTER (D4)?
        *Output some message, the immediate data is...
        *LEA     FNDADDI,A1  *Loads FNDADDI into address register A1
        *MOVE.B  #14,D0      *Moves the number 14 into data register D0
        *TRAP    #15         *Displays Message
        
        JMP     WrapperSizeImmediateEnd
                
LongSizeImmediate
        MOVE.L  (A0)+,D4    *read in next two words, data is those two words
        
        *Output '.L' to console...
        LEA     LongSize,A1 *Loads LongSize into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        *HOW TO OUTPUT THE CONTENTS OF A REGISTER (D4)?
        *Output some message, the immediate data is...
        *LEA     FNDADDI,A1  *Loads FNDADDI into address register A1
        *MOVE.B  #14,D0      *Moves the number 14 into data register D0
        *TRAP    #15         *Displays Message
        
        JMP     WrapperSizeImmediateEnd


*-----------------------------------------------------------        
* EA Mode/EA Register decoding functionality
*-----------------------------------------------------------        
DataRegMode
        *Depending on the EA Register, output a different register number
        JSR     WrapperDataReg
        
        *Nothing else to do here, should maybe go straight to next instruction and not back
        *to the EA_ADDI portion?

AddrDirectMode
        *some code...

AddrIndirectMode
        JSR     WrapperAddrIndirect
                        
        *Nothing else to do here, should maybe go straight to next instruction and not back
        *to the EA_ADDI portion?

AddrIndirectPostMode
        *Depending on the EA Register, output a different register number
        

        *Nothing else to do here, should maybe go straight to next instruction and not back
        *to the EA_ADDI portion?

AddrIndirectPreMode
        *Depending on the EA Register, output a different register number

        *Nothing else to do here, should maybe go straight to next instruction and not back
        *to the EA_ADDI portion?

AddrAbsoluteMode
        *Depending on the EA Register, output a different register number

        *READ IN THE NEXT WORD ADDRESS OR LONG ADDRESS, DEPENDING ON EA REGISTER, ALSO OUTPUT

        *Nothing else to do here, should maybe go straight to next instruction and not back
        *to the EA_ADDI portion?
        
ImmediateDataMode
        *some code      


*-----------------------------------------------------------        
* Output logic for all Data Registers (0-7)
*-----------------------------------------------------------     
*'Wrapper' func used for outputing the correct register. Used to do the nasty branching
WrapperDataReg
        CMP.B   #$00,D3
        BEQ     DataReg0
        
        CMP.B   #$01,D3
        BEQ     DataReg1
        
        CMP.B   #$02,D3
        BEQ     DataReg2
        
        CMP.B   #$03,D3
        BEQ     DataReg3
        
        CMP.B   #$04,D3
        BEQ     DataReg4
        
        CMP.B   #$05,D3
        BEQ     DataReg5
        
        CMP.B   #$06,D3
        BEQ     DataReg6
        
        CMP.B   #$07,D3
        BEQ     DataReg7        

*Used to get back to 'DataRegMode', after dealing with the specific register
WrapperDataRegEnd
        RTS

DataReg0
        *Output some message, EA mode is data register 0...
        LEA     OutDataReg0,A1  *Loads DataReg0 into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message   
        
        JMP     WrapperDataRegEnd

DataReg1
        LEA     OutDataReg1,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperDataRegEnd

DataReg2
        LEA     OutDataReg2,A1
        MOVE.B  #14,D0
        TRAP    #15

        JMP     WrapperDataRegEnd
    
DataReg3
        LEA     OutDataReg3,A1
        MOVE.B  #14,D0
        TRAP    #15

        JMP     WrapperDataRegEnd
        
DataReg4
        LEA     OutDataReg4,A1
        MOVE.B  #14,D0
        TRAP    #15

        JMP     WrapperDataRegEnd
               
DataReg5
        LEA     OutDataReg5,A1
        MOVE.B  #14,D0
        TRAP    #15

        JMP     WrapperDataRegEnd
        
DataReg6
        LEA     OutDataReg6,A1 A1
        MOVE.B  #14,D0
        TRAP    #15

        JMP     WrapperDataRegEnd
        
DataReg7
        LEA     OutDataReg7,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperDataRegEnd


*-----------------------------------------------------------        
* Output logic for all Address Indirec Registers (0-7)
*-----------------------------------------------------------     
*'Wrapper' func used for outputing the correct register. Used to do the nasty branching
WrapperAddrIndirect
        *Depending on the EA Register, output a different register number
        CMP.B   #$00,D3
        BEQ     AddrIndReg0
        
        CMP.B   #$01,D3
        BEQ     AddrIndReg1
        
        CMP.B   #$02,D3
        BEQ     AddrIndReg2
        
        CMP.B   #$03,D3
        BEQ     AddrIndReg3
        
        CMP.B   #$04,D3
        BEQ     AddrIndReg4
        
        CMP.B   #$05,D3
        BEQ     AddrIndReg5
        
        CMP.B   #$06,D3
        BEQ     AddrIndReg6
        
        CMP.B   #$07,D3
        BEQ     AddrIndReg7

*Used to get back to 'AddrIndirectMode', after dealing with the specific register
WrapperAddrIndirectEnd
        RTS        

AddrIndReg0
        *Output some message, EA mode is address indirect 0...
        LEA     OutAddrIndReg0,A1   *Loads AddrIndReg0 into address register A1
        MOVE.B  #14,D0              *Moves the number 14 into data register D0
        TRAP    #15                 *Displays Message        
        
        JMP     WrapperAddrIndirectEnd

AddrIndReg1
        LEA     OutAddrIndReg1,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectEnd

AddrIndReg2
        LEA     OutAddrIndReg2,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectEnd

AddrIndReg3
        LEA     OutAddrIndReg3,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectEnd

AddrIndReg4
        LEA     OutAddrIndReg4,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectEnd

AddrIndReg5
        LEA     OutAddrIndReg5,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectEnd

AddrIndReg6
        LEA     OutAddrIndReg6,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectEnd

AddrIndReg7
        LEA     OutAddrIndReg7,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectEnd


*-----------------------------------------------------------        
* Current handling of bad op/ea codes. Should be revisited.
*----------------------------------------------------------- 
BADOPCODE
        *We found a bad op code, output some error to the screen, jump to the 
        *next instruction in memory.
        *NOTE: IF THIS INSTRUCTION HAD IMMEDIATE OR ABSOLUTE DATA ATTACHED TO IT,
        *THEN WE WILL NEED SOME WAY TO FIGURE THAT OUT AND READ THROUGH THAT DATA.
        *OTHERWISE, THE NEXT OP WILL TRY TO TREAT THAT IMMEDIATE/ABSOULTE DATA AS
        *A LEGIT INSTRUCTION, NOT GARBAGE!!!
        *i/o and error message code...
        LEA     BADOPMSG,A1 *Loads BADOPMSG into address register A1        
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        JMP     GRAB_NEXT_OP
                
BADEACODE
        *We found a bad ea code, output some error to the screen, jump to the
        *next instruction in memory.
        *NOTE: WE SHOULDN'T HAVE TO WORRY ABOUT GARBAGE IMMEDAIATE/ABSOLUTE DATA
        *HERE, EACH EA FUNC SHOULD HAVE TAKEN CARE OF THAT BEFORE JUMPIN TO THIS FUNC        
        LEA     BADEAMSG,A1 *Loads BADEAMSG into address register A1        
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        JMP     GRAB_NEXT_OP
        
        
*-----------------------------------------------------------        
* End of Disassembler
*-----------------------------------------------------------    

DONE	STOP	#$2700  *What does this do? Why was it added?

THEEND  MOVE.B  #9,D0
        TRAP    #15             Halt Simulator        
        
     
*-----------------------------------------------------------        
* Output stuff
*-----------------------------------------------------------     
CR      EQU     $0D             ASCII code for Carriage Return
LF      EQU     $0A             ASCII code for Line Feed
MESSAGE     DC.B	'-------------------------------------------------------------',CR,LF
			DC.B	'||               Welcome to ZETA Disassembler              ||',CR,LF
			DC.B	'-------------------------------------------------------------',CR,LF
			DC.B	'*************************************************************',CR,LF
			DC.B	'*************************************************************',CR,LF
			DC.B	'******           ***        ***           ****    ***********',CR,LF
			DC.B	'************    ****   ************   *******  **  **********',CR,LF
			DC.B	'**********    ******        *******   ******        *********',CR,LF
			DC.B	'********    ********   ************   *****   ****   ********',CR,LF
			DC.B	'******           ***        *******   ****   ******   *******',CR,LF
			DC.B	'*************************************************************',CR,LF
			DC.B	'*************************************************************',CR,LF
			DC.B	'*                                                           *',CR,LF
			DC.B	'* Authors: Brandon Roth, Dwayne Honeycutt, Teresia Djunaedi *',CR,LF
			DC.B	'*                                                           *',CR,LF
			DC.B	'*************************************************************',CR,LF,CR,LF
			DC.B    'Starting disassembler...',CR,LF,CR,LF,0
			
STARTASSEM	DC.B	'Would you like to start disassembling the test? ',0

GETSTRTADDR DC.B	' ',CR,LF
			DC.B	'Please type in your starting address request: ',0
			
GETENDADDR	DC.B	' ',CR,LF
			DC.B	'Please type in your ending address request: ',0
			
QUIT_MSG	DC.B	' ',CR,LF
			DC.B	'Would you like to quit (Y/N)? ',0

*****************************************************
* I/O storages - assuming users knows what to do.
*****************************************************
CMD_HLD		DS.B	30
CMD_SZ		DS.B	30
STADDR		DS.B	10
STADDRSZ	DS.B	10
ENDADDR		DS.B	10
ENDADDRSZ	DS.B	10
*****************************************************

*output for all OPCODEs
ADDI    DC.B    'ADDI',0
ANDI    DC.B    'ANDI',0
EORI    DC.B    'EORI',0
BCHG_D  DC.B    'BCHG(dynamic)',0
BCHG_S  DC.B    'BCHG(static)',0
CMPI    DC.B    'CMPI',0

*output for the size of the operation
ByteSize    DC.B    '.B    ',0
WordSize    DC.B    '.W    ',0
LongSize    DC.B    '.L    ',0

*output for all data registers (0-7)
OutDataReg0 DC.B    ',D0',CR,LF,0
OutDataReg1 DC.B    ',D1',CR,LF,0
OutDataReg2 DC.B    ',D2',CR,LF,0
OutDataReg3 DC.B    ',D3',CR,LF,0
OutDataReg4 DC.B    ',D4',CR,LF,0
OutDataReg5 DC.B    ',D5',CR,LF,0
OutDataReg6 DC.B    ',D6',CR,LF,0
OutDataReg7 DC.B    ',D7',CR,LF,0

*output for all address indirect registers (0-7)
OutAddrIndReg0  DC.B    ',(A0)',CR,LF,0
OutAddrIndReg1  DC.B    ',(A1)',CR,LF,0
OutAddrIndReg2  DC.B    ',(A2)',CR,LF,0
OutAddrIndReg3  DC.B    ',(A3)',CR,LF,0
OutAddrIndReg4  DC.B    ',(A4)',CR,LF,0
OutAddrIndReg5  DC.B    ',(A5)',CR,LF,0
OutAddrIndReg6  DC.B    ',(A6)',CR,LF,0
OutAddrIndReg7  DC.B    ',(A7)',CR,LF,0

*current output for error messages
BADEAMSG    DC.B    'BAD EA, WHY?!',CR,LF,0
BADOPMSG    DC.B    'BAD OP CODE, WHY?!',CR,LF,0
INV_MSG		DC.B	'Improper command.',CR,LF,0
INVSTRTMSG	DC.B	'Invalid start address.',CR,LF,0
        
        END     START
        

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
