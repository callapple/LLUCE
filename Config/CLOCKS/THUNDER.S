            LST   OFF
            TR
            TR    ADR
*-------------------------------
* Thunderclock Driver - 24 hrs
*-------------------------------
* Date Revised: 08/04/87
*-------------------------------

            REL
            DSK   CLOCKS/REL/THUNDER

lnbuf       =     $200

thunder     ENT
            ORG   $A00

*-------------------------------

slot        HEX   40
mode        DB    0

            JMP   getdate
            JMP   gettime
            JMP   setdate

; get the date in prodos/gbbs format
getdate     JSR   $BF00
            HEX   82
            DW    0

            LDX   $BF90
            LDA   $BF91
setdate     RTS

* get the current time
*-------------------------------
gettime     JSR   rdtime
            LDA   mode
            BPL   gtime1
            JSR   convert

gtime1      LDX   #<timestr   ; point to string
            LDA   #>timestr
            RTS

* read time from clock
*-------------------------------
rdtime      BIT   initbyt     ; has routine been called before?
            BMI   clock1      ; yep

            LDA   slot        ; get clock slot
            LUP   4
            LSR
            --^
            ORA   #$C0        ; make into $Cn form

            STA   clock2+2    ; modify code for slot
            STA   clock3+2
            DEC   initbyt     ; show routine has been init'ed

clock1      LDA   #"#"        ; use "&" mode (24 hour)
clock2      JSR   $C00B       ; modified ($C40B)
clock3      JSR   $C008       ; modified ($C408)

            LDY   #0
clock4      LDA   lnbuf+9,y   ; get time from input buffer
            STA   timestr,y
            INY
            CPY   #8
            BNE   clock4
            LDA   #":"        ; put colens back into string
            STA   timestr+2
            STA   timestr+5
            LDA   #' '
            STA   timestr+9   ; make sure that the am/pm is reset
            STA   timestr+10
            RTS

* convert time to 12 hour format
*-------------------------------

convert     LDA   timestr     ;convert to 12 hour
            LDX   timestr+1

            AND   #$F
            TAY
            TXA
            AND   #$F

            DEY
            BMI   conv2
            CLC
            ADC   #10
            DEY
            BMI   conv2
            ADC   #10

conv2       CMP   #12
            BNE   conv2a
            LDA   #24
conv2a      TAY
            BNE   conv3
            LDA   #12

conv3       LDX   #'A'
            CMP   #13
            BCC   conv4

            SBC   #12
            LDX   #'P'

conv4       LDY   #'0'
conv5       CMP   #10
            BCC   conv6

            SBC   #10
            INY
            BNE   conv5

conv6       ORA   #'0'
            STA   timestr+1
            STY   timestr
            STX   timestr+9
            RTS

* data area
*-------------------------
initbyt     HEX   00
timestr     ASC   '00:00:00   '00

            DS    \

