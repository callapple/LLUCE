            LST     RTN
            TTL     'LLUCE - Compiler Subroutines'
            PAG
*===============================
* -- Add To Symbol Table --
*===============================

ADD_SYM     LDY     #-1
ADD_SYM2    INY                                     ; Find Last Char Of Label
            LDA     LNBUF2,Y
            JSR     CONV
            STA     LNBUF2,Y
            CPLT    #' '+1;ADD_SYM3
            CPEQ    #':';ADD_SYM3
            CPNE    #',';ADD_SYM2

ADD_SYM3    DEY
            LDA     LNBUF2,Y                        ; Set High-Bit Of Last Char
            ORA     #Hibit
            STA     LNBUF2,Y

            LDA     LNBUF2+7                        ; Mark Last Char Just In Case
            ORA     #Hibit
            STA     LNBUF2+7

            IFEQX   SYMNUM;#$FF;ADD_SYM6            ; check for overflow

            MOV     #>SYMTAB;ADD_SYM5+2             ; Set Up Table
            LDY     #-1
ADD_SYM4    INY
            LDA     LNBUF2,Y
            PHP
ADD_SYM5    STA     SYMTAB,X                        ; *** Self-Modified ***
            INC     ADD_SYM5+2
            PLP
            BPL     ADD_SYM4                        ; Loop Until Done

            MOV     TEMP;SYMTAB+L8,X                ; Save Label Location
            MOV     TEMP+1;SYMTAB+L9,X
            INC     SYMNUM                          ; Add To Table
            MOV     #>SYMTAB;ADD_SYM5+2             ; Reset Byte For CRC
            CLC
            RTS

ADD_SYM6    SEC                                     ; Symbol Table Overflow
            RTS

*===============================
* --- Add To Label Table ---
*===============================

ADD_LB13    LDA     #NoSymbol
            JMP     CHECKERR

ADD_LBL     LDY     LNCNT
            DEY
ADD_LB1     INY
            IFEQ    LNBUF2,Y;#cr;ADD_LB13           ; Eol?
            CPEQ    #'_';ADD_LB0

            JSR     TST_ALF                         ; gobble until legal char
            BCS     ADD_LB1
ADD_LB0     STY     LNCNT                           ; Save New Location
            DEY
            LDX     #8
ADD_LB2     INY                                     ; Find Last Char Of Label
            IFLT    LNBUF2,Y;#' '+1;ADD_LB4
            CPEQ    #':';ADD_LB4
            CPEQ    #',';ADD_LB4

            JSR     CONV                            ; Convert To Upper
            DBNE    X;ADD_LB3

            ORA     #Hibit                          ; Always Fix 8Th Char
ADD_LB3     STA     LNBUF2,Y
            BRA     ADD_LB2

ADD_LB4     STY     LNCNT2                          ; Save New Line Count
            DEY
            LDA     LNBUF2,Y                        ; Set High-Bit Of Last Char
            ORA     #Hibit
            STA     LNBUF2,Y

            IFEQX   LBLNUM;#$FF;ADD_LB12            ; check for overflow

            LDX     #-1                             ; Go Through And Add To Table
ADD_LB5     INX
            CPEQX   LBLNUM;ADD_LB8                  ; Add New Label

            MOV     #>LBLTAB;ADD_LB7+2              ; Set Up Table
            LDY     LNCNT
ADD_LB6     LDA     LNBUF2,Y
ADD_LB7     CMP     LBLTAB+L0,X                     ; *** Self-Modified ***
            PHP
            INC     ADD_LB7+2
            INY
            PLP
            BNE     ADD_LB5

            ASL     A                               ; Put High-Bit Into Carry
            BCC     ADD_LB6                         ; Loop Until Done
            BRA     ADD_LB11                        ; We Already Have Label In Table

ADD_LB8     LDY     LNCNT
ADD_LB9     LDA     LNBUF2,Y
            PHP
ADD_LB10    STA     LBLTAB,X
            INC     ADD_LB10+2
            INY
            PLP
            BPL     ADD_LB9

            INC     LBLNUM                          ; Increment Count
ADD_LB11    MOVY    LNCNT2;LNCNT
            MOV     #>LBLTAB;ADD_LB10+2             ; Reset Byte For CRC
            TXA                                     ; Return Label Number
            CLC
            RTS

ADD_LB12    LDA     #SymFull                        ; Symbol table overflow
            JMP     CHECKERR

*===============================
* ----- Get A Token -----
*===============================

TOKEN       LDX     LNCNT                           ; Get First Character
            LDA     LNBUF2,X

            JSR     CONV
            JSR     TST_ALF
            BCC     TOKEN1

            LDA     #'@'                            ; This Makes It Use 1st List
TOKEN1      SEC                                     ; Make Into Index For
            SBC     #'@'                            ; Table Addresses
            ASL     A
            TAX
            MOV     WHERES,X;TEMP2                  ; Get Table Location
            MOV     WHERES+1,X;TEMP2+1

            LDEQY   #0;TOKEN4                       ; Start Token Count

TOKEN2      LDA     (TEMP2),Y                       ; Try Next Token
            IBNE    Y;TOKEN3

            INC     TEMP2+1
TOKEN3      ASL     A                               ; Put Into Carry
            BCC     TOKEN2                          ; Was High Bit Set?

            IBNE    Y;TOKEN4                        ; skip token number
            INC     TEMP2+1

TOKEN4      LDX     LNCNT                           ; Get Line Offset
TOKEN5      LDEQ    (TEMP2),Y;TOKEN7                ; were done, no match

            STA     PRN
            LDA     LNBUF2,X                        ; Check It
            JSR     CONV
            EOR     PRN                             ; Match Bits
            ASL     A                               ; Move Bit 7
            BNE     TOKEN2                          ; No Match

            INX                                     ; Increment Pointers
            IBNE    Y;TOKEN6
            INC     TEMP2+1

TOKEN6      BCC     TOKEN5                          ; Keep Checking

            LDA     (TEMP2),Y
            STX     LNCNT                           ; Save New Text Pointer
            CLC
            RTS

TOKEN7      LDA     LNBUF2,X                        ; Get Char
            JSR     CONV                            ; Make Uppercase
            INC     LNCNT
            ORA     #Hibit
            SEC
            RTS

*===============================
* Read in a line and show it if needed
*===============================

COMPSHOW    STZ     LNCNT2
CSHOW1      JSR     PD_RDLN                         ; Read A Line From Disk
            BCC     CSHOW1A                         ; Skip Print If Bad Read
            STZ     LNCNT
            RTS

CSHOW1A     INCD    LINENUM
            TSTMI   BLOCKFLG;CSHOW2                 ; doing a text or comment block?

            LDA     LNBUF
            AND     #Clrhi

            CPEQ    #';';CSHOW1                     ; is it a comment line?
            CPEQ    #cr;CSHOW1                      ; blank line?

CSHOW2      JSR     STRIPHI
            STZ     LNCNT                           ; start at beginning
CSHOW3      LDX     LNCNT
            LDA     LNBUF,X
            TSTMI   BLOCKFLG;CSHOW4                 ; text?, no comment test
            CPNE    #'/';CSHOW4                     ; start of comment?
            LDA     LNBUF+1,X
            CPEQ    #'*';HNDLCOMM
            LDA     LNBUF,X

CSHOW4      LDX     LNCNT2                          ; save the char
            STA     LNBUF2,X
            INC     LNCNT2                          ; bump pointer
            CPEQ    #cr;CSHOW7                      ; end of line?
            IBNE    LNCNT;CSHOW3                    ; do next

CSHOW7      DEX                                     ; trim white spaces
            IFEQ    LNBUF2,X;#' ';CSHOW8
            CPNE    #tab;CSHOW9
CSHOW8      MOV     #cr;LNBUF2,X
            BRA     CSHOW7

CSHOW9      TSTPL   SHWTXT;CSHOW13

            LDX     #0
CSHOW10     LDA     LNBUF,X
            ORA     #Hibit
            PHA
            CPGE    #' '+Hibit;CSHOW11              ; Control Character?
            LDA     #'^'+Hibit
            JSR     VIDBAN                          ; Print The '^' For The Control Char
            PLA
            PHA
CSHOW11     JSR     VIDBAN                          ; Print The Character
            LDA     KYBD                            ; Check Local Keyboard
            ORA     #Hibit
            CPNE    #'Z'-Ctrl+Hibit;CSHOW12

            STA     KBDSTRB
            JSR     RDKEY                           ; Wait For A Keypress
CSHOW12     INX
            PLA
            CPNE    #cr+Hibit;CSHOW10               ; End Of Line?

CSHOW13     CLC
CSHOW14     STZ     LNCNT
            RTS

HNDLCOMM    PHX
STR_LUP     LDX     LNCNT2                          ; strip any white space
            IFEQ    LNBUF2-1,X;#' ';STRIPW
            CPNE    #tab;STRW_DN
STRIPW      DEC     LNCNT2
            IFNE    LNCNT2;#-1;STR_LUP

STRW_DN     PLX
            INX                                     ; skip /*
HCOMM_1     IBEQ    X;DO_CCR
HCOMM_2     LDA     LNBUF,X                         ; check for */
            CPNE    #'*';COMM_CR
            LDA     LNBUF+1,X
            CPEQ    #'/';COMM_DN

COMM_CR     CPNE    #cr;HCOMM_1                     ; end of line?, no, keep going
DO_CCR      JSR     PD_RDLN                         ; Read A Line From Disk
            BCS     CSHOW14                         ; Skip Print If Bad Read
            INCD    LINENUM
            JSR     STRIPHI
            LDRAX   #0;HCOMM_2

COMM_DN     INX
STRIPW2     INX                                     ; strip any white spaces
            IFEQ    LNBUF,X;#' ';STRIPW2
            CPEQ    #tab;STRIPW2
            STX     LNCNT
            JMP     CSHOW3                          ; point to past */

STRIPHI     LDX     #0
STRIP_0     LDA     LNBUF,X
            AND     #Clrhi
            STA     LNBUF,X
            IBNE    X;STRIP_0
            RTS

*===============================
* Convert Lower To Upper And Clear High Bit
*===============================

CONV        CPLT    #'a';CONV2
            CPGE    #'z'+1;CONV2
            SBC     #$1F                            ; Since Carry Is Clear, -$20
CONV2       RTS

*===============================
* Is Byte A Letter? Clc=Yep, Sec=Nope
*===============================

TST_ALF     PHA
            AND     #Clrhi
            JSR     CONV                            ; Change To Uppercase
            CPLT    #'A';TST_AL2
            CPLT    #'Z'+1;TST_AL3
TST_AL2     SEC
TST_AL3     PLA
            RTS

*===============================
* Is Byte A Number? Clc=Yep, Sec=Nope
*===============================

TST_NUM     PHA
            AND     #Clrhi                          ; Strip High Bit
            CPLT    #'0';TST_NM2
            CPLT    #'9'+1;TST_NM3
TST_NM2     SEC
TST_NM3     PLA
            RTS

*===============================
* Jsr Pr ;  Data ;  0 -- Quick Print Routine
*===============================

PR          PULL    PRN                             ; Save Calling Address
            PULL    PRN+1
            PHY                                     ; Save Y

PR1         INCD    PRN

            LDEQ    (PRN);PR4                       ; Get Byte

            JSR     VIDCOUT                         ; Otherwise Use Normal
            LDA     KYBD                            ; Check Local Keyboard
            ORA     #Hibit
            CPNE    #'Z'-Ctrl+Hibit;PR1
            STA     KBDSTRB
PR3         JSR     GETCHR                          ; Wait For A Keypress
            BEQ     PR3
            BRA     PR1

PR4         PLY                                     ; Restore Y
            PUSHA   PRN+1
            PUSHA   PRN
            RTS

*===============================
* check if number.  If so, convert it
*===============================

NUMBER      JSR     INPNUMB
            STY     LNCNT
            LDX     #ThreeByte                      ; default to 3 numbers
            LDNE    NUM+2;NUMBER4
            DEX                                     ; unless there's 2
            LDNE    NUM+1;NUMBER4
            DEX                                     ; or one
NUMBER4     TXA
            STA     (TEMP)                          ; save type
            INCD    TEMP                            ; Increment Temp By 1
            MOV     NUM;(TEMP)                      ; save first byte
            INCD    TEMP                            ; Increment Temp By 1
            DEX                                     ; count down
            DEX
            DBEQ    X;NUMBER5
            MOV     NUM+1;(TEMP)                    ; save next byte
            INCD    TEMP                            ; Increment Temp By 1
            DBEQ    X;NUMBER5
            MOV     NUM+2;(TEMP)                    ; save high byte
            INCD    TEMP                            ; Increment Temp By 1
            CLC                                     ; it was a number!
NUMBER5     RTS

HEX_NUM     INY
            LDA     LNBUF2,Y
            JSR     TST_NUM
            BCC     IS_HEX
            JSR     TST_ALF
            BCS     NUMBER5
            JSR     CONV
            CPLT    #'A';NUMBER5                    ; is it hex?
            CPGE    #'F'+1;NUMBER5
            SBC     #6                              ; make it binary
IS_HEX      AND     #LoNibble                       ; Clear Extra Bits Off
            LDX     #3                              ; shift over 4 bits
SHIFTIN     ASL     NUM
            ROL     NUM+1
            ROL     NUM+2
            DBPL    X;SHIFTIN
            ORA     NUM                             ; add in the new value
            STA     NUM
            BRA     HEX_NUM

INPNUMB     ZERO24  NUM                             ; Zero Info

            CPEQ    #'$';HEX_NUM                    ; is it hex ($)?
            CPNE    #'0';NUMBER2                    ; is it hex (0x)?
            IFNE    LNBUF2+1,Y;#'x';NUMBER2         ; x not here, do decimal
            IBRA    Y;HEX_NUM

NUMBER2     IFLT    LNBUF2,Y;#'0';NUMBER5           ; is it a number?
            CPGE    #'9'+1;NUMBER5
            INY
            JSR     XNUMIN                          ; Process Digit
            BRA     NUMBER2                         ; Loop

*===============================
*   Name: XNUMIN - Decimal To Binary
*
*  Input: A - Digit To Add In
*
* Output: None
*===============================

XNUMIN      AND     #LoNibble                       ; Clear Extra Bits Off
            STA     NUM+3                           ; Save It
            STZ     NUM+4                           ; Zero Rest Of Number
            STZ     NUM+5
            LDX     #10                             ; Multiply By 10 With New
XNUMIN2     ADD     NUM;NUM+3;NUM+3                 ; Number
            AD      NUM+2;NUM+5;NUM+5
            DBNE    X;XNUMIN2

            MOV24   NUM+3;NUM                       ; Save The New Number
            RTS

*===============================
* TEXTESC - Handle text escape sequence
*===============================

TEXTESC     INC     LNCNT
            LDY     LNCNT                           ; get next char (skip \)
            IFEQ    LNBUF2,Y;#'x';TEXT_HEX          ; hex escape?
            CPEQ    #'$';TEXT_HEX                   ; hex escape?
            CPGE    #'8';ESC_SRCH                   ; in octal range?
            CPEQ    #'0';DO_ZERO                    ; null?
            BGE     TEXT_OCT                        ; is octal!

ESC_SRCH    LDX     #ESCCONV-ESCCHARS
ESC_LUP     CPEQ    ESCCHARS,X;ESC_CNV
            DBPL    X;ESC_LUP
            BRA     SV_ESC

ESC_CNV     LDA     ESCCONV,X
            SKIP2
DO_ZERO     LDA     #0
SV_ESC      STA     (TEMP)
            INCD    TEMP                            ; Increment Temp By 1
            INC     LNCNT
            CPGEX   #2;ESC_EXIT
            JMP     ESC_ARGS

ESC_EXIT    RTS

TEXT_HEX    STZ     PRN
            LDX     #0

HEX_LUP     INC     LNCNT
            LDY     LNCNT                           ; get next char
            LDA     LNBUF2,Y
            JSR     TST_NUM
            BCC     T_IS_HEX
            JSR     TST_ALF
            BCS     THEXDONE
            JSR     CONV
            CPLT    #'A';THEXDONE                   ; is it hex?
            CPGE    #'F'+1;THEXDONE
            SBC     #6                              ; make it binary
T_IS_HEX    AND     #LoNibble                       ; Clear Extra Bits Off
            CPPLX   #0;ST_HBYTE                     ; first half of byte?
            ASL     PRN                             ; move bits over
            ASL     PRN
            ASL     PRN
            ASL     PRN
            ORA     PRN                             ; add in new nibble
            INX                                     ; flag as first
            STA     (TEMP)                          ; save byte
            INCD    TEMP                            ; Increment temp by 1
            BRA     HEX_LUP                         ; go back for another

ST_HBYTE    STA     PRN                             ; save for now
            DBRA    X;HEX_LUP                       ; flag first nibble done

THEXDONE    CPEQX   #0;HEX_EXIT
            MOV     PRN;(TEMP)
            INCD    TEMP                            ; Increment temp by 1
HEX_EXIT    RTS

TEXT_OCT    AND     #7                              ; clear high bits
            STA     PRN                             ; save it for later
            INY                                     ; get next char
            IFLT    LNBUF2,Y;#'0';OCT_DN            ; octal digit?
            CPGE    #'7'+1;OCT_DN
            AND     #7                              ; clear high bits
            ASL     PRN                             ; shift over
            ASL     PRN
            ASL     PRN
            ORA     PRN                             ; add in
            STA     PRN                             ; save
            INY                                     ; get next char
            IFLT    LNBUF2,Y;#'0';OCT_DN            ; octal digit?
            CPGE    #'7'+1;OCT_DN
            AND     #7                              ; clear high bits
            ASL     PRN                             ; shift over
            ASL     PRN
            ASL     PRN
            ORA     PRN                             ; add in
            STA     PRN                             ; save
            INY
OCT_DN      STY     LNCNT                           ; save line pointer
            MOV     PRN;(TEMP)                      ; get byte
            INCD    TEMP                            ; Increment temp by 1
            RTS

ESC_ARGS    LDY     LNCNT                           ; get char
            LDA     LNBUF2,Y
            CPNEX   #0;ARGS_2
            JSR     INPNUMB                         ; make it a number
            LDNE    NUM+1;ARGS_3                    ; too big?
            LDNE    NUM+2;ARGS_3
            LDA     NUM                             ; get value
            CLC                                     ; add in the offset
            ADC     #$20
            STA     (TEMP)                          ; save value
            INCD    TEMP                            ; point to next
            IFEQ    LNBUF2,Y;#',';ARGS_1            ; any more?
            STY     LNCNT                           ; fix line count
            LDA     #BadXYPrm
            JMP     CHECKERR

ARGS_1      INY
            LDA     LNBUF2,Y
            JSR     INPNUMB                         ; make it a number
            LDNE    NUM+1;ARGS_3                    ; too big?
            LDNE    NUM+2;ARGS_3
            LDA     NUM                             ; get value
            CLC                                     ; add in the offset
            ADC     #$20
            STA     (TEMP)                          ; save value
            INCD    TEMP                            ; point to next
            STY     LNCNT                           ; fix line count
            RTS

ARGS_2      JSR     INPNUMB                         ; make it a number
            LDA     NUM+1
ARGS_3      BNE     ARGS_6                          ; too big?
            LDNE    NUM+2;ARGS_6
            LDA     NUM                             ; get value
            STA     (TEMP)                          ; save value
            INCD    TEMP                            ; point to next
            IFEQ    LNBUF2,Y;#',';ARGS_4            ; any more?
            STY     LNCNT                           ; fix line count
            LDA     #BadTone
            JMP     CHECKERR

ARGS_4      INY
            LDA     LNBUF2,Y
            JSR     INPNUMB                         ; make it a number
            LDNE    NUM+1;ARGS_6                    ; too big?
            LDNE    NUM+2;ARGS_6
            LDA     NUM                             ; get value
            STA     (TEMP)                          ; save value
            INCD    TEMP                            ; point to next
            IFNE    LNBUF2,Y;#',';ARGS_5            ; any more?
            INY
            LDA     LNBUF2,Y
            JSR     INPNUMB                         ; make it a number
            LDNE    NUM+1;ARGS_6                    ; too big?
            LDNE    NUM+2;ARGS_6
            LDA     NUM                             ; get value
            STA     (TEMP)                          ; save value
            INCD    TEMP                            ; point to next
ARGS_5      STY     LNCNT                           ; fix line count
            RTS

ARGS_6      STY     LNCNT
            LDA     #NumOvfl
CHECKERR    PHA
            LDNE    ERRFLG;STDERR                   ; has an error happened before?

            JSR     CROUT

STDERR      MOV     #1;ERRFLG                       ; makes sure it doesn't pass 0
            BREQW   LINENUM;ERR_ONLY                ; any line?
            JSR     SHOWSTR
            DCI     'Error in line #'
            LD16    LINENUM                         ; show the number
            LDY     #0
            JSR     DECOUT0
            JSR     CROUT                           ; next line
            LDX     #0                              ; display the line
LINEOUT     IFEQ    LNBUF2,X;#cr;OUT_CHR
            CPGE    #' ';OUT_CHR
            CLC                                     ; make it inverse
            ADC     #'@'
            PHA
            LDA     #inv
            JSR     VIDCOUT
            PLA
            JSR     VIDCOUT
            LDA     #norm
OUT_CHR     JSR     VIDCOUT
            INX
            BEQ     LINE_X
            CMP     #cr                             ; including the cr
            BNE     LINEOUT

LINE_X      LDX     LNCNT                           ; space over to the error
            BEQ     NO_SPC
            LDA     #' '
SPACEOUT    JSR     VIDCOUT
            DEX
            BNE     SPACEOUT
NO_SPC      LDA     #'^'                            ; point to it
            JSR     VIDCOUT
            LDA     #' '
            JSR     VIDCOUT
ERR_ONLY    PLA
            JSR     PRINTMSG
            TSTMI   REMOTE;NO_PAUSE
            STA     KBDSTRB
            JSR     RDKEY                           ; Wait For A Keypress
NO_PAUSE    SEC
            RTS

PRINTMSG    ASL     A
            TAX
            MOV     MSGPTRS,X;PRN
            MOV     MSGPTRS+1,X;PRN+1
            LDA     #inv
            JSR     COUT
PRLOOP      LDEQ    (PRN);PRDONE
            JSR     COUT
            INCD    PRN
            BRA     PRLOOP

PRDONE      LDA     #norm
            JSR     COUT
CROUT       LDA     #cr
            JMP     COUT

MSGPTRS     DW      0
SymFull     =       *-MSGPTRS/2
            DA      SYMFULL
InvalChr    =       *-MSGPTRS/2
            DA      BADCHAR
PubFull     =       *-MSGPTRS/2
            DA      PUBFULL
NoQuote     =       *-MSGPTRS/2
            DA      NOQUOTE
WriteErr    =       *-MSGPTRS/2
            DA      WRITEERR
NoSymbol    =       *-MSGPTRS/2
            DA      NOSYMBOL
BadXYPrm    =       *-MSGPTRS/2
            DA      BADXYPRM
BadTone     =       *-MSGPTRS/2
            DA      BADTONE
NumOvfl     =       *-MSGPTRS/2
            DA      NUMOVFL

SYMFULL     ASC     'The Symbol Table Is Full'00    ; 1
BADCHAR     ASC     'Invalid character in line'00   ; 2
PUBFULL     ASC     'Too many public labels'00      ;3
NOQUOTE     ASC     'There Is A Quote Still Open At EOF'00  ;4
WRITEERR    ASC     'Write error, segment not saved'00  ; 5
NOSYMBOL    ASC     'A Symbol Is Missing'00         ; 6
BADXYPRM    ASC     'Missing gotoxy parameter'00    ; 7
BADTONE     ASC     'Missing tone parameter'00      ; 8
NUMOVFL     ASC     'Numeric overflow in text parameter'00  ; 9

ESCCHARS    ASC     'G'                             ; goto X,Y
            ASC     'T'                             ; tone
            ASC     'R'                             ; repeat
            ASC     'a'                             ; alert
            ASC     'b'                             ; backspace
            ASC     'f'                             ; formfeed
            ASC     'n'                             ; newline
            ASC     'r'                             ; return
            ASC     't'                             ; tab
            ASC     'v'                             ; vertical tab
            ASC     '\'                             ; \
            ASC     '"'                             ; "
            ASC     '?'                             ; ?
            HEX     27                              ; '
            ASC     'A'                             ; up
            ASC     'B'                             ; down
            ASC     'C'                             ; forward
            ASC     'D'                             ; back
            ASC     'E'                             ; escape
            ASC     'F'                             ; clear screen
            ASC     'H'                             ; home
            ASC     'I'                             ; inverse
            ASC     'M'                             ; mousetext
            ASC     'N'                             ; normal
            ASC     'O'                             ; insert char
            ASC     'P'                             ; delete char
            ASC     'V'                             ; insert line
            ASC     'W'                             ; delete line
            ASC     'Y'                             ; clear to eol
            ASC     'Z'                             ; clear to eos
ESCCONV     DB      goxy                            ; goto X,Y
            DB      Tonecmd                         ; tone
            DB      ptRepeat                        ; repeat
            DB      bel                             ; alert
            DB      bs                              ; backspace
            DB      ff                              ; formfeed
            DB      cr                              ; newline
            DB      cr                              ; return
            DB      tab                             ; tab
            DB      vt                              ; vertical tab
            ASC     '\'
            ASC     '"'
            ASC     '?'
            HEX     27                              ; '
            DB      csrup                           ; up
            DB      csrdwn                          ; down
            DB      csrfwd                          ; forward
            DB      csrback                         ; back
            DB      esc                             ; escape
            DB      clrscn                          ; clear screen
            DB      homeChar                        ; home
            DB      inv                             ; inverse
            DB      realmous                        ; mousetext
            DB      norm                            ; normal
            DB      inschar                         ; insert char
            DB      delchar                         ; delete char
            DB      insline                         ; insert line
            DB      delline                         ; delete line
            DB      clreol                          ; clear to eol
            DB      clreos                          ; clear to eos
            LST     OFF

