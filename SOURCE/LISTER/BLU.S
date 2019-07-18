*=================================================
* BINARY ][
*=================================================
* FILE FORMAT
*-------------------------------------------------
*
*    File Header 1
*         File 1
*    File Header 2
*         File 2
*    .
*    .
*    File Header N
*         File N
* EOF
*
*-------------------------------------------------
* FILE HEADER
*-------------------------------------------------
*
            DUM       HDRBUF
BLU_ID1     DB        10                   ; ID Bytes
BLU_ID2     ASC       'GL'                 ; Authors Initials - Gary Little
BLU_ACS     DB        0                    ; ProDOS 8 Access Code
BLU_FTYP    DB        0                    ; ProDOS 8 File Type
BLU_AUX     DA        0                    ; ProDOS 8 Auxiliary Type
            DB        0                    ; ProDOS 8 Storage Type
            DW        0                    ; Size Of File In 512-Byte Blocks
BLU_MDAT    DW        0                    ; Date Of Modification
BLU_MTIM    DW        0                    ; Time Of Modification
            DW        0                    ; Date Of Creation
            DW        0                    ; Time Of Creation
            DB        2                    ; ID Byte
            DS        1                    ; Reserved
BLU_EOF     DS        3                    ; End-Of-File (EOF) Position
BLU_FNLN    DB        0                    ; Length Of Filename Or Partial Pathname
BLU_FNAM    DS        15                   ; ASCII Filename Or Partial Pathname
; If The Filename Is A Partial Pathname
; It Will Overwrite The Following
; 2 Segments For Native Filename
            DB        0                    ; Length Of Native Filename
            DS        48                   ; ASCII Native Filename
            DS        21                   ; Reserved, Must Be Zero
            DW        0                    ; GS/OS Aux Type (High Word)
            DB        0                    ; GS/OS Access Code (High Byte)
            DB        0                    ; GS/OS File Type Code (High Byte)
            DB        0                    ; GS/OS Storage Type Code (High Byte)
            DW        0                    ; GS/OS Size Of File In Blocks (High Word)
BLU_GEOF    DB        0                    ; GS/OS EOF Position (High Byte)
            ADRL      0                    ; Disk Space Needed (512 Byte Blocks)
            DB        0                    ; Operating System Type
*
*  0  ProDOS Or SOS
*  1  DOS 3.3
*  2  Reserved
*  3  DOS 3.2 Or DOS 3.1
*  4  Apple II Pascal
*  5  Macintosh MFS
*  6  Macintosh HFS
*  7  Macintosh XL
*  8  Apple CP/M
*  9  Reserved
*  A  MS-DOS
*  B  High Sierra (CD-ROM)
*  C  ISO 9660 (CD-ROM)
*  D  AppleShare
*
            DW        0                    ; Native File Type Code
            DB        0                    ; Phantom File Flag
*
*  0   [Generic]
*  1   Point-To-Point
*  2   Tele-Master Comm Sys
*  3   ProTERM
*  4   Modem MGR
*  5   CommWorks
*  6   MouseTalk
* 100  Option List
*
            DB        0                    ; Data Flags
*
*  7  Data Is Compressed (SQUeezed)
*  6  Data Is Encrypted
*  0  File Is Sparse/Packed
*
* SQUEEZED  Huffman Squeeze. The Filename Will Have '.QQ'
*           Appended. The First 16 Bytes Of The File Are
*           The Original Filename Length And Filename, The
*           Next 14 Bytes Are Identical In Form And Content
*           To The Apple GetInfo Results And The Bytes 3 -
*           16 Of The Binary ][ Header. The Rest Of The
*           File Is Squeezed With Packing.
*
BLU_VER     DB        0                    ; Binary II Version Number
BLU_RECS    DB        0                    ; Number Of Files To Follow
            DEND
*
*-------------------------------------------------
* POSITIONING IN FILE
*-------------------------------------------------
*
* Beginning Of File Data = Beginning Of File Header + 128
*
* Next File Header = Beginning Of File Header + 128 + BLU_FBLK
*       Or
*                  = Beginning Of File Data + BLU_FBLK
*
DO_BLU      JSR       :RDHDR               ; Read Next Entry
            JSR       TESTLIBR
            CMP       #4                   ; Invalid Library?
            BGE       :BLU                 ; Yes

            PHA
            LDX       #128                 ; Reset Mark To 128
            LDA       #0
            TAY
            JSR       SET_POS
            JSR       SHOWSTR              ; Show In Wrapper
            ASC       'Archive In Binary // Wrapper'0D8D
            PLA
            ASL
            TAX
            LDA       :LIBSUBS,X
            STA       TEMP
            LDA       :LIBSUBS+1,X
            STA       TEMP+1
            JMP       (TEMP)

:LIBSUBS    DA        DO_ACU2              ; 0
            DA        DO_APL2              ; 1
            DA        DO_APL2              ; 2
            DA        DO_SHK2              ; 3

:BLU        ZEROSEEK                       ; Re-Read The Header
            JSR       :RDHDR
            PRINT     'Binary // V'
            DECOUT    $80;BYTE;BLU_VER     ; Show Version Number
            PRINT     '  Records: '
            LDA       BLU_RECS             ; Get Records Following
            STA       LASTMARK             ; +1 To Count Current
            INC       LASTMARK
            DECOUT    $80;BYTE;LASTMARK
            APPLE                          ; No Compression
:BLULOOP    JSR       :SHOWENT             ; Show The Entry
            LDA       BLU_RECS
            BEQ       :BLUDONE

            LDA       BLU_FTYP             ; Was It A Directory?
            CMP       #$F
            BEQ       :DIRDONE             ; Yes, Skip Length Add

            CLC
            LDA       BLU_EOF              ; Round Up To Next 128 Byte
            BEQ       :DO_EOF

            ASL
            PHP
            LDA       #0
            ROR
            PLP
            CLC
            BEQ       :DO_EOF

            ADC       #$80
:DO_EOF     STA       LASTMARK
            LDA       BLU_EOF+1
            ADC       #0
            STA       LASTMARK+1
            LDA       BLU_EOF+2
            ADC       #0
            STA       LASTMARK+2
            JSR       GET_MARK             ; Get Current Mark
            JSR       ADDXAY               ; Add In Record Size
            DA        LASTMARK
            JSR       SET_POS
:DIRDONE    JSR       :RDHDR               ; Read In Header
            BCS       :BLUDONE             ; If Error, Done

            LDA       BLU_ID1              ; Check Header Id's
            CMP       #$A
            BNE       :BLUDONE

            LDA       BLU_ID2
            CMP       #'G'
            BNE       :BLUDONE

            LDA       BLU_ID2+1
            CMP       #'L'
            BEQ       :BLULOOP

:BLUDONE    RTS

:SHOWENT    P_ACCESS  BLU_ACS              ; Show File Access
; Show Filename
            PSTRING   0;BLU_FNLN;BLU_FNAM
            FILETYPE  BLU_FTYP             ; Show File Type
            PDATE     BLU_MDAT
            PTIME     BLU_MTIM             ; And Time
            AUXTYPE   BLU_AUX              ; Show Aux Type
            LDA       BLU_EOF              ; Move All Of EOF
            STA       LASTMARK
            LDA       BLU_EOF+1
            STA       LASTMARK+1
            LDA       BLU_EOF+2
            STA       LASTMARK+2
            LDA       BLU_GEOF
            STA       LASTMARK+3
            DECOUT    8;LONG;LASTMARK      ; Show Size
            CROUT
            RTS

:RDHDR      READ      #128;BLU_ID1         ; Read In Header
            RTS

