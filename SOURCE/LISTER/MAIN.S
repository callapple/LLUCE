LISTER
            DO       ACOS
            JSR      OPEN                                       ; Open Ourself Again
            LDA      REFNUM
            STA      :READREF
            PUTMARK  #<LOWSUBS-$9E00,#>LOWSUBS-$9E00,#0
            STA      SET80COL                                   ; Swap In Alt $2000-$3FFF
            STA      HIRES
            JSR      SWAP                                       ; ACOS Out
            JSR      MLI
            DB       Read
            DA       :OURREAD
            JSR      SWAP                                       ; ACOS In
            JSR      CLOSE                                      ; Close Us
            JMP      DO_LIST

:OURREAD    DB       4
:READREF    DB       0
            DA       $2000
            DA       $2000
            DA       0
            ELSE
            LDX      #ENDMLI-MLILISTS
:MVMLI      LDA      MLILISTS,X
            STA      READLST,X
            DEX
            BPL      :MVMLI
            FIN

DO_LIST     JSR      GOBCOM                                     ; Get Archive Name
            JSR      MOVNAME
            JSR      OPEN                                       ; Open It
            BCS      :NOGOOD                                    ; Not There

            READ     #128;HDRBUF
            JSR      TESTLIBR
            CMP      #-1
            BEQ      :NOGOOD

            DO       ACOS
            PHA
            JSR      SWAP                                       ; ACOS Out
            PLA
            FIN
            TAY
            ASL
            TAX
            JSR      :DO_LIBR
            DO       ACOS
            JSR      SWAP                                       ; ACOS In
            BIT      LORES
            FIN
            LDA      #0
:NOGOOD
            DO       ACOS
            STA      $A
            FIN
            JMP      CLOSE

:DO_LIBR    LDA      LIBSUBS,X
            STA      TEMP
            LDA      LIBSUBS+1,X
            STA      TEMP+1
            JMP      (TEMP)

            DO       ACOS
SWAP        LDA      #$20
            STA      TEMP+1
            LDA      #0
            STA      TEMP
            LDY      #0
:LOOP       BIT      PAGE1
            LDA      (TEMP),Y
            PHA
            BIT      PAGE2
            LDA      (TEMP),Y
            TAX
            PLA
            STA      (TEMP),Y
            BIT      PAGE1
            TXA
            STA      (TEMP),Y
            INY
            BNE      :LOOP
            INC      TEMP+1
            LDA      TEMP+1
            CMP      #$30
            BNE      :LOOP
            RTS

            FIN
            DO       ACOS
            ELSE
MLILISTS    ORG      $300
            FIN

READLST     DB       4                                          ; MLI read list
READREF     DB       0
READBUF     DA       0
READCNT     DA       0
            DA       0
            DO       ACOS
            ELSE
            ORG
ENDMLI      =        *
            FIN
*=================================================
*      Routine Name: TESTLIBR
*
*  Input Parameters: None
*
* Output Parameters:
*
* A = 0  : ACU     (AppleLink Conversion Utility)
* A = 1  : LBR     (AppleDouble)
* A = 2  : LBR     (AppleSingle)
* A = 3  : ARC     (Sea-Arc)
* A = 4  : BIN     (Binary ][/BLU)
*          BNY
*          BQY
*          BXY
* A = 5  : LZH
* A = 6  : SHK     (ShrinkIt)
* A = 7  : SIT     (StuffIt)
* A = 8  : SIT     (Stuffit, AOL)
* A = 9  : ZIP     (PKZIP)
* A = 10 : ZOO
* A = 11 : LU      (Library Utility "IBM")
* A = 12 : MACBIN  (MacBinary)
* A = 13 : ARJ
*
* Purpose: Check For Library Type
*=================================================

TESTLIBR    LDY      #0
            STY      LIBTYPE
            STY      RESLEN
:LOOP       LDA      FORMATS,Y                                  ; Get Byte Offset
            CMP      #-1
            BEQ      :CNTUP                                     ; If -1, Done With Lib

            STA      RESLEN
            AND      #$7F
            TAX
            LDA      HDRBUF,X                                   ; Get Byte To Check
            BIT      RESLEN
            BPL      :ABS

            AND      #$7F
            CMP      #'a'
            BLT      :OK
            CMP      #'z'+1
            BGE      :OK
            SBC      #$1F
:OK         CMP      #' '
            BLT      :GOEND
            CMP      #'Z'+1
            BGE      :GOEND
            BLT      :NXTCHR

:ABS        CMP      FORMATS+1,Y                                ; Does This Work?
            BNE      :GOEND                                     ; Nope

:NXTCHR     INY                                                 ; Point To Next Byte
            INY
            LDX      FORMATS,Y                                  ; End Of Test?
            CPX      #-1
            BNE      :LOOP                                      ; Nope

            LDA      LIBTYPE
            RTS                                                 ; Finished

:GOEND      INY                                                 ; Search For Next -1
            INY
            LDA      FORMATS,Y
            CMP      #-1
            BNE      :GOEND

:CNTUP      INY                                                 ; Check For End Of Table
:SKIPLIB    INC      LIBTYPE
            LDA      FORMATS,Y                                  ; Second -1?
            CMP      #-1
            BNE      :LOOP                                      ; Nope

            RTS

*=================================================
* Library Id Bytes
*=================================================

FORMATS
:ACUFMT     DB       4,'f',5,'Z',6,'i',7,'n',8,'k',-1
:ADOUFMT    DB       0,0,1,5,2,$16,3,7,-1
:ASINFMT    DB       0,0,1,5,2,$16,3,0,-1
:NUFXFMT    DB       0,'N',1,"u"
            DB       2,'F',3,"i",4,'l',5,"e",-1
:B2FMT      DB       0,$A,1,'G',2,'L',$12,2,-1
:ARCFMT     DB       0,$1A,$82,0,-1
:LZHFMT     DB       2,'-',3,'l',4,'h',6,'-',-1
:SITFMT     DB       0,'S',1,'I',2,'T',3,'!'
            DB       10,'r',11,'L',12,'a',13,'u',-1
:SITFMT2    DB       32,'S',33,'I',34,'T',35,'!'
            DB       42,'r',43,'L',44,'a',45,'u',-1
:ZIPFMT     DB       0,'P',1,'K',2,3,3,4,-1
:ZOOFMT     DB       20,$DC,21,$A7,22,$C4,23,$FD,-1
:LUFMT      DB       0,0,1,' ',2,' ',3,' ',4,' ',5,' '
            DB       6,' ',7,' ',8,' ',9,' ',10,' ',11,' '
            DB       12,0,13,0,26,0
            DB       27,0,28,0,29,0,30,0,31,0,-1
:MACBIN     DB       0,0,$82,0,$4A,0,$52,0,-1
:ARJFMT     DB       0,$60,1,$EA,-1
            DB       -1

LIBSUBS     DA       DO_ACU                                     ; 0
            DA       DO_APL                                     ; 1
            DA       DO_APL                                     ; 2
            DA       DO_SHK                                     ; 3
            DA       DO_BLU                                     ; 4
            DA       DO_ARC                                     ; 5
            DA       DO_LZH                                     ; 6
            DA       DO_SIT                                     ; 7
            DA       SIT_AOL                                    ; 8
            DA       DO_ZIP                                     ; 9
            DA       DO_ZOO                                     ; 10
            DA       DO_LU                                      ; 11
            DA       DO_MAC                                     ; 12
            DA       DO_ARJ                                     ; 13

*=================================================
*      Routine Name: DO_READ
*
*  Input Parameters: Y = Number Of Bytes To Read
*                    (Address) = Buffer To Read Into
*
* Output Parameters: Data In (Address)
*
*  Format:    LDY  LENGTH
*             JSR  DO_READ
*             DA   BUFFER
*
* Purpose: Read In A Chunk Of Data
*=================================================

DO_READ     STY      READCNT
            STACK    WORD
            JSR      GETWORD
            STX      READBUF
            STA      READBUF+1
            LDA      REFNUM
            STA      READREF
            JSR      MLI
            DB       Read
            DA       READLST
            RTS

            DO       ACOS
GET_MARK    LDA      REFNUM
            STA      MARKREF
            JSR      MLI
            DB       Get_Mark
            DA       MARKLST
            LDA      #0
            TAX
            TAY
            BCS      :ERR

            LDX      MARK
            LDA      MARK+1
            LDY      MARK+2
:ERR        RTS

MARKLST     DB       2
MARKREF     DB       0
MARK        DS       3

            FIN
*=================================================
*      Routine Name: MARKZERO
*
*  Input Parameters: None
*
* Output Parameters: None
*
* Purpose: Set Mark To Zero
*=================================================

MARKZERO    LDX      #0
            TXA
            TAY
            DO       ACOS
SET_POS     STX      MARK
            STA      MARK+1
            STY      MARK+2
            LDA      REFNUM
            STA      MARKREF
            JSR      MLI
            DB       Set_Mark
            DA       MARKLST
            RTS
            ELSE
            JMP      SET_POS
            FIN

*=================================================
*      Routine Name: SHOWSTR
*
*  Input Parameters: (DCI String)
*
* Output Parameters: None
*
*  Format:   JSR  SHOWSTR
*            DCI  'String to print'
*
*            DB   1,n,c     Prints character c n times
*
* Purpose: Print A String
*=================================================

SHOWSTR     PLA
            STA      TEMP
            PLA
            STA      TEMP+1
            LSR
            PHP
            JMP      :NEXTEMP

:SHOWLUP    LDY      #0
            LDA      (TEMP),Y
            CMP      #1
            BEQ      :MULT

            PHP
            JSR      COUT
:NEXTEMP    INC      TEMP
            BNE      :DONE
            INC      TEMP+1
:DONE       PLP
            BPL      :SHOWLUP

            JMP      (TEMP)

:MULT       INY
            LDA      (TEMP),Y
            TAX
            INY
            LDA      (TEMP),Y
:LOOP       JSR      COUT
            DEX
            BNE      :LOOP

            CLC                                                 ; Skip Used Bytes
            LDA      TEMP
            ADC      #3
            STA      TEMP
            BCC      :SHOWLUP
            INC      TEMP+1
            BNE      :SHOWLUP

*=================================================
*      Routine Name: APLHDR
*
*  Input Parameters: A = Compressed Files Allowed
*                        High bit is flag
*
* Output Parameters: None
*
* Purpose: Display Apple Type Header
*=================================================

APLHDR      PHA
            JSR      SHOWSTR                                    ; Apple header
            DB       Cr,Cr
            ASC      ' Filename'
            DB       1,12,' '
            ASC      'Type  Mod Date   Mod Time   Aux'
            DB       1,5,' '
            DCI      'Size  '
            PLA
            PHA
            BPL      :NOPACK1
            JSR      SHOWSTR
            ASC      '   Method'
            DB       1,4,' '
            ASC      "%"
:NOPACK1    JSR      SHOWSTR
            DB       Cr
            DB       1,19,'-'                                   ; Filename
            ASC      '  '
            DB       1,4,'-'                                    ; Type
            ASC      '  '
            DB       1,9,'-'                                    ; Mod Date
            ASC      '  '
            DB       1,9,'-'                                    ; Mod Time
            ASC      '  '
            DB       1,4,'-'                                    ; Aux Type
            ASC      '  '
            DB       1,7,'-'                                    ; Size
            ASC      "-"
            PLA
            BPL      :NOPACK2
            JSR      SHOWSTR
            ASC      '  '
            DB       1,8,'-'                                    ; Method
            DCI      '  ----'                                   ; %
:NOPACK2    CROUT
            RTS

*=================================================
*      Routine Name: MSHDR
*
*  Input Parameters: A = Compressed Files Allowed
*                        High bit is flag
*
* Output Parameters: None
*
* Purpose: Display MS-DOS Type Header
*=================================================

MSHDR       PHA
            JSR      SHOWSTR                                    ; MS-DOS Header
            DB       Cr,Cr
            ASC      ' Filename'
            DB       1,12,' '
            DCI      'Mod Date   Mod Time     Size'
            PLA
            PHA
            BPL      :NOPACK1
            JSR      SHOWSTR
            DB       1,5,' '
            DCI      'Method    %'
:NOPACK1    JSR      SHOWSTR
            DB       Cr
            DB       1,19,'-'                                   ; Filename
            ASC      '  '
            DB       1,9,'-'                                    ; Mod Date
            ASC      '  '
            DB       1,9,'-'                                    ; Mod Time
            ASC      '  '
            DB       1,7,'-'                                    ; Size
            ASC      "-"
            PLA
            BPL      :NOPACK2
            JSR      SHOWSTR
            ASC      '  '
            DB       1,8,'-'                                    ; Method
            DCI      '  ----'
:NOPACK2    CROUT
            RTS

*=================================================
*      Routine Name: ZINKOS
*
*  Input Parameters: A - Operating System Number
*
* Output Parameters: None
*
* Purpose: Show ACU Or BLU Operating System
*=================================================

ZINKOS      ASL
            TAX
            LDA      OSNAME,X                                   ; Get String Address
            STA      TEMP
            LDA      OSNAME+1,X
            STA      TEMP+1
            LDY      #0                                         ; Print Name
:OSNUMLP    LDA      (TEMP),Y
            BEQ      :DONE

            JSR      COUT
            INY
            BNE      :OSNUMLP

:DONE       RTS

*=================================================
*      Routine Name: CROUT, SPACE
*
*  Input Parameters: None
*
* Output Parameters: None
*
* Purpose: Print A Cr Or Space
*=================================================

DO_CROUT    LDA      #Cr
            HEX      2C
DO_SPACE    LDA      #' '
            JMP      COUT

*=================================================
*      Routine Name: AUXTYPE
*
*  Input Parameters: (Address) = Address Of AuxType
*
* Output Parameters: None
*
*  Format:  JSR  AUXTYPE
*           DA   AUXTYPEBUF
*
* Purpose: Show A File's Auxillary Type
*=================================================

DO_AUX      STACK    WORD
            JSR      GETWORD
            LDY      #1
            LDA      (TEMP),Y                                   ; Get High Byte
            JSR      PRBYTE                                     ; Print It
            DEY                                                 ; Get Low Byte
            LDA      (TEMP),Y
            JSR      PRBYTE

*=================================================
*      Routine Name: TWODOTS
*                    TWOSPACE
*
*  Input Parameters: None
*
* Output Parameters: None
*
* Purpose: Print 2 Dots
*=================================================

DO_TWOSP    LDA      #' '
            HEX      2C
DO_DOTS     LDA      #'.'
            JSR      COUT
            JMP      COUT

*=================================================
*      Routine Name: PRBYTE
*
*  Input Parameters: A = Byte To Print
*
* Output Parameters: None
*
* Purpose: Print A Hex Byte
*=================================================

PRBYTE      PHA                                                 ; Save Byte To Print
            LSR                                                 ; Shift High Nibble
            LSR
            LSR
            LSR
            JSR      :PRHEX                                     ; Print Nibble
            PLA                                                 ; Restore Byte
            AND      #$F                                        ; Clear Off High Nibble
:PRHEX      ORA      #'0'                                       ; Make It ASCII
            CMP      #'9'+1                                     ; Is It A Number?
            BLT      :DOOUT                                     ; Yes, Leave It Alone
            ADC      #6                                         ; Make It Alpha
:DOOUT      JMP      COUT

*=================================================
*      Routine Name: SHWNAME2
*
*  Input Parameters: (Address) Of String
*
* Output Parameters: None
*
* Purpose: Show C Type Filename
*=================================================

DO_CSTR     STA      TEMP2
            STACK    WORD
            JSR      GETWORD                                    ; Get String Address
            LDY      #0
:LOOP       LDA      (TEMP),Y                                   ; Find End Of Name
            BEQ      :GOTLEN
            INY
            BNE      :LOOP

:GOTLEN     STY      TEMP3                                      ; Length Is In Y
            JMP      DO_NAME

*=================================================
*      Routine Name: SHOWNAME
*
*  Input Parameters: Y = Name Length
*                    A = Full name flag
*                    (Address) Of Filename
*
* Output Parameters: None
*
* Purpose: Print Pascal Type Filename
*=================================================

DO_PSTR     STA      TEMP2
            STY      TEMP3
            STACK    WORD
            JSR      GETWORD                                    ; Get Location Of Filename
DO_NAME     LDX      #0                                         ; Point To Starting Position
            STX      TEMP3+1
            LDY      TEMP3                                      ; Get length
            BIT      TEMP2                                      ; Show Full Name?
            BMI      :SHOWALL                                   ; Yes

            CPY      #78                                        ; Check For Name Longer
            BLT      :SHOWALL                                   ; Than Field

            TYA                                                 ; Fix For New Start Position
            SEC
            SBC      #76
            STA      TEMP3+1
            TWODOTS                                             ; Print 2 Dots
            LDX      #2                                         ; Skip 2 Characters
:SHOWALL    LDY      TEMP3+1                                    ; Print The Name
:NAMELP     LDA      (TEMP),Y
            JSR      COUT
            INX
            INY
            CPY      TEMP3
            BLT      :NAMELP

            BIT      TEMP2                                      ; Full Pathname?
            BMI      :NAMEDN                                    ; Yes, No Fill

:FILL       CPX      #18                                        ; Finished With Field?
            BGE      :NAMEDN                                    ; Yes.

:FILL2      SPACE                                               ; Fill Field With Spaces
            INX
            JMP      :FILL                                      ; Always

:NAMEDN     BEQ      :INFIELD                                   ; Within field, done

            CROUT                                               ; Skip down a line
            LDX      #-1                                        ; Go back and space out
            BNE      :FILL2                                     ; to data start point

:INFIELD    TWOSPACE                                            ; Skip 2 Spaces
            RTS

*=================================================
*      Routine Name: PRINTFMT
*
*  Input Parameters: X, A = Format String Location
*
* Output Parameters: None
*
* Purpose: Show File Packing Method
*=================================================

PRINTFMT    STX      TEMP                                       ; Save String Address
            STA      TEMP+1
            LDX      #8                                         ; Printing 8 Bytes
            LDY      #0
:PRLOOP     LDA      (TEMP),Y
            JSR      COUT
            INC      TEMP
            BNE      :NEXT
            INC      TEMP+1
:NEXT       DEX
            BNE      :PRLOOP

            SPACE                                               ; Skip 2 Spaces
            RTS

*=================================================
*      Routine Name: REVTWO
*
*  Input Parameters: (Address) Of Number
*
* Output Parameters: Reversed Number At (Address)
*
* Purpose: Reverse A Two Byte Word
*=================================================

REVTWO      STACK    WORD                                       ; Reverse A Number
            JSR      GETWORD
            LDY      #0
            LDA      (TEMP),Y                                   ; Get Low Byte
            PHA                                                 ; Save It
            INY
            LDA      (TEMP),Y                                   ; Get High Byte
            DEY
            STA      (TEMP),Y                                   ; Save At Low Byte
            INY
            PLA                                                 ; Get Back Low Byte
            STA      (TEMP),Y                                   ; Save At High Byte
            RTS

*=================================================
*      Routine Name: REVFOUR
*
*  Input Parameters: (Address) Of Long Word
*
* Output Parameters: Reversed Number At (Address)
*
* Purpose: Reverse A Long Word
*=================================================

REVFOUR     STACK    WORD                                       ; Reverse A Number
            JSR      GETWORD                                    ; Get Location Of Long Word
REVFOURX    LDY      #0
            LDA      (TEMP),Y                                   ; Get Low Byte
            PHA                                                 ; Save It
            LDY      #3
            LDA      (TEMP),Y                                   ; Get High Byte
            LDY      #0
            STA      (TEMP),Y                                   ; Save It At Low Byte
            PLA                                                 ; Get Back Byte
            LDY      #3
            STA      (TEMP),Y                                   ; Save It At High Byte
            DEY                                                 ; Get Mid High Byte
            LDA      (TEMP),Y
            PHA                                                 ; Save It
            DEY                                                 ; Get Mid Low Byte
            LDA      (TEMP),Y
            INY                                                 ; Save It At Mid High Byte
            STA      (TEMP),Y
            PLA                                                 ; Get Byte Back
            DEY                                                 ; Save It At Mid Low Byte
            STA      (TEMP),Y
            RTS

*=================================================
*      Routine Name: PDOSDATE, MSDATE
*
*  Input Parameters: (Address) Of Date
*
* Output Parameters: None
*
* Purpose: Print A ProDOS Or MS-DOS Date
*=================================================
* Date Format, MS-DOS/ProDOS
*-------------------------------------------------
* DATE  15-9   Year (0-99)
*        8-5   Month
*        4-0   Day (All Zeroes Means No Date)
*=================================================

PDOSDATE    LDA      #0
            HEX      2C
MSDATE      LDA      #80
            STA      GSYR
            STACK    WORD                                       ; Save Pointers
            JSR      GETWORD
            LDY      #1                                         ; Get Byte With Day
            LDA      (TEMP),Y
            DEY
            ORA      (TEMP),Y
            BNE      :DO_DATE

            JMP      NODATE

:DO_DATE    JSR      FIXDT
            LDY      #0
            LDA      (TEMP),Y
            AND      #$1F                                       ; Clear All But Day
            CONVDEC  DSTR                                       ; Make It ASCII
            LDY      #1                                         ; Get Byte W/Year & Month
            LDA      (TEMP),Y
            LSR                                                 ; Make Year, Month In C
            PHA                                                 ; Save Year
            DEY
            LDA      (TEMP),Y                                   ; Get Rest Of Month
            ROR                                                 ; Shift In C
            LSR                                                 ; Shift Down
            LSR
            LSR
            LSR
            JSR      MONTH                                      ; Do Month Text
            PLA                                                 ; Restore Year
            CLC
            ADC      GSYR
            CONVDEC  DSTR                                       ; Make It ASCII
            JMP      PRDATE

*=================================================
*      Routine Name: PDOSTIME
*
*  Input Parameters: (Address) Of Time
*
* Output Parameters: None
*
* Purpose: Print A ProDOS Time
*=================================================
* Time Format, ProDOS
*-------------------------------------------------
* TIME  15-8   Hours (Military)
*        7-0   Minutes
*=================================================

PDOSTIME    STACK    WORD
            JSR      GETWORD                                    ; Get Time Location
            LDY      #0
            LDA      (TEMP),Y                                   ; Get Minutes
            CONVDEC  TSTR+3                                     ; Convert To ASCII
            LDY      #1                                         ; Get Hours
            LDA      (TEMP),Y
            CONVDEC  TSTR                                       ; Convert To ASCII
            TWOSPACE
            LDX      #0                                         ; Print The Time
:PTIMEL1    LDA      TSTR,X
            JSR      COUT
            INX
            CPX      #5
            BNE      :PTIMEL1
            TWOSPACE                                            ; No Seconds
            TWOSPACE                                            ; Space To Next Field
            RTS

*=================================================
*      Routine Name: MSTIME
*
*  Input Parameters: (Address) Of Time
*
* Output Parameters: None
*
* Purpose: Print A MS-DOS Time
*=================================================
* Time Format, MS-DOS
*-------------------------------------------------
* TIME  15-11  Hours (Military)
*       10-5   Minutes
*        4-0   Seconds
*=================================================

MSTIME      STACK    WORD
            JSR      GETWORD                                    ; Get Time Location
            LDY      #0
            LDA      (TEMP),Y                                   ; Get Low Byte
            AND      #$1F                                       ; Mask For Seconds
            CONVDEC  TSTR+6                                     ; Convert To ASCII
            LDY      #0
            LDA      (TEMP),Y                                   ; Get Partial Minutes
            STA      TEMP2
            INY
            LDA      (TEMP),Y                                   ; Get Rest Of Minutes/Hours
            LSR                                                 ; Make Full Byte
            ROR      TEMP2
            LSR
            ROR      TEMP2
            LSR
            ROR      TEMP2
            CONVDEC  TSTR                                       ; Convert Hours To ASCII
            LDA      TEMP2                                      ; Fix Up Minutes
            LSR
            LSR
            CONVDEC  TSTR+3                                     ; Convert To ASCII
            JMP      PRTIME                                     ; Print The Time

NODATE      LDX      #8                                         ; Print No Date
:LOOP       LDA      NODATETX,X
            STA      DSTR,X
            DEX
            BPL      :LOOP
            JMP      PRDATE

*=================================================
*      Routine Name: GSTIME
*
*  Input Parameters: (Address) Of Time
*
* Output Parameters: None
*
* Purpose: Print A //GS Time
*=================================================

GSTIME      STACK    WORD
            JSR      GETWORD                                    ; Get Location Of Time
            JSR      FIXDT
            LDY      #0                                         ; Get Seconds
            LDA      (TEMP),Y
            CONVDEC  TSTR+6                                     ; Convert To ASCII
            LDY      #1                                         ; Get Minutes
            LDA      (TEMP),Y
            CONVDEC  TSTR+3                                     ; Convert To ASCII
            LDY      #2                                         ; Get Hours
            LDA      (TEMP),Y
            CONVDEC  TSTR                                       ; Convert To ASCII
PRTIME      LDX      #0                                         ; Print The Time
:PTIMEL     LDA      TSTR,X
            JSR      COUT
            INX
            CPX      #9
            BNE      :PTIMEL

            TWOSPACE                                            ; Space To Next Field
            RTS

*=================================================
*      Routine Name: GSDATE
*
*  Input Parameters: (Address) Of Date
*
* Output Parameters: None
*
* Purpose: Print A //GS Date
*=================================================

GSDATE      STACK    WORD
            JSR      GETWORD                                    ; Get Location Of Date
            LDY      #0                                         ; Get Year
            LDA      (TEMP),Y
            CONVDEC  DSTR+7                                     ; Convert To ASCII
            LDY      #1                                         ; Get Day
            LDA      (TEMP),Y
            CLC
            ADC      #1
            CONVDEC  DSTR                                       ; Convert To ASCII
            LDY      #2                                         ; Get Month
            LDA      (TEMP),Y
            CLC
            ADC      #1
            JSR      MONTH                                      ; Convert To Text
PRDATE      LDX      #0                                         ; Print Date
:PDATEL     LDA      DSTR,X
            JSR      COUT
            INX
            CPX      #9
            BNE      :PDATEL

            TWOSPACE                                            ; Space To Next Field
            RTS

*=================================================
*      Routine Name: SECONDS
*
*  Input Parameters: (Address) Of Seconds
*
* Output Parameters: None
*
* Purpose: Calculate Date/Time From
*          Seconds From 1904
*=================================================

SECONDS     STACK    WORD
            JSR      GETWORD                                    ; Get Location Of Seconds
            JSR      REVFOURX                                   ; Move In Seconds
            LDY      #3
:MVIN       LDA      (TEMP),Y                                   ; Copy Seconds
            STA      SECS,Y
            DEY
            BPL      :MVIN

* Divide by seconds in 4 years, save leap years

            DIVIDE   LONG;SEC4YEAR;LONG;SECS;WORD;LYEARS

            JSR      SECREM                                     ; Get Remaining Seconds

* Calculate remaining years
* Divide by seconds in 1 year, save years

:CONT       DIVIDE   LONG;SECYEAR;LONG;SECTEMP;BYTE;YRSAVE

:DODAYS     JSR      SECREM                                     ; Get Remeining Seconds

* Calculate days in year
* Divide by seconds in 1 day, save days

            DIVIDE   LONG;SECDAY;LONG;SECTEMP;LONG;SECTEMP

            LDX      #28                                        ; Calculate Month/Day
            LDA      YRSAVE                                     ; Set Days In February
            CMP      #3                                         ; Actual Leap Year?
            BNE      :FEB28                                     ; Nope
            INX                                                 ; Make It Leap Year
:FEB28      STX      MTHLENS+1
            LDX      #-1                                        ; Init Month Pointer
            LDY      SECTEMP+1                                  ; Get Day Number
            LDA      SECTEMP
:FNDMTH     INX                                                 ; Increment Pointer
            SEC                                                 ; Subtract First Month
            SBC      MTHLENS,X
            BCS      :FNDMTH                                    ; More Left, Do Again

            DEY                                                 ; Still More
            BPL      :FNDMTH

            ADC      MTHLENS,X                                  ; Add Day Back In
            STA      GSDAY                                      ; Save Proper Day
            STX      GSMNTH                                     ; Save Proper Month
            JSR      SECREM                                     ; Get Remaining Seconds

* Calculate hours
* Divide by seconds in 1 hour, save hours

            DIVIDE   WORD;SECHOUR;LONG;SECTEMP;BYTE;GSHR

            JSR      SECREM                                     ; Get Remaining Seconds

* Calculate minutes
* Divide by seconds in 1 minute, save minutes

            DIVIDE   BYTE;SECMIN;LONG;SECTEMP;BYTE;GSMIN

            LDA      REMAIN                                     ; Left Over Is Seconds
            STA      GSSEC
            ASL      LYEARS                                     ; Year4 = Year4 * 4
            ROL      LYEARS+1
            ASL      LYEARS
            ROL      LYEARS+1
            CLC                                                 ; Add In Left Over Years
            LDA      LYEARS                                     ; LYEARS = LYEARS + YRSAVE + 4
            ADC      YRSAVE                                     ; Add In Left Over Years
            ADC      #4                                         ; For GS Date
            STA      GSYR

* Calculate day of week
* Days = seconds / seconds in 1 day
* Weekday = days mod 7

            DIVIDE   LONG;SECDAY;LONG;SECS;LONG;SECTEMP
            DIVIDE   BYTE;SEVEN;LONG;SECTEMP;LONG+$80;SECTEMP

            CLC                                                 ; Weekday = Weekday + Friday
            LDA      SECTEMP
            ADC      #6
            STA      SECTEMP

* Weekday = days mod 7

            DIVIDE   LONG-1;SEVEN;LONG;SECTEMP;BYTE+$80;GSWDAY

            JSR      GSDATE
            DA       GSYR
            JSR      GSTIME
            DA       GSSEC
            RTS

*=================================================
*      Routine Name: MONTH
*
*  Input Parameters: A = Month Number, 0..11
*
* Output Parameters: None
*
* Purpose: Put Month Text Into Date String
*=================================================

MONTH       SEC
            SBC      #1
            CMP      #12
            BLT      :MTHOK

            LDA      #12
:MTHOK      STA      TEMP2+1
            ASL
            CLC
            ADC      TEMP2+1
            TAX
            LDA      MTHTXT,X
            STA      DSTR+3
            LDA      MTHTXT+1,X
            STA      DSTR+4
            LDA      MTHTXT+2,X
            STA      DSTR+5
            RTS

FIXDT       LDA      #'-'
            STA      DSTR+2
            STA      DSTR+6
            LDA      #':'
            STA      TSTR+2
            STA      TSTR+5
            RTS

*=================================================
*      Routine Name: BINDEC8
*
*  Input Parameters: A = Binary Number
*
* Output Parameters: A, X = ASCII Text Of Number
*
* Purpose: Convert Binary To ASCII Decimal
*=================================================

BINDEC8     LDY      #0                                         ; Start 10's Counter
:BIN8       CMP      #10
            BLT      :BIN8A                                     ; Less Than 10, Were Done

            SBC      #10                                        ; Minus 10
            INY                                                 ; Add 1 To The 10's Counter
            BNE      :BIN8                                      ; Loop

:BIN8A      ADC      #'0'                                       ; Make 1's Into Text
            TAX                                                 ; Save
            TYA
            ADC      #'0'                                       ; Make 10's Into Text
            RTS                                                 ; Were Done

*=================================================
*      Routine Name: DIVIDE
*
*  Input Parameters: (Length), (Address) Of First Number
*                    (Length), (Address) Of Second Number
*                    (Length), (Address) Of Destination
*
* Output Parameters: Result In Destination
*
* Purpose: Divide 2 Numbers
*=================================================

DO_DIV      STACK    BYTE+WORD+BYTE+WORD+BYTE+WORD
            JSR      GETDATA                                    ; Get The Data
            BIT      RESLEN                                     ; Is It MOD?
            BPL      :DODIV                                     ; Nope

            JSR      MOD                                        ; Execute The MOD
            JMP      GETRES

:DODIV      JSR      DIVIDE2                                    ; Execute The DIVIDE
GETRES      LDA      RESLEN                                     ; Move The Result
            AND      #$7F
            TAY
:MVRES      LDA      RESULT,Y
            STA      (TEMP2),Y
            DEY
            BPL      :MVRES

            RTS

*=================================================
*      Routine Name: DO_ADD
*
*  Input Parameters: (Length), (Address) Of First Number
*                    (Length), (Address) Of Second Number
*                    (Length), (Address) Of Destination
*
* Output Parameters: Result In Destination
*
* Purpose: Add 2 Numbers
*=================================================

DO_ADD      STACK    BYTE+WORD+BYTE+WORD+BYTE+WORD
            JSR      GETDATA                                    ; Get Information
            CLC                                                 ; Add The Numbers
            LDA      NUMB
            ADC      DATA
            STA      RESULT
            LDA      NUMB+1
            ADC      DATA+1
            STA      RESULT+1
            LDA      NUMB+2
            ADC      DATA+2
            STA      RESULT+2
            LDA      NUMB+3
            ADC      DATA+3
            STA      RESULT+3
            JMP      GETRES

*=================================================
*      Routine Name: DO_SUB
*
*  Input Parameters: (Length), (Address) Of First Number
*                    (Length), (Address) Of Second Number
*                    (Length), (Address) Of Destination
*
* Output Parameters: Result In Destination
*
* Purpose: Subtract 2 Numbers
*=================================================

DO_SUB      STACK    BYTE+WORD+BYTE+WORD+BYTE+WORD
            JSR      GETDATA                                    ; Get The Information
            SEC                                                 ; Subtract The Numbers
            LDA      DATA
            SBC      NUMB
            STA      RESULT
            LDA      DATA+1
            SBC      NUMB+1
            STA      RESULT+1
            LDA      DATA+2
            SBC      NUMB+2
            STA      RESULT+2
            LDA      DATA+3
            SBC      NUMB+3
            STA      RESULT+3
            JMP      GETRES

*=================================================
*      Routine Name: ADDXAY2
*
*  Input Parameters: X, A, (Address) Of Destination
*
* Output Parameters: Result In Destination
*
* Purpose: Add X And A To Destination
*=================================================

ADDXAY2     STA      TEMP2
            LDA      #$80                                       ; Flag Only 2 Bytes
            STA      TEMP2+1
            BNE      ADDXAY1

*=================================================
*      Routine Name: ADDXAY
*
*  Input Parameters: X, A, Y, (Address) Of Destination
*
* Output Parameters: Result In Destination
*
* Purpose: Add X, Y And A To Destination
*=================================================

ADDXAY      STA      TEMP2
            LDA      #0                                         ; Flag 3 Bytes
            STA      TEMP2+1
ADDXAY1     STACK    WORD
            TYA
            PHA
            LDY      #1
            LDA      (TEMP),Y
            PHA
            INY
            LDA      (TEMP),Y
            STA      TEMP+1
            PLA
            STA      TEMP
            CLC
            TXA
            LDY      #0
            ADC      (TEMP),Y
            TAX
            INY
            LDA      TEMP2
            ADC      (TEMP),Y
            STA      TEMP2
            INY
            PLA
            BIT      TEMP2+1
            BPL      :XAY1

            ADC      #0
            JMP      :XAY0

:XAY1       ADC      (TEMP),Y
:XAY0       TAY
            LDA      TEMP2
            RTS

*=================================================
* 32 Bit Divide And Mod
* NUMB Is First Number (Divide By)
* DATA Is Second Number
* On Exit, RESULT Holds The Result
*=================================================

DIVIDE2     CLC                                                 ; Flag Divide Only
            HEX      B0                                         ; Skip SEC
MOD         SEC
            PHP
            LDA      NUMB
            ORA      NUMB+1
            ORA      NUMB+2
            ORA      NUMB+3
            BNE      :DO_DIV1

            PLP
            RTS

:DO_DIV1    LDA      #0
            STA      REMAIN
            STA      REMAIN+1
            STA      REMAIN+2
            STA      REMAIN+3
            CLC
            LDX      #32                                        ; 32 Bits To Do
:DO_DIV2    ROL      DATA                                       ; Shift Up The Carry Bit
            ROL      DATA+1
            ROL      DATA+2
            ROL      DATA+3
            ROL      REMAIN
            ROL      REMAIN+1
            ROL      REMAIN+2
            ROL      REMAIN+3
            SEC
            TXA
            PHA
            LDX      #0
            LDY      #3
:SBCLUP     LDA      REMAIN,X                                   ; Check For Remainder > Divisor
            SBC      NUMB,X
            STA      SAVE,X
            INX
            DEY
            BPL      :SBCLUP
            PLA
            TAX
            BCC      :DO_DIV3                                   ; Nope, Skip Subtract

            LDA      SAVE                                       ; Allow Subtract To Take Place
            STA      REMAIN
            LDA      SAVE+1
            STA      REMAIN+1
            LDA      SAVE+2
            STA      REMAIN+2
            LDA      SAVE+3
            STA      REMAIN+3
:DO_DIV3    DEX
            BNE      :DO_DIV2

            ROL      DATA                                       ; Shift In Quotient
            ROL      DATA+1
            ROL      DATA+2
            ROL      DATA+3
            PLP
            BCS      MOVEMOD

            LDA      DATA
            STA      RESULT
            LDA      DATA+1
            STA      RESULT+1
            LDA      DATA+2
            STA      RESULT+2
            LDA      DATA+3
            STA      RESULT+3
            RTS

MOVEMOD     LDA      REMAIN
            STA      RESULT
            LDA      REMAIN+1                                   ; Get Remainder
            STA      RESULT+1
            LDA      REMAIN+2
            STA      RESULT+2
            LDA      REMAIN+3
            STA      RESULT+3
            RTS

*=================================================
*      Routine Name: DO_DEC
*
*  Input Parameters: (Flag) Fill To 8 Bytes
*                    (Byte) Length Of Data
*                    (Word) Location Of Data
*
* Output Parameters: None
*
* Purpose: Print 32 Bit Number
*=================================================

DO_DEC      STACK    BYTE+BYTE+WORD
            JSR      ZERODATA
            LDY      #1
            LDA      (TEMP),Y
            STA      TEMP3
            INY
            LDA      (TEMP),Y
            PHA
            INY
            LDA      (TEMP),Y
            STA      TEMP2
            INY
            LDA      (TEMP),Y
            STA      TEMP2+1
            PLA
            TAY
:SMV        LDA      (TEMP2),Y
            STA      NUMB,Y
            DEY                                                 ; Count Up
            BPL      :SMV

            SED                                                 ; Do It In Decimal Mode
            LDY      #32                                        ; Doing 32 Bits
:DEC2       ASL      NUMB                                       ; Add In Bit
            ROL      NUMB+1
            ROL      NUMB+2
            ROL      NUMB+3
            LDA      DATA+1
            ADC      DATA+1
            STA      DATA+1
            LDA      DATA+2
            ADC      DATA+2
            STA      DATA+2
            LDA      DATA+3
            ADC      DATA+3
            STA      DATA+3
            LDA      DATA+4
            ADC      DATA+4
            STA      DATA+4
            LDA      DATA+5
            ADC      DATA+5
            STA      DATA+5
            ROL      DATA+6
            DEY                                                 ; Do Next Bit
            BNE      :DEC2

            CLD                                                 ; No More Decimal Mode
            LDY      #10                                        ; Max Of 10 Characters
:DEC3       LDA      DATA+6                                     ; Get Byte
            AND      #$F                                        ; Remove Top Nibble
            BNE      :GOODNUM                                   ; If Not 0, Stuff It

            BIT      DATA+7                                     ; Leading Zero?
            BPL      :SKIP0                                     ; Yes, Skip It

:GOODNUM    DEC      DATA+7                                     ; Flag No Leading Zero
            CLC
            ADC      #'0'                                       ; Make It Ascii
            LDX      DATA+8                                     ; Get Pointer
            STA      RESULT+1,X                                 ; Store It
            INC      DATA+8                                     ; Bump Pointer
:SKIP0      LDX      #3                                         ; Shift In Next Nibble
:DEC4       ASL      DATA+1
            ROL      DATA+2
            ROL      DATA+3
            ROL      DATA+4
            ROL      DATA+5
            ROL      DATA+6
            DEX
            BPL      :DEC4

            DEY                                                 ; Count Down Digit
            BMI      :DECDONE                                   ; Finished...
            BNE      :DEC3                                      ; Branch If Not Last Digit

            STX      DATA+7                                     ; Force Zero If Zero
            BEQ      :DEC3                                      ; Do It..

:DECDONE    LDA      DATA+8                                     ; Save Length Of Number
            STA      RESULT
            SEC                                                 ; Calculate Leading Spaces
            LDA      TEMP3
            BMI      :PRINT                                     ; If Negative, Just Print
            SBC      RESULT
            BEQ      :PRINT                                     ; If None, Go Print It

            TAY
            LDA      #' '
:LDSPCS     JSR      COUT                                       ; Print A Space
            DEY
            BNE      :LDSPCS

:PRINT      LDX      #0                                         ; Print The Number
            LDY      RESULT
:PRDEC      LDA      RESULT+1,X
            JSR      COUT
            INX
            DEY
            BNE      :PRDEC

            RTS

*=================================================
*      Routine Name: PERCENT
*
*  Input Parameters: (Byte) Length Of First Number
*                    (Word) Location Of First Number
*                    (Byte) Length Of Second Number
*                    (Word) Location Of Second Number
*
* Output Parameters: None
*
* Purpose: Print A Percentage
*=================================================

DO_PER      STACK    BYTE+WORD+BYTE+WORD
            JSR      ZERODATA
            LDX      #7                                         ; Clear Out Any Old Data
            LDA      #0
:ZSECS      STA      SECS,X
            DEX
            BPL      :ZSECS

            LDY      #1
            LDA      (TEMP),Y                                   ; Get First Number & Length
            PHA
            INY
            LDA      (TEMP),Y
            STA      TEMP2
            INY
            LDA      (TEMP),Y
            STA      TEMP2+1
            PLA
            TAY                                                 ; Copy It
:MVNUMB     LDA      (TEMP2),Y
            STA      SECS,Y
            DEY
            BPL      :MVNUMB

            LDY      #4                                         ; Get Second Number & Length
            LDA      (TEMP),Y
            PHA
            INY
            LDA      (TEMP),Y
            STA      TEMP3
            INY
            LDA      (TEMP),Y
            STA      TEMP3+1
            PLA
            INY                                                 ; Copy It
:MVDATA     LDA      (TEMP3),Y
            STA      SECTEMP,Y
            DEY
            BPL      :MVDATA

            JSR      :MUL10                                     ; Multiply First Number
            JSR      :MUL10                                     ; By 100

* Divide result by second number

            DIVIDE   LONG;SECTEMP;LONG;SECS;LONG;SECTEMP

            LDA      SECTEMP+3                                  ; Is Number > 100?
            ORA      SECTEMP+2
            ORA      SECTEMP+1
            BNE      :GR100                                     ; Yes
            LDA      SECTEMP
            CMP      #100+1
            BLT      :LESS100                                   ; Nope
:GR100      LDA      #100                                       ; Reset To 100
            STA      SECTEMP
            LDA      #'>'                                       ; Tell Them It's Greater
            HEX      2C
:LESS100    LDA      #' '                                       ; Not Greater
            JSR      COUT
            DECOUT   3;WORD;SECTEMP                             ; Show The Number
            PRINT    '%'                                        ; And The Percent Sign
            RTS

:MUL10      LDA      SECS                                       ; Save Current Value
            STA      SAVE
            LDA      SECS+1
            STA      SAVE+1
            LDA      SECS+2
            STA      SAVE+2
            LDA      SECS+3
            STA      SAVE+3
            JSR      :MUL2                                      ; Multiply By 2
            JSR      :MUL2                                      ; Multiply By 2 ( * 4 )
            ADD      LONG;SECS;LONG;SAVE;LONG;SECS              ; Add In Original ( * 5 )
:MUL2       ASL      SECS                                       ; Multiply By 2 ( * 10 )
            ROL      SECS+1
            ROL      SECS+2
            ROL      SECS+3
            RTS

SECREM      LDA      REMAIN                                     ; Copy Remainder To
            STA      SECTEMP                                    ; Seconds Temporary
            LDA      REMAIN+1
            STA      SECTEMP+1
            LDA      REMAIN+2
            STA      SECTEMP+2
            LDA      REMAIN+3
            STA      SECTEMP+3
            RTS

*=================================================
*      Routine Name: ADDSTK
*
*  Input Parameters: A - Bytes To Skip
*
* Output Parameters: Call Address In TEMP
*
* Purpose: Get Call Address And Skip Bytes
*=================================================

ADDSTK      PHA                                                 ; Save A And X
            TXA
            PHA
            TSX                                                 ; Get Stack Pointer
            CLC
            LDA      $105,X                                     ; Get Call Address
            STA      TEMP                                       ; Save It
            ADC      $102,X                                     ; Add In Bytes To Skip
            STA      $105,X                                     ; Save It Back
            LDA      $106,X                                     ; Handle High Byte
            STA      TEMP+1
            ADC      #0
            STA      $106,X
            PLA
            TAX
            PLA
            RTS

*=================================================
*      Routine Name: ZERODATA
*
*  Input Parameters: None
*
* Output Parameters: None
*
* Purpose: Zero Out Data Area
*=================================================

ZERODATA    PHA                                                 ; Zero Numeric Data
            TXA
            PHA
            LDX      #27
            LDA      #0
:ZLOOP      STA      NUMB,X
            DEX
            BPL      :ZLOOP
            PLA
            TAX
            PLA
            RTS

*=================================================
*      Routine Name: GETDATA
*
*  Input Parameters: (TEMP) Data To Read
*
* Output Parameters: Source1, Source2 And Destination
*
* Purpose: Get Math Parameters
*=================================================

GETDATA     JSR      ZERODATA
            LDY      #1                                         ; Handle First Number
            LDA      (TEMP),Y                                   ; Get Length Byte
            PHA
            INY                                                 ; Copy Address
            LDA      (TEMP),Y
            STA      TEMP2
            INY
            LDA      (TEMP),Y
            STA      TEMP2+1
            PLA
            TAY                                                 ; Copy Data
:NUMLUP     LDA      (TEMP2),Y
            STA      NUMB,Y
            DEY
            BPL      :NUMLUP

            LDY      #4                                         ; Handle Second Number
            LDA      (TEMP),Y                                   ; Get Length Byte
            PHA
            INY                                                 ; Copy Address
            LDA      (TEMP),Y
            STA      TEMP2
            INY
            LDA      (TEMP),Y
            STA      TEMP2+1
            PLA
            TAY                                                 ; Copy Data
:MVDATA     LDA      (TEMP2),Y
            STA      DATA,Y
            DEY
            BPL      :MVDATA

            LDY      #7                                         ; Point To Destination
            LDA      (TEMP),Y
            STA      RESLEN                                     ; Save Destination Size
            INY
            LDA      (TEMP),Y
            STA      TEMP2                                      ; Save Destination Address
            INY
            LDA      (TEMP),Y
            STA      TEMP2+1
            RTS

*=================================================
*      Routine Name: GETWORD
*
*  Input Parameters: (TEMP) = Location Of Word
*
* Output Parameters: TEMP = Word
*
* Purpose: Get 2 Byte Word At Temp Into Temp
*=================================================

GETWORD     LDY      #1                                         ; Transfer Address To Temp
            LDA      (TEMP),Y
            TAX
            INY
            LDA      (TEMP),Y
            STX      TEMP
            STA      TEMP+1
            RTS

*=================================================
*      Routine Name: PD_ACCES
*
*  Input Parameters: (Word) Location Of Access Byte
*
* Output Parameters: None
*
* Purpose: Print File Locked Flag
*=================================================

PD_ACCES    STACK    WORD
            JSR      GETWORD
            LDY      #0                                         ; Get Access Byte
            LDA      (TEMP),Y
            AND      #$C3                                       ; Clear Extra Bits
            CMP      #$C3                                       ; Any Function Locked?
            BEQ      NOTLOCKD                                   ; Nope, Unlocked
LOCKED      LDA      #"*"                                       ; Flag Locked
            HEX      2C
NOTLOCKD    LDA      #" "                                       ; Flag Unlocked
            JMP      COUT

*=================================================
*      Routine Name: MAC_ACS, MS_ACS
*
*  Input Parameters: (Word) Location Of Flags
*
* Output Parameters: None
*
* Purpose: Print File Locked Flag
*=================================================

M_ACS       STACK    WORD
            JSR      GETWORD
            LDY      #0                                         ; Get Attribute Byte
            LDA      (TEMP),Y
            LSR                                                 ; Locked Bit In Carry
            BCC      NOTLOCKD
            BCS      LOCKED

*=================================================
*      Routine Name: PRTYPE
*
*  Input Parameters: (Word) Location Of File Type
*
* Output Parameters: None
*
* Purpose: Print File Type Code
*=================================================

PRTYPE      STACK    WORD                                       ; Skip Address
            JSR      GETWORD                                    ; Get Word
            LDY      #0
            LDA      (TEMP),Y                                   ; Get File Type
            LDX      #<:TYPES                                   ; Point To File Types
            STX      TEMP
            LDX      #>:TYPES
            STX      TEMP+1
            LDY      #0                                         ; Index Is Zero
            PHA                                                 ; Save Type
:LOOP       PLA                                                 ; Restore Type
            CMP      (TEMP),Y                                   ; Same Type?
            BEQ      :SHOWTYP                                   ; Yes, Show It
            PHA                                                 ; Save Type
            CLC                                                 ; Add 4 To Skip Last Type
            LDA      #4
            ADC      TEMP
            STA      TEMP
            BCC      :ITEMP
            INC      TEMP+1
:ITEMP      LDA      (TEMP),Y                                   ; Check For End Of List
            BNE      :LOOP                                      ; Not End, Do Next
            LDA      #'$'
            JSR      COUT
            PLA                                                 ; Throw Out Type
            JSR      PRBYTE
            JMP      :DONE

:SHOWTYP    INY                                                 ; Print First Character
            LDA      (TEMP),Y
            JSR      COUT
            INY                                                 ; Print Second Character
            LDA      (TEMP),Y
            JSR      COUT
            INY                                                 ; Print Last Character
            LDA      (TEMP),Y
            JSR      COUT
:DONE       SPACE
            TWOSPACE                                            ; Space to finish
            RTS

:TYPES      DB       0
            ASC      'UNK'
            DB       1
            ASC      'BAD'
            DB       2
            ASC      'PCD'
            DB       3
            ASC      'PTX'
            DB       4
            ASC      'TXT'
            DB       5
            ASC      'PDA'
            DB       6
            ASC      'BIN'
            DB       7
            ASC      'FNT'
            DB       8
            ASC      'FOT'
            DB       9
            ASC      'BA3'
            DB       $A
            ASC      'DA3'
            DB       $B
            ASC      'WPF'
            DB       $C
            ASC      'SOS'
            DB       $F
            ASC      'DIR'
            DB       $10
            ASC      'RPD'
            DB       $11
            ASC      'RPI'
            DB       $12
            ASC      'AFD'
            DB       $13
            ASC      'AFM'
            DB       $14
            ASC      'AFR'
            DB       $15
            ASC      'SCL'
            DB       $16
            ASC      'PFS'
            DB       $19
            ASC      'ADB'
            DB       $1A
            ASC      'AWP'
            DB       $1B
            ASC      'ASP'
            DB       $20
            ASC      'TDM'
            DB       $2A
            ASC      '8SC'
            DB       $2B
            ASC      '8OB'
            DB       $2C
            ASC      '8IC'
            DB       $2D
            ASC      '8LD'
            DB       $2E
            ASC      '8PC'
            DB       $42
            ASC      'FTD'
            DB       $50
            ASC      'GWP'
            DB       $51
            ASC      'GSS'
            DB       $52
            ASC      'GDB'
            DB       $53
            ASC      'DRW'
            DB       $54
            ASC      'GDP'
            DB       $55
            ASC      'HMD'
            DB       $56
            ASC      'EDU'
            DB       $57
            ASC      'STN'
            DB       $58
            ASC      'HLP'
            DB       $59
            ASC      'COM'
            DB       $5A
            ASC      'CFG'
            DB       $5B
            ASC      'ANM'
            DB       $5C
            ASC      'MUM'
            DB       $5D
            ASC      'ENT'
            DB       $5E
            ASC      'DVU'
            DB       $6B
            ASC      'BIO'
            DB       $6D
            ASC      'TDR'
            DB       $6E
            ASC      'PRE'
            DB       $6F
            ASC      'HDV'
            DB       $A0
            ASC      'WP '
            DB       $AB
            ASC      'GSB'
            DB       $AC
            ASC      'TDF'
            DB       $AD
            ASC      'BDF'
            DB       $B0
            ASC      'SRC'
            DB       $B1
            ASC      'OBJ'
            DB       $B2
            ASC      'LIB'
            DB       $B3
            ASC      'S16'
            DB       $B4
            ASC      'RTL'
            DB       $B5
            ASC      'EXE'
            DB       $B6
            ASC      'PIF'
            DB       $B7
            ASC      'TIF'
            DB       $B8
            ASC      'NDA'
            DB       $B9
            ASC      'CDA'
            DB       $BA
            ASC      'TOL'
            DB       $BB
            ASC      'DVR'
            DB       $BC
            ASC      'LDF'
            DB       $BD
            ASC      'FST'
            DB       $BF
            ASC      'DOC'
            DB       $C0
            ASC      'PNT'
            DB       $C1
            ASC      'PIC'
            DB       $C2
            ASC      'ANI'
            DB       $C3
            ASC      'PAL'
            DB       $C5
            ASC      'OOG'
            DB       $C6
            ASC      'SCR'
            DB       $C7
            ASC      'CDV'
            DB       $C8
            ASC      'FON'
            DB       $C9
            ASC      'FND'
            DB       $CA
            ASC      'ICN'
            DB       $D5
            ASC      'MUS'
            DB       $D6
            ASC      'INS'
            DB       $D7
            ASC      'MDI'
            DB       $D8
            ASC      'SND'
            DB       $DB
            ASC      'DBM'
            DB       $E0
            ASC      'LBR'
            DB       $E2
            ASC      'ATK'
            DB       $EE
            ASC      'R16'
            DB       $EF
            ASC      'PAS'
            DB       $F0
            ASC      'CMD'
            DB       $F1
            ASC      'UT1'
            DB       $F2
            ASC      'UT2'
            DB       $F3
            ASC      'UT3'
            DB       $F4
            ASC      'UT4'
            DB       $F5
            ASC      'UT5'
            DB       $F6
            ASC      'UT6'
            DB       $F7
            ASC      'UT7'
            DB       $F8
            ASC      'UT8'
            DB       $F9
            ASC      'OS '
            DB       $FA
            ASC      'INT'
            DB       $FB
            ASC      'IVR'
            DB       $FC
            ASC      'BAS'
            DB       $FD
            ASC      'VAR'
            DB       $FE
            ASC      'REL'
            DB       $FF
            ASC      'SYS'
            DB       0

