*-----------------------------------------------------------
* Title      :Brandon's Mini Disassembler Input
* Written by :Brandon Roth
* Date       :2/23/2014
* Description:***
*-----------------------------------------------------------
START   ORG $7FC0

        *BUCKET0000 TEST INSTRUCTIONS
        ADDI.B  #12,D1
        *ANDI    #12,D1
        *EORI    #12,D1
        *BCHG.L  D0,D1   *Dynamic
        *BCHG.L  #12,D1  *Static
        *CMPI.B  #$12,D1         
        
        END START
        
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
