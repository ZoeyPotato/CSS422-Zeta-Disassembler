*-------------------------------------------------------------
* Title      :Team Zeta 68k Disassembler, CSS 422 Winter 2014
* Written by :Brandon Roth, Dwayne Honeycutt, Teresia Djunaedi
* Date       :3/1/2014
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
        	MOVEA.W #ST_ADDR,A0 *Load starting location of test input file into A0
        	
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
			JMP		loop_1
			
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
        	TRAP	#15
        	MOVE.L	(A1),D4
        	JSR		CHECKSTRT1
CHECKSTRT1	CMPI.L	#08,D1		*Check if size 
			BGT		INV_STRT1
			CMPI.L	#00,D1
			BLS		INV_STRT1
			RTS			
			
*-----------------------------------------------------------        
* Start of Disassembler
*-----------------------------------------------------------
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
        MOVE.W  D7,D1   *Move the WHOLE instruction to D1
        AND.W   #$00C0,D1   *Mask out everything but the size bits
        LSR.B   #$06,D1 *Shift the size bits into LSB
        
        CMP.B   #$03,D1 *Compare the size bits to $3
        BEQ     BADOPCODE   *if equal, bad op code, size shouldn't be (%11)
        
        *Output some message, hey we found an ADDI instruction...
        LEA     FNDADDI,A1  *Loads FNDADDI into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        
        *Should have a valid IS_ADDI op code. Set data up for EA.
         
        *Set D1 to the EA mode of the operation located in bits 5-3 of the instruction
        MOVE.W  D7,D2   *Move the WHOLE instruction to D2
        AND.W   #$003C,D2   *Mask out everything but the EA mode bits
        LSR.B   #$03,D2 *Shift the EA mode bits into LSB
                
        *Set D3 to the EA register of the operation located in bits 2-0 of the instruction
        MOVE.W  D7,D3   *Move the WHOLE instruction to D3
        AND.W   #$0007,D3   *Mask out everything but the EA register bits
            
        JMP     EA_ADDI

EA_ADDI
        *some code verifiying the integrity/syntax of the EA bits of the instruction
        *if bad EA, jump to BADEACODE, where i/o will take care of it
        
        *make sure when you leave an EA func that you also read in and either use
        *or ignore immediate/absoluate data, so that we can we ready to start reading
        *in the next instruction.
        JMP     THEEND  *For now just end


*Now we know this instruction is exactly ANDI, lets set everything up for EA.
IS_ANDI
        *TODO:Verify bits

        *Output some message, hey we found an ANDI instruction...
        LEA     FNDANDI,A1  *Loads FNDANDI into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        *Should have a valid IS_ANDI op code. Set data up for EA.
        *TODO:
        MOVE.B  #14,D3
        JMP     EA_ANDI

EA_ANDI
        JMP     THEEND  *For now just end


*Now we know this instruction is exactly EORI, lets set everything up for EA.
IS_EORI
		*TODO:Verify bits

		*Output some message, hey we found an EORI instruction...
        LEA     FNDEORI,A1  *Loads FNDEORI into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        *Should have a valid IS_EORI op code. Set data up for EA.
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
        
        *Output a message, hey we found a BCHG(dynamic) instruction...
        LEA     FNDBCHG_D,A1    *Loads FNDBCHG_D into address register A1
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

		*Output some message, hey we found an BCHG_S instruction...
        LEA     FNDBCHG_S,A1    *Loads FNDBCHG_S into address register A1
        MOVE.B  #14,D0          *Moves the number 14 into data register D0
        TRAP    #15             *Displays Message
        
        *Should have a valid IS_BCHG_S op code. Set data up for EA.
        *TODO:
        MOVE.B  #14,D3
        JMP     EA_BCHG_S

EA_BCHG_S
        JMP     THEEND  *For now just end


*Now we know this instruction is exactly CMPI, lets set everything up for EA.
IS_CMPI
		*TODO:Verify bits

		*Output some message, hey we found an CMPI instruction...
        LEA     FNDCMPI,A1  *Loads FNDCMPI into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        *Should have a valid IS_CMPI op code. Set data up for EA.
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

*for now, i guess every OPCODE will have a corresponding 'found it' msg...
FNDADDI     DC.B    'Found an ADDI opcode',CR,LF,0
FNDANDI     DC.B    'Found an ANDI opcode',CR,LF,0
FNDEORI     DC.B    'Found an EORI opcode',CR,LF,0
FNDBCHG_D   DC.B    'Found a BCHG(dynamic) opcode',CR,LF,0
FNDBCHG_S   DC.B    'Found a BCHG(static) opcode',CR,LF,0
FNDCMPI     DC.B    'Found a CMPI opcode',CR,LF,0

BADEAMSG    DC.B    'BAD EA, WHY?!',CR,LF,0
BADOPMSG    DC.B    'BAD OP CODE, WHY?!',CR,LF,0
INV_MSG		DC.B	'Improper command.',CR,LF,0
INVSTRTMSG	DC.B	'Invalid start address.',CR,LF,0
        
        END     START
        







*~Font name~Courier New~
*~Font size~12~
*~Tab type~1~
*~Tab size~4~
