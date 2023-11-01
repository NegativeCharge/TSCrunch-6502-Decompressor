LOAD_ADDR = &5800

\ Allocate vars in ZP
ORG &80
GUARD &9F
.zp_start
    INCLUDE ".\lib\tscrunch.h.asm"
.zp_end

\ Main
CLEAR 0, LOAD_ADDR
GUARD LOAD_ADDR
ORG &1100
.start
    INCLUDE ".\lib\tscrunch.s.asm"

.entry_point

    \\ Turn off cursor by directly poking crtc
    lda #&0b
    sta &fe00
    lda #&20
    sta &fe01

    lda #<comp_data
    sta tsget
    lda #>comp_data
    sta tsget + 1
    lda #<LOAD_ADDR
    sta tsput
    lda #>LOAD_ADDR
    sta tsput + 1
    
    jsr tsdecrunch
    
.loop
    jmp loop
    
.comp_data
    INCBIN ".\tests\test_0.bin.tsc"

.end

SAVE "TSCRNCH", start, end, entry_point

\ ******************************************************************
\ *	Memory Info
\ ******************************************************************

PRINT "------------------------"
PRINT " TSCrunch Decompressor  "
PRINT "------------------------"
PRINT "CODE size      = ", ~end-start
PRINT "DECOMPRESSOR SIZE = ", entry_point-start, "bytes"
PRINT "ZERO PAGE SIZE    = ", zp_end-zp_start, "bytes"
PRINT "------------------------"
PRINT "LOAD ADDR      = ", ~start
PRINT "HIGH WATERMARK = ", ~P%
PRINT "RAM BYTES FREE = ", ~LOAD_ADDR-P%
PRINT "------------------------"

PUTBASIC "loader.bas","LOADER"
PUTFILE  "BOOT","!BOOT", &FFFF  