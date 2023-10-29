\\
\\
\\decrunch_extreme.asm
\\
\\NMOS 6502 decompressor for data stored in TSCrunch format.
\\
\\This code is written for the BeebAsm assembler.
\\
\\Copyright Antonio Savona 2022.
\\
\\


\\#define INPLACE 		\\Enables inplace decrunching. Use -i switch when crunching. 

IF INPLACE

MACRO TS_DECRUNCH src
{
		lda #<src
		sta tsget
		lda #>src
		sta tsget + 1
		jsr tsdecrunch
}
ENDMACRO

ELSE

MACRO TS_DECRUNCH src, dst
{
		lda #<src
		sta tsget
		lda #>src
		sta tsget + 1
		lda #<dst
		sta tsput
		lda #>dst
		sta tsput + 1
		jsr tsdecrunch
}
ENDMACRO

ENDIF

.tsdecrunch
{
	.decrunch

	IF INPLACE
			ldy #$ff
		.l1	iny
			lda (tsget),y
			sta tsput , y	\\last iteration trashes lzput, with no effect.
			cpy #3
			bne l1 
			
			pha
			
			lda lzput
			sta optRun + 1
			
			ldx #$d0 \\bne opcode
			and #1
			bne skp1
			ldx #$29 \\and immediate opcode
		.skp1
			stx optOdd 

			tya
			ldy #0
			beq update_getonly
	ELSE 
			ldy #0			
	
			lda (tsget),y
			sta optRun + 1

			ldx #$d0 \\bne opcode
			and #1
			bne skp1
			ldx #$29 \\and immediate opcode
		.skp1
			stx optOdd 
			
			inc tsget
			bne entry2
			inc tsget + 1
	ENDIF
	
	.entry2		
			lda (tsget),y
                        tax
			
			bmi rleorlz
			
			cmp #$20
			bcs lz2	
	\\literal
			
	IF INPLACE
			
			inc tsget
			beq updatelit_hi
		.return_from_updatelit
			and #1
			bne odd1
		
		.ts_delit_loop

			lda (tsget),y
			sta (tsput),y
			iny
			dex
		.odd1	
			lda (tsget),y
			sta (tsput),y
			iny
			dex
			
			bne ts_delit_loop	
			
			tya
			tax
			\\carry is clear
			ldy #0
	ELSE	\\not inplace
			tay
		
			and #1
			bne odd1
				
		.ts_delit_loop
			
			lda (tsget),y
			dey
			sta (tsput),y
		.odd1
			lda (tsget),y
			dey
			sta (tsput),y
			
			bne ts_delit_loop
			
			txa
			inx
	ENDIF
			
	.updatezp_noclc
			adc tsput
			sta tsput
			bcs updateput_hi
		.putnoof
			txa
		.update_getonly
			adc tsget
			sta tsget
			bcc entry2
			inc tsget+1
			bcs entry2
	
	IF INPLACE		
	.updatelit_hi
			inc tsget+1
			bcc return_from_updatelit
	ENDIF		
	.updateput_hi
			inc tsput+1
			clc
			bcc putnoof
	
	\\LZ2	
		.lz2
			beq done
			
			ora #$80
			adc tsput
			sta lzput
			lda tsput + 1
			sbc #$00
			sta lzput + 1 		
	
			\\y already zero			
			lda (lzput),y
			sta (tsput),y
			iny		
			lda (lzput),y
			sta (tsput),y
					
			tya
			dey
			
			adc tsput
			sta tsput
			bcs lz2_put_hi
		.skp2	
			inc tsget
			bne entry2
			inc tsget + 1
			bne entry2			

		.lz2_put_hi
			inc tsput + 1
			bcs skp2	
										
	.rleorlz
			
			and #$7f
                        lsr a
			bcc ts_delz		

		\\RLE
			beq zeroRun
				
		.plain
			
			iny
			sta tstemp		\\number of bytes to de-rle		

			lsr a			\\c = test parity
		
			lda (tsget),y	\\fetch rle byte
			ldy tstemp
		.runStart
			sta (tsput),y

			bcs odd
			sec
			
		.ts_derle_loop
			dey
			sta (tsput),y
		.odd
	
			dey
			sta (tsput),y
			
			bne ts_derle_loop
			
			\\update zero page with a = runlen, x = 2 , y = 0 
			lda tstemp		
			ldx #2
			bcs updatezp_noclc
	
					
	   .done
IF INPLACE	   
	   		pla
	   		sta (tsput),y
ENDIF	   		
			rts	
	

	\\LZ
	.ts_delz
			
			lsr a
			sta lzto + 1
			
			iny
			
			lda tsput
			bcc long
			
			sbc (tsget),y
			sta lzput
			lda tsput+1
	
			sbc #$00
		
			ldx #2
			\\lz MUST decrunch forward	
	.lz_put
			sta lzput+1
			
			ldy #0
		
			lda lzto + 1
			lsr a
			bcs odd2

			lda (lzput),y
			sta (tsput),y
	.ts_delz_loop			
			iny

	.odd2		

			lda (lzput),y
			sta (tsput),y

			iny
		
			lda (lzput),y
			sta (tsput),y
			
	.lzto	cpy #0
			bne ts_delz_loop 
			
			tya
			
			\\update zero page with a = runlen, x = 2, y = 0
			ldy #0
			\\clc not needed as we have len - 1 in A (from the encoder) and C = 1
			jmp updatezp_noclc
	
	.zeroRun		
	.optRun 	ldy #255
			sta (tsput),y
	.optOdd 	bne odd3
	.ts_dezero_loop
			dey
			sta (tsput),y
		.odd3
			dey
			sta (tsput),y
			bne ts_dezero_loop
			
		        lda optRun + 1
		    
			ldx #1
			jmp updatezp_noclc		

	.long
			\\carry is clear and compensated for from the encoder
			adc (tsget),y
			sta lzput
			iny
			lda (tsget),y
                        tax
			ora #$80
			adc tsput + 1
				
			cpx #$80
			rol lzto + 1
			ldx #3
	
			bne lz_put
	
}