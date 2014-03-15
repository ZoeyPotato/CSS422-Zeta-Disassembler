*-------------------------------------------------------------
* Title      :Team Zeta 68k Disassembler, CSS 422 Winter 2014
* Written by :Brandon Roth, Dwayne Honeycutt, Teresia Djunaedi
* Date       :3/14/2014
* Description:
* This program disassembles a subset of 68k assembly instructions. After specifying
* where the program to be disassembled is located, this program will disassemble
* instructions of that program, and output the contents to console.
*
* For use with the EASy68K Emulator. To run, open this program in the emulator.
* Hit 'F9' to execute. In the execution window, open the test input file, and press
* 'F9' to run the program.
*
* This program will not disassemble every 68k instruction, only a subset of instructions
* that we have currently implemented. See corresponding documentation for more details.
*-------------------------------------------------------------
ST_ADDR 	EQU $7FC6   *Starting address of input test file
STACK   	EQU $7000   *Stack location
MAX_LINE	EQU 15		*Maximum number of instructions that can be displayed
START   	ORG $1000   *Start program at provided location	
			LEA	stack,SP
			MOVE	#MAX_LINE,D6


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
           	TRAP	#15
           	CMPI.B	#01,D1
           	BNE		INVALID1
        	JSR		CHECK_UPY
        	
        	
*-----------------------------------------------------------
* I/O: Check Start Address
*
* Make sure that start address starts after allocated 
* memory addresses. Else, it will print out a message 
* saying that requested address is invalid & prompts the
* user again for the starting address.
*-----------------------------------------------------------
GET_STRT 	LEA		GETSTRTADDR,A1	*Ask start address once everything is OK.
			MOVE.B	#14,D0
			TRAP	#15
			LEA		STADDR,A1	*Need to change where it can hold the start/end address
			MOVE.W	STADDRSZ,D1	*Store the size in a buffer
			MOVE	#2,D0			*Get start address
        	TRAP	#15
        	JSR		CHECKSTRT1
        	CLR.L	D7
        	JSR		ASCIIHEX	*Convert ASCII to Hex if all's ok
        	CMPI.B	#01,D3		*Check if there was a bad start
        	BEQ		INV_STRT1	*Prints error message if there was a bad start
        	CMPI.L	#ST_ADDR,D7	*Checks the minimum start address for D7
        	BLT		INV_STRT1	*Asks for another start address if invalid
        	CMPI.L	#$00FFFFFE,D7	*Checks if it goes beyond the possible end address
        	BGE		INV_STRT1
        	MOVE.L	D7,PROGST

GET_END		LEA		GETENDADDR,A1	*Command prompt for end address
			MOVE.B	#14,D0
			TRAP	#15
			LEA		ENDADDR,A1		*Buffer to hold end address
			MOVE.W	ENDADDRSZ,D1	*Buffer to hold size of end address
			MOVE	#2,D0
			TRAP	#15
			JSR		CHECKEND1
			CLR.L	D7
			JSR		ASCIIHEX
			CMPI.B	#01,D3
			BEQ		INV_END1
			CMPI.L	#PROGST,D7
			BLT		INV_END1
			CMPI.L	#$00FFFFFF,D7
			BGE		INV_END1
			MOVE.L	D7,PROGEND
			MOVEA.L	PROGST,A0
			BRA		GRAB_NEXT_OP			
        	        	
CHECKSTRT1	CMPI.L	#08,D1		*Check if size falls within range
			BGT		INV_STRT1
			CMPI.L	#00,D1
			BLS		INV_STRT1
			RTS			
			
CHECKEND1	CMPI.L	#08,D1
			BGT		INV_END1
			CMPI.L	#00,D1
			BLS		INV_END1
			RTS


*-----------------------------------------------------------
* I/O: Input check for Y, y, N, n
*-----------------------------------------------------------
CHECK_UPY	CMPI.B	#$59,(A1)	*Checks for uppercase Y
			BNE		CHECK_LOWY
			RTS
CHECK_LOWy	CMPI.B	#$79,(A1)	*Checks for lowercase y
			BNE		CHECK_UPN
			RTS
CHECK_UPN	CMPI.B	#$4E,(A1)	*Checks for uppercase N
			BEQ		DONE
			
CHECK_LOWn	CMPI.B	#$6E,(A1)	*Checks for lowercase n
			BEQ		DONE
			
INVALID1	MOVE.B	#0,D3		*Reset bad flag
			MOVE	#0,D0		*Prints invalid command msg if not found
			LEA		INV_MSG,A1
			MOVE	#14,D0
			TRAP	#15
			BRA		loop_1
			
INV_STRT1	LEA		INVSTRTMSG,A1
			MOVE.B	#14,D0
			TRAP	#15
			MOVE.B	#00,D3		*Reset flag
			BRA		GET_STRT		
			
INV_END1	LEA		INVENDMSG,A1
			MOVE.B	#14,D0
			TRAP	#15
			MOVE.B	#00,D3		*Reset flag
			BRA		GET_END
			
			
*-----------------------------------------------------------
* ASCII to Hex converter
*
* Checks and converts the ASCII value to the hex equivalent
*-----------------------------------------------------------
ASCIIHEX	MOVEM.L	D1/D2,-(SP)	*Free up and store the values in the stack
ASCIIHEX1	CMPI.B	#00,D1		*See if done
			BEQ		exitSub		*Exit subroutine 
			SUBI.B	#01,D1		*Keep track of how many chars we need to go through
			ROL.L	#4,D7		*Keep shifting to add the next appropriate hex for the full addr
			MOVE.B	(A1)+,D2	*Takes the first char
			CMPI.B	#$24,D2		*See if the first char is $
			BEQ		ASCIIHEX1	*Loop through to get the next char if first is $
			CMPI.B	#$30,D2		*See if the char is less than the hex value for '0'
			BLT		st_bad		*Put error message
			CMPI.B	#$39,D2		*Checks if char value is between 0 and 9's hex value
			BLE		CONV_NUM	*Convert to number, if so
			CMPI.B	#$41,D2		*Checks if char value is not a number or letter (A-F)
			BLT		st_bad		*Put error message
			CMPI.B	#$46,D2		*Checks if char value is an uppercase letter between A and F
			BLE		CONV_UpL	*Convert to hex
			CMPI.B	#$61,D2		*Checks for non-valid chars
			BLT		st_bad
			CMPI.B	#$66,D2		*Checks for lowercase chars of (a-f)
			BLE		CONV_LoL	
			BGT		st_bad		*Puts error message for anything greater than f value
			
CONV_NUM	SUBI.B	#$30,D2
			OR.B	D2,D7
			JMP		ASCIIHEX1
CONV_UpL	SUBI.B	#$37,D2		*Put it in a range of 10-15
			OR.B	D2,D7
			JMP		ASCIIHEX1
CONV_LoL	SUBI.B	#$57,D2
			OR.B	D2,D7
			JMP		ASCIIHEX1	

st_bad		ADDI.B	#01,D3
exitSub		MOVEM.L	(SP)+,D1/D2	*Pop back data back to the respective registers
			RTS
			
			
*-----------------------------------------------------------
* Hex to ASCII converter
*-----------------------------------------------------------
HEXASCII	MOVEM.L	D1/D4/D5,-(SP)	* Push registers into the stack
CHECK		CMPI.B	#00,D1			* Check if it's sending a byte, word, or longword
			BEQ		CHNG_SZB		* Set the appropriate size for for-loop
			CMP.W	#01,D1			
			BEQ		CHNG_SZW
			BRA		CHNG_SZL		

HEXASCIIREG	MOVEM.L	D1/D4/D5,-(SP)	* Push registers into the stack
CHNG_SZL	MOVE.B	#8,D1			* Set size to 8
LOOP_L		CMPI.B	#00,D1
			BEQ		EXIT_CONV
			SUBI.B	#01,D1
			ROL.L   #4,D4           * Shift it for next bit
			MOVE.L	D4,D5			* Keep a copy of hex values in D5
			JSR		CONV_LOOP
			BRA		LOOP_L		

CHNG_SZB	MOVE.B	#2,D1			* Set size to 2
LOOP_B		CMPI.B	#00,D1
			BEQ		EXIT_CONV
			SUBI.B	#01,D1
			ROL.B   #4,D4           * Shift it for next bit
			MOVE.L	D4,D5			* Keep a copy of hex values in D5
			JSR		CONV_LOOP
			BRA		LOOP_B
			
CHNG_SZW	MOVE.B	#4,D1			* Set size to 4
LOOP_W		CMPI.B	#00,D1
			BEQ		EXIT_CONV
			SUBI.B	#01,D1
			ROL.W   #4,D4           * Shift it for next bit
			MOVE.L	D4,D5			* Keep a copy of hex values in D5
			JSR		CONV_LOOP
			BRA		LOOP_W

CONV_LOOP	ANDI.L	#$0000000F,D5	* Grab only the last bit in D5
			CMPI.B	#$0,D5
			BEQ		NUM_0
			CMPI.B	#$1,D5
			BEQ		NUM_1
			CMPI.B	#$2,D5
			BEQ		NUM_2
			CMPI.B	#$3,D5
			BEQ		NUM_3
			CMPI.B	#$4,D5
			BEQ		NUM_4
			CMPI.B	#$5,D5
			BEQ		NUM_5
			CMPI.B	#$6,D5
			BEQ		NUM_6
			CMPI.B	#$7,D5
			BEQ		NUM_7
			CMPI.B	#$8,D5
			BEQ		NUM_8
			CMPI.B	#$9,D5
			BEQ		NUM_9
			CMPI.B	#$A,D5
			BEQ		NUM_A
			CMPI.B	#$B,D5
			BEQ		NUM_B
			CMPI.B	#$C,D5
			BEQ		NUM_C
			CMPI.B	#$D,D5
			BEQ		NUM_D
			CMPI.B	#$E,D5
			BEQ		NUM_E
			CMPI.B	#$F,D5
			BEQ		NUM_F
			
EXIT_CONV	MOVEM.L	(SP)+,D1/D4/D5
			RTS
			
PRINT_NUM	MOVE	#14,D0
			TRAP	#15
			RTS
NUM_0		LEA		PRNT0,A1
			BRA		PRINT_NUM
NUM_1		LEA		PRNT1,A1
			BRA		PRINT_NUM
NUM_2		LEA		PRNT2,A1
			BRA		PRINT_NUM
NUM_3		LEA		PRNT3,A1
			BRA		PRINT_NUM
NUM_4		LEA		PRNT4,A1
			BRA		PRINT_NUM
NUM_5		LEA		PRNT5,A1
			BRA		PRINT_NUM
NUM_6		LEA		PRNT6,A1
			BRA		PRINT_NUM
NUM_7		LEA		PRNT7,A1
			BRA		PRINT_NUM
NUM_8		LEA		PRNT8,A1
			BRA		PRINT_NUM
NUM_9		LEA		PRNT9,A1
			BRA		PRINT_NUM
NUM_A		LEA		PRNTA,A1
			BRA		PRINT_NUM
NUM_B		LEA		PRNTB,A1
			BRA		PRINT_NUM
NUM_C		LEA		PRNTC,A1
			BRA		PRINT_NUM
NUM_D		LEA		PRNTD,A1
			BRA		PRINT_NUM
NUM_E		LEA		PRNTE,A1
			BRA		PRINT_NUM
NUM_F		LEA		PRNTF,A1
			BRA		PRINT_NUM


*-----------------------------------------------------------        
* Start of Disassembler
*-----------------------------------------------------------
        *FOR DEBUGGING ONLY!!!
        MOVEA.L #ST_ADDR,A0 *Load starting location of test input file into A0
        
GRAB_NEXT_OP
        *Check and see if A0 == end of test address. If so, we need to end.
		MOVE.L	A0,D7
		MOVEA.L	PROGEND,A2
        CMP.L	A2,D7  		* Check and see if A0 == end of test address. 
        CMPI.L	#00,D6		* Check if max line of instructions output on console is reached
        BEQ		CONT_Q		* Asks user if they want to continue with the disassembler
        SUBI.B	#01,D6		* Keep track of how many lines of instruction has been printed

        *Output a newline to console...        
        LEA     NewLine,A1  *Loads NewLine into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message

        *Output the address of this instruction to console...
        MOVE.L  A0,D4
        JSR     HEXASCIIREG
        
        *Output a tab (4 spaces) to console, just after the address...
        LEA     Tab,A1  *Loads Tab into address register A1
        MOVE.B  #14,D0  *Moves the number 14 into data register D0
        TRAP    #15     *Displays Message
        
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
        BRA		BUCKET_0000		* Start with 0000


*-----------------------------------------------------------        
* Question Prompts
*-----------------------------------------------------------        
CONT_Q		LEA		QUES_CONT,A1
			MOVE	#14,D0
			TRAP	#15
			LEA		CONT,A1		*Need to store Y/N
			MOVE	#2,D0
			TRAP	#15
			CMPI.B	#01,D1
	        BNE		INVALID1
			CMPI.B	#$59,CONT	*Checks for uppercase Y
			BNE		CHECK_Y
			MOVE	#MAX_LINE,D6	*Resets counter
			RTS
CHECK_Y		CMPI.B	#$79,(A1)	*Checks for lowercase y
			BNE		CHECK_N
			MOVE	#MAX_LINE,D6	*Resets counter
			RTS
CHECK_N		CMPI.B	#$4E,(A1)	*Checks for uppercase N
			BEQ		loop_1
			CMPI.B	#$6E,(A1)	*Checks for lowercase n
			BEQ		loop_1      

INV2		MOVE.B	#0,D3		*Reset bad flag
			MOVE	#0,D0		*Prints invalid command msg if not found
			LEA		INV_MSG,A1
			MOVE	#14,D0
			TRAP	#15
			BRA		CONT_Q

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
        *Compare the first 4 bits of the CURRENT instruction with first 4 of BUCKET0000. 
        *If equal, continue decoding. If not, branch to next bucket.
        CMP.B   D0,D1
        BNE     BUCKET_0001

        *Test the 8th bit in this instruction, if it is 1, then it is a BCHG(dynamic) 
        *The zbit will be 1 if the bit is 0, and 0 if the bit is 1. 
        MOVE.W  D7,D0   *Move the WHOLE instruction back to D0
        BTST.L  #$08,D0
        BNE     IS_BCHG_D  *If the zbit was 0 (the 8th bit is 1), branch to IS_BCHG_D
        
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
        *Set D1 to the 'size' of the operation located in bits 7 and 6 of the instruction
        CLR.L   D1
        MOVE.W  D7,D1       *Move the WHOLE instruction to D1
        AND.W   #$00C0,D1   *Mask out everything but the size bits
        LSR.B   #$06,D1     *Shift the size bits into LSB
        
        CMP.B   #$03,D1     *Compare the size bits to $3
        BEQ     BADOPCODE   *if equal, bad op code, size shouldn't be (%11)
        
        *Output 'ADDI' to console...
        LEA     ADDI,A1     *Loads ADDI into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        
        *Should have a valid ADDI op code. Set data up for EA.
        
        *Set D2 to the EA mode of the operation located in bits 5-3 of the instruction
        CLR.L   D2
        MOVE.W  D7,D2       *Move the WHOLE instruction to D2
        AND.W   #$0038,D2   *Mask out everything but the EA mode bits
        LSR.B   #$03,D2     *Shift the EA mode bits into LSB
                
        *Set D3 to the EA register of the operation located in bits 2-0 of the instruction
        CLR.L   D3
        MOVE.W  D7,D3       *Move the WHOLE instruction to D3
        AND.W   #$0007,D3   *Mask out everything but the EA register bits
        
        JMP     EA_ADDI

EA_ADDI
        *Decode the ea bits of ADDI. Assuming D1 holds the size, D2 holds the EA mode,
        *and D3 holds the EA register.
        
        *Determine how much data to read in, depending on the size of the operation
        *output the size of the operation and the immediate data to console
        JSR     WrapperSizeImmediate
        
        *manually output a comma here...
        LEA     Comma,A1        *Loads Comma into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message        
        
        *Determine which EA mode and thus Register/Mem Address this instruction used
        CMP.B   #$00,D2
        BEQ     DataRegMode *If EA mode is a data register, output that
        
        CMP.B   #$02,D2
        BEQ     AddrIndirectMode  *If EA mode is an addr indirect, output that
        
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
        *Verify the size of this operation. If incorrect size (%11), then bad opcode!
        *Set D1 to the 'size' of the operation located in bits 7 and 6 of the instruction
        CLR.L   D1
        MOVE.W  D7,D1       *Move the WHOLE instruction to D1
        AND.W   #$00C0,D1   *Mask out everything but the size bits
        LSR.B   #$06,D1     *Shift the size bits into LSB
        
        CMP.B   #$03,D1     *Compare the size bits to $3
        BEQ     BADOPCODE   *if equal, bad op code, size shouldn't be (%11)
        
        *Output 'ANDI' to console...
        LEA     ANDI,A1     *Loads ANDI into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        
        *Should have a valid ANDI op code. Set data up for EA.
        
        *Set D2 to the EA mode of the operation located in bits 5-3 of the instruction
        CLR.L   D2
        MOVE.W  D7,D2       *Move the WHOLE instruction to D2
        AND.W   #$0038,D2   *Mask out everything but the EA mode bits
        LSR.B   #$03,D2     *Shift the EA mode bits into LSB
                
        *Set D3 to the EA register of the operation located in bits 2-0 of the instruction
        CLR.L   D3
        MOVE.W  D7,D3       *Move the WHOLE instruction to D3
        AND.W   #$0007,D3   *Mask out everything but the EA register bits
        
        JMP     EA_ANDI

EA_ANDI
        *Decode the ea bits of ANDI. Assuming D1 holds the size, D2 holds the EA mode,
        *and D3 holds the EA register.
        
        *Determine how much data to read in, depending on the size of the operation
        *output the size of the operation and the immediate data to console
        JSR     WrapperSizeImmediate
        
        *manually output a comma here...
        LEA     Comma,A1        *Loads Comma into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message        
        
        *Determine which EA mode and thus Register/Mem Address this instruction used
        CMP.B   #$00,D2
        BEQ     DataRegMode *If EA mode is a data register, output that
        
        CMP.B   #$02,D2
        BEQ     AddrIndirectMode  *If EA mode is an addr indirect, output that
        
        CMP.B   #$03,D2
        BEQ     AddrIndirectPostMode    *If EA mode is an addr indirect postinc, output that
        
        CMP.B   #$04,D2
        BEQ     AddrIndirectPreMode    *If EA mode is an addr indirect predec, output that
        
        CMP.B   #$07,D2
        BEQ     AddrAbsoluteMode    *If EA mode is an addr absolute word/long, output that
        
        *If the ea mode isn't equal to any of these, it is an invalid EA
        JMP     BADEACODE
        

*Now we know this instruction is exactly EORI, lets set everything up for EA.
IS_EORI
		*Verify the size of this operation. If incorrect size (%11), then bad opcode!
        *Set D1 to the 'size' of the operation located in bits 7 and 6 of the instruction
        CLR.L   D1
        MOVE.W  D7,D1       *Move the WHOLE instruction to D1
        AND.W   #$00C0,D1   *Mask out everything but the size bits
        LSR.B   #$06,D1     *Shift the size bits into LSB
        
        CMP.B   #$03,D1     *Compare the size bits to $3
        BEQ     BADOPCODE   *if equal, bad op code, size shouldn't be (%11)
        
        *Output 'EORI' to console...
        LEA     EORI,A1     *Loads EORI into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        
        *Should have a valid EORI op code. Set data up for EA.
        
        *Set D2 to the EA mode of the operation located in bits 5-3 of the instruction
        CLR.L   D2
        MOVE.W  D7,D2       *Move the WHOLE instruction to D2
        AND.W   #$0038,D2   *Mask out everything but the EA mode bits
        LSR.B   #$03,D2     *Shift the EA mode bits into LSB
                
        *Set D3 to the EA register of the operation located in bits 2-0 of the instruction
        CLR.L   D3
        MOVE.W  D7,D3       *Move the WHOLE instruction to D3
        AND.W   #$0007,D3   *Mask out everything but the EA register bits
        
        JMP     EA_EORI

EA_EORI
        *Decode the ea bits of EORI. Assuming D1 holds the size, D2 holds the EA mode,
        *and D3 holds the EA register.
        
        *Determine how much data to read in, depending on the size of the operation
        *output the size of the operation and the immediate data to console
        JSR     WrapperSizeImmediate
        
        *manually output a comma here...
        LEA     Comma,A1        *Loads Comma into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message        
        
        *Determine which EA mode and thus Register/Mem Address this instruction used
        CMP.B   #$00,D2
        BEQ     DataRegMode *If EA mode is a data register, output that
        
        CMP.B   #$02,D2
        BEQ     AddrIndirectMode  *If EA mode is an addr indirect, output that
        
        CMP.B   #$03,D2
        BEQ     AddrIndirectPostMode    *If EA mode is an addr indirect postinc, output that
        
        CMP.B   #$04,D2
        BEQ     AddrIndirectPreMode    *If EA mode is an addr indirect predec, output that
        
        CMP.B   #$07,D2
        BEQ     AddrAbsoluteMode    *If EA mode is an addr absolute word/long, output that
        
        *If the ea mode isn't equal to any of these, it is an invalid EA
        JMP     BADEACODE


*Found a possible BCHG(dynamic) instruction. Verify its bit integrity and then set
*everything up for EA, if is a legit instruction.
IS_BCHG_D
        *Check bits 7 and 6, these should be 0 and 1. If not, this instruction is
        *invalid, branch to BADOPCODE
        MOVE.W  D7,D0      *Move the WHOLE instruction back to D0
        BTST.L  #$07,D0
        BNE     BADOPCODE  *If the zbit was 0 (the 7th bit is 1), branch to BADOPCODE
        BTST.L  #$06,D0
        BEQ     BADOPCODE  *If the zbit was 1 (the 6th bit is 0), branch to BADOPCODE
        
        *Output 'BCHG' to console...
        LEA     BCHG,A1         *Loads BCHG into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message
                
                
        *Should have a valid BCHG op code. Set data up for EA.

        *Set D1 to the EA source register located in bits 11-9 of the instruction
        CLR.L   D1
        MOVE.W  D7,D1       *Move the WHOLE instruction to D1
        AND.W   #$0E00,D1   *Mask out everything but the EA source register bits
        LSR.W   #$08,D1     *Shift the EA source register bits into LSB
        LSR.W   #$01,D1

        *Set D2 to the EA mode of the operation located in bits 5-3 of the instruction
        CLR.L   D2
        MOVE.W  D7,D2       *Move the WHOLE instruction to D2
        AND.W   #$0038,D2   *Mask out everything but the EA mode bits
        LSR.B   #$03,D2     *Shift the EA mode bits into LSB
                
        *Set D3 to the EA register of the operation located in bits 2-0 of the instruction
        CLR.L   D3
        MOVE.W  D7,D3       *Move the WHOLE instruction to D3
        AND.W   #$0007,D3   *Mask out everything but the EA register bits

        JMP     EA_BCHG_D

EA_BCHG_D
        *Decode the ea bits of BCHG(dynamic). Assuming D1 holds the source register, 
        *D2 holds the EA mode, and D3 holds the EA register.
        
        *Determine the size of this BCHG instruction. Output the correct size...
        JSR     BCHGSizeHelper
        
        *output the source register to console, flag D6 with a 1 so we come back...
        MOVEM.L D6,-(SP)    *Push D6 into stack (line counter)
        MOVEM.L D3,-(SP)    *Push EA destination register into stack            
        MOVE.B  #$01,D6     *Flag D6
        MOVE.B  D1,D3       *Move source register into D3
        JSR     DataRegMode
        MOVEM.L (SP)+,D3    *Pull destination register back into D3
        MOVEM.L (SP)+,D6    *Pull the line counter back into D6
        
        *manually output a comma here...
        LEA     Comma,A1        *Loads Comma into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message
        
        *Determine which EA mode and thus Register/Mem Address this instruction used
        CMP.B   #$00,D2
        BEQ     DataRegMode *If EA mode is a data register, output that
        
        CMP.B   #$02,D2
        BEQ     AddrIndirectMode  *If EA mode is an addr indirect, output that
        
        CMP.B   #$03,D2
        BEQ     AddrIndirectPostMode    *If EA mode is an addr indirect postinc, output that
        
        CMP.B   #$04,D2
        BEQ     AddrIndirectPreMode    *If EA mode is an addr indirect predec, output that
        
        CMP.B   #$07,D2
        BEQ     AddrAbsoluteMode    *If EA mode is an addr absolute word/long, output that
        
        *If the ea mode isn't equal to any of these, it is an invalid EA
        JMP     BADEACODE


*Found a possible BCHG(static) instruction. Verify its bit integrity and then set up
*everything up for EA, if is a legit instruction.
IS_BCHG_S
		*Check bits 7 and 6, these should be 0 and 1. If not, this instruction is
        *invalid, branch to BADOPCODE
        MOVE.W  D7,D0      *Move the WHOLE instruction back to D0
        BTST.L  #$07,D0
        BNE     BADOPCODE  *If the zbit was 0 (the 7th bit is 1), branch to BADOPCODE
        BTST.L  #$06,D0
        BEQ     BADOPCODE  *If the zbit was 1 (the 6th bit is 0), branch to BADOPCODE
        
        *Output 'BCHG' to console...
        LEA     BCHG,A1         *Loads BCHG into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message
        
        
        *Should have a valid BCHG op code. Set data up for EA.
        
        *Move #$00 into D1, BCHG_S's immediate data is always in byte size
        CLR.L   D1
        MOVE.W  #$00,D1

        *Set D2 to the EA mode of the operation located in bits 5-3 of the instruction
        CLR.L   D2
        MOVE.W  D7,D2       *Move the WHOLE instruction to D2
        AND.W   #$0038,D2   *Mask out everything but the EA mode bits
        LSR.B   #$03,D2     *Shift the EA mode bits into LSB
                
        *Set D3 to the EA register of the operation located in bits 2-0 of the instruction
        CLR.L   D3
        MOVE.W  D7,D3       *Move the WHOLE instruction to D3
        AND.W   #$0007,D3   *Mask out everything but the EA register bits

        JMP     EA_BCHG_S

EA_BCHG_S
        *Decode the ea bits of BCHG(static). Assuming D2 holds the EA mode, and 
        *D3 holds the EA register.
        
        *Determine the size of this BCHG instruction. Output the correct size...
        JSR     BCHGSizeHelper                
        
        *output the immediate data of this operation to console (always byte)...
        JSR     BCHGImmediate
        
        *manually output a comma here...
        LEA     Comma,A1        *Loads Comma into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message
        
        *Determine which EA mode and thus Register/Mem Address this instruction used
        CMP.B   #$00,D2
        BEQ     DataRegMode *If EA mode is a data register, output that
        
        CMP.B   #$02,D2
        BEQ     AddrIndirectMode  *If EA mode is an addr indirect, output that
        
        CMP.B   #$03,D2
        BEQ     AddrIndirectPostMode    *If EA mode is an addr indirect postinc, output that
        
        CMP.B   #$04,D2
        BEQ     AddrIndirectPreMode    *If EA mode is an addr indirect predec, output that
        
        CMP.B   #$07,D2
        BEQ     AddrAbsoluteMode    *If EA mode is an addr absolute word/long, output that
        
        *If the ea mode isn't equal to any of these, it is an invalid EA
        JMP     BADEACODE


*Now we know this instruction is exactly CMPI, lets set everything up for EA.
IS_CMPI
		*Verify the size of this operation. If incorrect size (%11), then bad opcode!
        *Set D1 to the 'size' of the operation located in bits 7 and 6 of the instruction
        CLR.L   D1
        MOVE.W  D7,D1       *Move the WHOLE instruction to D1
        AND.W   #$00C0,D1   *Mask out everything but the size bits
        LSR.B   #$06,D1     *Shift the size bits into LSB
        
        CMP.B   #$03,D1     *Compare the size bits to $3
        BEQ     BADOPCODE   *if equal, bad op code, size shouldn't be (%11)
        
        *Output 'CMPI' to console...
        LEA     CMPI,A1     *Loads CMPI into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        
        *Should have a valid CMPI op code. Set data up for EA.
        
        *Set D2 to the EA mode of the operation located in bits 5-3 of the instruction
        CLR.L   D2
        MOVE.W  D7,D2       *Move the WHOLE instruction to D2
        AND.W   #$0038,D2   *Mask out everything but the EA mode bits
        LSR.B   #$03,D2     *Shift the EA mode bits into LSB
                
        *Set D3 to the EA register of the operation located in bits 2-0 of the instruction
        CLR.L   D3
        MOVE.W  D7,D3       *Move the WHOLE instruction to D3
        AND.W   #$0007,D3   *Mask out everything but the EA register bits
        
        JMP     EA_CMPI

EA_CMPI
        *Decode the ea bits of CMPI. Assuming D1 holds the size, D2 holds the EA mode,
        *and D3 holds the EA register.
        
        *Determine how much data to read in, depending on the size of the operation
        *output the size of the operation and the immediate data to console
        JSR     WrapperSizeImmediate
        
        *manually output a comma here...
        LEA     Comma,A1        *Loads Comma into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message
        
        *Determine which EA mode and thus Register/Mem Address this instruction used
        CMP.B   #$00,D2
        BEQ     DataRegMode *If EA mode is a data register, output that
        
        CMP.B   #$02,D2
        BEQ     AddrIndirectMode  *If EA mode is an addr indirect, output that
        
        CMP.B   #$03,D2
        BEQ     AddrIndirectPostMode    *If EA mode is an addr indirect postinc, output that
        
        CMP.B   #$04,D2
        BEQ     AddrIndirectPreMode    *If EA mode is an addr indirect predec, output that
        
        CMP.B   #$07,D2
        BEQ     AddrAbsoluteMode    *If EA mode is an addr absolute word/long, output that
        
        *If the ea mode isn't equal to any of these, it is an invalid EA
        JMP     BADEACODE
      
  
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


*-----------------------------------------------------------        
* Bucket 0100:
* STARTS WITH 0100, MOVEM | MULS(L)-------------------------
*                   LEA | CLR | JSR | RTS-------------------
*-----------------------------------------------------------
BUCKET_0100
BUCKET0100_BITS EQU $4
        CLR.L   D1
        *Load the first 4 bits (really a byte) of BUCKET0 into D1
        MOVE.B  #BUCKET0100_BITS,D1
        *Compare the first 4 bits of the CURRENT instruction with first 4 of BUCKET0100. 
        *If equal, continue decoding. If not, branch to next bucket.
        CMP.B   D0,D1
        BNE     BUCKET_0101

        *Test the 8th bit in this instruction, if it is 1, then it is an LEA 
        *The zbit will be 1 if the bit is 0, and 0 if the bit is 1.
        MOVE.W  D7,D0   *Move the WHOLE instruction back to D0
        BTST.L  #$08,D0
        BNE     IS_LEA  *If the zbit was 0 (the 8th bit is 1), branch to IS_LEA

        *Some codes in this bucket can be determined by only bits 11-8, but some need
        *11-6 to be unambiguous with others. First, solve codes that need bits 11-6...           
        AND.W   #$0FC0,D0   *Mask out everything but bits 11-6
        LSR.W   #$06,D0     *Move bits 11-6 into LSB position
        
        *Check bits 11-6 in the instruction and branch to different op-codes depending 
        *on what the bits equal, without ambiguity
        CMP.B   #$33,D0 *Is this a MOVEM(long)?
        BEQ     IS_MOVEM
        CMP.B   #$30,D0 *Is this a MULS(long)?
        BEQ     IS_MULS_L
        CMP.B   #$3A,D0 *Is this a JSR?
        BEQ     IS_JSR
        CMP.B   #$39,D0 *Is this a RTS?
        BEQ     IS_RTS

        *Now we can use only bits 11-8 and branch to different op-codes only needing these
        *four bits to be unambiguous
        LSR.W   #$02,D0 *Shift the 7-6 bits out, leaving only 11-8        
        CMP.B   #$08,D0 *Is this a MOVEM(word)?
        BEQ     IS_MOVEM
        CMP.B   #$02,D0 *Is this a CLR?
        BEQ     IS_CLR
        
        *If we get through all of the compares without finding the specific instruction,
        *then this instruction is either not in our list of OP CODES to decode, or is an
        *invalid instruction/syntax.
        JMP     BADOPCODE   *jump to BADOPCODE, where i/o will take care of it.


*Now we know this instruction is exactly MOVEM, lets set everything up for EA.
IS_MOVEM

EA_MOVEM


*Now we know this instruction is exactly IS_MULS_L, lets set everything up for EA.
IS_MULS_L

EA_MULS_L


*Now we know this instruction is exactly LEA, lets set everything up for EA.
IS_LEA
        *Check bits 7 and 6, these should be 1 and 1. If not, this instruction is
        *invalid, branch to BADOPCODE
        MOVE.W  D7,D0      *Move the WHOLE instruction back to D0
        BTST.L  #$07,D0
        BEQ     BADOPCODE  *If the zbit was 1 (the 7th bit is 0), branch to BADOPCODE
        BTST.L  #$06,D0
        BEQ     BADOPCODE  *If the zbit was 1 (the 6th bit is 0), branch to BADOPCODE
        
        *Output 'LEA' to console...
        LEA     LEA,A1         *Loads LEA into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message
        
        
        *Should have a valid LEA op code. Set data up for EA.      
        
        *Set D1 to the EA destination register located in bits 11-9 of the instruction
        CLR.L   D1
        MOVE.W  D7,D1       *Move the WHOLE instruction to D1
        AND.W   #$0E00,D1   *Mask out everything but the EA destination register bits
        LSR.W   #$08,D1     *Shift the EA destination register bits into LSB
        LSR.W   #$01,D1

        *Set D2 to the EA mode of the operation located in bits 5-3 of the instruction
        CLR.L   D2
        MOVE.W  D7,D2       *Move the WHOLE instruction to D2
        AND.W   #$0038,D2   *Mask out everything but the EA mode bits
        LSR.B   #$03,D2     *Shift the EA mode bits into LSB
                
        *Set D3 to the EA register of the operation located in bits 2-0 of the instruction
        CLR.L   D3
        MOVE.W  D7,D3       *Move the WHOLE instruction to D3
        AND.W   #$0007,D3   *Mask out everything but the EA register bits

        JMP     EA_LEA       

EA_LEA
        *Decode the ea bits of LEA. Assuming D2 holds the EA mode, and D3 holds the EA 
        *register.                                        
        
        *Determine which EA mode and thus Register/Mem Address this instruction used
        MOVEM.L D6,-(SP)    *Push D6 into stack (line counter)
        MOVE.B  #$01,D6     *Flag D6 so that we come back
        
        CMP.B   #$02,D2
        BEQ     LEA_AddrIndirectWrapper *If EA mode is an addr indirect, output that
        
        CMP.B   #$07,D2
        BEQ     LEA_AddrAbsoluteWrapper *If EA mode is an addr absolute word/long, output that

EA_LEA_WrapperEnd        
        MOVEM.L (SP)+,D6    *Pull the line counter back into D6
                
        *manually output a comma here...
        LEA     Comma,A1        *Loads Comma into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message
        
        *output the destination address register to console
        *Overwrite the EA register with destination register (no longer need D3 at this point)
        MOVE.B  D1,D3
        JSR     AddrRegMode
        
        *If the ea mode isn't equal to any of these, it is an invalid EA
        JMP     BADEACODE
        
        
*Now we know this instruction is exactly CLR, lets set everything up for EA.
IS_CLR

EA_CLR


*Now we know this instruction is exactly JSR, lets set everything up for EA.
IS_JSR

EA_JSR


*Now we know this instruction is exactly RTS, lets set everything up for EA.
IS_RTS

EA_RTS


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
* EA operation size decoding functionality for immediate data
*-----------------------------------------------------------   
*'Wrapper' func used for all size decoding. Used to do the nasty branching for diff sizes
WrapperSizeImmediate
        CLR.L   D4
        *Depending on the EA Register, choose which size to decode
        CMP.B   #$00,D1
        BEQ     ByteSizeImmediate
        
        CMP.B   #$01,D1
        BEQ     WordSizeImmediate

        CMP.B   #$02,D1
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
        
        *Output '#$' just before the immediate data
        LEA     ShaBang,A1
        MOVE.B  #14,D0
        TRAP    #15  
        
        *output the immediate data to console with the hex-ascii converter
        JSR     HEXASCII
                
        JMP     WrapperSizeImmediateEnd
                
WordSizeImmediate
        MOVE.W  (A0)+,D4    *read in next word, data is that word
        
        *Output '.W' to console...
        LEA     WordSize,A1 *Loads WordSize into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        *Output '#$' just before the immediate data
        LEA     ShaBang,A1
        MOVE.B  #14,D0
        TRAP    #15  
        
        *output the immediate data to console with the hex-ascii converter
        JSR     HEXASCII
        
        JMP     WrapperSizeImmediateEnd
                
LongSizeImmediate
        MOVE.L  (A0)+,D4    *read in next two words, data is those two words
        
        *Output '.L' to console...
        LEA     LongSize,A1 *Loads LongSize into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        *Output '#$' just before the immediate data
        LEA     ShaBang,A1
        MOVE.B  #14,D0
        TRAP    #15  
        
        *output the immediate data to console with the hex-ascii converter
        JSR     HEXASCII
        
        JMP     WrapperSizeImmediateEnd        


*-----------------------------------------------------------        
* BCHG Size decoding functionality
*----------------------------------------------------------- 
BCHGSizeHelper
        *Determine if the EA mode is a data register. If so, output '.L' to console...
        CMP.B   #$00,D2
        BEQ     BCHGLongSize
        
        *If the EA mode isn't a data register, WE MUST output a '.B' to console...
        JMP     BCHGByteSize
        
*Used to get back to what we were doing, after dealing with the specific size
BCHGSizeHelperEnd
        RTS  
        
BCHGLongSize
        *Output '.L' to console...
        LEA     LongSize,A1 *Loads LongSize into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message

        JMP     BCHGSizeHelperEnd
        
BCHGByteSize
        *Output '.B' to console...
        LEA     ByteSize,A1 *Loads ByteSize into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message   
        
        JMP     BCHGSizeHelperEnd
        
*Output the immediate data for a BCHG(static). Data is always byte size.
BCHGImmediate
        MOVE.W  (A0)+,D4    *read in the next word, data is the last 2 chars of word        
        
        *Output '#$' just before the immediate data
        LEA     ShaBang,A1
        MOVE.B  #14,D0
        TRAP    #15  
        
        *output the immediate data to console with the hex-ascii converter
        JSR     HEXASCII
                
        RTS        


*-----------------------------------------------------------        
* LEA Wrappers to conform to design of EA mode/register as destination operand. 
* LEA is weird in that its EA mode/register is used as a source operand.
*-----------------------------------------------------------        
*This conforms LEA to the JSR requirement of AddrIndirectMode. JMPs back to LEA after the JSR.
LEA_AddrIndirectWrapper
        JSR     AddrIndirectMode
        
        JMP     EA_LEA_WrapperEnd
        
*This conforms LEA to the JSR requirement of AddrAbsoluteMode. JMPs back to LEA after the JSR.
LEA_AddrAbsoluteWrapper
        JSR     AddrAbsoluteMode
        
        JMP     EA_LEA_WrapperEnd


*-----------------------------------------------------------        
* EA Mode/EA Register decoding functionality
*-----------------------------------------------------------        
DataRegMode
        *Depending on the EA Register, output a different register number
        JSR     WrapperDataReg        
        
        *if this was called for a destination decoding then we are done decoding this        
        *instruction, go get the next instruction
        CMP.B   #$01,D6
        BNE     GRAB_NEXT_OP
        
        *else this was a source decoding, rts back to we can keep decoding
        RTS

AddrRegMode
        JSR     WrapperAddrReg
        
        *if this was called for a destination decoding then we are done decoding this        
        *instruction, go get the next instruction
        CMP.B   #$01,D6
        BNE     GRAB_NEXT_OP
        
        *else this was a source decoding, rts back to we can keep decoding
        RTS

AddrIndirectMode
        *Depending on the EA Register, output a different register number
        JSR     WrapperAddrIndirect
                        
        *if this was called for a destination decoding then we are done decoding this        
        *instruction, go get the next instruction
        CMP.B   #$01,D6
        BNE     GRAB_NEXT_OP
        
        *else this was a source decoding, rts back to we can keep decoding
        RTS

AddrIndirectPostMode
        *Depending on the EA Register, output a different register number
        JSR     WrapperAddrIndirectPost

        *if this was called for a destination decoding then we are done decoding this        
        *instruction, go get the next instruction
        CMP.B   #$01,D6
        BNE     GRAB_NEXT_OP
        
        *else this was a source decoding, rts back to we can keep decoding
        RTS

AddrIndirectPreMode
        *Depending on the EA Register, output a different register number
        JSR     WrapperAddrIndirectPre

        *if this was called for a destination decoding then we are done decoding this        
        *instruction, go get the next instruction
        CMP.B   #$01,D6
        BNE     GRAB_NEXT_OP
        
        *else this was a source decoding, rts back to we can keep decoding
        RTS

AddrAbsoluteMode
        *Depending on the EA Register, output a different register number
        JSR     WrapperAddrAbsolute        

        *if this was called for a destination decoding then we are done decoding this        
        *instruction, go get the next instruction
        CMP.B   #$01,D6
        BNE     GRAB_NEXT_OP
        
        *else this was a source decoding, rts back to we can keep decoding
        RTS
        
ImmediateDataMode
        *some code        
        
        
*-----------------------------------------------------------        
* Output logic for all Data Registers (0-7)
*-----------------------------------------------------------
*'Wrapper' func used for outputing the correct register. Used to do the nasty branching
WrapperDataReg
        *Depending on the EA destination register, output a different register number
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
        *Output the specific data register...
        LEA     OutDataReg0,A1  *Loads OutDataReg0 into address register A1
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
* Output logic for all Address Registers (0-7)
*-----------------------------------------------------------     
*'Wrapper' func used for outputing the correct register. Used to do the nasty branching
WrapperAddrReg
        *Depending on the EA Register, output a different register number
        CMP.B   #$00,D3
        BEQ     AddrReg0
        
        CMP.B   #$01,D3
        BEQ     AddrReg1
        
        CMP.B   #$02,D3
        BEQ     AddrReg2
        
        CMP.B   #$03,D3
        BEQ     AddrReg3
        
        CMP.B   #$04,D3
        BEQ     AddrReg4
        
        CMP.B   #$05,D3
        BEQ     AddrReg5
        
        CMP.B   #$06,D3
        BEQ     AddrReg6
        
        CMP.B   #$07,D3
        BEQ     AddrReg7

*Used to get back to 'AddrRegMode', after dealing with the specific register
WrapperAddrRegEnd
        RTS        

AddrReg0
        *Output the specific address indirect register...
        LEA     OutAddrReg0,A1   	*Loads AddrReg0 into address register A1
        MOVE.B  #14,D0              *Moves the number 14 into data register D0
        TRAP    #15                 *Displays Message        
        
        JMP     WrapperAddrRegEnd

AddrReg1
        LEA     OutAddrReg1,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrRegEnd

AddrReg2
        LEA     OutAddrReg2,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrRegEnd

AddrReg3
        LEA     OutAddrReg3,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrRegEnd

AddrReg4
        LEA     OutAddrReg4,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrRegEnd

AddrReg5
        LEA     OutAddrReg5,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrRegEnd

AddrReg6
        LEA     OutAddrReg6,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrRegEnd

AddrReg7
        LEA     OutAddrReg7,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrRegEnd


*-----------------------------------------------------------        
* Output logic for all Address Indirect Registers (0-7)
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
        *Output the specific address indirect register...
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
* Output logic for all Address Indirect Post Increment Registers (0-7)
*-----------------------------------------------------------     
*'Wrapper' func used for outputing the correct register. Used to do the nasty branching
WrapperAddrIndirectPost
        *Depending on the EA Register, output a different register number
        CMP.B   #$00,D3
        BEQ     AddrIndPoReg0
        
        CMP.B   #$01,D3
        BEQ     AddrIndPoReg1
        
        CMP.B   #$02,D3
        BEQ     AddrIndPoReg2
        
        CMP.B   #$03,D3
        BEQ     AddrIndPoReg3
        
        CMP.B   #$04,D3
        BEQ     AddrIndPoReg4
        
        CMP.B   #$05,D3
        BEQ     AddrIndPoReg5
        
        CMP.B   #$06,D3
        BEQ     AddrIndPoReg6
        
        CMP.B   #$07,D3
        BEQ     AddrIndPoReg7

*Used to get back to 'AddrIndirectPostMode', after dealing with the specific register
WrapperAddrIndirectPostEnd
        RTS        

AddrIndPoReg0
        *Output the specific address indirect post register...
        LEA     OutAddrIndPoReg0,A1 *Loads AddrIndPoReg0 into address register A1
        MOVE.B  #14,D0              *Moves the number 14 into data register D0
        TRAP    #15                 *Displays Message        
        
        JMP     WrapperAddrIndirectPostEnd

AddrIndPoReg1
        LEA     OutAddrIndPoReg1,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPostEnd

AddrIndPoReg2
        LEA     OutAddrIndPoReg2,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPostEnd

AddrIndPoReg3
        LEA     OutAddrIndPoReg3,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPostEnd

AddrIndPoReg4
        LEA     OutAddrIndPoReg4,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPostEnd

AddrIndPoReg5
        LEA     OutAddrIndPoReg5,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPostEnd

AddrIndPoReg6
        LEA     OutAddrIndPoReg6,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPostEnd

AddrIndPoReg7
        LEA     OutAddrIndPoReg7,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPostEnd


*-----------------------------------------------------------        
* Output logic for all Address Indirect Pre Decrement Registers (0-7)
*-----------------------------------------------------------     
*'Wrapper' func used for outputing the correct register. Used to do the nasty branching
WrapperAddrIndirectPre
        *Depending on the EA Register, output a different register number
        CMP.B   #$00,D3
        BEQ     AddrIndPrReg0
        
        CMP.B   #$01,D3
        BEQ     AddrIndPrReg1
        
        CMP.B   #$02,D3
        BEQ     AddrIndPrReg2
        
        CMP.B   #$03,D3
        BEQ     AddrIndPrReg3
        
        CMP.B   #$04,D3
        BEQ     AddrIndPrReg4
        
        CMP.B   #$05,D3
        BEQ     AddrIndPrReg5
        
        CMP.B   #$06,D3
        BEQ     AddrIndPrReg6
        
        CMP.B   #$07,D3
        BEQ     AddrIndPrReg7

*Used to get back to 'AddrIndirectPreMode', after dealing with the specific register
WrapperAddrIndirectPreEnd
        RTS        

AddrIndPrReg0
        *Output the specific address indirect post register...
        LEA     OutAddrIndPrReg0,A1 *Loads AddrIndPrReg0 into address register A1
        MOVE.B  #14,D0              *Moves the number 14 into data register D0
        TRAP    #15                 *Displays Message        
        
        JMP     WrapperAddrIndirectPreEnd

AddrIndPrReg1
        LEA     OutAddrIndPrReg1,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPreEnd

AddrIndPrReg2
        LEA     OutAddrIndPrReg2,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPreEnd

AddrIndPrReg3
        LEA     OutAddrIndPrReg3,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPreEnd

AddrIndPrReg4
        LEA     OutAddrIndPrReg4,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPreEnd

AddrIndPrReg5
        LEA     OutAddrIndPrReg5,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPreEnd

AddrIndPrReg6
        LEA     OutAddrIndPrReg6,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPreEnd

AddrIndPrReg7
        LEA     OutAddrIndPrReg7,A1
        MOVE.B  #14,D0
        TRAP    #15
        
        JMP     WrapperAddrIndirectPreEnd


*-----------------------------------------------------------        
* Output logic for absolute memory addressing (0-7)
*-----------------------------------------------------------     
*'Wrapper' func used for all size decoding. Used to do the nasty branching for diff sizes
WrapperAddrAbsolute
        CLR.L   D4
        *Depending on the EA Register, choose which size to decode
        CMP.B   #$00,D3
        BEQ     WordSizeAbsolute

        CMP.B   #$01,D3
        BEQ     LongSizeAbsolute
        
*Used to get back to 'AddrAbsoluteMode', after dealing with the specific register
WrapperAddrAbsoluteEnd
        RTS

WordSizeAbsolute        
        MOVE.W  (A0)+,D4    *read in next word, data is that word        
            
        *Output ',$' just after source operand
        LEA     Bang,A1
        MOVE.B  #14,D0
        TRAP    #15
            
        *Push D1 into stack, in case something was using it
        MOVEM.L D1,-(SP)
        *Move #$01 into D1 to specify this as a word, used for hextoascii conversion...
        CLR.L   D1
        MOVE.B  #$01,D1
            
        *output the absolute mem address to console with the hex-ascii converter
        JSR     HEXASCII
        MOVEM.L (SP)+,D1    *Pull D1 back out from the stack
        
        JMP     WrapperAddrAbsoluteEnd

LongSizeAbsolute
        MOVE.L  (A0)+,D4    *read in next long, data is that long                
                
        *Output ',$' just after source operand
        LEA     Bang,A1
        MOVE.B  #14,D0
        TRAP    #15  
        
        *Push D1 into stack, in case something was using it
        MOVEM.L D1,-(SP)
        *Move #$10 into D1 to specify this as a long, used for hextoascii conversion...
        CLR.L   D1
        MOVE.B  #$10,D1
            
        *output the absolute mem address to console with the hex-ascii converter
        JSR     HEXASCII
        MOVEM.L (SP)+,D1    *Pull D1 back out from the stack
        
        JMP     WrapperAddrAbsoluteEnd
        

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
			
QUES_CONT	DC.B	' ',CR,LF
			DC.B	'Would you like to continue (Y/N)? ',0
			
QUIT_MSG	DC.B	' ',CR,LF
			DC.B	'Would you like to quit (Y/N)? ',0

*****************************************************
* I/O storages - assuming users knows what to do.
*****************************************************
CMD_HLD		DS.B	30
CMD_SZ		DS.B	30
STADDR		DS.B	10
STADDRSZ	DS.B	10
PROGST		DS.L	1
ENDADDR		DS.B	10
ENDADDRSZ	DS.B	10
PROGEND		DS.L	1
CONT		DS.B	30
*****************************************************

*Table for 0-9 && A-F
PRNT0	DC.B	'0',0
PRNT1	DC.B	'1',0
PRNT2	DC.B	'2',0
PRNT3	DC.B	'3',0
PRNT4	DC.B	'4',0
PRNT5	DC.B	'5',0
PRNT6	DC.B	'6',0
PRNT7	DC.B	'7',0
PRNT8	DC.B	'8',0
PRNT9	DC.B	'9',0
PRNTA	DC.B	'A',0
PRNTB	DC.B	'B',0
PRNTC	DC.B	'C',0
PRNTD	DC.B	'D',0
PRNTE	DC.B	'E',0
PRNTF	DC.B	'F',0

*output for all OPCODEs
*Bucket 0000
ADDI    DC.B    'ADDI',0
ANDI    DC.B    'ANDI',0
EORI    DC.B    'EORI',0
BCHG    DC.B    'BCHG',0
CMPI    DC.B    'CMPI',0
*Bucket 0100
MOVEM   DC.B    'MOVEM',0
MULS    DC.B    'MULS',0
LEA     DC.B    'LEA      ',0   *Need spaces here since LEA has no size
CLR     DC.B    'CLR',0
JSR     DC.B    'JSR      ',0   *Need spaces here since JSR has no size
RTS     DC.B    'RTS      ',0   *Need spaces here since RTS has no size

*output for the size of the operation
ByteSize    DC.B    '.B    ',0
WordSize    DC.B    '.W    ',0
LongSize    DC.B    '.L    ',0

*output for all data registers (0-7)
OutDataReg0 DC.B    'D0',0
OutDataReg1 DC.B    'D1',0
OutDataReg2 DC.B    'D2',0
OutDataReg3 DC.B    'D3',0
OutDataReg4 DC.B    'D4',0
OutDataReg5 DC.B    'D5',0
OutDataReg6 DC.B    'D6',0
OutDataReg7 DC.B    'D7',0

*output for all address registers (0-7)
OutAddrReg0 DC.B    'A0',0
OutAddrReg1 DC.B    'A1',0
OutAddrReg2 DC.B    'A2',0
OutAddrReg3 DC.B    'A3',0
OutAddrReg4 DC.B    'A4',0
OutAddrReg5 DC.B    'A5',0
OutAddrReg6 DC.B    'A6',0
OutAddrReg7 DC.B    'A7',0
        
*output for all address indirect registers (0-7)
OutAddrIndReg0  DC.B    '(A0)',0
OutAddrIndReg1  DC.B    '(A1)',0
OutAddrIndReg2  DC.B    '(A2)',0
OutAddrIndReg3  DC.B    '(A3)',0
OutAddrIndReg4  DC.B    '(A4)',0
OutAddrIndReg5  DC.B    '(A5)',0
OutAddrIndReg6  DC.B    '(A6)',0
OutAddrIndReg7  DC.B    '(A7)',0

*output for all address indirect post registers (0-7)
OutAddrIndPoReg0    DC.B    '(A0)+',0
OutAddrIndPoReg1    DC.B    '(A1)+',0
OutAddrIndPoReg2    DC.B    '(A2)+',0
OutAddrIndPoReg3    DC.B    '(A3)+',0
OutAddrIndPoReg4    DC.B    '(A4)+',0
OutAddrIndPoReg5    DC.B    '(A5)+',0
OutAddrIndPoReg6    DC.B    '(A6)+',0
OutAddrIndPoReg7    DC.B    '(A7)+',0

*output for all address indirect pre registers (0-7)
OutAddrIndPrReg0    DC.B    '-(A0)',0
OutAddrIndPrReg1    DC.B    '-(A1)',0
OutAddrIndPrReg2    DC.B    '-(A2)',0
OutAddrIndPrReg3    DC.B    '-(A3)',0
OutAddrIndPrReg4    DC.B    '-(A4)',0
OutAddrIndPrReg5    DC.B    '-(A5)',0
OutAddrIndPrReg6    DC.B    '-(A6)',0
OutAddrIndPrReg7    DC.B    '-(A7)',0

*output for a tab only (4 spaces)
Tab DC.B    '    ',0

*output for a comma only
Comma   DC.B    ',',0

*output for a new line only
NewLine DC.B    CR,LF,0

*output for a '#$' and '$' only
ShaBang DC.B    '#$',0
Bang    DC.B    '$',0

*current output for error messages
BADEAMSG    DC.B    'BAD EA',0
BADOPMSG    DC.B    'BAD OP',0
INV_MSG		DC.B	'Improper command.',CR,LF,0
INVSTRTMSG	DC.B	'Invalid start address.',CR,LF,0
INVENDMSG	DC.B	'Invalid end address.',CR,LF,0

        
        END     START
        
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
