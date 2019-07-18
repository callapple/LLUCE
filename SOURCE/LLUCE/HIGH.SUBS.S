            LST     RTN
            TTL     'High End Stuff'
            PAG
*===============================
* ADDCRC2  - Add Byte To CRC
* ANSILST  - ANSI screen control list
* ARGTYP   - Get Argument Type
* BINDEC82 - Binary To Decimal
* CLRSMT2  - Clear Variables, GOSUBs And FORs
* COMPRES2 - Compress Variables
* DO_DIV1A - Actual Divide routine
* DO_FDT0  - Part of FMTDATE
* DO_FRE2  - Compress String Space
* DO_MUL0  - Actual Multiply Routine
* DO_NSR00 - Part of the INSTR function
* DO_RNDS2 - Generate Random Character
* GETCHR2  - Get Character From Buffer
* IFGOB1   - Ignore To Line End Or Else Cmd
* INPTYP2  - Get Next Token/Character Type
* LFTTRIM0 - Part of LEFTTRIM
* PUTCHR2  - Save Character In Buffer
* RAMIN2   - Get Byte From RAM Drive
* RAMOUT2  - Write Byte To RAM Drive
* RESTSCRN - Restore Screen
* RGTTRIM0 - Part of RGTTRIM
* RstEMUL  - Restore original emulation
* RSTLINE  - Print Saved Screen Line
* SAVESCRN - Save And Clear Screen
* SetANSI  - Set ANSI mode, save old emulation
* SETSCRPT - Setup Screen Pointers
* STRCASE  - Part of UPPERSTR, LOWERSTR and MIXEDSTR
* STRCOPY  - Copy A String To String Space
* SVLINE   - Save Screen Line
* SWPBLK0  - Switch Block Buffers
* UNCOMP2  - Uncompress Variables
*===============================

*===============================
*   Name: PUTCHR2 - Save Character In Buffer
*
*  Input: A - Character To Store
*
* Output: None
*===============================

PUTCHR2     PHX                                  ; Save X
            LDX     TYPIN                        ; Any Room?
            STA     TYPEBUF,X                    ; Save Data
            INX
            CPEQX   TYPOUT;GETCHR3               ; Overflow?
            STX     TYPIN                        ; Save Pointer
            BRA     GETCHR3

*===============================
*   Name: GETCHR2 - Get Character From Buffer
*
*  Input: None
*
* Output: A > 0: Character
*         A = 0: No Character Available
*===============================

GETCHR2     PHX
            IFEQX   TYPOUT;TYPIN;GETCHR3         ; Any Data?

            LDA     TYPEBUF,X                    ; Get Character
            INX                                  ; Inc Pointer
            STX     TYPOUT                       ; Update
GETCHR3     PLX                                  ; Restore X
            CMP     #0
            RTS

*===============================
*   Name: INPTYP2 - Get Next Token/Character Type
*
*  Input:  None
*
* Output:  A = 0: Line/Command Link
*          A = 1: Expression
*          A = 2: Literal String
*          A = 3: Literal Number
*          A = 4: Token Or Unknown
*          A = 5: String Variable
*          A = 6: Numeric Variable
*===============================

INPTYP2     LDPL    (PRGPTR);INPTYP5             ; Get Current Program Byte

            LDX     #tknExpr
            CPEQ    #'('+Hibit;INPTYP4           ; Is It An Expression
            INX
            CPEQ    #'"'+Hibit;INPTYP4           ; Is It Data?

            INX
            JSR     TST_NUM                      ; Is It A Number?
            BCC     INPTYP4                      ; Yep

INPTYP3     INX
INPTYP4     TXA
            RTS

INPTYP5     LDX     #numVar
            CPEQ    #Number;INPTYP4              ; Is It A Var Number?
            CPLT    #OneByte;INPTYP6             ; what about a constant?
            CPLT    #ThreeByte+1;INPTYP4

INPTYP6     DEX
            CPEQ    #String;INPTYP4              ; Is It A Var String?
            LDX     #eolChain
            CPEQ    #Chain;INPTYP4               ; Is It End Of Statement
            CPEQ    #Chain2;INPTYP4              ; Is It End Of Line?
            CPEQ    #CompStrt;INPTYP4
            CPEQ    #CompEnd;INPTYP4
            BRA     INPTYP3                      ; Must Be A Token

*===============================
*   Name: BINDEC82 - Binary To Decimal
*
*  Input: A - Number To Convert
*
* Output: X,A Converted Number
*===============================

BINDEC82    LDY     #0                           ; Start 10s Counter
BIN8        CPLT    #10;BIN8A                    ; Less Than 10, Were Done

            SBC     #10                          ; Minus 10
            IBNE    Y;BIN8                       ; Add 1 To The 10s Counter

BIN8A       ADC     #'0'                         ; Make 1s Into Text
            TAX                                  ; Save
            TYA
            ADC     #'0'                         ; Make 10s Into Text
            RTS                                  ; Were Done

*===============================
*   Name: ADDCRC2 - Add Byte To CRC
*
*  Input: A - Byte To Act On
*
* Output: CRC
*===============================

ADDCRC2     PHAX                                 ; Save X And A
            EOR     CRC+1                        ; Add It To CRC
            TAX
            LDA     CRC
            EOR     CRCHI,X
            STA     CRC+1
            MOV     CRCLO,X;CRC
            PLAX                                 ; Restore X And A
            RTS

*===============================
*   Name: RAMIN2 - Get Byte From RAM Drive
*   Name: RAMOUT2 - Write Byte To RAM Drive
*
*  Input: A - Byte To Save (RAMOUT)
*
* Output: A - Byte Read (RAMIN)
*===============================

RAMIN2      CLC
            SKIPCS                               ; fake a BCS
RAMOUT2     SEC
            PHY
            LDY     RAMPTR                       ; Is Pointer In Range?
            IBEQ    Y;RAMOUT4                    ; this way, dont hose c

            DEY
            BCC     RAMIN3
            STA     RAMDRV,Y                     ; Save Data
            BRA     RAMOUT3

RAMIN3      LDA     RAMDRV,Y                     ; Get Data
RAMOUT3     INC     RAMPTR                       ; Move Pointer
RAMOUT4     PLY
            RTS

*===============================
*   Name: CLRSMT2 - Clear Variables, GOSUBs And FORs
*
*  Input: None
*
* Output: None
*===============================

CLRSMT2     MOV     #>ENDMOD;HIMEM+1
            STA     TEMP+1
            MOV     #<ENDMOD;HIMEM               ; Save Ending Address
            SEC
            SBA     #vRecSize;TEMP               ; Point to actual variable
            BCS     CLRSMT3
            DEC     TEMP+1

CLRSMT3     MOV     #0;(TEMP)
            MOVD    LOMEM;VARSTR                 ; Reset String Space

            SEC
            LDA     HIMEM+1                      ; Midmem=Lomem
            SBC     LOMEM+1                      ; +(Himem-Lomem)/2
            LSR     A
            CLC
            ADA     LOMEM+1;MIDMEM+1             ; Compute Midmem Value
            STZ     MIDMEM

            STZ     FROMERR                      ; Clear error location
            STZ     FROMERR+1

            STZ     GSBLVL                       ; Reset Gosub Stack
            STZ     FORLVL                       ; Reset For-Next Level
            RTS

*===============================
*   Name: DO_FRE2  - Compress String Space
*         COMPRES2 - Compress Variables
*         UNCOMP2  - Uncompress Variables
*
*  Input: None
*
* Output: None
*===============================

DO_FRE2     JSR     COMPRES2                     ; compress variables to AUX
; fall through to uncompress

UNCOMP2     MOVD    #STORETOP;TEMP               ; point to top of aux space
            MOVD    HIMEM;TEMP2                  ; point to top of variable space
            MOVD    LOMEM;TEMP3                  ; point to string space
            STZ     AUXREAD                      ; reading from aux memory
            BRA     COMPRES3                     ; go do it

COMPRES2    MOVD    HIMEM;TEMP                   ; point to top of variable space
            MOVD    #STORETOP;TEMP2              ; point to top of aux space
            MOVD    #STRDEST;TEMP3               ; point to bottom of aux space
            STZ     AUXWRT                       ; writing to aux memory

COMPRES3    SEC                                  ; destination -= 8
            SB      TEMP2;#vRecSize;TEMP2
            BCS     COMPRES4
            DEC     TEMP2+1

COMPRES4    SEC                                  ; source -= 8
            SB      TEMP;#vRecSize;TEMP
            BCS     COMPRES5
            DEC     TEMP+1

COMPRES5    LDY     #vRecSize-1                  ; move variable record
COMPRES6    MOV     (TEMP),Y;(TEMP2),Y
            DBPL    Y;COMPRES6

            LDEQ    (TEMP);COMPRESX              ; end of variables?
            BMI     COMPRES7                     ; go handle strings

            LDY     #valOffs                     ; Is the value 0?
            LDA     (TEMP),Y
            INY
            ORA     (TEMP),Y
            INY
            ORA     (TEMP),Y
            BEQ     COMPRES4                     ; yes, skip it
            BRA     COMPRES3                     ; no, do next one

COMPRES7    LDY     #valOffs                     ; Where is it located?
            MOV     (TEMP),Y;STRLOC
            INY
            MOV     (TEMP),Y;STRLOC+1
            PHA
            INY
            MOV     (TEMP),Y;STRLEN
            PLA
            CPGE    #>ENDMOD;COMPRES3            ; in high memory?

            LDEQ    STRLEN;COMPRES4              ; any string allocated?

            LDY     #0                           ; copy string
COMPRES8    CPEQY   STRLEN;COMPRES9              ; Go Until Done

            MOV     (STRLOC),Y;(TEMP3),Y         ; Copy Byte

            IBNE    Y;COMPRES8

COMPRES9    PHY                                  ; move new pointers
            LDY     #valOffs
            MOV     TEMP3;(TEMP2),Y
            INY
            MOV     TEMP3+1;(TEMP2),Y

            CLC                                  ; add in string length
            PLA
            ADA     TEMP3;TEMP3
            BCC     COMPRES3                     ; continue
            IBRA    TEMP3+1;COMPRES3

COMPRESX    TSTPL   RDRAMRD;COMPED               ; compressing or uncompressing?

            MOVD    TEMP3;VARSTR                 ; reset end of strings

            SEC
            LDA     TEMP2+1
            SBC     LOMEM+1                      ; +(Himem-Lomem)/2
            LSR     A
            CLC
            ADA     LOMEM+1;MIDMEM+1             ; Compute Midmem Value
            STZ     MIDMEM

COMPED      STZ     MAINWRT                      ; set back to main memory
            STZ     MAINREAD

            RTS

*===============================
*   Name: SVLINE - Save Screen Line
*
*  Input: None
*
* Output: None
*===============================

SVLINE2     LDX     CV
            LDY     WNDWDTH
            DEY
SVLNLUP     STZ     MAINWRT
            JSR     V_RDCHAR                     ; Read Character
            STZ     AUXWRT
            STA     CHATBUF+2,Y
            DBPL    Y;SVLNLUP                    ; Save Entire Line

            MOV     CH;CHATBUF                   ; Save Current Ch Position
            MOV     INPMODE;CHATBUF+1            ; Save Current Input Mode
            BRA     COMPED

*===============================
*   Name: RSTLINE - Print Saved Screen Line
*
*  Input: None
*
* Output: None
*===============================

RSTLINE2    STZ     AUXREAD
            LDEQX   CHATBUF;RSTLN3               ; Get Length

            LDY     #0
RSTLN2      LDA     CHATBUF+2,Y
            STZ     MAINREAD
            JSR     COUTLO                       ; Print Line
            STZ     AUXREAD
            INY
            DBNE    X;RSTLN2

RSTLN3      MOV     CHATBUF+1;INPMODE
            BRA     COMPED

*===============================
*   Name: IFGOB1 - Ignore To Line End Or Else Cmd
*
*  Input: None
*
* Output: None
*===============================

IFGOB2      EOR     LSTTXT                       ; toggle text mode
            STA     LSTTXT
IFGOBX      RTS

IFGOB1      JSR     GETRAW                       ; get a token
            CPEQ    #'"'+Hibit;IFGOB2            ; start or end of text?
            LDNEX   LSTTXT;IFGOBX                ; in text mode?
            CPNE    #Hitoken;IFGOB3              ; Check For High Tokens
            JSR     GETRAW                       ; Get The Token
            ORA     #Hibit                       ; Make It High
IFGOB3      CPEQ    #Number;IFGOB8               ; Check For Variables
            CPEQ    #String;IFGOB8
            CPLT    #ThreeByte+1;IFGOB9          ; Check for constants
            CPEQ    #Goto;IFGOB4                 ; Goto And Push
            CPEQ    #Push;IFGOB4                 ; both have 2 extra bytes
            CPEQ    #On;HandleON                 ; is it an ON statement?
            CPNE    #Gosub;IFGOB7                ; Gosub Might Not Have 2

            LDY     LSTTOK                       ; Check For Clear Gosub
            CPEQ    #Clear;IFGOB7                ; CHANGE TO IFEQY

IFGOB4      JSR     GETRAW
IFGOB5      JSR     GETRAW
IFGOB6      LDA     #0
IFGOB7      RTS

IFGOB8      JSR     GETRAW                       ; BUG FIX: 11/17/92
; ADD CHECK OF NEXT BYTE, NOT CURRENT BYTE
            LDPL    (PRGPTR);IFGOB6              ; eat variable name

            JSR     TST_NUM
            BCC     IFGOB8
            JSR     TST_ALF
            BCC     IFGOB8
            BRA     IFGOB6

IFGOB9      TAX                                  ; eat constant bytes
            JSR     GETRAW
            CPEQX   #TwoByte;IFGOB5
            CPEQX   #ThreeByte;IFGOB4
            BNE     IFGOB6                       ; CHANGE TO BRA LATER

HandleON    IFEQY   LSTTOK;#Chain;DOONN          ; ON or control token?
            CPNEY   #Chain2;IFGOB7

DOONN       IFEQ    (PRGPTR);#Nocar;IFGOB7       ; Is It ON NOCAR?
            CPEQ    #Onerr;IFGOB7                ; Is It ON ERROR?
            PUSHA   SHWTRC                       ; dont show this part
            STZ     SHWTRC
            JSR     INPNUM                       ; Get Value
            JSR     GETBYT                       ; Get ON Type
            PULL    SHWTRC
            JSR     GETRAW                       ; Get ON Count
            STA     TEMP                         ; Save Count Number
            STZ     TEMP+1
            ASL     TEMP                         ; Multiply By 2 For Index
            ROL     TEMP+1
            ADD     PRGPTR;TEMP;PRGPTR           ; Add In Count To End Of ON
            RTS

*===============================
*   Name: DO_RNDS2 - Generate Random Character
*
*  Input: None
*
* Output: None
*===============================

DO_RNDS2    LDA     RNDNUM
            AND     #%00011111                   ; Make In Range [0-31]
            CPLT    #'Z'-Ctrl;DO_RNDS3           ; in range

            SBC     #10                          ; Put Into Range
DO_RNDS3    ADC     #'A'
            STA     (VARSTR)                     ; Save Character
            LDA     RNDNUM+1
            EOR     #%10110100
            ADA     RNDNUM;RNDNUM                ; Re-Seed For Next Pass
            ROL     A
            ROL     A
            ROL     A
            STA     RNDNUM+1
            LD16    VARSTR                       ; Point To Random Char
            INY
            JMP     INCVARST

*===============================
*   Name: SAVESCRN - Save And Clear Screen
*
*  Input: None
*
* Output: None
*===============================

SAVESCRN    JSR     SETSCRPT                     ; Move Buffer To Screen
SS_LOOP1    LDY     #119
SS_LOOP2    MOV     (TEMP),Y;HISCR
            STA     (TEMP2),Y
            MOV     (TEMP),Y;(TEMP3),Y
            MOV     #' '+Hibit;(TEMP),Y
            STA     LOWSCR
            STA     (TEMP),Y
            DBPL    Y;SS_LOOP2

            JSR     INCSCRPT

            DBNE    X;SS_LOOP1

            STA     LORES
            RTS

*===============================
*   Name: RESTSCRN - Restore Screen
*
*  Input: None
*
* Output: None
*===============================

RESTSCRN    JSR     SETSCRPT                     ; Move Screen To Buffer
RS_LOOP1    LDY     #119
RS_LOOP2    STA     HISCR
            MOV     (TEMP3),Y;(TEMP),Y
            MOV     (TEMP2),Y;LOWSCR
            STA     (TEMP),Y
            DBNE    Y;RS_LOOP2

            JSR     INCSCRPT

            DBNE    X;RS_LOOP1

            STA     LORES
            RTS

*===============================
*   Name: INCSCRPT - Setup Screen Pointers
*
*  Input: None
*
* Output: None
*===============================

INCSCRPT    LDA     TEMP
            EOR     #$80
            STA     TEMP
            STA     TEMP2
            STA     TEMP3
            BNE     INCSRET
            INC     TEMP+1
            INC     TEMP2+1
            INC     TEMP3+1
INCSRET     RTS

*===============================
*   Name: SETSCRPT - Setup Screen Pointers
*
*  Input: None
*
* Output: None
*===============================

SETSCRPT    STZ     TEMP
            STZ     TEMP2
            STZ     TEMP3
            MOV     #>LINE1;TEMP+1
            MOV     #>SCRNBUF;TEMP2+1
            MOV     #>SCRNBUF+$400;TEMP3+1
            LDX     #8
            STA     HIRES
            RTS

*===============================
* Set ANSI mode, save old emulation
*===============================

SetANSI     LDX     #$C0
SetAlup     DEX
            MOV     CURREMUL,X;EMULSAVE,X
            MOV     ANSILST,X;CURREMUL,X
            TXA
            BNE     SetAlup
            RTS

*===============================
* Restore original emulation
*===============================

RstEMUL     LDX     #$C0
RstLup      DEX
            MOV     EMULSAVE,X;CURREMUL,X
            TXA
            BNE     RstLup
            RTS

*===============================
*   Name: ARGTYP - Get Argument Type
*
*  Input: Program Pointer
*
* Output: C = 1: String
*         C = 0: Number
*===============================

ARGTYP0     IFEQ    (PRGPTR);#'"'+Hibit;ARGTYP1  ; If Its Text
            CPEQ    #'('+Hibit;ARGTYP2           ; If Its An Expression
            CPMI    #0;ARGTYP2                   ; If Its Other Than Text
            CPEQ    #String;ARGTYP1              ; If Its A String Var
            CPLT    #Strtyp;ARGTYP2              ; Set Carry If String
            CPGE    #Compare;ARGTYP2             ; Make Sure Its In Range

ARGTYP1     SEC                                  ; Its A String
            RTS

ARGTYP2     CLC                                  ; Its A Number
            RTS

*===============================
*   Name: STRCOPY - Copy A String To String Space
*
*  Input: String Parameters
*
* Output: None
*===============================

STRCOPY0    LDY     #0
STRCOP2     CPEQY   STRLEN;STRCOP3               ; Go Until Done

            MOV     (STRLOC),Y;(VARSTR),Y        ; Copy Byte
            IBEQ    TTLLEN;STR2BIG               ; increase length, too big

            IBNE    Y;STRCOP2

STRCOP3     TYA                                  ; Add In Bytes Copied
            CLC
            ADA     VARSTR;VARSTR
            BCC     STRCOP4
            INC     VARSTR+1
STRCOP4     RTS

STR2BIG     LDA     #Strtobig
            JMP     BADERR

*===============================
*   Name: DO_MUL0 - Actual Multiply Routine
*
*  Input: None
*
* Output: None
*===============================

DO_MUL00    LDX     #5                           ; Empty Result
DO_MUL0A    STZ     RESULT,X
            DBPL    X;DO_MUL0A

            STZ     DATA+4
            STZ     DATA+5
            LDX     #24                          ; 24 Bits To Do
DO_MUL1     LSR     NUMB+2
            ROR     NUMB+1                       ; Put Bit 0 Into Carry
            ROR     NUMB
            BCC     DO_MUL2                      ; If Carry Set, Do Add

            CLC
            LDY     #0                           ; Start Index
            PHP                                  ; Save Carry For Later
ADDIT       PLP                                  ; Restore Current Carry
            AD      RESULT,Y;DATA+1,Y;RESULT,Y   ; Add In Multiplier
            PHP                                  ; Save Carry
            INY                                  ; Bump Index
            CPNEY   #6;ADDIT                     ; Finished? (Kills Carry)

            PLP
DO_MUL2     ASL     DATA+1                       ; Shift Data For Next Bit
            ROL     DATA+2
            ROL     DATA+3
            ROL     DATA+4
            ROL     DATA+5
            DBNE    X;DO_MUL1

            RTS

*===============================
*   Name: DO_DIV1A - Actual Divide routine
*
*  Input: None
*
* Output: None
*===============================

DO_DIV1A    BREQ3   NUMB;DO_DIV5                 ; Is It Divide By Zero?

            LDA     #0                           ; Clear Remainder
            ZERO24  REMAIN
            CLC
            LDX     #24                          ; 24 Bits To Do
DO_DIV2     ROL     DATA+1                       ; Shift Up The Carry Bit
            ROL     DATA+2
            ROL     DATA+3
            ROL     REMAIN
            ROL     REMAIN+1
            ROL     REMAIN+2
            PHX
            SEC
            LDA     REMAIN                       ; Check Remainder>Divisor
            SBC     NUMB
            TAX
            LDA     REMAIN+1
            SBC     NUMB+1
            TAY
            LDA     REMAIN+2
            SBC     NUMB+2
            BCC     DO_DIV3                      ; Nope, Skip Subtract

            STX     REMAIN                       ; Allow Subtract
            STY     REMAIN+1
            STA     REMAIN+2
DO_DIV3     PLX
            DBNE    X;DO_DIV2

            ROL     DATA+1                       ; Shift In Quotient
            ROL     DATA+2
            ROL     DATA+3
            JSR     GETDATA
            ST24    RESULT
            RTS

DO_DIV5     LDA     #Divby0                      ; Division By Zero
            JMP     BADERR

*===============================
* Switch Block Buffers
*===============================

SWPBLK0     LDY     #127
SWPBLK2     PUSHA   BLKBUF,Y                     ; Get Buf 1 Char
            MOV     BLKBUF2,Y;BLKBUF,Y           ; Get Buf 2 Char
            PULL    BLKBUF2,Y                    ; Put In Buf 2
            DBPL    Y;SWPBLK2                    ; Loop

            LDY     #3
SWPBLK3     PUSHA   MSGPTR,Y                     ; Swap Pointers
            MOV     MSGPTR2,Y;MSGPTR,Y
            PULL    MSGPTR2,Y
            DBPL    Y;SWPBLK3

            RTS

*===============================
* Part of the INSTR function
*===============================

DO_NSR00    STX     TEMP+1                       ; Restore first string info
            STY     TEMP
            STA     TEMP2
            LDX     TEMP3+1
            TAY                                  ; For null match
            BEQ     DO_NSR5                      ; Null String, Always Match

            SEC
            LDA     STRLEN                       ; How Many Chars To Search?
            SBC     TEMP2
            BEQ     DO_NSR1
            BCC     DO_NSR9                      ; None!
DO_NSR1     TAX
            SEC                                  ; force subtract - 1
            SBC     TEMP3+1
            BEQ     DO_NSR2
            BCC     DO_NSR9                      ; None!

DO_NSR2     INX
            STX     TEMP2+1                      ; Save Passes Plus 1

            LDX     TEMP3+1                      ; Start At Pass 0
            CLC
            TXA                                  ; add in start
            ADA     STRLOC;STRLOC
            BCC     DO_NSR3
            INC     STRLOC+1

DO_NSR3     LDY     #0                           ; Start Checking At Byte 0
DO_NSR4     LDA     (TEMP),Y                     ; Get First Byte
            JSR     CONV                         ; Make Upper
            STA     TEMP3                        ; Save
            LDA     (STRLOC),Y                   ; Get Second Byte
            JSR     CONV                         ; Make Upper
            CPNE    TEMP3;DO_NSR7                ; Do They Match?

            INY                                  ; Inc Pointer
            CPNEY   TEMP2;DO_NSR4                ; We Done?

DO_NSR5     INX                                  ; Get Pass+1
            TXA
DO_NSR6     JMP     SVDATA                       ; Return

DO_NSR7     INCD    STRLOC                       ; Check Against Next Byte
            INX                                  ; Count Up Passes
            CPNEX   TEMP2+1;DO_NSR3              ; Are We Done?

DO_NSR9     LDEQ    #0;DO_NSR6                   ; No Match CHANGE TO BRA LATER

*===============================
* Part of UPPERSTR, LOWERSTR and MIXEDSTR
*===============================

STRCASE     STA     TEMP                         ; Flags
            LDEQY   STRLEN;CVS_EXIT              ; Null String?

            STZ     TEMP+1                       ; Upper/Lower Switch
            LDY     #0                           ; Get First Char
CVS_NEXT    MOV     (STRLOC),Y;TEMP2             ; savint hi bit
            AND     #Clrhi                       ; Clear Hi Bit
            TSTMI   TEMP;CVS_LOW                 ; What Are We Doing?
            BVS     CVS_MIX                      ; Make Mixed

            JSR     CONV                         ; Convert To Upper
            BRA     CVS_STOR

CVS_LOW     JSR     LOWER                        ; Convert To Lower
            BRA     CVS_STOR

CVS_MIX     CPLT    #'A';CVS_SW                  ; Make Next Char Upper

            LDNEX   TEMP+1;MKLOW                 ; Making Lower Or Upper?

            JSR     CONV
            BRA     XSTORE

MKLOW       JSR     LOWER
XSTORE      INC     TEMP+1                       ; Flag Next Is Lower
CVS_STOR    TSTPL   TEMP2;CVS_STUF               ; Was Hi Bit Set?

            ORA     #Hibit                       ; Reset Hi Bit
CVS_STUF    STA     (STRLOC),Y                   ; Save New Char
CVS_NCH     INY                                  ; Point To Next
            CPNEY   STRLEN;CVS_NEXT              ; Done?

CVS_EXIT    RTS

CVS_SW      STZ     TEMP+1                       ; Flag Next Is Upper
            BRA     CVS_NCH

LOWER       CPLT    #'A';LO_EXIT                 ; Standard Convert
            CPGE    #'Z'+1;LO_EXIT
            ADC     #$20
LO_EXIT     RTS

*===============================
* Part of RGTTRIM
*===============================

RGTTRIM0    LDEQY   STRLEN;RT_ZERO               ; Get Length

RT_NXTCH    DEY                                  ; Bump Down
            CPEQY   #-1;RT_EXIT                  ; Finished?

            LDA     (STRLOC),Y                   ; Get Character
            AND     #Clrhi                       ; Clear Hi Bit
            CPNE    #' ';RT_EXIT                 ; Is It A Space?

            DBRA    STRLEN;RT_NXTCH              ; Count Down Length

* CHANGE TO MOV STRLEN;(VPTR),Y LATER
RT_EXIT     LDA     STRLEN                       ; Get New Length
            LDY     #2                           ; Store It
            STA     (VPTR),Y
RT_ZERO     RTS

*===============================
* Part of LEFTTRIM
*===============================

LFTTRIM0    LDEQY   STRLEN;LFT_ZERO              ; Get Length

LF_NXTCH    LDA     (STRLOC)                     ; Get The Character
            AND     #Clrhi                       ; Clear Off High Bit
            CPNE    #' ';LFT_FIN                 ; Is It A Space?

            DEC     STRLEN                       ; Count Down Length
            INCD    STRLOC                       ; Increment String Pointer
            BRA     LF_NXTCH                     ; Check Next One

LFT_FIN     LDY     #1                           ; Save New String Start
            MOV     STRLOC;(VPTR)
            MOV     STRLOC+1;(VPTR),Y
            INY
            MOV     STRLEN;(VPTR),Y              ; Get New Length
LFT_ZERO    RTS

*===============================
* Part of  FMTDATE
*===============================

DO_FDT0     STZ     DOWSTR                       ; Zero Out Old String Length
            STA     TEMP                         ; Save Year*2..
            TXA
            PHA                                  ; Save Month/Day
            AND     #%00011111                   ; Mask Out Month Data
            STA     TEMP2                        ; Save The Day
            PLA                                  ; Get Back Month/Day
            LSR     TEMP                         ; Make Year Normal
            ROR     A                            ; Put Month Bit Into Month
            AND     #%11110000                   ; Mask Out Day Data
            LSR     A                            ; Move to low nibble
            LSR     A
            LSR     A
            LSR     A
            STA     TEMP2+1                      ; Save This (Month)
            TAX                                  ; Get Token For This Month
            MOV     MTKNS-1,X;TEMP3
            LDX     TEMP                         ; Get Year
            TXA                                  ; Do The Calculation
            SEC                                  ; For Day Of Week
            SBC     #85                          ; Subtract 85
            LSR     A                            ; Divide By 4
            LSR     A
            CLC                                  ; Add Year In Again
            ADC     TEMP                         ; Year
            SBC     #83                          ; Subtract 83
            JSR     SUBWEEK                      ; Mod 7
            TAY                                  ; Save In Y
            TXA                                  ; Get Year Again
            STZ     TEMP+1
            AND     #%00000011                   ; If Year Mod 4<>0, X=FF
            BEQ     CALCDAY

            DEC     TEMP+1                       ; Year Mod 4 Flag
CALCDAY     TYA                                  ; Get Back Previous Result
            CLC                                  ; Add In Month Token
            ADC     TEMP3                        ; Month Token
            ADC     TEMP2                        ; Add In Day Of Month
            IFLTY   TEMP2+1;#3;DOMOD             ; month

            ADC     TEMP+1                       ; 0 Or -1
DOMOD       JSR     SUBWEEK                      ; Mod 7 Again
            ASL     A                            ; Multiply By 4 For Index
            ASL     A
            TAY                                  ; Move To Index
FMT_LUP1    LDA     DAYS,Y                       ; Get Character To Save
            JSR     SAVECHR                      ; Save The Character
            INY                                  ; Go For Next One
            CPNE    #'.';FMT_LUP1

            LDA     #' '
            JSR     SAVECHR
            LDA     TEMP2+1                      ; Get Month
            DEC     A
            ASL     A                            ; Multiply By 4 For Index
            ASL     A
            TAY                                  ; Move To Index
FMT_LUP2    LDA     MONTHS,Y                     ; Get Character Of Month
            JSR     SAVECHR                      ; Save It
            INY                                  ; Go For Next One
            CPNE    #' ';FMT_LUP2

            LDA     TEMP2                        ; Get Day Of Month
            JSR     BINDEC82                     ; Convert It To ASCII
            CPNE    #'0';FMT2                    ; Make Leading 0 A Space

            LDA     #' '
FMT2        JSR     SAVEAX                       ; Stuff It In Buffer
            LDA     #','
            LDX     #' '                         ; Stuff ", " In Buffer
            JSR     SAVEAX
            LDA     #'1'                         ; Stuff In Leading 19
            LDX     #'9'
            JSR     SAVEAX
            LDA     TEMP                         ; Get Year
            JSR     BINDEC82                     ; Convert To ASCII
            JSR     SAVEAX                       ; Save It
            LD16    #DOWSTR+1                    ; Point To String
            LDY     DOWSTR
            STY     STRLEN                       ; Save Length
            ST16    STRLOC                       ; Save String Location
            PUSHW   VARSTR                       ; Save Current String pointer
            JSR     STRCOPY0                     ; Copy String To Main
            LDY     STRLEN                       ; Get Back Length
            PLAX                                 ; And Pointer
            JMP     SVSTR

SAVEAX      JSR     SAVECHR
            TXA                                  ; Get X
SAVECHR     PHX                                  ; Save X
            LDX     DOWSTR                       ; Get Index In X
            STA     DOWSTR+1,X                   ; Stuff It
            INC     DOWSTR                       ; Increment Index
            PLX                                  ; Get Back X
            RTS

SUBWEEK     SEC                                  ; A=A Mod 7
FMT_LUP3    SBC     #7
            BCS     FMT_LUP3

            ADC     #7
            RTS
            DS      \

*===============================
* ANSI screen control list
*===============================

ANSILST     =       *
ANSIhome    HEX     031B5B48                     ; Home
            DS      8-*+ANSIhome
ANSIup      HEX     031B5B41                     ; Cursor up
            DS      8-*+ANSIup
ANSIdown    HEX     031B5B42                     ; Cursor down
            DS      8-*+ANSIdown
ANSIleft    HEX     031B5B44                     ; Cursor left
            DS      8-*+ANSIleft
ANSIrght    HEX     031B5B43                     ; Cursor right
            DS      8-*+ANSIrght
ANSIeos     HEX     041B5B304A                   ; Clear to eos
            DS      8-*+ANSIeos
ANSIbos     HEX     041B5B314A                   ; Clear to bos
            DS      8-*+ANSIbos
ANSIcls     HEX     041B5B324A                   ; Clear screen
            DS      8-*+ANSIcls
ANSIeol     HEX     041B5B304B                   ; Clear to eol
            DS      8-*+ANSIeol
ANSIbol     HEX     041B5B314B                   ; Clear to bol
            DS      8-*+ANSIbol
ANSIcll     HEX     041B5B324B                   ; Clear line
            DS      8-*+ANSIcll
ANSIiln     HEX     031B5B4C                     ; Insert line
            DS      8-*+ANSIiln
ANSIdln     HEX     031B5B4D                     ; Delete line
            DS      8-*+ANSIdln
ANSIich     HEX     031B5B40                     ; Insert char
            DS      8-*+ANSIich
ANSIdch     HEX     031B5B50                     ; Delete char
            DS      8-*+ANSIdch
ANSInor     HEX     041B5B306D                   ; Normal
            DS      8-*+ANSInor
ANSIinv     HEX     061B5B303B376D               ; Inverse
            DS      8-*+ANSIinv
            DS      $C0-*+ANSILST

EMULSAVE    =       *
            LST     OFF

