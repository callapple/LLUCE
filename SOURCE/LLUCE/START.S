            LST    RTN
            TTL    'LLUCE - Start'
            PAG
*-------------------------------
* Start LLUCE From Scratch
*-------------------------------

LLUCE       JSR    SWITCH2                   ; Select Ram Card
            STZ    SETALTZP
            PHP                              ; Save Current Status
            PULL   SYSSTAT

            JSR    DO_CL3                    ; Close All Open Files
            JSR    LOGSYS                    ; Log To System Prefix

*-------------------------------
* Move In Starting File Name
*-------------------------------

            JSR    PD_GPFX                   ; Get Current Prefix
            LD16   #SEGSAVE                  ; Save segment prefix
            JSR    FRMFLN                    ; for later reload

            LD16   #SEG_NAME                 ; Coyp default filename
            JSR    TOFLN
            BEQ    LL_NOMOD

            JSR    SAVESEG

*-------------------------------
* Load In Starting Module
*-------------------------------

            JSR    LD_MOD                    ; Load Module
            BCC    LL_CLR

*-------------------------------
* Error Occurred, Module Not Found
*-------------------------------

LL_NOMOD    LDA    #SMnotFnd
            JSR    PRTEXT
            JMP    RESTART1

*-------------------------------
* Clear Everything
*-------------------------------

LL_CLR      JSR    CLRSMT                    ; Clear Everything
            MOV    #1;FILTFLAG               ; Make Sure Filter Is On

*-------------------------------
* Start At Beginning Of Segment
*-------------------------------

RUNMOD1     MOVD   MODULE;PRGPTR             ; Point At Program
            LDA    RESETVEC+1                ; Set Power-Up Byte
            EOR    #%10100101
            STA    SOFTEV

*-------------------------------
* Showing Input Or Tracing?
*-------------------------------

            TSTMI  SHWTXT;LL_BTM             ; Showing User Input?
            TSTPL  SHWTRC;ERRENT             ; Tracing The Program?

LL_BTM      IFNE   WNDBTM;#vidHeight;ERRENT  ; bottom line protected?

            DEC    WNDBTM                    ; Shorten Screen
            DEC    WNDBTM

ERRENT      JSR    SWITCH2                   ; Select Ram Card
            STZ    SETALTZP

            LDX    #-1
            TXS

            JSR    RUNMAIN

*-------------------------------
* Enter Error Dispatch Routines
*-------------------------------

DO_END      LDA    #Prgend                   ; End Of Program
            SKIP2
NOLABEL     LDA    #Undeflbl                 ; Undefined Label
BADERR2     STZ    ONERRFLG                  ; Force A Program Halt
            SKIP2                            ; Skip Next Two Bytes
MISSMTCH    LDA    #Typemiss                 ; Type Mismatch Error
            SKIP2
BADDEV      LDA    #Baddev                   ; Bad Device Number
            SKIP2
BADNAME     LDA    #Badfn                    ; Bad Filename
            SKIP2
BADWRITE    LDA    #Badwrite                 ; Bad Disk Write
            SKIP2
BADEXT      LDA    #Badxtrn                  ; Bad External

*-------------------------------
* All Critical Errors Enter Here
*-------------------------------

BADERR      JSR    SWITCH2                   ; Select Ram Card
            STZ    SETALTZP
            MOVY   PRGPTR;FROMERR            ; Save Where Error Occurred
            MOVY   PRGPTR+1;FROMERR+1
            STA    ERRNO

            TSTPL  ONERRFLG;PUT_ERR          ; Is There A Error Vector?

            MOVD   ONERRVEC;PRGPTR
            STZ    ONERRFLG                  ; reset the onerr flag
            BRA    ERRENT

PUT_ERR     LDX    #-1
            TXS

            PHA                              ; Save error code
            LDY    #0                        ; Set output to screen
            JSR    SETOVEC
            PLA                              ; Restore code
            JSR    SHOW_ERR                  ; Show Error
            BRA    RESTART1

*-------------------------------
* Enter Here If Reset Pressed
*-------------------------------

RESET       PUSHA  SYSSTAT                   ; restore status for AT
            PLP                              ; Operational
            JSR    SWITCH2                   ; Select Ram Card
            STZ    SETALTZP
            INC    SOFTEV                    ; Next Reset Must Do Reboot
            STZ    SHWTRC                    ; Reset Trace Mode
            STZ    AUTORST                   ; Disable Auto-Reset
            STZ    ONERRFLG                  ; Clear Onerr

*-------------------------------
* Do Program Restart
*-------------------------------

RESTART1    JSR    PRGINIT
            JSR    MDM1_2                    ; Hang Up Modem
            JSR    PR
            ASC    "*** RESTART: S,M,Q ?"00
            STZ    TEMP                      ; Start Restart Timeout
            STZ    TEMP+1
            MOV    #-10;TEMP2

*-------------------------------
* Wait For Restart Command
*-------------------------------

REST2       LDEQ   AUTORST;REST2A            ; Auto-Restart?

            IBNE   TEMP;REST2A               ; do low counter
            IBNE   TEMP+1;REST2A
            IBNE   TEMP2;REST2A              ; Not Done Yet
            DEC    AUTORST
            BRA    REST3A                    ; count down start

REST2A      JSR    CHKKEY                    ; Get Input
            JSR    CONV                      ; Convert
            CPEQ   #'S';REST3                ; Restart System?
            CPEQ   #'M';REST4                ; Restart Module?
            CPEQ   #'*';GOMONITR             ; Goto Monitor?
            CPNE   #'Q';REST2                ; Quit?

            MOV    #-1;INVFLG                ; Reset Inverse Flag
            DO     DEMOPGM
            ELSE
            JSR    MDMQUIT
            FIN
            JMP    PD_QUIT

REST3       MOV    #3;AUTORST                ; Reset Auto-Restart Byte
REST3A      JMP    LLUCE                     ; Cold Start

REST4       MOV    #3;AUTORST                ; Reset Autostart Count
            JMP    RUNMOD1                   ; Warm Start

*-------------------------------
* Drop Into The Monitor
*-------------------------------

GOMONITR    MOV    #-1;INVFLG
            MOV    SETROM;SETSTDZP           ; Enable Rom
            JMP    ENTRMON                   ; Monitor

*-------------------------------
* Initialize Program Variables
*-------------------------------

PRGINIT     STZ    REMOTE                    ; Turn Off Chat
            STZ    MSGREF
            STZ    BLINK                     ; No Last Character
            STZ    V_MODE                    ; Nothing Special Happens
            STZ    AUTOLOG                   ; Clear auto logon flag
            STZ    CO_XY                     ; Clear COUT X,Y counter
            STZ    CO_RPT                    ; Clear COUT repeat counter
            MOV    #vidWidth;V_OLDCV         ; 80 Columns Wide
            STA    VIDLEN
            STA    WNDWDTH
            MOV    #vidHeight;WNDBTM         ; 24 Lines
            MOV    #$60;USERVEC              ; Put RTS For User-Routine
            LDA    LORES                     ; ** It Makes Things Work !!
            LDA    ANU_ON                    ; Annunc_On
            MOV    KBDSTRB;DISP80            ; Switch To 80 Column Mode
            STA    STORE80                   ; Enable Page Select
            STA    ALTCHRS                   ; Mousetext Available
            STZ    LEVEL                     ; Close All Open Files
            STZ    REFNUM
            JSR    PD_CLOSE
            LDX    #10
ZDEVUSE     MOV    DEVTBL,X;DEVUSE,X         ; Reset Device Table
            DBPL   X;ZDEVUSE

            STX    VIDECHO                   ; Make Sure Characters
            RTS                              ; Get Seen

*-------------------------------
* Handle An Incoming IRQ (And Fix It)
*-------------------------------

            DO     DEMOPGM
IRQ_FIX     CLC
            ELSE
IRQ_FIX     JSR    MDMINT
            FIN
            RTI
            LST    OFF

