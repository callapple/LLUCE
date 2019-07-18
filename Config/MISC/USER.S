            LST   OFF
            TR
            TR    ADR
********************************
*                              *
*   Config - Print Userlist    *
*                              *
********************************

*-------------------------------
* Date: 11/29/86
*-------------------------------

usrlist     LDX   #<start
            LDA   #>start        ; setup esc handler
            JSR   escape

            JSR   TopBox
            JSR   print
            DB    1,2,27
            ASC   '- Sort and Print Userlist -'
            DB    1,4,5
            ASC   'Please refer to Appendix F of your user'
            ASC   ' manual for more information.'00

            JSR   cls
            JSR   print
            DB    1,7,0
            ASC   '  1 - Sort by user name'0D
            ASC   '  2 - Sort by the user number'0D
            ASC   '  3 - Sort by user password'0D
            ASC   '  4 - Sort by phone number'0D
            ASC   '  5 - Sort by last date on'0D
            ASC   '  6 - Sort by security level'0D
            ASC   '  7 - Return to main menu'0D0D
            ASC   'Which? [1-7] '00

            LDX   #7             ; get there choice
            JSR   inpnum
            STA   sortyp
            CMP   #7             ; check for abort
            BNE   :over
            JMP   start

:over       LDX   #<usrlist      ; setup esc handler
            LDA   #>usrlist
            JSR   escape

list0       JSR   cls
            JSR   print
            HEX   0D
            ASC   'Show users with which security flags:'0D0D
            ASC   '[0]   = Un-Verified Users'0D
            ASC   '[1]   = Verified Users'0D
            ASC   '[34]  = Sysop Status'0D
            ASC   '[RET] = Print all users'0D0D
            ASC   'List which users [CR,0-34]: '00

            LDA   #%00100000
            STA   inpmode        ; set input mode
            LDA   #2
            STA   maxlen         ; set input length

            LDA   #-1            ; default to all users
            STA   seclvl
            JSR   inpln          ; input their choice
            LDA   lnbuf
            CMP   #cr            ; show all users?
            BEQ   list0a         ; get password status

            LDX   #<lnbuf        ; change to number
            LDA   #>lnbuf
            JSR   numin
            STX   seclvl         ; save the level
            CPX   #35
            BCC   list0a         ; out of range
            JMP   list0

list0a      JSR   print
            HEX   0D
            ASC   'Display Passwords [Y/N] ? '00
            JSR   inpyn
            LDA   #0
            ROR
            STA   shwpass        ; save password status

            JSR   print
            HEX   0D0D
            ASC   'Make sure printer, config disk, and '
            ASC   'system disk are on-line and ready.'00
:oops       JSR   getcr
            LDA   #1             ; log to system disk
            JSR   logspec
            BCS   :oops          ; opps, error

            JSR   cls            ; clear screen
            JSR   print
            DB    1,8,12
            ASC   'Reading data...'00

            LDX   #<usrname      ; setup user file name
            LDA   #>usrname
            JSR   movname

            LDX   #1             ; start user number at 1
            STX   temp
            DEX
            STX   temp+1

            LDA   #<sortbuf
            STA   temp2          ; point to buffer
            LDA   #>sortbuf
            STA   temp2+1

            JSR   open           ; open userfile
            BCC   list1a         ; all is well

            JSR   close
            JSR   cls
            JSR   print
            ASC   'Error: Unable to open file USERS'00
            JSR   getcr
            JMP   usrlist        ; start over

list1a      LDX   #<hdrbuf       ; gobble user #0
            LDA   #>hdrbuf
            LDY   #128           ; 128 byte records
            JSR   rdpart

list_2      LDA   #0             ; clear buffer
            STA   hdrbuf
            LDX   #<hdrbuf
            LDA   #>hdrbuf       ; read in a user
            LDY   #128           ; 128 byte records
            JSR   rdpart
            BCS   list2c         ; opps, end of file

            LDA   hdrbuf
            AND   #$7F
            BEQ   list2c         ; no more users

            CMP   #','
            BEQ   list2a         ; opps, no user in that slot

            LDA   seclvl         ; show all users?
            BMI   list2e         ; yep
            BEQ   list2d         ; show non-verified

            PHA
            LSR
            LSR                  ; divide by 8
            LSR
            TAX                  ; and make into byte offset
            PLA
            AND   #%00000111
            TAY                  ; get bit offset
            LDA   hdrbuf+92,X    ; get byte
            AND   secmap,Y       ; check bit
            BEQ   list2a         ; nope, dont show
            BNE   list2e         ; show it

list2d      LDA   hdrbuf+92      ; check for non-verified
            AND   #%00000010
            BNE   list2a         ; user is verified, dont show

list2e      JSR   list_5         ; handle sort dispatch

list2a      INC   temp
            BNE   *+4            ; inc user number
            INC   temp+1
            JMP   list_2         ; loop

list2c      LDY   #0
            TYA                  ; mark last entry
            STA   (temp2),Y

            LDA   sortbuf        ; check for no entries
            BNE   list2f         ; there is data

            JSR   close          ; close user file
            JSR   cls
            JSR   print
            ASC   'No users fit parameters'00
            JSR   getcr
            JMP   usrlist        ; restart

list2f      LDA   sortbuf+12     ; only 1 user in list?
            BEQ   list2g         ; yep

            JSR   print
            DB    1,8,12         ; change on-screen operation
            ASC   'Sort'00
            JSR   list6          ; sort data

list2g      JSR   print
            DB    1,8,12
            ASC   'Printing data...'00

            LDA   #<sortbuf      ; point to data
            STA   temp2
            LDA   #>sortbuf
            STA   temp2+1
            LDA   #0             ; count the page display
            STA   prinit         ; set printer to init
            STA   pagecnt

list_3      LDY   #0
            LDA   (temp2),Y
            BEQ   list_4         ; opps, end of list

            LDY   #10
            LDA   (temp2),Y      ; get user number
            STA   hdrbuf+128
            TAX
            INY
            LDA   (temp2),Y
            STA   hdrbuf+129     ; save user number as data
            JSR   gouser

            LDX   #<hdrbuf
            LDA   #>hdrbuf       ; read in user record
            LDY   #128
            JSR   rdpart

            bit   shwpass        ; show passwords?
            BPL   list3b         ; yep

            LDA   #'*'
            LDX   #7
list3a      STA   hdrbuf+70,X    ; cover password with *'s
            DEX
            BPL   list3a

list3b      JSR   pruser         ; print users data

            CLC
            LDA   temp2
            ADC   #12
            STA   temp2          ; goto next record
            LDA   temp2+1
            ADC   #0
            STA   temp2+1
            JMP   list_3         ; do next user

list_4      JSR   close          ; close user file
list4a      DEC   pagecnt        ; check page count
            BEQ   list4b

            LDA   #cr            ; advance page
            JSR   prcout
            JMP   list4a

list4b      LDA   #cr            ; add 4 last lines
            JSR   prcout
            JSR   prcout
            JSR   prcout
            JSR   prcout
            JMP   usrlist        ; we are done

*-------------------------------
* handle moving data for sort

list_5      LDY   #9
            LDA   #' '
list5f      STA   hdrbuf+$100,Y  ; fill with blanks just in case
            DEY
            BPL   list5f

            JSR   list5b         ; get into 10 byte form

            LDY   #11            ; save user record number
            LDA   temp+1
            STA   (temp2),Y
            DEY
            LDA   temp
            STA   (temp2),Y

            DEY
list5a      LDA   hdrbuf+$100,Y  ; copy over data
            STA   (temp2),Y
            DEY
            BPL   list5a

            CLC
            LDA   temp2          ; go to next record
            ADC   #12
            STA   temp2
            LDA   temp2+1
            ADC   #0
            STA   temp2+1
            RTS

sortyp      DB    0

*-------------------------------

list5b      LDA   sortyp
            ASL
            TAX
            LDA   displist,X
            STA   prn
            INX
            LDA   displist,X
            STA   prn+1
            JMP   (prn)

displist    DA    0
            DA    sname          ; sort user name
            DA    sunum          ; sort by user number
            DA    spass          ; sort by password
            DA    sfone          ; sort by phone number
            DA    sdate          ; sort by last user
            DA    ssec           ; sort by sec level

*-------------------------------

sname       LDY   #-1
sname2      INY
            LDA   hdrbuf,Y       ; search for divider
            AND   #$7F
            CMP   #' '           ; control char?
            BCC   sunum          ; hmm, just blank out
            CMP   #','
            BNE   sname2

            LDX   #-1
sname3      INX
            INY
            LDA   hdrbuf,Y       ; move byte
            STA   hdrbuf+$100,X
            AND   #$7F
            CMP   #' '
            BCS   sname3         ; loop and finish

            LDY   #-1
sname4      INY
            LDA   hdrbuf,Y       ; add on first name
            STA   hdrbuf+$100,X
            AND   #$7F
            INX
            CMP   #','           ; done?
            BNE   sname4         ; nope

sunum       RTS                  ; leave data as blanks

spass       LDY   #7
spass2      LDA   hdrbuf+70,Y    ; move password
            STA   hdrbuf+$100,Y
            DEY
            BPL   spass2
            RTS

sfone       LDX   #0
            LDY   #0
sfone2      LDA   hdrbuf+78,Y    ; get phone number
            STA   hdrbuf+$100,X
            INX
            INY
            CPY   #3
            BNE   *+3            ; skip if not at 3
            INY
            CPY   #7
            BNE   *+3
            INY
            CPY   #12            ; done?
            BNE   sfone2         ; nope
            RTS

sdate       LDA   hdrbuf+91      ; move date into sort field
            AND   #%00011111     ; get rid of extra stuff
            STA   hdrbuf+$101
            LDA   hdrbuf+90
            STA   hdrbuf+$102
            RTS

ssec        LDY   #3
ssec2       LDA   hdrbuf+92,Y    ; move sec level in
            STA   hdrbuf+$101,Y
            DEY
            BPL   ssec2
            RTS

; sort all the records into order
list6       LDA   #<sortbuf
            STA   temp           ; point to buffer #1
            LDA   #>sortbuf
            STA   temp+1

            LDA   #<sortbuf+12
            STA   temp2          ; point to buffer #2
            LDA   #>sortbuf+12
            STA   temp2+1

list6a      LDY   #0
list6b      LDA   (temp),Y       ; get first byte
            CMP   (temp2),Y      ; check againt second
            BEQ   list6c         ; all is well
            BCS   list6e
            BCC   list6d         ; order is correct

list6c      INY                  ; go to next char
            CPY   #10            ; there yet?
            BNE   list6b         ; nope

list6d      CLC
            LDA   temp           ; advance pointer #1
            ADC   #12
            STA   temp
            LDA   temp+1
            ADC   #0
            STA   temp+1

            CLC
            LDA   temp2          ; advance pointer #2
            ADC   #12
            STA   temp2
            LDA   temp2+1
            ADC   #0
            STA   temp2+1

            LDY   #0             ; we done?
            LDA   (temp),Y
            BEQ   list6q         ; yep

            LDA   (temp2),Y      ; done?
            BNE   list6a         ; nope, do next record
list6q      RTS

list6e      LDY   #11
list6f      LDA   (temp),Y
            PHA
            LDA   (temp2),Y      ; swap data
            STA   (temp),Y
            PLA
            STA   (temp2),Y
            DEY
            BPL   list6f         ; do 12 bytes

            LDA   temp+1
            CMP   #>sortbuf      ; at record #1 ?
            BNE   list6g         ; nope

            LDA   temp
            CMP   #<sortbuf      ; at record #1 ?
            BEQ   list6h         ; yep

list6g      SEC
            LDA   temp           ; backup record #1
            SBC   #12
            STA   temp
            LDA   temp+1
            SBC   #0
            STA   temp+1

            SEC
            LDA   temp2          ; backup record #2
            SBC   #12
            STA   temp2
            LDA   temp2+1
            SBC   #0
            STA   temp2+1
list6h      JMP   list6a

*-------------------------------
; print out a user record
pruser      DEC   pagecnt        ; count down list
            BMI   pruser0
            BNE   pruser1

            LDA   #cr
            JSR   prcout         ; advance page
            JSR   prcout
            JSR   prcout
            JSR   prcout

pruser0     LDX   #<prthdr
            LDA   #>prthdr
            LDY   #-1            ; print page header
            JSR   prdata

            LDA   sortyp
            LUP   4
            ASL
            --^
            TAX
pruser3     LDA   sortnam-16,X
            INX
            JSR   prcout
            ASL
            BNE   pruser3

            LDX   #77            ; move over to col 77
            JSR   gocol

            LDX   #<prthdr2      ; print rest of header
            LDA   #>prthdr2
            LDY   #-1
            JSR   prdata

            LDA   #58
            STA   pagecnt        ; reset page counter

pruser1     LDX   #<hdrbuf       ; point to buffer with data
            LDA   #>hdrbuf
            LDY   #","           ; print first name
            JSR   prdata
            STX   prn            ; save location
            STA   prn+1

            LDA   #' '           ; put a space between first & last
            JSR   prcout

            LDX   prn            ; pick up last location
            LDA   prn+1
            LDY   #cr+128        ; print last name
            JSR   prdata

            LDX   #25            ; move over to col 25
            JSR   gocol

            LDX   #<hdrbuf+78    ; point buffer to data
            LDA   #>hdrbuf+78
            LDY   #12
            JSR   prdata         ; print phone number

            LDX   hdrbuf+128
            LDA   hdrbuf+129     ; translate number
            JSR   decmem

            SEC
            LDA   #43
            SBC   txtnum         ; move over to print user number
            TAX
            JSR   gocol

            LDY   txtnum
            LDX   #<txtnum+1
            LDA   #>txtnum+1
            JSR   prdata         ; print user number

            LDA   #'-'           ; add in a dash
            JSR   prcout

            LDX   #<hdrbuf+70    ; point buffer data
            LDA   #>hdrbuf+70
            LDY   #8
            JSR   prdata         ; print password

            LDX   #54            ; move over to col 54
            JSR   gocol

            LDA   hdrbuf+92
            LSR                  ; dont show guest/user flag
            LDX   #7
pruser2     LSR
            PHA
            LDA   #0             ; show 1 or 0 flag status
            ADC   #'0'
            JSR   prcout
            PLA
            DEX                  ; print 7 flags
            BNE   pruser2

            LDX   #63            ; move over to col 63
            JSR   gocol

            LDA   hdrbuf+90      ; get most of month
            LSR   hdrbuf+91      ; shift last bit into carry
            ROR                  ; move bit in
            LUP   4
            LSR
            --^
            JSR   bindec8
            JSR   prdec8         ; print it out
            LDA   #'/'
            JSR   prcout

            LDA   hdrbuf+90
            AND   #$1F           ; translate month
            JSR   bindec8
            JSR   prdec8         ; print out
            LDA   #'/'
            JSR   prcout

            LDA   #'8'           ; print out /8x
            JSR   prcout

            LDA   hdrbuf+91      ; get year
            AND   #%00001111     ; just use last digit
            CLC
            ADC   #'0'           ; make ascii
            JSR   prcout

            LDA   hdrbuf+99
            AND   #%00001111
            TAX                  ; display time limit
            LDA   #0
            JSR   decmem

            SEC
            LDA   #75
            SBC   txtnum         ; move over to print time limit
            TAX
            JSR   gocol

            LDY   txtnum
            LDX   #<txtnum+1
            LDA   #>txtnum+1
            JSR   prdata         ; print time limit

            LDA   #'0'           ; add on zero (time * 10)
            JSR   prcout
            LDA   #cr            ; end of line data
            JMP   prcout

; print out selected data
prdata      STX   prn            ; point to data
            STA   prn+1
            STY   prn+2          ; save delimeter
            STY   prn+3          ; save length

            LDY   #0
prdata2     LDA   (prn),Y        ; get data
            INC   prn
            BNE   *+4            ; goto next byte
            INC   prn+1

            ORA   #$80           ; set high for ascii check
            CMP   prn+2          ; we done?
            BEQ   prdata3        ; yep

            JSR   prcout         ; print data
            DEC   prn+3          ; count down length
            BNE   prdata2        ; keep going

prdata3     LDX   prn
            LDA   prn+1          ; get new address
            RTS

; go to a specified column
gocol       STX   prn            ; save end address
gocol2      LDA   prcol          ; are we done?
            CMP   prn
            BCS   gocol3         ; yep

            LDA   #' '           ; move over a space
            JSR   prcout
            JMP   gocol2         ; keep going

gocol3      RTS

; print out a 2 byte number [xx]
prdec8      JSR   prcout         ; call
            TXA                  ; ... fall into ...

; print character: A = character
prcout      PHA                  ; save all reg's
            STX   prsv_x
            STY   prsv_y

            LDX   #$13
prcout1     LDA   $24,X          ; save zero page stuff
            STA   przero,X
            DEX
            BPL   prcout1

            BIT   prinit         ; has printer been used?
            BMI   prcout3        ; yep

            LDA   #$10
            STA   $26            ; setup slot pointer
            LDA   #>$C100
            STA   $36+1          ; point ($0036) at $c100
            LDA   #0             ; init printer card
            STA   prcol          ; reset column
            TAX
            TAY
            STA   $24
            STA   $27            ; zero character buffer
            STA   $36

            JSR   $C100
            LDA   $36            ; point to output routine
            STA   jpcout2+1
            LDA   $36+1
            STA   jpcout2+2
            DEC   prinit         ; show we have done init

            LDA   #'I'-$40       ; send ctrl-I 80 n
            JSR   jpcout
            LDA   #'8'
            JSR   jpcout
            LDA   #'0'
            JSR   jpcout
            LDA   #'N'
            JSR   jpcout

prcout3     LDA   #0             ; set ch over to border
            STA   $24
            INC   prcol          ; move over 1 col
            PLA                  ; get byte to print
            PHA
            AND   #$7F           ; print with high-bit off
            CMP   #cr
            BNE   prcout5

            LDX   #0             ; reset column
            STX   prcol
prcout5     JSR   jpcout

            LDX   #$13
prcout4     LDA   przero,X       ; restore zero page
            STA   $24,X
            DEX
            BPL   prcout4

            LDX   prsv_x         ; restore reg's
            LDY   prsv_y
            PLA
            RTS

jpcout      ORA   #$80
jpcout2     JMP   $C000          ; do output routine

prinit      DB    0
prsv_x      DB    0
prsv_y      DB    0
przero      DS    $14

; position to a user
gouser      STX   temp+1         ; reset scratch bytes
            LDX   #0
            STX   temp

            LSR                  ; do multipication
            ROR   temp+1
            ROR   temp
            LDX   temp
            TAY
            LDA   temp+1
            JMP   setpos         ; position to user

seclvl      DB    0
shwpass     DB    0
secmap      DB    1,2,4,8,$10,$20,$40,$80

prcol       DB    0
pagecnt     DB    0

prthdr      ASC   '++  MultiPro   Userlist  -  Version 1.4  '
            ASC   '-  List Sorted By: ',FF
prthdr2     ASC   '++'0D
            ASC   '[Name]                     [Phone]    [User] '
            ASC   '[Pass]    [Sec]    [Last]  [Time]'0D
            ASC   '[Alias]                    [Number]   [Numb] '
            ASC   '[Word]    [Lvl]    [Call] [Limit]'0D0D,FF

sortnam     ASC   'User Name     '0000
            ASC   'User Number   '0000
            ASC   'User Password '0000
            ASC   'Phone Number  '0000
            ASC   'Last Date On  '0000
            ASC   'Security Level'0000

