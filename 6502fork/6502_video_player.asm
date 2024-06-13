;6502 video player for the Easy6502 emulator (modified for higher clock speed)

;32x32 20fps video is processed so each pixel turns into a bit, 
;8 bits forming a byte on the file
;this script takes each byte from the rom data,
;shifts all 8 bits out and then
;draws each one of them into the screen

;the modified emulator instead of having the entire rom inserted into the memory space, splits it into 8kb banks
;which can be accessed one at a time from a certain range

;0xfd:            current rom bank index
;0x1000 - 0x3000: current rom bank data

;also the original emulator runs 97 instructions every 15ms, this one (should) run as much instructions per second as possible 
;(i also implemented some sort of "vsync" feature, so the video player can actually run 20fps,
;because otherwise it would just freeze the current tab)

define vsync              $f0

define currentPixelPosH   $02
define currentPixelPosL   $01

define currentBank        $fd
define currentBankChunkH  $04
define currentBankChunkL  $03

define accumulatorStack   $00

lda #$00
sta currentBank

init:
 lda #$00
 ldy #$00
 sta currentPixelPosL
 sta currentBankPosL
 sta accumulatorStack
 lda #$10
 sta currentBankChunkH
 lda #$02
 sta currentPixelPosH
 jmp loop

resetCurPixel:                  ;resets the pixel cursor back to top left
 lda #$00
 sta currentPixelPosL
 lda #$02
 sta currentPixelPosH
 sta vsync                      ;halts execution for 50ms
 rts

incCurPixelH:                   ;increases the high byte of the pixel cursor
 inc currentPixelPosH
 lda currentPixelPosH
 cmp #$06
 beq resetCurPixel              ;cursor gets past #$05FF (bottom right corner of the canvas)
 rts

incCurPixelL:                   ;increases low byte of pixel cursor
 inc currentPixelPosL
 beq incCurPixelH               ;increases high byte if it overflows
 rts

incCurBank:                     ;(same thing from pixel cursor is done with the rom banks)
 inc currentBank
 lda #$00
 sta currentBankChunkL
 lda #$10
 sta currentBankChunkH
 rts

incCurBankChunkH:
 inc currentBankChunkH
 lda currentBankChunkH
 cmp #$30
 beq incCurBank
 rts

incCurBankChunkL:
 inc currentBankChunkL
 beq incCurBankChunkH
 rts

paint:                     
 asl                            ;shifts the highest bit (which is the current pixel) out into the carry
 sta accumulatorStack           ;backs up the current byte
 lda #$00
 rol                            ;shifts the carry bit into accumulator
 sta (currentPixelPosL), Y      ;draws the pixel into the current pixel cursor position
 jsr incCurPixelL               ;increases the pixel cursor position
 lda accumulatorStack           ;loads the current byte backup
 dex
 beq incCurBankChunkL           ;if all bits from the current byte have been processed, exits the loop
 jmp paint                      ;otherwise continue processing the other bits

loop:
 lda (currentBankChunkL),Y      ;loads the current byte into accumulator
 ldx #$08                       ;the X register keeps track of the current bit to be processed
 jsr paint                      ;bleh
 jmp loop
