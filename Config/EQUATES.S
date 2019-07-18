            LST   OFF
            tr
            tr    adr
********************************
*                              *
*   Config Program - Equates   *
*                              *
********************************

*-------------------------------
* Date: 3/11/88
*-------------------------------

bs          =     8
lf          =     $A
up          =     $B
cr          =     $D
fs          =     $15
can         =     $18
esc         =     $1B
del         =     $7F

; memory allocation / buffers

*index = $200 ; offset to skip over lluce header info
lnbuf       =     $200
flname      =     $300
fltext      =     $301
reset       =     $3f2
dvrbuf      =     $800        ; start of driver buffer space
prdrv       =     $900        ; printer driver is at $900-$9ff
clkdrv      =     $A00        ; clocks driver is at $a00-$aff
mdmdrv      =     $B00        ; modem driver is at $b00-$fff
pfilter     =     $1000       ; profanity filter is at $1000-$10ff
cdbyte      =     $10BF       ; carrier detect byte
ansstr      =     $10C0       ; modem answer string
initstr     =     $10D0       ; modem init string
hdrbuf      =     $1100       ; buffer for editing the profanity filter

cdtype      =     $1FFD
modemtype   =     $1FFE
serialtype  =     $1FFF

mli         =     $BF00

initbuf     =     $1800
ansbuf      =     $1830
fbuf1       =     $1C00
fnam1       =     $1E00

sortbuf     =     $8000
copybuf     =     $6000
copymax     =     $5800
; zero page usage

temp        =     0
temp2       =     2
temp3       =     4
temp4       =     6
x_save      =     9
y_save      =     $A
chrptr      =     $B
base        =     $D
maxlen      =     $F
inverse     =     $10
point0      =     $11
point1      =     $14
prn         =     $16         ; [4 bytes]
numptr      =     $1A
psave       =     $1C
prnt        =     $1E

ch          =     $24
cv          =     $25

fmparm      =     $60
doszero     =     $62
dosptr      =     $64
part        =     $66
dosbyt      =     $68

point3      =     $FD

