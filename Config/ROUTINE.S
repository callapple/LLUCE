            LST   OFF
            TR
            TR    ADR
********************************
*                              *
*   Config Program - Routine   *
*                              *
********************************

*-------------------------------
* Date: 3/11/88
*-------------------------------

            REL
cr          =     $D          ; cariage return
bs          =     8           ; backspace
can         =     $18         ; ctrl-x
esc         =     $27         ; escape
del         =     $7F         ; delete

temp        =     0
temp2       =     2
*temp3 = 4
temp4       =     6
x_save      =     9
y_save      =     $A
numptr      =     $1A
psave       =     $1C
prnt        =     $1E

ch          =     $24
cv          =     $25

lnbuf       =     $200
flname      =     $300

            DSK   REL/ROUTINE

cout        EXT               ; routine that are external to this one
plotchr     EXT

*-------------------------------
* print a line of text
*-------------------------------

print       ENT
            STA   psave       ; save all reg's
            STY   psave+1
            PLA
            STA   prnt        ; point to address of data
            PLA
            STA   prnt+1

:print2     INC   prnt        ; inc address
            BNE   :print3
            INC   prnt+1

:print3     LDY   #0
            LDA   (prnt),Y    ; get data
            CMP   #1
            BNE   :pr3a

:pr3v       JSR   gettmp
            JSR   gettmp      ; get horiz/vert address
            STA   cv
            JSR   gettmp
            STA   ch
            JMP   :print3

:pr3a       PHA
            JSR   cout        ; display it
            PLA
            BNE   :print2     ; keep going

            JSR   gettmp
            LDA   psave
            LDY   psave+1
            JMP   (prnt)

*-------------------------------
* get a byte from temp and advance pointers
*-------------------------------

gettmp      ENT
            LDY   #0
            LDA   (prnt),Y
            INC   prnt
            BNE   :gettmp2
            INC   prnt+1
:gettmp2    RTS

*-------------------------------
* put a cursor, get a key, remove cursor, return
*-------------------------------

rdkey       ENT
            STX   x_save      ; save x & y
            STY   y_save
            LDA   #$5F
            JSR   plotchr     ; bypass cout for speed

:rdkey2     LDA   $C000       ; check for a key
            BPL   :rdkey2
            STA   $C010       ; reset flag
            AND   #$7F

            STA   $C030
            STA   $C030       ; audio feedback

            PHA
            LDA   #' '        ; remove cursor
            JSR   plotchr
            PLA
            LDX   x_save
            LDY   y_save
            JSR   chk_esc     ; check for escape
            RTS

*-------------------------------
* get a line of input
*-------------------------------

inpln       ENT
            LDY   #0          ; start at first byte
:inpln1     JSR   rdkey       ; get data
:inpln1a    CMP   #cr         ; return
            BEQ   :inpln6
            CMP   #bs         ; back space
            BEQ   :inpln2
            CMP   #can        ; ctrl-x / cancel
            BEQ   :inpln2
            CMP   #del        ; delete
            BNE   :inpln3

:inpln2     CPY   #0          ; can we back up?
            BEQ   :inpln1     ; nope

            PHA
            JSR   prbs        ; backspace w/delete
            DEY               ; decrease line count
            PLA
            CMP   #can        ; if its a cancel
            BEQ   :inpln2     ; keep going
            BNE   :inpln1

:inpln3     CMP   #' '        ; if its a control char...
            BCC   :inpln1

            CPY   maxlen      ; check for max length
            BNE   :inpln4
            BRA   :inpln1

:inpln4     BIT   inpmode     ; do we convert?
            BPL   :inpln4a    ; nope

            JSR   conv        ; convert to upper

:inpln4a    BIT   inpmode     ; check the inpmode
            BVC   :inpln5

            CMP   #','        ; dont accept a comma
            BEQ   :inpln1
            CMP   #' '
            BNE   :inpln5     ; dont accept a space
            CPY   #0          ; for first char of the line
            BEQ   :inpln1

:inpln5     STA   lnbuf,Y     ; save char
            INY
            JSR   cout        ; print it
            JMP   :inpln1     ; loop

:inpln6     LDA   #cr
            STA   lnbuf,Y     ; save the return
            CPY   #0          ; was is just a return?
            BNE   :inpln7     ; nope

            LDA   inpmode     ; can we accept a blank line?
            AND   #$20
            BNE   :inpln7     ; yep

            BRA   inpln       ; dont take, cr, start over

:inpln7     LDA   inpmode     ; do cr?
            AND   #$10
            BNE   :inpln8     ; nope

            LDA   #cr
            JMP   cout        ; print the return AND exit

:inpln8     RTS

maxlen      ENT
            DB    0
inpmode     ENT
            DB    %00000000

*-------------------------------
* input a number in the range [1-x] where x={1-99}
*-------------------------------

inpnum      ENT
            STX   maxnum      ; save maximum number
            LDA   #2
            STA   maxlen      ; set length at 2
            LDA   ch
            STA   prnt+1      ; record currnt horiz offset
            LDA   #%00010000
            STA   inpmode     ; use input mode 0

:inpnum2    JSR   inpln       ; get line
            LDA   #0
            STA   prnt        ; make number init to 0

            LDA   lnbuf       ; get data
            SEC
            SBC   #'0'
            CMP   #10         ; in range?
            BCS   :inpnum5    ; nope, we are done

            STA   prnt        ; update total

            LDA   lnbuf+1     ; get more data
            SEC
            SBC   #'0'
            CMP   #10         ; in range?
            BCS   :inpnum5    ; nope

:inpnum3    DEC   prnt        ; count down 10's
            BMI   :inpnum4

            CLC
            ADC   #10         ; add 10 and loop
            BCC   :inpnum3

:inpnum4    STA   prnt        ; save new total
:inpnum5    LDA   prnt
            BEQ   :inpnum7    ; opps, problem

            CMP   maxnum      ; is it in range?
            BCC   :inpnum8
            BEQ   :inpnum8    ; all is well!

:inpnum7    LDA   ch
            CMP   prnt+1      ; at original spot?
            BEQ   :inpnum2    ; yep

            JSR   prbs        ; backup
            JMP   :inpnum7

:inpnum8    RTS

maxnum      DB    0

*-------------------------------
* print a backspace
*-------------------------------

prbs        ENT
            LDA   #bs         ; do a backspace w/delete
            JSR   cout
            LDA   #' '
            JSR   cout
            LDA   #bs
            JMP   cout

*-------------------------------
* input a 'y' or a 'n' for a yes/no situation
*-------------------------------

inpyn       ENT
            LDA   #1          ; max length 1
            STA   maxlen
            LDA   ch          ; save horiz position
            STA   temp+1
            LDA   #%10010000
            STA   inpmode

:inpyn2     JSR   inpln       ; get the line
            LDA   lnbuf
            CMP   #'Y'        ; did they say 'YES' ?
            CLC
            BEQ   :inpyn3     ; yep

            CMP   #'N'        ; did they say 'NO' ?
            SEC
            BEQ   :inpyn3     ; yep

            LDA   ch
            CMP   temp+1      ; are they the same?
            BEQ   :inpyn2

            JSR   prbs        ; backup
            JMP   :inpyn2

:inpyn3     RTS

*-------------------------------
* convert a character to uppercase
*-------------------------------

conv        ENT
            AND   #$7F        ; strip high
            CMP   #'a'        ; below 'a'?
            BCC   :conv2      ; yep

            CMP   #'z'+1      ; above 'z'?
            BCS   :conv2      ; yep

            SBC   #$1F        ; use clear carry for sbc $20
:conv2      RTS

*-------------------------------

copyinp     ENT
            STX   temp        ; point to dest
            STA   temp+1
            TYA
            PHA               ; save ending byte

            LDX   #0          ; start offsets
            LDY   #0
:copyin2    LDA   lnbuf,X     ; get byte
            INX
            CMP   #cr         ; we done?
            BEQ   :copyin3    ; yep

            STA   (temp),Y    ; copy and inc pointers
            INC   temp
            BNE   :copyin2
            INC   temp+1
            BNE   :copyin2

:copyin3    PLA               ; get back ending byte
            BEQ   :copyin4    ; opps, there wasnt one

            STA   (temp),Y    ; save ending byte
            INC   temp
            BNE   :copyin4    ; inc pointers
            INC   temp+1

:copyin4    LDX   temp        ; return pointers
            LDA   temp+1
            RTS

*-------------------------------
* copy a line of input to some location uppercase
*-------------------------------

ucopyinp    ENT
            STX   temp        ; point to dest
            STA   temp+1
            TYA
            PHA               ; save ending byte

            LDX   #0          ; start offsets
            LDY   #0
:ucopy2     LDA   lnbuf,X     ; get byte
            INX
            CMP   #cr         ; we done?
            BEQ   :ucopy3     ; yep

            JSR   conv        ; convert to uppercase
            STA   (temp),Y    ; copy and inc pointers
            INC   temp
            BNE   :ucopy2
            INC   temp+1
            BNE   :ucopy2

:ucopy3     PLA               ; get back ending byte
            BEQ   :ucopy4     ; opps, there wasnt one

            STA   (temp),Y    ; save ending byte
            INC   temp
            BNE   :ucopy4     ; inc pointers
            INC   temp+1

:ucopy4     LDX   temp        ; return pointers
            LDA   temp+1
            RTS

*-------------------------------
* print a string pointed by A & X
*   if y<128, use length = y
*   if y>127, stop at chr$(y)
*-------------------------------

prstr       ENT
            STX   temp
            STA   temp+1      ; point to data
            STY   temp2
            TYA
            AND   #$7F        ; (was $7D ???)
            STA   temp2+1     ; save possible length

            LDY   #0
:prstr2     LDA   (temp),Y    ; get data
            AND   #$7F        ; clear high
            INY

            BIT   temp2       ; use which compare?
            BPL   :prstr3     ; other one

            CMP   temp2+1     ; are we done?
            BEQ   :prstr4     ; yep

            JSR   cout        ; show and loop
            JMP   :prstr2

:prstr3     CPY   temp2       ; done?
            BEQ   :prstr4     ; yep

            JSR   cout
            BRA   :prstr2

:prstr4     TYA
            CLC
            ADC   temp        ; compute next address
            TAX
            LDA   #0
            ADC   temp+1
            RTS

*-------------------------------
* get names from a list
*-------------------------------

getname     ENT
            LDY   #0
            LDA   (temp4),Y   ; we done?
            SEC
            BEQ   :getnam3

:getnam2    LDA   (temp4),Y   ; copy name
            STA   flname+1,Y
            INY
            CMP   #0
            BNE   :getnam2

            DEY
            STY   flname      ; save length

            TYA
            SEC
            ADC   temp4       ; update length
            STA   temp4
            LDA   temp4+1
            ADC   #0
            STA   temp4+1
            CLC
:getnam3    RTS

*-------------------------------
* translate a binary to text [0-99]
*-------------------------------

bindec8     ENT
            LDY   #0          ; start 10's counter
:bin8       CMP   #10
            BCC   :bin8a      ; less than 10, were done

            SBC   #10         ; minus 10
            INY               ; add 1 to the 10's counter
            BNE   :bin8       ; loop

:bin8a      ADC   #'0'        ; make 1's into text
            TAX               ; save
            TYA
            ADC   #'0'        ; make 10's into text
            RTS               ; were done

*-------------------------------
* input a number [X-A point to text]
*-------------------------------

numin       ENT
            STX   numptr      ; point to text
            STA   numptr+1
            LDA   #0
            STA   num         ; zero totals
            STA   num+1

:numin2     LDY   #0
            LDA   (numptr),Y  ; get digit
            AND   #$7F        ; clear high
            SEC
            SBC   #'0'        ; make in 0-9 range
            CMP   #'9'+1
            BCS   :numin4     ; opps, we are done

            INC   numptr      ; point to next byte
            BNE   *+4
            INC   numptr+1

            STA   num+2       ; save digit
            LDA   #0
            STA   num+3

            LDX   #10
:numin3     CLC               ; num = num + num2
            LDA   num
            ADC   num+2
            STA   num+2
            LDA   num+1
            ADC   num+3
            STA   num+3
            DEX
            BNE   :numin3     ; num = num * 10

            LDA   num+2       ; move result
            STA   num
            LDA   num+3
            STA   num+1
            JMP   :numin2     ; loop

:numin4     LDX   num         ; return value
            LDA   num+1
            RTS

*-------------------------------
* display a decimal number [0 to 65535]
*-------------------------------

decmem      ENT
            STX   num         ; save number
            STA   num+1

            LDA   #0
            STA   num+2
            STA   num+3
            STA   num+5
            STA   num+6

            SED
            LDY   #16         ; use decimal mode
:decmem2    ASL   num
            ROL   num+1
            LDA   num+2
            ADC   num+2       ; do actual 'woz' conversion
            STA   num+2
            LDA   num+3
            ADC   num+3
            STA   num+3
            ROL   num+4
            DEY               ; loop down
            BNE   :decmem2

            CLD               ; done with decimal
            LDY   #4          ; print 5 digits

:decmem3    LDA   num+4       ; get digit
            AND   #$F
            BNE   :decmem4    ; is it zero?

            BIT   num+5       ; is this a leading zero?
            BPL   :decmem5    ; yep

:decmem4    DEC   num+5
            CLC
            ADC   #'0'        ; print digit
            LDX   num+6
            STA   txtnum+1,X  ; save number to memory
            INC   num+6

:decmem5    LDX   #3          ; move up next digit
:decmem6    ASL   num+1
            ROL   num+2
            ROL   num+3
            ROL   num+4
            DEX
            BPL   :decmem6

            DEY               ; count down digits
            BMI   :decmem7
            BNE   :decmem3

            STX   num+5       ; print last zero for sure
            BPL   :decmem3
:decmem7    LDA   num+6       ; save number length
            STA   txtnum
            RTS

num         DS    7
txtnum      DS    6

*-------------------------------
* escape handler
*-------------------------------

escape      ENT
            STA   escadr      ; possible reset
            CMP   #0          ; turn off handler?
            BEQ   :esc2       ; yep

            STX   escadr+1    ; save escape address
            STA   escadr+2
            TSX
            STX   escadr+3    ; save stack location
            LDA   #-1
            STA   escadr      ; turn on handler
:esc2       RTS

; check for esc and handle if needed
chk_esc     BIT   escadr      ; is handler enabled?
            BPL   :esc3       ; nope

            PHA
            AND   #$7F        ; did escape occur?
            CMP   #esc
            BNE   :esc2       ; nope

            LDA   escadr+1    ; setup jump location
            STA   temp
            LDA   escadr+2
            STA   temp+1
            LDX   escadr+3
            TXS               ; reset stack
            PLA
            PLA               ; restore stack
            JMP   (temp)      ; change program control

:esc2       PLA
:esc3       RTS

escadr      DB    0,0,0,0

*-------------------------------
* print a number
*-------------------------------

prnumb      ENT
            JSR   decmem      ; convert number
            LDX   #<txtnum+1
            LDA   #>txtnum+1
            LDY   txtnum
            INY               ; display it
            JMP   prstr

*-------------------------------
* wait for a return
*-------------------------------

get_cr      ENT
            JSR   print
            DB    1,22,0
            ASC   'Press [RETURN] to continue...'00

wait_cr     JSR   rdkey
            CMP   #cr
            BNE   wait_cr
            RTS

*-------------------------------
* wait for a 'g'o message
*-------------------------------

get_ok      ENT
            JSR   print
            DB    1,20,0
            ASC   'Press [RETURN] when diskette is online.'00

            BRA   wait_cr

