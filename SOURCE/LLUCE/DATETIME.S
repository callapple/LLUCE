            LST    RTN
            TTL    'LLUCE - Time/Date Commands'
            PAG
*===============================
* Contents:
*
* CLOCK    - Do Time Computations
* CONVSEC  - Convert Time To Seconds
* DATESTR  - Get Date
* FMTDATE  - Get Date In Formated Form
* FMTWHEN  - Get formatted date from 2 byte binary
* TIME2STR - Get Time (12 hour format)
* TIMESTR  - Get Time (24 hour format)
* SECON    - Find Time On In Seconds
* WHENSTR  - Get Date From 2 Byte Binary
*===============================

*===============================
* Name: WHENSTR - Get Date From 2 Byte Binary
*===============================

WHENSTR     BCC    DO_WH2                        ; Get Data

            JSR    GOBEQU                        ; Gobble Equals
            JSR    ARGTYP                        ; Find Out Data Type
            BCS    DO_WH1

            JSR    INPNUM16                      ; Get Location
            ST16   WHNPTR                        ; And Save
            RTS

DO_WH1      JSR    INPSTR                        ; Gobble
            IFNE   STRLEN;#8;DO_WH1A             ; date supplied?

            MOVD   STRLOC;TEMP3                  ; Set Pointer To String
            JSR    ZNUMIN                        ; Get Month
            PHX
            JSR    INCTEMP3
            JSR    ZNUMIN                        ; Get Date
            PHX
            JSR    INCTEMP3
            JSR    ZNUMIN                        ; Get Year
            STX    TEMP                          ; Save Year
            PULL   TEMP+1                        ; save date
            PLA                                  ; Move Month Over
            ASL    A
            ASL    A
            ASL    A
            ASL    A
            ASL    A
            ROL    TEMP                          ; High Bit Of Month W/Year
            ORA    TEMP+1                        ; Add In Date
            TAX                                  ; Get Values
            LDRA   TEMP;DO_WH1B                  ; Save Date

DO_WH1A     JSR    GETDATE                       ; Get Date From Clock
DO_WH1B     LDY    #1
            STA    (WHNPTR),Y                    ; Save Compacted Date
            TXA
            STA    (WHNPTR)
            RTS

DO_WH2      LDA    (WHNPTR)                      ; Get Compressed Date
            TAX
            LDY    #1
            LDRA   (WHNPTR),Y;DO_DT2             ; Translate

*===============================
* Name: DATESTR - Get Date
*===============================

DATESTR     BCC    DO_DT1                        ; Get The Date

            JSR    GOBEQU                        ; Gobble Equ
            JSR    INSTR2                        ; Get String
            LD16   STRLOC
            LDY    STRLEN
            JMP    SETDATE                       ; Set The Date

DO_DT1      JSR    GETDATE
DO_DT2      STA    TEMP                          ; Save Date Data
            STX    TEMP+1
            LDA    TEMP+1
            AND    #%00011111
            JSR    BINDEC8                       ; Save Day
            STA    DATETXT+3
            STX    DATETXT+4
            LDA    TEMP+1                        ; Get Most Of Month
            LSR    TEMP                          ; Shift Last Bit Into Carry
            ROR    A                             ; Move Bit In
            LSR    A
            LSR    A
            LSR    A
            LSR    A
            JSR    BINDEC8
            STA    DATETXT                       ; Save Month
            STX    DATETXT+1
            LDA    TEMP                          ; Get Year
            JSR    BINDEC8                       ; Make ASCII
            STA    DATETXT+6
            STX    DATETXT+7
            LDX    #<DATETXT
            LDA    #>DATETXT                     ; Point To String
            LDY    #8                            ; Always 8 Bytes
COPYDATE    STY    STRLEN                        ; Save Length
            ST16   STRLOC                        ; Save String Location
            PUSHW  VARSTR                        ; Save Current String pointer
            JSR    STRCOPY                       ; Copy String To Main
            LDY    STRLEN                        ; Get Back Length
            PLAX                                 ; And Pointer
            JMP    SVSTR

*===============================
* Name: TIMESTR - Get Time
*===============================

TIMESTR     CLC                                  ; Hi Bit Clear Is 24 Hours
            SKIPCS
TIME2STR    SEC                                  ; Hi Bit Set Is 12 Hours
            ROR    CLKMODE
            JSR    GETTIME                       ; Read Clock
            JMP    COPYDATE                      ; Save The String
; Address In A,X Length In Y
; See Clock Driver

*===============================
* Name: FMTDATE - Get Date In Formated Form
*===============================

FMTDATE     JSR    GETDATE                       ; Get The ProDOS Date
            BRA    DO_FDT2

FMTWHEN     LDA    (WHNPTR)                      ; Get Compressed Date
            TAX
            LDY    #1
            LDA    (WHNPTR),Y
DO_FDT2     STZ    SETRAM1
            JSR    DO_FDT0
            STZ    SETRAM2
            RTS

*===============================
* Name: CLOCK - Do Time Computations
*===============================

CLOCK       IFEQ   (PRGPTR);#OnlineTkn;CLKONLN
            CPEQ   #Clear;CLK_CLR
            BRA    CLKLIMIT

*===============================
* Name: CLK_CLR - Reset Timer
*===============================

CLK_CLR     JSR    GETBYT
            JSR    CONVSEC                       ; Get Base In Seconds
            ST16   CLKBASE
            RTS

*===============================
* Name: CLKONLN - Get Connect Time In Seconds
*===============================

CLKONLN     JSR    GETBYT
            JSR    SECON                         ; Connect Time In Seconds
CLK_OUT     JMP    MATH_16                       ; Save Time

*===============================
* Name: CLKLIMIT - Get Time Limit
*===============================

CLKLIMIT    TSTMI  IMMDEF;SETLIMIT               ; Check Exec Status

            LD16   TIMEON                        ; Get Time Limit
            BRA    CLK_OUT                       ; Return It

SETLIMIT    JSR    EQUNUM16                      ; Get Time Limit
            ST16   TIMEON
            RTS

*===============================
* Name: SECON - Find Time On In Seconds
*===============================

SECON       JSR    CONVSEC                       ; Get Time In Seconds
            SEC
            PHA
            TXA
            SBC    CLKBASE                       ; Time On = Current - Base
            TAX
            PLA
            SBC    CLKBASE+1
            BCS    SECON1

            PHA
            TXA
            ADC    #<ROLTIME                     ; Time Past Midnight
            TAX                                  ; Add In Rolover
            PLA
            ADC    #>ROLTIME
SECON1      RTS

ROLTIME     =      43200                         ; # Seconds In 12 Hours

*-------------------------------
* Convert Time To Seconds
*-------------------------------

CONVSEC     STZ    CLKMODE
            JSR    GETTIME
            ST16   TEMP3                         ; Point To Time String
            MOV    #60;DATA+1                    ; Set Up Multiplier
            STZ    DATA+2
            STZ    DATA+3
            JSR    ZNUMIN                        ; Get Hour
            STA    NUMB+1                        ; Zero High
            TXA
            BNE    CONVSC2                       ; Not 00 Hours

            LDA    #24                           ; Make 0 Hour Into 24 Hour
CONVSC2     CPLT   #13;CONVSC3                   ; Is It Out Of Range?

            SBC    #12                           ; Make Into 1-12 Range
CONVSC3     STA    NUMB                          ; Save Result
            JSR    DO_MUL0                       ; Multiply Into Minutes
            INC    TEMP3
            JSR    ZNUMIN                        ; Get Minute
            CLC
            TXA
            ADA    RESULT;NUMB                   ; Add In Minutes
            AD     #0;RESULT+1;NUMB+1
            MOV    #60;DATA+1                    ; Multiply By 60
            JSR    DO_MUL0
            INC    TEMP3                         ; Position To Seconds
            JSR    ZNUMIN
            CLC
            TXA
            ADC    RESULT                        ; Add In Seconds
            TAX
            LDA    #0
            ADC    RESULT+1
            RTS
            LST    OFF

