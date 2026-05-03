; Apple 1 / RC6502 PIA I/O for cc65 (-t none)
;
; Implements _write so that printf/puts/fwrite all work via the
; 6820 PIA at the standard Apple 1 addresses.
;
; Calling convention (cc65 __fastcall__, 3-arg):
;   count  in A:X (last argument, passed in registers)
;   buf    on cc65 software stack  (popped with popax -> A:X)
;   fd     on cc65 software stack  (popped with popax -> A:X, discarded)

        .export _write

        .import popax
        .importzp ptr1, ptr2

KBD     = $D010         ; keyboard data
KBDCR   = $D011         ; keyboard control  — bit 7 = key ready
DSP     = $D012         ; display data
DSPCR   = $D013         ; display control

; int write(int fd, const void *buf, unsigned count)
        .proc   _write

        sta     ptr2            ; save count low byte
        stx     ptr2+1          ; save count high byte

        jsr     popax           ; pop buf pointer
        sta     ptr1
        stx     ptr1+1

        jsr     popax           ; pop fd (discard)

        ; write ptr2 bytes from ptr1 to the Apple 1 display
        ldy     #0
        ldx     ptr2+1          ; high byte of count (full 256-byte pages)
        beq     partial

pages:  lda     (ptr1),y
        jsr     outchar
        iny
        bne     pages
        inc     ptr1+1
        dex
        bne     pages

partial:
        ldx     ptr2            ; remaining bytes (< 256)
        beq     done

bytes:  lda     (ptr1),y
        jsr     outchar
        iny
        dex
        bne     bytes

done:   lda     ptr2            ; return count in A:X
        ldx     ptr2+1
        rts

; Send one character to the display.
; Apple 1 protocol: wait while DSP bit 7 is set (busy), then write
; the character with bit 7 set as the data-ready strobe.
; LF ($0A) is converted to CR ($0D) — the Apple 1 terminal only has CR.
outchar:
        cmp     #$0A
        bne     @send
        lda     #$0D
@send:  ora     #$80            ; bit 7 = data strobe
        pha
@busy:  bit     DSP
        bmi     @busy           ; loop while display busy (bit 7 set)
        pla
        sta     DSP
        rts

        .endproc
