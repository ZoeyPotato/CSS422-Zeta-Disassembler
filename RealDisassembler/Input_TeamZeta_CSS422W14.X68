*-----------------------------------------------------------
* Title      :Brandon's Mini Disassembler Input
* Written by :Brandon Roth
* Date       :2/23/2014
* Description:***
*-----------------------------------------------------------
START   ORG $7FC0

        MOVE.L  #$00008000,A0

Bucket0000  *BUCKET0000 TEST INSTRUCTIONS
*ADDI.B
*        ADDI.B  #$AB,D1
*        ADDI.B  #$CD,(A0)        
*        ADDI.B  #$EF,(A0)+
*        ADDI.B  #$09,-(A0)      *Weird bug when this is equal or less than #$08...
*        ADDI.B  #$0A,$8200
*        ADDI.B  #$0B,$00008100
*        
*ADDI.W
*        ADDI.W  #$AB,D1
*        ADDI.W  #$CD,(A0)        
*        ADDI.W  #$EF,(A0)+
*        ADDI.W  #$09,-(A0)      *Weird bug when this is equal or less than #$08...
*        ADDI.W  #$0A,$8200
*        ADDI.W  #$0B,$00008100     
*
*ADDI.L
*        ADDI.L  #$AB,D1
*        ADDI.L  #$CD,(A0)        
*        ADDI.L  #$EF,(A0)+
*        ADDI.L  #$09,-(A0)      *Weird bug when this is equal or less than #$08...
*        ADDI.L  #$0A,$8200
*        ADDI.L  #$0B,$00008100 
*
*EORI.B
*        EORI.B  #$AB,D1
*        EORI.B  #$CD,(A0)        
*        EORI.B  #$EF,(A0)+
*        EORI.B  #$01,-(A0)    
*        EORI.B  #$0A,$8200
*        EORI.B  #$0B,$00008100
*        
*CMPI.B
*        CMPI.B  #$AB,D1
*        CMPI.B  #$CD,(A0)        
*        CMPI.B  #$EF,(A0)+
*        CMPI.B  #$01,-(A0)    
*        CMPI.B  #$0A,$8200
*        CMPI.B  #$0B,$00008100                
*
*BCHG_dynamic
*        BCHG.L  D0,D1
*        BCHG.B  D0,(A0)
*        BCHG.B  D0,(A0)+
*        BCHG.B  D0,-(A0)
*        BCHG.B  D0,$8200
*        BCHG.B  D0,$00008100        
*               
*BCHG_static
*        BCHG.L  #$AB,D1
*        BCHG.B  #$CD,(A0)
*        BCHG.B  #$EF,(A0)+
*        BCHG.B  #$01,-(A0)
*        BCHG.B  #$02,$8200
*        BCHG.B  #$03,$00008100  
*
*LEA
*        LEA (A0),A1
*        LEA $8200,A1
*        LEA $00008100,A1
*
CLR
        CLR.L   D1
        CLR.L   (A0)
        CLR.L   (A0)+
        CLR.L   -(A0)
        CLR.L   $8200
        CLR.L   $00008100
        
*MULS_word
*        MULS.W  D0,D1
*        MULS.W  (A0),D1
*        MULS.W  (A0)+,D1
*        MULS.W  -(A0),D1
*        MULS.W  $8200,D1
*        MULS.W  $00008100,D1
*        MULS.W  #$AB,D1
        
*JUST REMEMBERED, SHE COULD GIVE IMMEDIATE DATA WITH A '#' OR A '#%' NOT JUST '#$'

        *BCHG.L  #12,D1  *Static
        *CMPI.B  #$12,D1         
        
        END START
        
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
