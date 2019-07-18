*=================================================
* LU (MS-DOS)
*=================================================
* FILE FORMAT
*-------------------------------------------------
*
*    Master Header
*    File Header 1
*    File Header 2
*    .
*    .
*    File Header N
*    File Data 1
*    File Data 2
*    .
*    .
*    File Data N
* EOF
*
*-------------------------------------------------
* MASTER HEADER
*-------------------------------------------------
*
            DUM       HDRBUF
LUMSTAT     DB        0                                       ; Always 0
            ASC       '        '                              ; Always Blank
            ASC       '   '                                   ; Always Blank
            DW        0                                       ; Always 0
            DW        0                                       ; Never 0
            DW        0                                       ; CRC-16
            DW        0                                       ; Create Date
            DW        0                                       ; Modified Date
            DW        0                                       ; Create Time
            DW        0                                       ; Modified Time
            DB        0                                       ; Should Be 0
            DS        5                                       ; Filler
            DEND
*
*-------------------------------------------------
* FILE HEADER
*-------------------------------------------------
*
            DUM       LUMSTAT
LUSTAT      DB        0                                       ; 00 File Status
LUFNAME     ASC       '        '                              ; 01 Filename
            ASC       '   '                                   ; 09 Extension
            DW        0                                       ; 0C Always 0
LULEN       DW        0                                       ; 0E Record Length, Blocks
            DW        0                                       ; 10 CRC-16
LUCDATE     DW        0                                       ; 12 Create Date
            DW        0                                       ; 14 Modified Date
LUCTIME     DW        0                                       ; 16 Create Time
            DW        0                                       ; 18 Modified Time
LUPAD       DB        0                                       ; 1A Should Be 0
            DS        5                                       ; 1B Filler
            DEND

            DUM       LUMSTAT
            DB        0                                       ; 00 Record Status
ALUFNAME    ASC       '        '                              ; 01 Filename
            ASC       '   '                                   ; 09 Extension
            DW        0                                       ; 0C Index To Record, Blocks
            DW        0                                       ; 0E Record Length
ALUACS      DB        0                                       ; 10 File Access
ALUFTYP     DB        0                                       ; 11 File Type
ALUAUX      DW        0                                       ; 12 Aux Type
ALUMDAT     DW        0                                       ; 14 Modified Date
ALUMTIM     DW        0                                       ; 16 Modified Time
ALUEOF      DS        3                                       ; 18 File EOF
            DS        5                                       ; 1B Filler
*
ALUNFNM     DS        1                                       ; 20 New Filename
            DEND
*
*-------------------------------------------------
* POSITIONING IN FILE
*-------------------------------------------------
*
* Beginning Of File Data = Beginning Of Library
*                          + (128 * MAST_LEN)
*
* Next File Header = Current File Header + 32
*
*LU Or ALU
*
DO_LU       ZEROSEEK
            LDA       #0
            STA       LIBTYPE
            LDA       #$A2                                    ; Apple // LU?
            CMP       HDRBUF+62
            BNE       :LU                                     ; Nope

            CMP       HDRBUF+63
            BNE       :LU                                     ; Nope

            DEC       LIBTYPE
            PRINT     'Apple '
:LU         PRINT     'Library Utility'
:START      JSR       :RD_DIR                                 ; Read In Library Header
            LDA       LIBTYPE
            BEQ       :MSLU

            APPLE                                             ; Show Apple Header
            JMP       :LULOOP

:MSLU       MSDOS                                             ; Show MS-DOS Header
:LULOOP     BIT       INTOUT                                  ; Interrupted?
            BMI       :QUIT                                   ; Yes

            JSR       :RD_DIR                                 ; Read In Directory Entry
            LDA       LUSTAT                                  ; Active Entry?
            BNE       :TST_ENT                                ; Yes, Go Print It

            BIT       LIBTYPE
            BPL       :DO_LU

            JSR       :SHOWALU                                ; Show ALU Entry
            JMP       :LULOOP

:DO_LU      JSR       :SHOW_LU                                ; Show LU Entry
            JMP       :LULOOP

:TST_ENT    BIT       LIBTYPE                                 ; Check For Deleted Entry
            BPL       :LUEND?

            CMP       #-1                                     ; ALU Deleted Flag
            JMP       :END?

:LUEND?     CMP       #-2                                     ; LU Deleted Flag
:END?       BEQ       :LULOOP                                 ; Entry Is Deleted

:QUIT       RTS                                               ; Not Deleted, Must Be End

:SHOW_LU    LDY       #7                                      ; Move Main Filename
            LDX       #0
:FIXNAME    LDA       LUFNAME,X
            STA       ALUNFNM,X
            INX
            DEY
            BPL       :FIXNAME
            LDA       #'.'                                    ; Insert The '.'
            STA       ALUNFNM,X
            LDY       #2                                      ; Move The Extension
:FIXNM2     LDA       LUFNAME,X
            STA       ALUNFNM+1,X
            INX
            DEY
            BPL       :FIXNM2
            SPACE                                             ; No Attribute Byte
            PSTRING   #0;#12;ALUNFNM                          ; Show The Name
            MDATE     LUCDATE                                 ; Show MS-DOS Date/Time
            MTIME     LUCTIME
            LDA       LULEN+1                                 ; Size = Blocks * 128
            STA       LASTMARK+1
            LDA       #0
            STA       LASTMARK+2
            STA       LASTMARK+3
            LDA       LULEN
            LDX       #7
:MUL128     ASL
            ROL       LASTMARK+1
            ROL       LASTMARK+2
            DEX
            BNE       :MUL128
            STA       LASTMARK
; Size = Size - Pad
            SUB       BYTE;LUPAD;LADR;LASTMARK;LADR;LASTMARK
            DECOUT    8;LONG;LASTMARK                         ; Show Entry Length
            CROUT
            RTS

:SHOWALU    P_ACCESS  ALUACS                                  ; Show File Access
            PSTRING   #0;#11;ALUFNAME                         ; Show The Name
            FILETYPE  ALUFTYP                                 ; Show File Type
            PDATE     ALUMDAT                                 ; Show ProDOS Date/Time
            PTIME     ALUMTIM
            AUXTYPE   ALUAUX                                  ; Show Aux Type
; Show Entry Length
            DECOUT    8;LADR;ALUEOF
            CROUT
            RTS

:RD_DIR     READ      #32;LUSTAT                              ; Read In A Chunk
            RTS

