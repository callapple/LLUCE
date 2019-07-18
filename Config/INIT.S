            LST   OFF
            TR
            TR    ADR
*-------------------------------
* config/init
*-------------------------------
* Date: 3/11/88
*-------------------------------

            REL
cr          =     $D

temp        =     0
temp2       =     2
temp3       =     4
temp4       =     6

confbuf     =     $800
devnam      =     $815

copybuf     =     $6000
copymax     =     $5800

mli         =     $BF00

            DSK   REL/INIT

begin       EXT
escape      EXT
cls         EXT
print       EXT
maxlen      EXT
inpmode     EXT
inpln       EXT
copyinp     EXT
ucopyinp    EXT
prstr       EXT
inpyn       EXT
re_mdm      EXT
re_pr       EXT
re_clk      EXT
TopBox      EXT
inpnum      EXT
get_cr      EXT
chkspc      EXT
bindec8     EXT
setspec     EXT
get_ok      EXT
setdrv      EXT
setsys      EXT
settac      EXT
makesys     EXT
maketac1    EXT
maketac2    EXT
dstpfx      EXT
do_quit     EXT
verify      EXT
p_crpth     EXT
copy        EXT
movname     EXT
logdst      EXT
open        EXT
wrblk       EXT
close       EXT
create      EXT
logcon      EXT
cout        EXT

do_init     ENT
            LDX   #<begin     ; setup esc handler
            LDA   #>begin
            JSR   escape

            JSR   cls

            LDA   #30
            STA   maxlen
            LDA   #%00000000
            STA   inpmode

            JSR   print
            ASC   'What are you going to call your system?'0D
            ASC   ':'00
            JSR   inpln

            LDX   #<datadef
            LDA   #>datadef
            LDY   #cr
            JSR   copyinp     ; copy name into file
            STX   temp4
            STA   temp4+1

            LDA   #20         ; limit length
            STA   maxlen

            JSR   print
            HEX   0D
            ASC   'Enter your FULL name (20 characters max)'0D
            ASC   ':'00
            JSR   inpln       ; get name

            LDX   #<user      ; copy line uppercase
            LDA   #>user
            LDY   #cr
            JSR   ucopyinp
            LDY   #cr
            JSR   copyinp     ; copy the line
            STX   temp3
            STA   temp3+1

            LDX   temp4
            LDA   temp4+1
            LDY   #cr
            JSR   copyinp
            STX   temp4
            STA   temp4+1

            LDY   #0
init1d      LDA   user,Y
            INY
            CMP   #$20
            BNE   init1d
            DEY
            LDA   #','
            STA   user,Y

init2       LDA   #%11000000
            STA   inpmode

            JSR   print
            HEX   0D
            ASC   'Enter your telephone number'0D
            ASC   '(XXX-XXX-XXXX): '00

            JSR   inpln       ; get tele number
            CPY   #12
            BNE   init2

            LDX   #<usrtele
            LDA   #>usrtele
            LDY   #0
            JSR   copyinp     ; copy the line

            LDA   #16
            STA   maxlen      ; set length for city

            JSR   print
            HEX   0D
            ASC   'What city do you call from (16 char)'0D
            ASC   ':'00

            JSR   inpln       ; get where from
            LDX   temp3
            LDA   temp3+1
            LDY   #','
            JSR   copyinp     ; copy the input
            STX   temp2
            STA   temp2+1

            LDA   #2
            STA   maxlen      ;set length for state

init2a      JSR   print
            HEX   0D
            ASC   'What state do you call from (XX):'00

            JSR   inpln       ;get state
            CPY   #2
            BNE   init2a
            LDX   temp2
            LDA   temp2+1
            LDY   #cr
            JSR   copyinp     ;copy to date area

            LDA   #8
            STA   maxlen

init3       JSR   cls
            JSR   print
            ASC   'Enter a 4-8 char password:'00

            JSR   inpln
            CPY   #4
            BCC   init3

            LDX   #<usrpass
            LDA   #>usrpass
            LDY   #0
            JSR   copyinp     ; copy the line

            LDA   #20
            STA   maxlen

            JSR   print
            HEX   0D
            ASC   'Enter a second password for remote logon (1-20 chars)'0D
            ASC   ':'00

            JSR   inpln       ; get second password
            LDX   temp4
            LDA   temp4+1
            LDY   #cr
            JSR   copyinp     ; copy password into data file
            STX   temp4
            STA   temp4+1     ; save new pointers

            LDY   #0
init3a      LDA   xdata,Y     ; copy rest of the data file
            STA   (temp4),Y
            INY
            CMP   #0
            BNE   init3a

            JSR   cls         ; clear screen
            JSR   print
            DB    1,7,30
            ASC   '- System Information -'0D0D
            ASC   'System Name: '00

            LDX   #<datadef
            LDA   #>datadef
            LDY   #cr+128
            JSR   prstr       ; show system name
            STX   temp4
            STA   temp4+1

            JSR   print
            HEX   0D0D
            ASC   'Sysop Name: '00

            LDX   temp4
            LDA   temp4+1
            LDY   #cr+128
            JSR   prstr       ; show sysop name
            STX   temp4
            STA   temp4+1

            JSR   print
            HEX   0D0D
            ASC   'Sysop Phone Number: '00

            LDX   #<usrtele
            LDA   #>usrtele
            LDY   #13
            JSR   prstr       ; show tele number

            JSR   print
            HEX   0D0D
            ASC   'Sysop is From: '00

            LDX   temp3
            LDA   temp3+1
            LDY   #cr+128
            JSR   prstr       ; show where from

            JSR   print
            HEX   0D0D
            ASC   'Logon Password:  '00

            LDX   #<usrpass
            LDA   #>usrpass
            LDY   #9
            JSR   prstr       ; show main password

            JSR   print
            HEX   0D0D
            ASC   'Remote Password: '00

            LDX   temp4
            LDA   temp4+1
            LDY   #cr+128
            JSR   prstr       ; show remote password

            JSR   print
            HEX   0D0D
            ASC   'Is this information correct? [Y/N] '00

            JSR   inpyn
            BCC   init4
            JMP   do_init

*-------------------------------

init4       LDA   #-1
            STA   init        ; set init mode

einit1      JSR   re_mdm
einit2      LDX   #<einit1
            LDA   #>einit1    ; if esc, go back 1 level
            JSR   escape
            JSR   re_pr
einit3      LDX   #<einit2
            LDA   #>einit2
            JSR   escape
            JSR   re_clk

*-------------------------------

            LDY   #<devnam
            LDA   #0
:loop       STA   confbuf,Y   ; zero out pathname buffer
            INY
            BNE   :loop

*-------------------------------
* start the hardware config

hard1       LDX   #<einit3
            LDA   #>einit3    ; backup 1 level
            JSR   escape

            JSR   TopBox
            JSR   print
            DB    1,2,22
            ASC   '- Copy Files to Mass Storage Device -'
            DB    1,4,13
            ASC   'Please refer to your user manual for more information.'00

            JSR   cls
            JSR   print
            ASC   'Please enter the slot and drive of your '
            ASC   'mass storage device. If your media is'0D0D
            ASC   'removable, then please make sure there '
            ASC   'is formatted media in place.'0D0D0D
            ASC   '     Slot? [1-7] '00
            LDX   #7
            JSR   inpnum
            STA   slot        ; save the slot

            JSR   print
            HEX   0D
            ASC   '    Drive? [1-2] '00
            LDX   #2
            JSR   inpnum
            STA   drive       ; save the drive
            DEC   drive       ; make into [0-1] range

            JSR   print
            HEX   0D0D0D
            ASC   'Is the above correct [Y/N] ? '00
            JSR   inpyn
            BCC   *+5
            JMP   hard1       ;nope

            JSR   cls
            JSR   print
            ASC   'If you continue, 2 subdirectories will'
            ASC   ' be created on your mass storage'0D0D
            ASC   'device. (MPRO.SEGS and MPRO.SYS) All'
            ASC   ' needed files will be copied into'0D0D
            ASC   'these subdirectories.  No existing files will be destroyed.'00
            JSR   get_cr

            LDA   #0          ; no more turning away..
            JSR   escape      ; [p. floyd]

            JSR   chkspc      ; check drive space
            CMP   #3          ; are there are at least 768 blocks free?
            BCC   *+5         ; not enough room
            JMP   hard2

            JSR   cls
            JSR   print
            ASC   'The storage device checked does not '
            ASC   'contain enough storage space to run'0D0D
            ASC   'the system. You need to make some '
            ASC   'more room on the device, or'0D0D
            ASC   'choose another device.'00

            JSR   get_cr
            JMP   hard1       ; goto hard/floppy question

hard2       JSR   cls
            JSR   print
            ASC   'Should the MultiPro transfer system be installed'
            ASC   'onto this device? [Y/N] '00

            JSR   inpyn
            BCC   :trans
            LDA   #0
            STA   settrans
            STA   superlist   ;mark the end of the supertac list as such
            JMP   :notrans

:trans      LDA   #1
            STA   settrans

            JSR   print
            HEX   0D0D0D
            ASC   'Please enter the number of volumes that '
            ASC   'should be allocated to the MultiPro'0D0D
            ASC   'file transfer system.'0D0D0D
            ASC   'Number of volumes? [1-99] '00

            LDX   #99         ;max is 99
            JSR   inpnum
            STA   volumes

            JSR   bindec8
            STA   stacacc+2   ;sysop high (10's)
            STX   stacacc+3   ;sysop high (1's)
            STA   stacacc+7   ;user high
            STX   stacacc+8   ;user high
            STA   stacacc+12
            STX   stacacc+13  ;elite high
            STA   stacacc+17
            STX   stacacc+18  ;priv high
            STA   stacacc+22
            STX   stacacc+23  ;board manager high

:notrans    JSR   setspec
            JSR   chkspc      ;reset

            JSR   cls
            JSR   print
            ASC   'The configuration program is now going to '
            ASC   'copy over all the files needed'0D0D
            ASC   'to run MultiPro onto your mass storage device.'00

            JSR   get_ok      ; get permission
            JSR   cls

            JSR   setdrv      ;create & log xxx/mpro.segs
            JSR   make1       ;do copy in 3 parts
            JSR   make2

            JSR   chkspc      ;reset path to original drive

            JSR   setsys      ;create & log xxx/mpro.sys
            JSR   make3

            LDA   settrans    ;did they want a transfer system?
            BNE   :doit       ;yes, set it up
            JMP   noxfer      ;nope, skip the next step

:doit       JSR   settac      ;create & log xxx/mpro.sys/transfer/vol.
            JSR   make4

*-------------------------------
* setup supertac volumes

            JSR   chkspc      ;reset path to /xxx/
            JSR   makesys     ;add /xxx/mpro.sys/
            JSR   maketac1    ;add /xxx/mpro.sys/stac
            JSR   maketac2    ;add /xxx/mpro.sys/stac/vol.

            LDA   #0
            STA   curvol      ;start at volume 1
            INC   dstpfx      ;add one to length of destination prefix

:loop       INC   curvol      ;++current volume
            LDA   curvol      ;which volume are we at?
            CMP   #10         ;did we do 10 yet?
            BCC   :less10     ;nope, we have less than 10
            CMP   #11         ;more than 9, but how much more?
            BCS   :over10     ;>= 11, so we not right on 10
            INC   dstpfx      ;smack dab on 10, so length is one greater

:over10     JSR   bindec8     ;convert volume we're on to decimal

            LDY   dstpfx      ;get current length
            DEY               ;character before the end
            STA   dstpfx,Y    ;store 10's
            TXA               ;get 1's
            INY               ;next character forward
            STA   dstpfx,Y    ;store 1's

            JSR   mli         ; create /xxx/mpro.sys/stac/vol.XX
            DB    $C0         ; create new path
            DA    p_crpth
            JMP   :over

:less10     LDX   dstpfx      ;add single number to end of prefix
            CLC
            ADC   #'0'        ;make it ascii
            STA   dstpfx,X

            JSR   mli         ; create /xxx/mpro.sys/stac/vol.X
            DB    $C0         ; create new path
            DA    p_crpth

:over       LDA   curvol      ;how many volumes done
            CMP   volumes     ;done 'em all yet?
            BNE   :loop       ;nope, do some more

*-------------------------------

noxfer      JSR   cls
            JSR   print
            ASC   'Your system is now configured and is '
            ASC   'ready to run. To bring up your system'0D0D
            ASC   'for operation, do the following:'0D0D0D
            ASC   'Boot up your mass storage device and '
            ASC   'type "PREFIX MPRO.SEGS".'0D0D
            ASC   'Type "-ACOS" to start your system running.'00

            JSR   get_cr
            JMP   do_quit

volumes     DB    0
curvol      DB    0

*-------------------------------
* copy boot stuff over
*-------------------------------

make1       LDX   #<disk1     ; is first disk online?
            LDA   #>disk1
            JSR   verify
            BCC   :online     ; yes, it is

            JSR   cls
            JSR   print
            ASC   'Please place MultiPro Disk #1, /CONFIG, online.'00

            JSR   get_ok      ; wait for ok
            JMP   make1       ;check it to make sure

:online     JSR   cls
            JSR   print
            ASC   'Copying MultiPro...'00

            LDX   #<list1     ; copy acos & acos.obj
            LDA   #>list1
            JSR   copy

*-------------------------------

            JSR   logdst      ; log to destination
            LDX   #<gname2
            LDA   #>gname2    ; open file
            JSR   movname
            JSR   open

            LDX   #<confbuf
            LDA   #>confbuf   ; write configured system out
            LDY   #18         ; write 9 pages (16.5 blocks)
            JSR   wrblk
            JSR   close       ; close file

            LDX   #<program
            LDA   #>program   ; create file named "PROGRAM"
            JSR   movname
            LDY   #$F5        ; make into special type
            JMP   create

*-------------------------------
* copy second set of files into XXX/MPRO.SEGS

make2       LDX   #<disk2     ; is second disk in place?
            LDA   #>disk2
            JSR   verify
            BCC   :online     ; yes, it is

            JSR   cls
            JSR   print
            ASC   'Please place MultiPro Disk #2, /SEGS, online.'00

            JSR   get_ok      ; wait for ok
            JMP   make2

:online     JSR   cls
            JSR   print
            ASC   'Copying MultiPro program segments...'00

            LDX   #<list2     ; copy segments to xxx/mpro.segs
            LDA   #>list2
            JMP   copy

*-------------------------------
* make main part of disk in XXX/MPRO.SYS

make3       LDX   #<disk3     ; is third disk in place?
            LDA   #>disk3
            JSR   verify
            BCC   :online     ; yes, it is

            JSR   cls
            JSR   print
            ASC   'Please place MultiPro Disk #3, /FILE, online.'00

            JSR   get_ok      ; wait for ok
            JMP   make3

:online     JSR   cls
            JSR   print
            ASC   'Copying MultiPro system files...'00

            LDX   #<list3     ; copy last 4 files
            LDA   #>list3
            JSR   copy

            JSR   logdst      ; log to seg sub
            LDX   #<usrname   ; open user file
            LDA   #>usrname
            JSR   movname
            JSR   open

            LDX   #<user-128  ; write out sysop data
            LDA   #>user-128
            LDY   #2          ; write 1 page (2 blocks)
            JSR   wrblk

            JSR   close       ; finish up

            LDX   #<dtanam1
            LDA   #>dtanam1   ; open data1 file
            JSR   movname
            JSR   open

            LDX   #<datadef
            LDA   #>datadef
            LDY   #4          ; write 2 pages (4 blocks)
            JSR   wrblk
            JSR   close
            JMP   logcon      ; log back

*-------------------------------
* make supertac segments

make4       LDX   #<list4     ;copy protocol up/down
            LDA   #>list4     ;and xdos
            JSR   copy

:loop       LDX   #<disk4     ; is fourth disk in place?
            LDA   #>disk4
            JSR   verify
            BCC   :online     ; yes, it is

            JSR   cls
            JSR   print
            ASC   'Please place MultiPro Disk #4, /STAC, online.'00

            JSR   get_ok      ; wait for ok
            JMP   :loop

:online     JSR   cls
            JSR   print
            ASC   'Copying MultiPro transfer system files...'00

            LDX   #<list5     ;copy supertac files
            LDA   #>list5
            JSR   copy

* copy the access file to the supertac stuff

            JSR   logdst      ;log to supertac seg parts
            LDX   #<access    ;open user file
            LDA   #>access
            JSR   movname
            JSR   open

            LDX   #<stacacc   ;write out sysop data
            LDA   #>stacacc
            LDY   #1          ;write 128 bytes
            JSR   wrblk

            JSR   close       ;finish up
            JSR   logcon      ;log back to config
            RTS               ;oi, we be done!

*-------------------------------
* print the slot or drive

prslot      LDA   slot
            CLC
            ADC   #'0'        ; print slot
            JMP   cout

prdriv      LDA   drive
            CLC               ; print drive
            ADC   #'1'
            JMP   cout

*-------------------------------
* variables
*-------------------------------

init        ENT
            DB    0

diskid      DB    $A2,$20,$A0,0

gname2      STR   'ACOS.OBJ'
program     STR   'PROGRAM'
access      STR   'ACCESS'

slot        ENT
            DB    0
drive       ENT
            DB    0
dtanam1     STR   'DATA1'

user        DS    70
usrpass     ASC   '        '
usrtele     ASC   'xxx-xxx-xxxx'
            DA    0           ;when$
            DB    %11111110,%11111111,%11111111
            DB    %11111111,%00000111
            DB    $50,0,0,0,0,0,0,0,0,0
            DS    20          ;bytes

datadef     ASC   'System Name'0D
            ASC   'Sysop Name'0D
            ASC   'Second Password'0D

            DS    120

xdata       ASC   '---------------------------------------'0D
            ASC   'Ctrl-S Stop/Start  Spacebar to Exit'0D
            ASC   'Press N for Next Bulletin'0D
            ASC   '1,0'0D
            DB    0

condata     ASC   ' '
            ASC   'N'
            DB    2
            DB    32,40,64,80

stacacc     ASC   '1'0D       ;sysop low access
            ASC   '50'0D      ;sysop high access
            ASC   '1'0D       ;user low access
            ASC   '50'0D      ;user high access
            ASC   '1'0D       ;elite low access
            ASC   '50'0D      ;elite high access
            ASC   '1'0D       ;priv low access
            ASC   '50'0D      ;priv high access
            ASC   '1'0D       ;board manager low access
            ASC   '50'0D      ;board manager high access
            HEX   0D0D

*-------------------------------
* lists for identifying files

disk1       STR   '/CONFIG'00
disk2       STR   '/SEGS'00
disk3       STR   '/FILE'00
disk4       STR   '/STAC'00

usrname     ASC   'system/sys.users'00

list1       ASC   'lluce.system'00
            ASC   'lluce.druvers'00
            DB    00

list2       ASC   'logon.seg.s'00
            ASC   'main.seg.s'00
            ASC   'msg.seg.s'00
            ASC   'system.seg.s'00
            ASC   'maint.seg.s'00
            ASC   'mail.seg.s'00

* supertac segments
* a 00 is placed here if they don't want to include the
* transfer system's segments

settrans    DB    0
superlist   ASC   'supertac.s'00
            ASC   'supertac.sys.s'00
            ASC   'supertac.aux.s'00
            ASC   'purge.seg.s'00
            DB    00

list3       ASC   'bbs'00
            ASC   'data'00
            ASC   'data1'00
            ASC   'data2'00
            ASC   'g1'00
            ASC   'g1.1'00
            ASC   'g1.2'00
            ASC   'g1.3'00
            ASC   'hlp.edit'00
            ASC   'hlp.main'00
            ASC   'hlp.msg'00
            ASC   'hlp.user'00
            ASC   'mnu.val.40'00
            ASC   'mnu.val.80'00
            ASC   'mnu.new'00
            ASC   'sys.newinfo'00
            ASC   'sys.news'00
            ASC   'sys.info'00
            ASC   'sys.questions'00
            ASC   'users'00
            ASC   'v1.1'00
            ASC   'v1.2'00
            ASC   'v1.3'00
            ASC   'v1.4'00
            ASC   'b1'00

list4       ASC   'protocol.up'00
            ASC   'protocol.down'00
            ASC   'xdos'00
            DB    00

list5       ASC   'access'00
            ASC   'xshow'00
            ASC   'xcat'00
            ASC   'menu.supertac'00
            ASC   'menu.sysop'00
            ASC   'menu.aux'00
            ASC   'menu.batch'00
            DB    00

