            LST   OFF
            TR
            TR    ADR
*-------------------------------
* Date: 3/11/88
*-------------------------------

            REL
temp2       =     $02

ch          =     $24
cv          =     $25

lnbuf       =     $200
filtbuf     =     $1000
hdrbuf      =     $1100

            DSK   REL/FILTER

TopBox      EXT
print       EXT
cls         EXT
cout        EXT
maxlen      EXT
inpmode     EXT
inpln       EXT
inpyn       EXT
cleos       EXT
start       EXT
get_cr      EXT

*-------------------------------
* profanity filter
*-------------------------------

; change profanity filter (yuk)

do_filt     ENT
            JSR   TopBox
            JSR   print
            DB    1,2,27
            ASC   '- Edit Profanity Filter -'
            DB    1,4,5
            ASC   'Please refer to Appendix E of your user'
            ASC   ' manual for more information.'00
            JSR   cls

            LDX   #0          ; move table to a different space
:loop       LDA   filtbuf,X   ; so we don't change it if they abort
            STA   hdrbuf,X
            DEX
            BNE   :loop

filt2       LDA   #0          ; start at #1
            STA   temp2

:filt3      LDX   temp2       ; get entry number
            JSR   fndword     ; find the word
            BCS   filt5       ; opps, end of table

            LDA   ch          ; save current horiz
            PHA

            LDA   temp2       ; print entry letter
            CLC
            ADC   #'A'
            JSR   cout
            INC   temp2       ; goto next entry next pass

            LDA   #')'        ; show a border
            JSR   cout
            INC   ch          ; move over 1 space

:filt4      LDA   hdrbuf,Y    ; get data
            PHP
            JSR   cout        ; print data
            INY
            PLP
            BPL   :filt4      ; keep showing

            PLA
            CLC
            ADC   #19
            STA   ch          ; move over horiz position

            LDA   #' '        ; either wrap or move 1 space
            JSR   cout
            JMP   :filt3

filt5       JSR   print
            DB    1,20,0
            ASC   'Cmd: A=Add, D=Delete, Q=Quit ? '00

            LDA   #1
            STA   maxlen      ; get command
            LDA   #%10000000
            STA   inpmode
            JSR   inpln

            LDA   lnbuf
            CMP   #'A'
            BNE   :tryd
            JMP   fl_add

:tryd       CMP   #'D'
            BEQ   fl_del
:tryq       CMP   #'Q'
            BNE   filt5
            JMP   fl_quit

*-------------------------------
* delete a word from list

fl_del      LDX   #20
            JSR   cleos       ; clear line
            JSR   print
            DB    1,20,0
            ASC   'Delete [A-'00

            CLC
            LDA   temp2
            ADC   #'@'
            JSR   cout        ; print range

            JSR   print
            ASC   '] ? '00

            LDA   #%10000000
            STA   inpmode     ; set mode

            JSR   inpln       ; get data
            LDA   lnbuf
            CMP   #'A'
            BCC   filt5       ; move back, error

            SEC
            SBC   #'A'        ; make into [0-xxx] range
            CMP   temp2
            BCC   *+5
            JMP   filt5       ; out of range

            PHA
            TAX
            INX
            JSR   fndword     ; locate second word
            STY   temp2+1     ; save offset
            PLA
            TAX
            JSR   fndword     ; locate first word
            LDX   temp2+1     ; point to second word

:fl_del2    LDA   hdrbuf,X    ; move data
            STA   hdrbuf,Y
            INY
            INX
            BNE   :fl_del2    ; loop
            JMP   filt2       ; show new screen

; add a word to list
fl_add      LDX   #20
            JSR   cleos       ; clear line
            JSR   print
            DB    1,20,0
            ASC   'Enter new word: '00

            LDA   #16         ; 16 chars max length
            STA   maxlen
            LDA   #%10000000
            STA   inpmode     ; set input mode

            JSR   inpln       ; get the data
            LDA   lnbuf
            CMP   #'A'
            BCC   :fl_add4    ; abort

            LDX   temp2       ; get last word
            JSR   fndword     ; find end
            STY   temp2+1     ; save current end

            LDX   #0
:fl_add2    LDA   lnbuf,X
            CMP   #'A'
            BCC   :fl_add3

            STA   hdrbuf,Y    ; add byte
            INX
            INY
            BNE   :fl_add2    ; and loop

            LDA   #0
            LDY   temp2+1     ; mark old end of table
            STA   hdrbuf,Y

            JSR   print
            DB    1,20,0
            ASC   'Error: Filter Table Overrun.   Press [RETURN] '00
            JSR   get_cr      ; wait for cr
:fl_add4    JMP   filt5       ; get new data

:fl_add3    LDA   #0          ; mark end of table
            STA   hdrbuf,Y
            DEY
            LDA   hdrbuf,Y    ; mark as last char
            ORA   #$80
            STA   hdrbuf,Y
            JMP   filt2       ; show new table

; quit from filter changer
fl_quit     LDX   #20
            JSR   cleos       ; clear bottom of screen
            JSR   print
            DB    1,20,0
            ASC   'Is the above table correct [Y/N] ? '00
            JSR   inpyn
            BCS   :fl_q1      ; nope!

            LDX   #0          ; put new table in place over
:loop       LDA   hdrbuf,X    ; the old table and return
            STA   filtbuf,X
            BNE   :loop
:fl_q1      JMP   start

; locate a word [indexed by x]
fndword     LDY   #0
            CPX   #0          ; we done?
            BEQ   :fndwd2     ; yep

:fndwd1     LDA   hdrbuf,Y    ; loop until next word
            BEQ   :fndwd4     ; end of table

            INY               ; goto next byte
            ASL               ; check high bit
            BCC   :fndwd1

            DEX               ; count down entries
            BNE   :fndwd1

:fndwd2     LDA   hdrbuf,Y
            BEQ   :fndwd4     ; opps, that is end marker

:fndwd3     CLC
            RTS               ; we are done

:fndwd4     SEC               ; opps, end of table
            RTS

