              LST   OFF
              TR
              TR    ADR
********************************
*                              *
*    Config Program - Start    *
*                              *
********************************

*-------------------------------
* Date: 3/11/88
*-------------------------------

              REL
m_vers        =     '1'           ; make into ascii # (Main Version)
s_vers        =     '0'           ; make into ascii # (Sub Version)
p_vers        =     '5'           ; make into ascii # (Patch Version)

entrmon       =     $FF59

prn           =     $16           ; [4 bytes]

reset         =     $3F2
mli           =     $BF00

              DSK   REL/START

findcon       EXT
VideoStartup  EXT
cls           EXT
print         EXT
inpyn         EXT
inpnum        EXT
ld_drvs       EXT
do_init       EXT
drv_path      EXT
refnum        EXT
escape        EXT
close         EXT
logcon        EXT
re_mdm        EXT
re_pr         EXT
re_clk        EXT
do_dflts      EXT
do_filt       EXT
TopBox        EXT


begin         ENT
              STA   $C051         ;text mode
              STA   $C00E         ;Turn MouseText off
              BIT   $C082

              LDA   #<do_quit     ;fudge reset vector
              STA   reset
              LDA   #>do_quit
              STA   reset+1
              EOR   #$A5
              STA   reset+2

              LDX   #$F0          ;reset stack
              TXS

              JSR   findcon       ;find the config disk, logit
              JSR   VideoStartup  ; Init the video driver

              JSR   do_main

              JSR   cls           ; clear screen
              JSR   print
              DB    1,7,0
              ASC   'When you do an initial configure, '
              ASC   'all previous data will be destroyed'0D0D
              ASC   'and replaced with the new configuration.  '
              ASC   'All old data will be lost.'0D0D0D
              ASC   'Do you want to do an Initial Configure? [Y/N] '00

              JSR   inpyn         ; input yes/no
              BCS   :no_init

              JSR   ld_drvs       ; load in drivers file
              JMP   do_init       ; do initial config

*-------------------------------

:no_init      JSR   drv_path      ; get drivers file path and load it

start         ENT
              LDA   #0            ; turn off escape handler
              STA   refnum
              JSR   escape
              JSR   close         ; close all files
              JSR   logcon

              JSR   do_main

              JSR   cls           ; clear screen
              JSR   print
              ASC   'Select an Option:'0D0D
              ASC   '  1 - Reconfigure Modem              '0D
              ASC   '  2 - Reconfigure Printer            '0D
              ASC   '  3 - Reconfigure Clock'0D
              ASC   '  4 - Edit System Defualts'0D
              ASC   '  5 - Edit Profanity Filter'0D
              ASC   '  6 - Quit',0D0D

              ASC   'Which? [1-6] '00

              LDX   #7            ; get a number [1-6]
              JSR   inpnum

              PHA
              LDX   #<start
              LDA   #>start
              JSR   escape        ;esc goes back to here
              PLA
              ASL
              TAX

              LDA   jumptable,X
              STA   prn
              INX                 ;push low
              LDA   jumptable,X
              STA   prn+1
              JMP   (prn)

jumptable     DA    0
              DA    re_mdm        ; 1
              DA    re_pr         ; 2
              DA    re_clk        ; 3
              DA    do_dflts      ; 4
              DA    do_filt       ; 5
              DA    do_quit       ; 6
              DA    do_mtr        ; 7 (hidden command)

*-------------------------------
* print the top box

do_main       ENT
              JSR   TopBox
              JSR   print
              DB    1,2,19
              ASC   'LLUCE - Configuration Program - Ver. '
              DB    m_vers        ; major version #
              ASC   '.'
              DB    s_vers        ; sub version #
              DB    p_vers        ; patch version #
              DB    0

              JSR   print
              DB    1,4,20
              ASC   'Copyright 1989 - L&L Productions, Inc.'00
              RTS

*-------------------------------

drvname       ENT
              STR   'LLUCE.DRIVERS'

*-------------------------------
* Quit
*-------------------------------

; quit the program
do_quit       ENT
              JSR   $FC58         ; clear screen
              STA   $C051         ; goto text mode

              LDA   #$FF          ; reset inverse flag
              STA   $32


              JSR   mli
              DB    $65           ; quit
              DA    p_quit
              RTS


p_quit        DB    4
              DB    0
              DA    0
              DB    0
              DA    0

do_mtr        LDA   #-1
              STA   $32

              JMP   entrmon       ; monitor

