*-------------------------------------------------
* Hayes result codes
*-------------------------------------------------

SM_OK          =     0                                  ; Modem 'OK'
SM_CON03       =     1                                  ; Modem 'CONNECT 300'
SM_RING        =     2                                  ; Modem 'RING'
SM_NOCAR       =     3                                  ; Modem 'NO CARRIER'
SM_ERROR       =     4                                  ; Modem 'ERROR'
SM_CON12       =     5                                  ; Modem 'CONNECT 1200'
SM_NODT        =     6                                  ; Modem 'NO DIALTONE'
SM_BUSY        =     7                                  ; Modem 'BUSY'
SM_NOANS       =     8                                  ; Modem 'NO ANSWER'
SM_CON24       =     10                                 ; Modem 'CONNECT 2400'
SM_CON48       =     11                                 ; Modem 'CONNECT 4800'
SM_CON96       =     12                                 ; Modem 'CONNECT 9600'
SM_CON14       =     13                                 ; Modem 'CONNECT 14400'
SM_CON19       =     14                                 ; Modem 'CONNECT 19200'
SM_CON57       =     18                                 ; Modem 'CONNECT 57600'
SM_CON72       =     24                                 ; Modem 'CONNECT 7200'
SM_CON120      =     25                                 ; Modem 'CONNECT 12000'
SM_CON38       =     28                                 ; Modem 'CONNECT 38400'

SM_CAR03       =     40                                 ; Modem 'CARRIER 300'
SM_CAR12       =     46                                 ; Modem 'CARRIER 1200'
SM_CAR24       =     47                                 ; Modem 'CARRIER 2400'
SM_CAR48       =     48                                 ; Modem 'CARRIER 4800'
SM_CAR72       =     49                                 ; Modem 'CARRIER 7200'
SM_CAR96       =     50                                 ; Modem 'CARRIER 9600'
SM_CAR120      =     51                                 ; Modem 'CARRIER 12000'
SM_CAR14       =     52                                 ; Modem 'CARRIER 14400'

COMP_MNP5      =     66                                 ; Modem 'COMPRESSION: CLASS 5'
COMP_V42BIS    =     67                                 ; Modem 'COMPRESSION: V.42BIS'
COMP_ADC       =     68                                 ; Modem 'COMPRESSION: ADC'
COMP_NONE      =     69                                 ; Modem 'COMPRESSION: NONE'

PROT_NONE      =     70                                 ; Modem 'PROTOCOL: NONE'
PROT_LABP      =     71                                 ; Modem 'PROTOCOL: LAP-B'
PROT_AFT       =     73                                 ; Modem 'PROTOCOL: AFT'
PROT_LAPM      =     77                                 ; Modem 'PROTOCOL: LAP-M'
PROT_ALT       =     80                                 ; Modem 'PROTOCOL: ALT'

*-------------------------------------------------
* AppleCat II control locations
*-------------------------------------------------

SWBYT          =     $C080
DV             =     %10000000                          ; Valid Touch tone present
BSR60          =     %01000000                          ; 60HZ from BSR (solid 1 = no BSR)
CD103          =     %00100000                          ; 103 carrier detect
AUDIODET       =     %00010000                          ; Audio sample
CATSW4         =     %00001000                          ; Firmware switch 4
CATSW3         =     %00000100                          ; Firmware switch 3
CATSW2         =     %00000010                          ; Firmware switch 2
CATSW1         =     %00000001                          ; Firmware switch 1
TONBYT         =     $C081
IRQ29ST        =     %00010000                          ; IRQ 29.12 HZ status
TTB8           =     %00001000                          ; Touch tone bit 8
TTB4           =     %00000100                          ; Touch tone bit 4
TTB2           =     %00000010                          ; Touch tone bit 2
TTB1           =     %00000001                          ; Touch tone bit 1
INDATA         =     $C08B
ACBYTE         =     $C08D
CAT_CTS        =     %00001000                          ; CTS line
CD212          =     %00000100                          ; 212 carrier detect
CATRING        =     %00000001                          ; Ring signal
STATUS1        =     $C08F
CAT_OV         =     %10000000                          ; Overrun
CAT_FE         =     %01000000                          ; Framing error
CAT_PE         =     %00100000                          ; Parity error
CAT_TXE        =     %00010000                          ; Transmit register empty
CAT_RXF        =     %00001000                          ; Receive register full
CAT_TXI        =     %00000100                          ; Transmit IRQ
CAT_RXI        =     %00000010                          ; Receive IRQ
CAT_RNGI       =     %00000001                          ; Ring IRQ

DACBYT         =     $C080
SQUBYT         =     $C081
EN212          =     %00000000                          ; 212 Disable
DIS212         =     %10000000
MODE212        =     %00100000                          ; 212 originate
TRMC           =     %00011100                          ; Tape motor on
SSQ            =     %00000010                          ; Speaker on
MSQ            =     %00000001                          ; Microphone off
SHBYT          =     $C082
SH             =     %00000010                          ; Off hook
CLRDV          =     %00000001                          ; Reset TouchTone
BSRBYT         =     $C083
IRQ29EN        =     %00000000
IRQ29DIS       =     %00000100                          ; 29.12HZ IRQ disabled
BSR120DIS      =     %00000010                          ; Disable BSR 120KHZ output
RECBYT         =     $C089
CDT            =     %01000000                          ; Normal carrier detect timing
RA103          =     %01100100                          ; 103 answer
RO103          =     %01100101                          ; 103 originate
RAV21          =     %01100110                          ; V.21 answer
ROV21          =     %01100111                          ; V.21 originate
RA103MRK       =     %01100000                          ; 103 answer, mark CD
RO103MRK       =     %01100001                          ; 103 originate, mark CD
RAV21MRK       =     %01100010                          ; V.21 answer, mark CD
ROV21MRK       =     %01100011                          ; V.21 originate, mark CD
RX202          =     %01011100                          ; 202
RX202MK        =     %01011000                          ; 202, mark CD
RX_TDD         =     %00101101                          ; Receive TDD
DET900HZ       =     %01101111                          ; Detect 900Hz tones
DT_BUSY_DET    =     %01111110                          ; Detect dialtone & busy signal
CON            =     $C08A
PARITYEN       =     %01000000                          ; Parity enable
MARKP          =     %00110000                          ; Mark parity
ODDP           =     %00100000                          ; Odd parity
SPACEP         =     %00010000                          ; Space parity
EVENP          =     %00000000                          ; Even parity
STOP2          =     %00001000                          ; 2 stop bits
STOP1_5        =     %00000100                          ; 1.5 stop bits
STOP1          =     %00000000                          ; 1 stop bit
DATBITS8       =     %00000011                          ; 8 data bits
DATBITS7       =     %00000001                          ; 7 data bits
DATBITS6       =     %00000010                          ; 6 data bits
DATBITS5       =     %00000000                          ; 5 data bits
SPDBYT         =     $C08B
TXBR1200       =     %00000000                          ; Transmit baud rates
TXBR600        =     %00010000
TXBR300        =     %00100000
TXBR150        =     %00110000
TXBR110        =     %01010000
TXBR75         =     %01100000
TXBR50         =     %01110000
TXBR45_5       =     %01000000
RXBR1200       =     %00000000
RXBR600        =     %00000001
RXBR300        =     %00000010
RXBR150        =     %00000011
RXBR110        =     %00000101
RXBR75         =     %00000110
RXBR50         =     %00000111
RXBR45_5       =     %00000100
COM            =     $C08C
TXOFF          =     %00001100                          ; Transmit off
TX_IRQ         =     %00001000                          ; Transmit on, IRQ enabled
TXON           =     %00000100                          ; Transmit on
TX_BRK         =     %00000000                          ; Transmit break
RX_IRQ         =     %00000010                          ; Receive on, IRQ enabled
RXON           =     %00000001                          ; Receive on
RX_OFF         =     %00000000                          ; Receive off
XMTBYT         =     $C08D
RNGIRQEN       =     %00010000                          ; Ring IRQ enable
TA103          =     0                                  ; 103 answer
TO103          =     1                                  ; 103 originate
TCCITTA        =     2                                  ; CCITT answer
TCCITTO        =     3                                  ; CCITT originate
TX_TDD         =     4                                  ; TDD
SOFTC202       =     5                                  ; 202 soft carrier
MODE202        =     6                                  ; 202
REVCHAN        =     7                                  ; reverse channel (view data)
TXDISABLE      =     %00001000                          ; Transmitter off
OUTDAT         =     $C08E
DEVBYT         =     $C08F
TX212          =     %00001000                          ; Transmit through 212
TXPTR          =     %00000100                          ; Transmit to printer
TXMDM          =     %00000000                          ; Transmit to main modem
RX212          =     %00000010                          ; Receive from 212
RXPTR          =     %00000001                          ; Receive from printer
RXMDM          =     %00000000                          ; Receive from main modem

BYT212         =     $C080
ALOOP          =     %00100000                          ; Analog loopback
DLOOP          =     %00010000                          ; Digital loopback
RDLOOP         =     %00001000                          ; Remote digital loopback
B212_10        =     %00000100                          ; 10 bit 212 data
B212_9         =     %00000010                          ; 9 bit 212 data
RESET212       =     %00000001                          ; reset 212

*-------------------------------------------------
* Super Serial Card (SSC) control
*-------------------------------------------------

DATA           =     $C088
STATUS         =     $C089
SSCIRQ         =     %10000000                          ; SSC interrupted
SSCDSR         =     %01000000                          ; DSR
SSCDCD         =     %00100000                          ; DCD
SSCTXE         =     %00010000                          ; TX buffer empty
SSCRXF         =     %00001000                          ; RX buffer full
SSCOE          =     %00000100                          ; Overrun error
SSCFE          =     %00000010                          ; Framing error
SSCPE          =     %00000001                          ; Parity error
COMMAND        =     $C08A
SSCNOP         =     %00000000                          ; No parity
SSCODDP        =     %00100000                          ; Odd parity
SSCEVEVP       =     %01100000                          ; Even parity
SSCMARKP       =     %10100000                          ; Mark parity
SSCSPCP        =     %11100000                          ; Space parity
SSCECHO        =     %00010000                          ; Echo mode
SSCTXOFF       =     %00000000                          ; TX off, RTS high, TX IRQ off
SSCTXONI       =     %00000100                          ; TX on, RTS low, TX IRQ on
SSCTXON        =     %00001000                          ; TX on, RTS low, TX IRQ off
SSCTXBRK       =     %00001100                          ; TX break, RTS low, TX IRQ off
SSCRXIRQX      =     %00000010                          ; RX IRQ off
SSCRXON        =     %00000001                          ; RX on, DTR low
CONTROL        =     $C08B
SSCSTOP1       =     %00000000                          ; 1 stop bit
SSCSTOP2       =     %10000000                          ; 2 stop bits
SSCDATA8       =     %00000000                          ; 8 data bits
SSCDATA7       =     %00100000                          ; 7 data bits
SSCDATA6       =     %01000000                          ; 6 data bits
SSCDATA5       =     %01100000                          ; 5 data bits
SSCCLK         =     %00010000                          ; Baud rate generator/ext clk
SSCEXTCK       =     %00000000                          ; 16x external clock
SSC50          =     %00000001                          ; 50 baud
SSC75          =     %00000010                          ; 75 baud
SSC110         =     %00000011                          ; 110 baud
SSC135         =     %00000100                          ; 135 baud
SSC150         =     %00000101                          ; 150 baud
SSC300         =     %00000110                          ; 300 baud
SSC600         =     %00000111                          ; 600 baud
SSC1200        =     %00001000                          ; 1200 baud
SSC1800        =     %00001001                          ; 1800 baud
SSC2400        =     %00001010                          ; 2400 baud
SSC3600        =     %00001011                          ; 3600 baud
SSC4800        =     %00001100                          ; 4800 baud
SSC7200        =     %00001101                          ; 7200 baud
SSC9600        =     %00001110                          ; 9600 baud
SSC19200       =     %00001111                          ; 19,200 baud

*-------------------------------------------------
* MicroModem ][ control
*-------------------------------------------------

CR3            =     $C083
CR2            =     $C085
RINGIN         =     $C085
CR1            =     $C086
MMSTATUS       =     $C086
MMDATA         =     $C087

*-------------------------------------------------
* Apple //gs serial port equates
*-------------------------------------------------

oINIT          =     MSLOT*256+$C00D
oREAD          =     MSLOT*256+$C00E
oWRITE         =     MSLOT*256+$C00F
oSTATUS        =     MSLOT*256+$C010
oCONTROL       =     MSLOT*256+$C012

SCCREG         =     MSLOT-1!1+$C038
SCCDATA        =     MSLOT-1!1+$C03A

*-------------------------------------------------
* Baud rate generator time constants

X1_19200       =     94
X1_9600        =     190
X1_7200        =     254
X1_4800        =     382
X1_3600        =     510
X1_2400        =     766
X1_1800        =     1022
X1_1200        =     1534
X1_600         =     3070
X1_300         =     6142
X1_150         =     12286
X1_134         =     13703
X1_110         =     16754
X1_75          =     24574

X16_19200      =     4
X16_9600       =     10
X16_7200       =     14
X16_4800       =     22
X16_3600       =     30
X16_2400       =     46
X16_1800       =     62
X16_1200       =     94
X16_600        =     190
X16_300        =     382
X16_150        =     766
X16_134        =     855
X16_110        =     1045
X16_75         =     1534
X16_50         =     2302

X32_19200      =     1
X32_9600       =     4
X32_7200       =     6
X32_4800       =     10
X32_3600       =     14
X32_2400       =     22
X32_1800       =     30
X32_1200       =     46
X32_600        =     94
X32_300        =     190
X32_150        =     382
X32_110        =     522
X32_75         =     766
X32_50         =     1150

X64_9600       =     1
X64_7200       =     2
X64_4800       =     4
X64_3600       =     6
X64_2400       =     10
X64_1800       =     14
X64_1200       =     22
X64_600        =     46
X64_300        =     94
X64_150        =     190
X64_110        =     260
X64_75         =     382
X64_50         =     574

*-------------------------------------------------
* Zilog Z8530 SCC-specific definitions
*
* Reference: Zilog Z8530 SCC Product Specification
*
* Each SCC channel data window is always available and is accessed by
* invoking either SCC?_out( x ) to write byte x
* or x = SCC?_in() to read byte x.
*
* SCC register # n (for n > 0) is accessed by performing
* either SCC?_ctrl( n, x ) to write x to register # n
* or x = SCC?_stat( n ) to read x from register # n.
*
* (In the above, ? is either A or B depending on the SCC channel.)
*-------------------------------------------------

* SCCA_reg(n) (SCCAREG = (n))
* SCCB_reg(n) (SCCBREG = (n))
* SCCA_out(x) (SCCADATA = (x))
* SCCB_out(x) (SCCBDATA = (x))
* SCCA_in() SCCADATA
* SCCB_in() SCCBDATA
* SCCA_ctrl(n, x) ((n) ? (SCCA_reg(n), SCCA_reg(n)) : SCCA_reg(x))
* SCCB_ctrl(n, x) ((n) ? (SCCB_reg(n), SCCB_reg(n)) : SCCB_reg(x))
* SCCA_stat(n) (SCCA_reg(n), SCCAREG)
* SCCB_stat(n) (SCCB_reg(n), SCCBREG)

*-------------------------------------------------
* Read Register bit-field definitions
*
* (Unspecified bits are always 0)
*
*-------------------------------------------------
* RR0: Transmit/Receive buffer status and External status
* (RR0 does not require the preliminary SCC?_reg( 0 ))
*
RR0_BRK        =     $80                                ; break/abort
RR0_UND        =     $40                                ; Tx underrun/EOM
RR0_CTS        =     $20                                ; tracks CTS.L input pin
RR0_SYN        =     $10                                ; synchronous/hunt
;   (affected by SYNC.L transition if no crystal)
RR0_DCD        =     $08                                ; tracks DCD.L input pin
RR0_EMPTY      =     $04                                ; Tx buffer empty
RR0_ZCT        =     $02                                ; zero count
RR0_AVAIL      =     $01                                ; Rx character available

*-------------------------------------------------
* RR1: Special Receive Condition status
*
RR1_END        =     $80                                ; end of frame (SDLC)
RR1_FERR       =     $40                                ; CRC/framing error
RR1_OERR       =     $20                                ; Rx overrun error
RR1_PERR       =     $10                                ; parity error
RR1_RESIDUE    =     $0E                                ; residue codes 0|1|2
RR1_SENT       =     $01                                ; all sent

*-------------------------------------------------
* RR2: Unmodified interrupt vector (channel A)
* or Modified interrupt vector (channel B)
*
*-------------------------------------------------
* RR3: Interrupt Pending bits (channel A)
* (all 0 when read through channel B)
*
RR3_ARIP       =     $20                                ; channel A Rx interrupt pending
RR3_ATIP       =     $10                                ; channel A Tx interrupt pending
RR3_AXIP       =     $08                                ; channel A ext/stat interrupt pending
RR3_BRIP       =     $04                                ; channel B Rx interrupt pending
RR3_BTIP       =     $02                                ; channel B Tx interrupt pending
RR3_BXIP       =     $01                                ; channel B ext/stat interrupt pending

*-------------------------------------------------
* RR8: Receive buffer
* (must be accessed via SCC?_in())
*
*-------------------------------------------------
* RR10: Miscellaneous status
*
RR10_1MISS     =     $80                                ; one clock missing
RR10_2MISS     =     $40                                ; two clocks missing
RR10_LPSEND    =     $10                                ; loop sending
RR10_ONLOOP    =     $02                                ; on loop

*-------------------------------------------------
* RR12: lower byte of baud rate generator time constant
* RR13: upper byte of baud rate generator time constant
*
*-------------------------------------------------
* RR15: External/Status interrupt information
*
RR15_BRKIE     =     $80                                ; break/abort interrupt enable
RR15_UNDIE     =     $40                                ; Tx underrun interrupt enable
RR15_CTSIE     =     $20                                ; CTS transition interrupt enable
RR15_SYNIE     =     $10                                ; sync/hunt interrupt enable
RR15_DCDIE     =     $08                                ; DCD transition interrupt enable
RR15_ZCTIE     =     $02                                ; zero count interrupt enable

*-------------------------------------------------
* Write register bit-field definitions
*
* (Unspecified bits must always be 0)
*
*-------------------------------------------------
* WR0: CRC initialize, initialization commands for the various modes,
* Register Pointers
* (WR0 does not require the preliminary SCC?_reg( 0 ))
*
WR0_RUND       =     $C0                                ; reset Tx underrun latch
WR0_RGEN       =     $80                                ; reset Tx CRC generator
WR0_RCHK       =     $40                                ; reset Rx CRC checker
WR0_NULL       =     $00                                ; null code
WR0_RIUS       =     $38                                ; reset highest IUS
WR0_RERR       =     $30                                ; error reset
WR0_RTIP       =     $28                                ; reset Tx interrupt pending
WR0_RCIE       =     $20                                ; enable interrupt on next Rx character
WR0_ABORT      =     $18                                ; send abort (SDLC)
WR0_RXI        =     $10                                ; reset ext/stat interrupts
WR0_PHI        =     $08                                ; point high
WR0_REG        =     $07                                ; register 0-15 select (see SCC?_reg( n ))

*-------------------------------------------------
* WR1: Transmit/Receive interrupt and data transfer mode definition
*
WR1_WREN       =     $80                                ; wait/DMA request enable
WR1_DMA        =     $40                                ; 0=>wait/1=>DMA request function
WR1_WRRX       =     $20                                ; wait/DMA request on 0=>transmit/1=>receive
WR1_RISCO      =     $18                                ; Rx interrupt on special condition only
WR1_RIALL      =     $10                                ; interrupt on all Rx chars or special cond.
WR1_RIFCS      =     $08                                ; Rx interrupt on 1st char or special cond.
WR1_RIDIS      =     $00                                ; Rx interrupt disable
WR1_PARSC      =     $04                                ; parity is special condition
WR1_TIEN       =     $02                                ; Tx interrupt enable
WR1_XIEN       =     $01                                ; ext interrupt enable

*-------------------------------------------------
* WR2: Interrupt vector (accessed through either channel)
* (useless on Apple IIGS)
*
*-------------------------------------------------
* WR3: Receive parameters and control
*
WR3_R8B        =     $C0                                ; Rx 8 bits/character
WR3_R6B        =     $80                                ; Rx 6 bits/character
WR3_R7B        =     $40                                ; Rx 7 bits/character
WR3_R5B        =     $00                                ; Rx 5 bits/character
WR3_AUTO       =     $20                                ; auto enables
* "auto enables" => CTS/DCD enable transmitters/receivers,
* RTS raised when transmitter empty
WR3_HUNT       =     $10                                ; enter hunt mode
WR3_RCRC       =     $08                                ; Rx CRC enable
WR3_ADDR       =     $04                                ; address search mode (SDLC)
WR3_SCLI       =     $02                                ; sync character load inhibit
WR3_RXEN       =     $01                                ; Rx enable

*-------------------------------------------------
* WR4: Transmit/Receive miscellaneous parameters and modes
*
WR4_X64        =     $C0                                ; x64 clock mode
WR4_X32        =     $80                                ; x32 clock mode
WR4_X16        =     $40                                ; x16 clock mode
WR4_X1         =     $00                                ; x1 clock mode
WR4_XSYN       =     $30                                ; external sync mode
WR4_SDLC       =     $20                                ; SDLC mode (01111110 flag)
WR4_S16B       =     $10                                ; 16 bit sync character
WR4_S8B        =     $00                                ; 8 bit sync character
WR4_2SB        =     $0C                                ; 2 stop bits/character
WR4_15SB       =     $08                                ; 1.5 stop bits/character
WR4_1SB        =     $04                                ; 1 stop bit/character
WR4_SYNC       =     $00                                ; sync modes enable
WR4_EVEN       =     $02                                ; parity 0=>odd/1=>even
WR4_PAREN      =     $01                                ; parity enable

*-------------------------------------------------
* WR5: Transmit parameters and controls
*
WR5_DTR        =     $80                                ; tracked by DTR/REQ.L output pin
WR5_T8B        =     $60                                ; Tx 8 bits/character
WR5_T6B        =     $40                                ; Tx 6 bits/character
WR5_T7B        =     $20                                ; Tx 7 bits/character
WR5_T5B        =     $00                                ; Tx 5 bits (or less)/character
WR5_SBRK       =     $10                                ; send break
WR5_TXEN       =     $08                                ; Tx enable
WR5_CRC16      =     $04                                ; 0=>SDLC(CCITT)/1=>CRC-16
WR5_RTS        =     $02                                ; tracked by RTS.L output pin
;   (except when auto enable is on)
WR5_TCEN       =     $01                                ; Tx CRC enable

*-------------------------------------------------
* WR6: Sync characters or SDLC address field
* WR7: Sync character or SDLC flag
* (See the Z8530 SCC Product Specification for bit layouts)
*

*-------------------------------------------------
* WR8: Transmit buffer
* (must be accessed via SCC?_out())
*

*-------------------------------------------------
* WR9: Master interrupt control and reset
* (accessed through either channel)
*
WR9_HARD       =     $C0                                ; force hardware reset
WR9_RSTA       =     $80                                ; channel reset A
WR9_RSTB       =     $40                                ; channel reset B
WR9_NULL       =     $00                                ; no reset
WR9_STAT       =     $10                                ; status 0=>low/1=>high
WR9_MIE        =     $08                                ; master interrupt enable
WR9_DLC        =     $04                                ; DLC
WR9_NV         =     $02                                ; NV
WR9_VIS        =     $01                                ; VIS

*-------------------------------------------------
* WR10: Miscellaneous transmitter/receiver control bits
*
WR10_CP1       =     $80                                ; CRC preset 0=>all 0s/1=>all 1s
WR10_FM0       =     $60                                ; frequency modulation 0 (transition = 0)
WR10_FM1       =     $40                                ; frequency modulation 1 (transition = 1)
WR10_NRZI      =     $20                                ; NRZI (non-return to zero inhibit)
WR10_NRZ       =     $00                                ; NRZ (non-return to zero)
WR10_POLL      =     $10                                ; go active on poll
WR10_MIDLE     =     $08                                ; 0=>flag/1=>mark idle
WR10_AUND      =     $04                                ; 0=>flag/1=>abort on underrun
WR10_LOOP      =     $02                                ; loop mode
WR10_S6B       =     $01                                ; 0=>8/1=>6 bit sync

*-------------------------------------------------
* WR11: Clock mode control
*
WR11_RXTAL     =     $80                                ; RTxC 0=>no crystal/1=>crystal
WR11_RPLL      =     $60                                ; receive clock = DPLL output
WR11_RBRG      =     $40                                ; receive clock = BR generator output
WR11_RTRXC     =     $20                                ; receive clock = TRxC pin
WR11_RRTXC     =     $00                                ; receive clock = RTxC pin
WR11_TPLL      =     $18                                ; transmit clock = DPLL output
WR11_TBRG      =     $10                                ; transmit clock = BR generator output
WR11_TTRXC     =     $08                                ; transmit clock = TRxC pin
WR11_TRTXC     =     $00                                ; transmit clock = RTxC pin
WR11_OTRXC     =     $04                                ; TRxC.L 0=>input/1=>output
WR11_OPLL      =     $03                                ; TRxC.L out = DPLL output
WR11_OBRG      =     $02                                ; TRxC.L out = BR generator output
WR11_OTCLK     =     $01                                ; TRxC.L out = transmit clock
WR11_OXTAL     =     $00                                ; TRxC.L out = crystal output

*-------------------------------------------------
* WR12: lower byte of baud rate generator time constant
* WR13: upper byte of baud rate generator time constant
*

*-------------------------------------------------
* WR14: Miscellaneous control bits
*
WR14_NRZI      =     $E0                                ; set NRZI mode
WR14_FM        =     $C0                                ; set FM mode
WR14_RTXC      =     $A0                                ; set source = RTxC
WR14_BRG       =     $80                                ; set source = BR generator
WR14_DPLL      =     $60                                ; disable DPLL
WR14_RMISS     =     $40                                ; reset missing clock
WR14_SEARCH    =     $20                                ; enter search mode
WR14_NULL      =     $00                                ; null command
WR14_LLB       =     $10                                ; local loopback
WR14_ECHO      =     $08                                ; auto echo
WR14_REQ       =     $04                                ; 0=>DTR/1=>request function
WR14_BRSRC     =     $02                                ; BR generator source
WR14_BREN      =     $01                                ; BR generator enable

*-------------------------------------------------
* WR15: External/Status interrupt control
*
WR15_BRKIE     =     $80                                ; break/abort interrupt enable
WR15_UNDIE     =     $40                                ; Tx underrun interrupt enable
WR15_CTSIE     =     $20                                ; CTS interrupt enable
WR15_SYNIE     =     $10                                ; sync/hunt interrupt enable
WR15_DCDIE     =     $08                                ; DCD interrupt enable
WR15_ZCTIE     =     $02                                ; zero count interrupt enable

*-------------------------------------------------
* Serial port control parameters
*-------------------------------------------------

GetModeBits    =     0
SetModeBits    =     1
PORTMODE       =     %00000000000000000000000000000001
XONWAIT        =     %00000000000000000000000000000010
DTRDSREN       =     %00000000000000000000000000000100
KEEPLF         =     %00000000000000000000000000001000
ACCEPTKB       =     %00000000000000000000000000010000
XONXOFFEN      =     %00000000000000000000000000100000
GENLF          =     %00000000000000000000000001000000
ECHOTOVID      =     %00000000000000000000000010000000
BGPRTON        =     %00000000000000000000000100000000
OUTHALT        =     %00000000000000000000001000000000
INHALT         =     %00000000000000000000010000000000
GENCR          =     %00000000000000000000100000000000
DCDEN          =     %00000000000000000010000000000000
IOBUFEN        =     %00000000000000000100000000000000
GOTPE          =     %00000000000100000000000000000000
GOTFE          =     %00000000010000000000000000000000
IGNCMDS        =     %00000000100000000000000000000000
GetPortStat    =     6
RXFULL         =     %0000000000000001
TXEMPTY        =     %0000000000000100
DCDSTATE       =     %0000000000001000
DSRSTATE       =     %0000000000100000
TXUNDER        =     %0000000001000000
BRK_ABT        =     %0000000010000000
GetSCC         =     8
SetSCC         =     9
GetDTR         =     $A
SetDTR         =     $B
DTRSTATE       =     %0000000010000000
GetIntInfo     =     $C                                 ; Use GetPortStat masks
SetIntInfo     =     $D
GetInBuffer    =     $10
GetOutBuffer   =     $11
SetInBuffer    =     $12
SetOutBuffer   =     $13
FlushInQueue   =     $14
FlushOutQueue  =     $15
InQStatus      =     $16
OutQStatus     =     $17
SendQueue      =     $18

*-------------------------------------------------
* Other serial port equates
*
TXREADY        =     0
RXREADY        =     1
               LST   OFF

