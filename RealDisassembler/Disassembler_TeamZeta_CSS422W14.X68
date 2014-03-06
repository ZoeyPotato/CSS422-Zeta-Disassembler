*-------------------------------------------------------------
* Title      :Team Zeta 68k Disassembler, CSS 422 Winter 2014
* Written by :Brandon Roth, Dwayne Honeycutt, Teresia Djunaedi
* Date       :3/1/2014
* Description:
* This program disassembles a subset of 68k
* assembly instructions. *visit this later, describe what it 
* does, how to use it, assumptions, etc.
*-------------------------------------------------------------

START   ORG $1000   *Start program at provided location
ST_ADDR EQU $7FC0   *Starting address of input test file
STACK   EQU $7000   *Stack location

        MOVEA.W #ST_ADDR,A0 *Load starting location of test input file into A0
        LEA     MESSAGE,A1  *Loads MESSAGE into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
        MOVE	#2,D0
        TRAP	#15
        MOVE.L	(A1),D4
        
*-----------------------------------------------------------        
* Start of Disassembler
*-----------------------------------------------------------        

GRAB_NEXT_OP
        *Move word data at (A0) into D0. D0 should now hold the entire 16 bits of the
        *next OP CODE instruction to disassemble, EXCLUDING any immediate/absolute 
        *data that may be associated with the instruction.
        CLR.L   D0
        *Post increment addr, A0 will point to the start of next instruction or will 
        *point to the start of any immed/abso data with this current instruction
        MOVE.W  (A0)+,D0
        *Copy the word data we just moved into D0 into D7. We are copying this data
        *So we always have a copy of the WHOLE instruction somewhere
        MOVE.W  D0,D7
        *Now shift D0 to the right by 12 bit values, so that we can isolate the first
        *four bits of the instruction. Once we have just the first four bits, we can
        *begin to see which 'bucket'/category this instruction falls into. 
        LSR.W   #$08,D0 *The max we can shift at once is 8 bits...
        LSR.W   #$04,D0
        *Now try to figure out what OP CODE this is using these 4 bits. Run down the
        *list of buckets until we find which one this instruction falls into.


*STARTS WITH 0000, ADDI | ANDI | EORI-----------------------
*                  BCHG(dynamic) | BCHG (static) | CMPI-----
BUCKET_0000
BUCKET0_BITS    EQU $0

        CLR.L   D1
        *Load the first 4 bits (really a byte) of BUCKET0 into D1
        MOVE.B  #BUCKET0_BITS,D1  
        *Compare the first 4 bits of the CURRENT instruction with first 4 of BUCKET0. 
        *If equal, continue decoding. If not, branch to next bucket.
        CMP.B   D0,D1
        BNE     BUCKET_0001

        *Test the 8th bit in this instruction, if it is 1, then it is a BCHG(dynamic) 
        *The zbit will be 1 if the bit is 0, and 0 if the bit is 1. 
        MOVE.W  D7,D0   *Move the WHOLE instruction back to D0
        BTST.L  #$08,D0
        BNE     IS_BCHG_D  *If the zbit was 0 (the 8th bit is 1), branch to ISBCHG_D
        
        *TODO:
        *Check the next four bits in the instruction, branch to different subsets 
        *depending on what the bits equal
        *Perform compares with these 4 bits to see which specific instruction it is.
        *If we get through all of the if's without finding the specific instruction,
        *then this instruction is either not in our list of OP CODES to decode, or
        *is an invalid instruction/syntax.
        *If invalid, jump to BADOPCODE, where i/o will take care of it.
        JMP     BADOPCODE  


*Now we know this instruction is exactly ADDI, lets set everything up for EA.
*THIS IS STILL PART OF OPCODES RESPONSIBILITY
IS_ADDI
        *Output some message, hey we found an ADDI instruction or something...
        LEA     FNDADDI,A1  *Loads FNDADDI into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        JMP     GRAB_NEXT_OP    *Jump and go to the next instruction
        
        *some code setting up registers/data for EA to disect and verify

*THIS IS AN 'EAFUNC', EA'S RESPONSIBILITY  
EA_ADDI
        *some code verifiying the integrity/syntax of the EA bits of the instruction
        *if bad EA, jump to BADEACODE, where i/o will take care of it
        
        *make sure when you leave an EA func that you also read in and either use
        *or ignore immediate/absoluate data, so that we can we ready to start reading
        *in the next instruction.


*Now we know this instruction is exactly ANDI, lets set everything up for EA.
IS_ANDI
EA_ANDI


*Now we know this instruction is exactly EORI, lets set everything up for EA.
IS_EORI
EA_EORI


*Found a possible BCHG(dynamic) instruction. Verify its bit integrity and then set
* everything up for EA if is a legit instruction. Assuming D0 holds full instruction.
IS_BCHG_D
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
                
        *Should have a valid BCHG(dynamic) instruction. Set data up for EA.
        *TODO:
        MOVE.B  #14,D3
        JMP     EA_BCHG_D

EA_BCHG_D


*Now we know this instruction is exactly BCHG(static), lets set everything up for EA.
IS_BCHG_S
EA_BCHG_S


*Now we know this instruction is exactly CMPI, lets set everything up for EA.
IS_CMPI
EA_CMPI


*STARTS WITH 0001, MOVE.B-----------------------------------
BUCKET_0001
BUCKET1_BITS    EQU $1
        
        *some code...


*STARTS WITH 0010, MOVE.L-----------------------------------
BUCKET_0010
BUCKET2_BITS    EQU $2

        *some code...


*STARTS WITH 0011, MOVE.W-----------------------------------
BUCKET_0011
BUCKET3_BITS    EQU $3

        *some code...


*STARTS WITH 0100, MOVEM | MULS(L) | LEA | CLR | JSR | RTS--
BUCKET_0100
BUCKET4_BITS    EQU $4

        *some code...


*STARTS WITH 0101, SUBQ-------------------------------------
BUCKET_0101
BUCKET5_BITS    EQU $5

        *some code...


*STARTS WITH 0110, BCC--------------------------------------
BUCKET_0110
BUCKET6_BITS    EQU $6

        *some code...


*STARTS WITH 1000, DIVU-------------------------------------
BUCKET_1000
BUCKET8_BITS    EQU $8

        *some code...


*STARTS WITH 1001, SUBA-------------------------------------
BUCKET_1001
BUCKET9_BITS    EQU $9

        *some code...


*STARTS WITH 1011, EOR | CMP | CMPA-------------------------
BUCKET_1011
BUCKETB_BITS    EQU $B

        *some code...


*STARTS WITH 1100, MULS(W) | AND----------------------------
BUCKET_1100
BUCKETC_BITS    EQU $C

        *some code...


*STARTS WITH 1101, ADD | ADDA-------------------------------
BUCKET_1101
BUCKETD_BITS    EQU $D

        *some code...


*STARTS WITH 1110, ASR(REGSHIFT) | ASR(MEMSHIFT)------------
*                  LSL(REGSHIFT) | LSL(MEMSHIFT)------------
*                  ROL/ROR(REGROTATE) | ROLS/ROR(MEMROTATE)-
BUCKET_1110
BUCKETE_BITS    EQU $E     

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
  
THEEND  MOVE.B  #9,D0
        TRAP    #15             Halt Simulator        
        
CR      EQU     $0D             ASCII code for Carriage Return
LF      EQU     $0A             ASCII code for Line Feed
MESSAGE     DC.B	'-------------------------------------------------------------',CR,LF
			DC.B	'||               Welcome to ZETA Disassembler              ||',CR,LF
			DC.B	'-------------------------------------------------------------',CR,LF,CR,LF
			DC.B	'*************************************************************',CR,LF
			DC.B	'*                                                           *',CR,LF
			DC.B	'* Authors: Brandon Roth, Dwayne Honeycutt, Teresia Djunaedi *',CR,LF
			DC.B	'*                                                           *',CR,LF
			DC.B	'*************************************************************',CR,LF,CR,LF
			DC.B    'Starting disassembler...',CR,LF,CR,LF
			DC.B	'Please type in your starting address request: ',0
			
GET_ENDADDR	DC.B	' ',CR,LF
			DC.B	'Please type in your ending address request: ',0
			DC.B	' ',CR,LF

FNDADDI     DC.B    'Found an ADDI opcode',CR,LF,0
FNDBCHG_D   DC.B    'Found a BCHG(dynamic) opcode',CR,LF,0
*for now, i guess every OPCODE will have a corresponding 'found it' msg...

BADEAMSG    DC.B    'BAD EA, WHY?!',CR,LF,0
BADOPMSG    DC.B    'BAD OP CODE, WHY?!',CR,LF,0
        
        END     START
        


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
