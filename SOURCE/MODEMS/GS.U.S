             TTL   'Hayes Ultra - GS port driver'
             PAG
             LST   OFF
*-------------------------------
* GS Port Driver Bios
* written by Andy Nicholas on July 26, 1987
* Updated for Ultra 144 - 1/17/92 - LTW
* Fixed for buffering/interrupts 12/10/92 - AMW
*-------------------------------

             XC
             XC                                    ; uses 65816 code
BIGBUFF      =     0

* Equates
*-------------------------------

*VIDCOUT =     $906
PTR          =     $A

RETURN       =     13
PRTSPDL      =     12
PRTSPDH      =     13
*ESCAPE  =     43

* Jump Table
*-------------------------------
             ORG   $B00
MODEMDVR     =     *
SLOT         DB    MSLOT*16                        ; Serial Card Slot
MDMSPEED     =     *
INITSPD      DB    6                               ; initialize speed
CALLSPD      DB    0                               ; speed of call

BYTCNT       DB    0,0,0

MDMINIT      BRL   M_INIT
MDMRSET      BRL   RESET
MDMRING      BRL   RING
MDMANS       BRL   ANSRING
MDMHANG      BRL   HANGUP
MDMIN        BRL   INP
MDMOUT       BRL   OUT
MDMDCD       BRL   M_CHKDCD
MDMSSPD      BRL   SETSPD
MDMINT       BRL   M_IRQ
MDMDTR       BRL   RAISEDTR                        ; raise dtr
MDMCBUF      BRL   CLEAR_BUF
MDMQUIT      BRL   QUIT

* init the serial port pascal locations
*-------------------------------

M_INIT       LDA   MSLOT*256+$C00D                 ; Get Init Address
             STA   DOINIT+1
             LDA   MSLOT*256+$C00E                 ; Get Read Address
             STA   DOREAD+1
             LDA   MSLOT*256+$C00F                 ; Get Write Address
             STA   DOWRITE+1
             LDA   MSLOT*256+$C010                 ; Get Status Address
             STA   DOSTATUS+1
             LDA   MSLOT*256+$C012
             STA   DOEXT+1

             LDX   #MSLOT+$C0                      ; setup modem port
             LDY   #MSLOT*16
             JSR   DOINIT

             LDA   #<PORTINIT                      ; point to port init string
             LDX   #>PORTINIT
             LDY   #0
             JSR   XMITSTR                         ; send it!

             DO    BIGBUFF
             LDA   #GetInBuffer                    ; getting IO buffer
             STA   IGETSET

             LDA   #<INBUFFER                      ; get current buffer
             LDX   #>INBUFFER
             LDY   #0
             JSR   DOEXT

             CLC
             XCE
             REP   #$30
             MX    %00

             PHA
             PEA   $1000                           ; type 1, application, auxID
             LDX   #$2003
             JSL   $E10000
*        _GetNewID
             PLA
             STA   M_MEM_ID

             PHA
             PHA
             PEA   0
             PEA   $4000                           ; we want 16k
             PHA
             PEA   $C018                           ; locked, fixed, no special
             PEA   0
             PEA   0
             LDX   #$902
             JSL   $E10000
*        _NewHandle
             BCC   MINIT_OK

             PLA
             PLA
             LDA   #$EAEA                          ; Put no-ops over the input buffer
             STA   PATCHIN                         ; JSR if we could not get any memory
             STA   PATCHIN+1
             STZ   M_MEM_ID                        ; mark no memory found
             BRA   MINIT_DN

MINIT_OK     PLA
             STA   0                               ; get the handle
             STA   M_HANDLE
             PLA
             STA   0+2
             STA   M_HANDLE+2

             LDY   #2                              ; get memory pointer
             LDA   [0]
             STA   M_BUFADR
             LDA   [0],Y
             STA   M_BUFADR+2

             LDA   #$4000                          ; set length to 16K
             STA   M_BUFLEN

             SEC
             XCE
             MX    %11
             LDA   #<IN_BUF                        ; set up buffer
             LDX   #>IN_BUF
             LDY   #0
             JSR   DOEXT
             FIN

             LDA   #GetIntInfo                     ; get interrupt info
             STA   INTCODE

             LDA   #<INTLIST                       ; tell it, no interrupts
             LDX   #>INTLIST
             LDY   #0
             JSR   DOEXT

             LDA   #SetIntInfo                     ; set interrupt info
             STA   INTCODE

             STZ   INTFLAGS                        ; tell it no interrupts
             STZ   INTFLAGS+1

             LDA   #<INTLIST
             LDX   #>INTLIST
             LDY   #0
             JSR   DOEXT

MINIT_DN     SEC
             XCE
             RTS

PATCHIN      DS    3
CLEAR_BUF    RTS

* Reset modem before quitting ACOS
*-------------------------------
QUIT         JSR   RAISEDTR                        ; raise DTR

             LDY   INITSPD                         ; set init speed
             JSR   SETSPD

             LDA   #<QUITSTR
             LDX   #>QUITSTR
             LDY   #$80
             JSR   XMITSTR

             DO    BIGBUFF
             LDA   M_MEM_ID                        ; any buffer?
             ORA   M_MEM_ID+1
             BEQ   HANGUP

             LDA   #SetInBuffer                    ; setting IO buffer
             STA   IGETSET

             LDA   #<INBUFFER                      ; reset buffer back
             LDX   #>INBUFFER
             LDY   #0
             JSR   DOEXT

             CLC
             XCE
             REP   #$30
             MX    %00
             LDA   M_HANDLE+2                      ; get rid of memory
             PHA
             LDA   M_HANDLE
             PHA
             LDX   #$1002
             JSL   $E10000
*        _DisposeHandle
             SEC
             XCE
             MX    %11
             FIN

* Hang up the modem if needed
*-------------------------------
HANGUP       LDA   #$80
             HEX   2C
RAISEDTR     LDA   #0
             STA   DTRFLAG
             LDA   #<DTRLIST
             LDX   #>DTRLIST
             LDY   #0
             BRL   DOEXT

* clear the input buffer
*-------------------------------

CLRBUFF      LDA   #<FLUSHINQ
             LDX   #>FLUSHINQ
             LDY   #0
             BRL   DOEXT

* input data
*-------------------------------
INP          PHX                                   ; save x
             PHY

             LDX   #MSLOT+$C0
             LDY   #MSLOT*16
             LDA   #RXREADY
             JSR   DOSTATUS
             LDA   #0
             BCC   M_INP1

             LDX   #MSLOT+$C0
             LDY   #MSLOT*16
             JSR   DOREAD

             SEC
M_INP1       PLY                                   ; restore & return
             PLX
             RTS

* output data
*-------------------------------

OUT          PHX                                   ; save x
             PHY                                   ; save y
             PHA                                   ; save a

M_OUT1       LDX   #MSLOT+$C0                      ; ready for send?
             LDY   #MSLOT*16
             LDA   #TXREADY
             JSR   DOSTATUS
             BCC   M_OUT1                          ; nope

             PLA                                   ; get a
             LDX   #MSLOT+$C0
             LDY   #MSLOT*16
             JSR   DOWRITE                         ; send it

             PLY                                   ; get y
             PLX                                   ; get x
             RTS

* init modem for ring
*-------------------------------

RESET        JSR   HANGUP

             STZ   CARRIER                         ; clear previous stuff
             STZ   M_PROTOCOL
             STZ   COMPRESSION
             STZ   CONNECT

             LDA   #0                              ; let modem reset
             JSR   M_WAIT
             JSR   M_WAIT

             JSR   RAISEDTR                        ; raise DTR

             LDY   INITSPD                         ; set init speed
             JSR   SETSPD

             LDA   #<INITSTR                       ; point to init string
             LDX   #>INITSTR
             LDY   #$80
             JSR   XMITSTR                         ; transmit init string

             LDA   #6
             STA   COUNTLO
             STA   COUNTHI

M_RSET4      LDY   #-1
M_RSET5      DEY
             BNE   M_RSET6

             DEC   COUNTLO
             BNE   M_RSET4
             DEC   COUNTHI
             BNE   M_RSET4
             BEQ   RESET

M_RSET6      JSR   GETNUMBER
             BCC   M_RSET5
             BNE   M_RSET5

             STZ   BYTCNT                          ; reset byte counter
             STZ   BYTCNT+1
             STZ   BYTCNT+2

             JSR   CLRBUFF

M_IRQ        CLC
             RTS                                   ; return

* test for a ring and handle it
*-------------------------------
RING         JSR   GETNUMBER                       ; check for a char
             BCC   M_NODATA                        ; nope...

             CMP   #SM_OK                          ; is it a 'OK'? (numeric)
             BEQ   M_NODATA
             CMP   #SM_RING                        ; is it a 'ring'? (numeric)
             BEQ   M_NODATA
             CMP   #SM_NOCAR                       ; is it a 'no carrier'? (numeric)
             BNE   M_ISCNCT                        ; nope, check for connect messages
             BRA   M_NODATA                        ; yes, ignore it!

RING_RES     JSR   GETNUMBER
             BVS   M_ISCNCT
             BCC   RING_RES
             BCS   M_DROPIT

*-------------------------------
M_ISCNCT     JSR   RINGHUNG
             CMP   #PROT_NONE
             BCC   TST_COMP                        ; it's not 70 or greater
             STA   M_PROTOCOL                      ; save it so we can look at it in acos
             BCS   RING_RES

TST_COMP     CMP   #COMP_MNP5
             BCC   TST_CARR                        ; is not 66 or greater
             STA   COMPRESSION                     ; save it so we can look at it in ACOS
             BCS   RING_RES

TST_CARR     CMP   #SM_CAR03                       ; Carrier message?
             BCC   TST_CONN                        ; No, test for connect message
             STA   CARRIER
             BCS   RING_RES

TST_CONN     LDY   TBL_CONN
TST_CON1     DEY
             BMI   RING_RES                        ; no more to check, so go back and wait
             CMP   TBL_CONN,Y                      ; is it a valid code?
             BNE   TST_CON1                        ; nope, keep checking

             STA   CONNECT                         ; save it so we can look at it in ACOS
             DEY                                   ; reduce it one for setbaud

             JSR   SETSPD                          ; set the correct speed

             LDY   #5
RING4        LDA   #0                              ; let carrier's settle
             JSR   M_WAIT
             DEY
             BNE   RING4

             JSR   CLRBUFF
             SEC                                   ; we have a connection!
             RTS

M_DROPIT     JSR   RESET
M_NODATA     CLC
             RTS

* wait routine
*-------------------------------

M_WAIT       SEC                                   ; from apple ][+ ref man - pg 147
M_WAIT2      PHA
M_WAIT3      SBC   #1
             BNE   M_WAIT3
             PLA
             SBC   #1
             BNE   M_WAIT2
             RTS

* Check for carrier using Get_Port_Stat routine
*-------------------------------
M_CHKDCD     PHX
             PHY

             LDA   #<CARRLIST
             LDX   #>CARRLIST
             LDY   #0
             JSR   DOEXT

             CLC
             LDA   CARRBITS
             AND   CDBYTE
             BEQ   NO_CARR
             SEC
NO_CARR      PLY
             PLX
             RTS

* send ata to phone
*-------------------------------
ANSRING      JSR   ANSWER                          ; the phone rang so send answer string
             CLC
             RTS

* set the rs-232 speed [speed offset in Y]
*
* 0 =   300 baud
* 1 =  1200 baud
* 2 =  2400 baud
* 3 =  4800 baud
* 4 =  9600 baud
* 5 = 19200 baud
* 6 = 38400 baud
*-------------------------------

SETSPD       PHX
             PHY

             LDY   #0
             LDA   CARRIER
             BEQ   DO_BAUD
SETSPD1      CMP   ACOS_SPD,Y
             BEQ   SETSPD2
             INY
             INY
             BRA   SETSPD1

SETSPD2      INY
             LDX   ACOS_SPD,Y
             STX   CALLSPD

DO_BAUD      PLA                                   ; get desired speed off stack
             ASL                                   ; shift in one for index
             TAY                                   ; transfer for Y for indexing
             LDA   #PRTSPDL
             STA   SCCREG
             LDA   PRTSPD,Y
             STA   SCCREG
             INY
             LDA   #PRTSPDH
             STA   SCCREG
             LDA   PRTSPD,Y
             STA   SCCREG

             PLX
             RTS

ANSWER       LDA   #<ANSSTR                        ; point to init string
             LDX   #>ANSSTR
             LDY   #$80

* Send string to modem
*
* A&X point to string
* Y is time for wait loop
*-------------------------------
XMITSTR      STA   PTR
             STX   PTR+1

             TYA
             JSR   M_WAIT

             LDY   #-1
M_XMIT2      INY
             LDA   (PTR),Y                         ; get text
             BEQ   M_XMIT3                         ; we are done

             JSR   OUT                             ; send it
             BRA   M_XMIT2

             CLC
M_XMIT3      RTS


* Get the two digit result code in one byte (Hex Format)
*-------------------------------
GETNUMBER    LDA   #-1
             STA   DECBYTE
M_GET1ST     JSR   M_GETBYT                        ; get the first byte
             BVC   GNM_EXIT
             BCS   M_GET1ST
             STA   DECBYTE                         ; and incase the next byte is a CR

M_GET2ND     JSR   M_GETBYT                        ; get the second byte
             BVC   M_GET2ND
             BCS   GNM_EXIT

             LDY   #10
M_DEC8A      CLC
             ADC   DECBYTE                         ; add the 10's digit, 10 times
             DEY
             BNE   M_DEC8A
             STA   DECBYTE

M_GETCR      JSR   INP                             ; GetData
             BCC   M_GETCR

GNM_EXIT     LDA   DECBYTE
             PHP
             CMP   #SM_NOCAR
             BNE   GETDAOK
             STZ   M_PROTOCOL
             LDA   #SM_CAR03
             STA   CARRIER
             LDA   #SM_CON03

GETDAOK      PLP
             RTS

* Flags on Exit:
* Overflow Carry  Condidtion
* -------- -----  ----------
*  Clear   Clear  No data recieved
*   Set    Clear  Number recieved
*   Set     Set   <CR> recieved
*
M_GETBYT     JSR   INP                             ; GetData
             CLV
             BCC   DAT_DONE
             AND   #$7F
             CMP   #RETURN
             BEQ   DAT_EXIT
             CMP   #' '
             BCC   M_GETBYT
             CMP   #'0'
             BCC   M_GETBYT
             CMP   #'9'+1
             BCS   M_GETBYT
             EOR   #'0'
             CLC
DAT_EXIT     BIT   DAT_DONE
DAT_DONE     RTS

*GETDATA JSR   INP
*        BCC   GD_EXIT
*        PHP
*        BIT   GD_DEBUG
*        BPL   GD_DONE
*
*        PHA
*        PHX
*        PHY
*        CMP   #RETURN
*        BNE   GETSHOW
*        LDA   #' '
*GETSHOW JSR   VIDCOUT
*        PLY
*        PLX
*        PLA
*GD_DONE PLP
*GD_EXIT RTS

RINGHUNG     RTS

* Table of Speeds and other important stuff
*-------------------------------
DOINIT       JMP   MSLOT*256+$C000
DOREAD       JMP   MSLOT*256+$C000
DOWRITE      JMP   MSLOT*256+$C000
DOSTATUS     JMP   MSLOT*256+$C000
DOEXT        JMP   MSLOT*256+$C000
*-------------------------------
PRTSPD       DB    126,1,94,0,46,0,22,0,10,0,4,0,1,0  ; speeds 300-38400
*-------------------------------
M_MEM_ID     DS    2
M_HANDLE     DS    4
COUNTHI      DB    0
COUNTLO      DB    0
*-------------------------------
PORTINIT     DB    1
             ASC   '0D'                            ; 8 bits
             DB    1
             ASC   '2P'                            ; no parity
             DB    1
             ASC   'AD'                            ; auto-tabbing
             DB    1
             ASC   'XD'                            ; no xoff recognition
             DB    1
             ASC   'FD'                            ; no find keyboard
             DB    1
             ASC   'CD'                            ; no column overflow
             DB    1
             ASC   'ED'                            ; echo disabled
             DB    1
             ASC   'MD'                            ; no lf masking
             DB    1
             ASC   'BE'                            ; buffering enabled
             DB    1
             ASC   'Z'
             DB    0                               ; no more control characters
*-------------------------------
CARRLIST     DB    3                               ; GetPortStat
             DB    GetPortStat                     ; detecting carrier drop
             DA    0                               ; result
CARRBITS     DA    0                               ; carrier status here
*-------------------------------
DTRLIST      DB    3                               ; parameter list for
             DB    SetDTR                          ; setting DTR
             DA    0                               ; result
DTRFLAG      DA    0                               ; bit 7 affects DTR
*-------------------------------
FLUSHINQ     DB    2                               ; parameter list for flushing input queue
             DB    FlushInQueue
             DA    0                               ; result
*-------------------------------
INBUFFER     DB    4                               ; parameter count
IGETSET      DB    GetInBuffer                     ; Set/GetInBuffer
             DW    0                               ; result code
             DS    4                               ; buffer address
             DW    0                               ; buffer length
*-------------------------------
IN_BUF       DB    4                               ; count
             DB    SetInBuffer
             DA    0                               ; result
M_BUFADR     ADRL  0                               ; buffer address
M_BUFLEN     DW    $4000                           ; buffer length
*-------------------------------
INTLIST      DB    3                               ; count
INTCODE      DB    GetIntInfo                      ; Get/SetIntInfo
             DW    0                               ; result
INTFLAGS     DW    0                               ; we dont want interrupts
INTPROC      DS    4                               ; no handler
*-------------------------------
TBL_CONN     DB    9
             DB    SM_CON03
             DB    SM_CON12
             DB    SM_CON24
             DB    SM_CON48
             DB    SM_CON96
             DB    SM_CON19
             DB    SM_CON38

ACOS_SPD     DB    SM_CAR03,1
             DB    SM_CAR12,4
             DB    SM_CAR24,8
             DB    SM_CAR48,16
             DB    SM_CAR96,32
             DB    SM_CAR14,48
             DB    SM_CON38,128
DECBYTE      DB    0

             ASC   'GS/Ultra'

             DS    $3B0-*+MODEMDVR

             DS    11
CARRIER      DS    1
M_PROTOCOL   DS    1
COMPRESSION  DS    1
CONNECT      DS    1

CDBYTE       DB    DSRSTATE                        ; mask DCD only (0=connected)
*CDBYTE DB DCDSTATE ; mask DCD only (0=connected)

ANSSTR       ASC   'ATA'0D00
             DS    $8-*+ANSSTR                     ; DON'T TOUCH

QUITSTR      ASC   'ATZ'0D00
             DS    $8-*+QUITSTR                    ; DON'T TOUCH

INITSTR      ASC   'ATS0=1S2=128&C1&D2&K3&S0VEM'0D00
             DS    $30-*+INITSTR                   ; DON'T TOUCH

