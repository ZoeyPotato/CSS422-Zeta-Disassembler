*-----------------------------------------------------------
* Title      :Brandon's Mini Disassembler
* Written by :Brandon Roth
* Date       :2/23/2014
* Description:Disassembles and stuff!
*-----------------------------------------------------------
START   ORG $1000   *Start program at provided location
ST_ADDR EQU $7FC0   *Starting address of input test file
STACK   EQU $7000   *Stack location

        MOVEA.W #ST_ADDR,A0 *Load starting location of test input file into A0
        LEA     MESSAGE,A1  *Loads MESSAGE into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        
*-----------------------------------------------------------        
* Start of Mini Disassembler
*-----------------------------------------------------------        

GRAB_NEXT_OP
        *Move byte data at (A0) into D0. D0 is now the first 8 bits of the first
        *OP instruction from the test input file
        CLR.L   D0
        MOVE.B  (A0),D0
        *Clear the first 4 bits from 8 bit value in D0. I am doing this so we retain
        *just the last 4 bits. These LAST 4 bits are FIRST 4 bits the of the first OP
        *CODE. By using only the first 4 bits of an instruction, we can begin to
        *narrow down which particular OP code the instruction actually is!
        *BCLR.L  #$00,D0 
        *BCLR.L  #$01,D0
        *BCLR.L  #$02,D0
        *BCLR.L  #$03,D0
        *Now I need to shift these 4 bit values right by 4 bits, so that these 4 bits
        *are in the LSB position. Then I can begin to compare this value with others 
        *and start decoding this OP CODE.
        LSR.W   #$04,D0
        *Now try to figure out what OP CODE this is using these 4 bits.        
        *Later I will not try to go directly to op codes, but to a 'category' of
        *potential codes it could be (since many share the same first 4 bits).

*Decode a NOP OP--------------------------------------------
NOP_OP  EQU $04 *Store as byte, but I really only care about first 4 bits

        CLR.L   D1
        MOVE.B  #NOP_OP,D1  *Load the first 4 bits (really a byte) of NOP into D1
        *Compare the first 4 bits of the first OP CODE with first 4 of NOP. 
        *If equal we have a NOP instruction. Branch to 'ISNOP' and decode the rest.
        CMP.B   D0,D1
        BEQ     ISNOP
        
*Decode a MOVE OP-------------------------------------------
*MOVEOP EQU %00 *First two bits of move are always 00
        *MOVE.B  (A0),D0     *Move the byte data at A0 into D0 (**i really want only 4 bits...)
        
        
        *We didn't find a valid OP CODE from given instruction, go to next OP in mem
        JMP     GRAB_NEXT_OP
        
*Verify valid NOP syntax------------------------------------
ISNOP   
NOPALL  EQU $4E71   *The entire NOP instruction equals this constant hex value
        MOVE.W  (A0),D0 *Move the WHOLE instruction from mem into D0
        MOVE.W  #NOPALL,D1 *Move the entire NOP instruction into D1
        *Compare D0 to D1, if equal we found a match, print some message.
        *If not equal, there was some syntax error, print error message.
        CMP.W   D0,D1
        BEQ     CORRECTNOP
        BRA.S   ERRORNOP
CORRECTNOP
        *Output some message, hey we found a NOP or something...
        LEA     FOUNDNOP,A1 *Loads FOUNDNOP into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        JMP     GRAB_NEXT_OP    *Jump and go to the next instruction
ERRORNOP
        *Output some error message, hey incorrect NOP syntax or something...
        LEA     BADNOP,A1   *Loads BADNOP into address register A1
        MOVE.B  #14,D0      *Moves the number 14 into data register D0
        TRAP    #15         *Displays Message
        JMP     GRAB_NEXT_OP    *Jump and go to the next instruction
        
*Verify valid MOVE syntax-----------------------------------
*ISMOVE  *is a move instruction, try to decode rest.
        
*-----------------------------------------------------------        
* End of Mini Disassembler
*-----------------------------------------------------------    
        
THEEND  MOVE.B  #9,D0
        TRAP    #15             Halt Simulator        
        
CR      EQU     $0D             ASCII code for Carriage Return
LF      EQU     $0A             ASCII code for Line Feed
MESSAGE DC.B    'Hey, going to try to disassemble MOVE.B',CR,LF,0
FOUNDNOP    DC.B    'Hey, found a NOP!',CR,LF,0
BADNOP  DC.B    'Hey, something is wrong with this NOP!',CR,LF,0
        END     START
        


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
