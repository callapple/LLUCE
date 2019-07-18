            LST   OFF
            TR
            TR    ADR
********************************
*                              *
* GBBS Config - Prodos Storage *
*                              *
********************************

*-------------------------------
* Date: 3/11/88
*-------------------------------

re_stor     JSR   cls         ; clear screen

            LDA   #<hdrbuf
            STA   temp
            LDA   #>hdrbuf
            STA   temp+1

            LDX   #0          ; start pointers
            LDY   #0
            STY   temp2       ; set device count at zero
stor2       LDA   devnam,x    ; get drive info
            STA   temp2+1

stor3       LDA   devnam,x    ; copy pathname
            STA   (temp),y
            INX
            INY
            DEC   temp2+1
            BPL   stor3

            CLC
            LDA   temp        ; go to next address
            ADC   #128
            STA   temp
            LDA   temp+1
            ADC   #0
            STA   temp+1

            LDY   #0
            INC   temp2       ; inc number of pathnames
            LDA   temp2
            CMP   #12         ; done all 12?
            BNE   stor2       ; nope

stor4       JSR   TopBox
            JSR   print
            DB    1,2,21
            ASC   '- Edit Drive Specifier Allocation -'
            DB    1,4,5
            ASC   'Please refer to Appendix D of your user'
            ASC   ' manual for more information.'00
            JSR   cls

            LDX   #-1
stor5       INX
            JSR   shwpfx      ; show drive
            LDA   #cr         ; add end of line
            JSR   cout
            CPX   #11
            BCC   stor5       ; show all 12 entries

stor6       JSR   print
            DB    1,20,0
            ASC   'Edit: [A-L] or Q=Quit ? '00

            LDA   #%10000000
            STA   inpmode     ; set mode 0
            LDA   #1
            STA   maxlen      ; set length to 1

            JSR   inpln       ; get input
            LDA   lnbuf
            CMP   #'Q'        ; quit?
            BNE   stor7       ; yep

            JMP   stor9       ; handle quit

stor7       SEC
            SBC   #'A'        ; make into range
            CMP   #12         ; is it ok?
            BCS   stor6       ; nope

            PHA
            TAX
            JSR   finddrv     ; find the drive location

            LDX   #20
            JSR   cleos       ; claer last line

            LDX   #20         ; position
            STX   cv
            LDX   #0
            STX   ch

            PLA
            CLC
            ADC   #'A'        ; show drive specifier
            JSR   cout
            JSR   print
            ASC   ': /'00

            LDA   #30         ; make max length 32 total
            STA   maxlen
            LDA   #%10100001
            STA   inpmode

            JSR   inpln
            LDA   lnbuf-1,y
            CMP   #'/'        ; check for ending slash
            BNE   stor7f

            LDA   #cr         ; delete ending slash
            STA   lnbuf-1,y

stor7f      LDA   lnbuf       ; did they just do a return?
            CMP   #cr
            BNE   stor8       ;nope

            JSR   print
            DB    1,20,0
            ASC   'Clear contents of this line [Y/N] ? '00

            JSR   inpyn       ; get answer
            BCS   stor7a      ; nope

            LDY   #0
            TYA               ; nullify an entry
            STA   (temp4),y
stor7a      JMP   stor4       ; do another

stor8       LDX   #0
            LDY   #2
stor8a      LDA   lnbuf,x     ; copy pathname
            STA   (temp4),y
            INX
            INY
            CMP   #cr
            BNE   stor8a

            LDY   #0          ; save length
            TXA
            STA   (temp4),y
            INY
            LDA   #'/'        ; add leading slash
            STA   (temp4),y
            JMP   stor4       ; show results

stor9a      JMP   start       ; abort out

stor9       LDX   #20
            JSR   cleos       ; clear bottom
            JSR   print
            DB    1,20,0
            ASC   'Is the above correct [Y/N] ? '00
            JSR   inpyn
            BCS   stor9a      ; nope

            LDA   #<hdrbuf
            STA   temp        ; point at pathnames
            LDA   #>hdrbuf
            STA   temp+1

            LDX   #0
            LDY   #0
            STY   temp2       ; start with drive A:
stor9b      LDA   (temp),y
            STA   temp2+1     ; save length

stor9c      LDA   (temp),y    ; get data
            STA   devnam,x
            INX
            CPX   #$f0        ; is table ok?
            BEQ   stor9d      ; nope, it is too big

            INY
            DEC   temp2+1     ; count down length
            BPL   stor9c

            CLC
            LDA   temp
            ADC   #$80        ; go to next field
            STA   temp
            LDA   temp+1
            ADC   #0
            STA   temp+1

            LDY   #0          ; reset pointer within field
            INC   temp2
            LDA   temp2       ; done all 12 yet?
            CMP   #12
            BNE   stor9b      ; nope, loop
            JMP   wrtchg      ; write changes to disk

stor9d      JSR   cls
            JSR   print
            ASC   'ERROR !',0d,0d
            ASC   'Overflow error. Too much data within '
            ASC   'drive table. Cut down on the amount',0d,0d
            ASC   'of data within the table.'
            DB    1,20,0
            ASC   'Press [RETURN] to continue... ',00

stor9e      JSR   rdkey       ; wait for a return
            CMP   #cr
            BNE   stor9e
            JMP   stor4       ; get new stuff

; point to the pathname of a device
finddrv     LDA   #0          ; set lower to 0
            STA   temp4
            TXA
            LSR
            ROR   temp4       ; put extra into low
            CLC
            ADC   #>hdrbuf
            STA   temp4+1     ; setup high
            RTS

; show a pathname of a device
shwpfx      JSR   finddrv     ; position
            TXA
            CLC
            ADC   #'A'        ; show drive name
            JSR   cout

            LDA   #':'        ; add colon
            JSR   cout

            LDA   #' '        ; put in space
            JSR   cout

            LDY   #0          ; check for data
            LDA   (temp4),y
            STA   temp2+1
            BEQ   prdrv3      ; nope, there isnt any

prdrv2      INY
            LDA   (temp4),y   ; get byte of name
            JSR   conv
            JSR   cout        ; show it
            DEC   temp2+1
            BNE   prdrv2      ; keep going

            CLC
            RTS

prdrv3      SEC               ; no data
            RTS

