*=================================================
* ARC/PAK (MS-DOS)
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
            DUM      HDRBUF
ARC_ID      DB       26
ARC_MTHD    DB       0                            ; Method
*
* ARC_MTHD  0  Stored    No Compression Used
*           1  Packed    Repeated Running Length Encoding (RLE)
*           2  Squeezed  Huffman Encoding
*           3  Crunched  LZW, 4K, 12 Bit
*           4  Crunched  Packing, LZW, 4K, 12 Bit
*           5  Crunched  Packing, LZW, 4K, 9-12 Bit
*           6  Squashed  LZW, 8K, 9-13 Bits
*           7  Crushed   Packing, LZW, 8K, 2-13 Bit (PAK 1.0)
*           8  Distill   Dynamic Huffman, 8K (PAK 2.0)
*
ARC_FNAM    DS       12                           ; Filename
            DB       0
ARC_NSIZ    ADRL     0                            ; Compressed Size
ARC_DATE    DW       0                            ; File Date (MSDOS)
ARC_TIME    DW       0                            ; File Time (MSDOS)
            DW       0                            ; File CRC-16
ARC_OSIZ    ADRL     0                            ; Uncompressed Size
            DEND
*
*-------------------------------------------------
* POSITIONING IN FILE
*-------------------------------------------------
*
* Beginning Of File Data = Beginning Of File Header + 29
*
* Next File Header = Beginning Of File Header + 29 + ARC_NSIZ
*      Or
*                  = Beginning Of File Data + ARC_NSIZ
*
*ARC
*
DO_ARC      ZEROSEEK
            PRINT    'ARC'
            MSDOS    1                            ; Show List Header
:ARCLOOP    BIT      INTOUT
            BMI      :ARCDONE

            LDX      #28                          ; Zero Out Header Buffer
            LDA      #0
:0LOOP      STA      ARC_ID,X
            DEX
            BPL      :0LOOP

            READ     #2;ARC_ID                    ; Read In Next Header
            LDA      ARC_ID                       ; Test Entry Validity
            CMP      #$1A
            BNE      :ARCDONE

            LDA      ARC_MTHD                     ; Check For Valid Method
            BEQ      :ARCDONE

            CMP      #9
            BLT      :SHOWENT

:ARCDONE    RTS

:SHOWENT    LDY      #23
            CMP      #1
            BEQ      :RDHDR

            LDY      #27
:RDHDR      JSR      DO_READ
            DA       ARC_FNAM
            SPACE                                 ; No Attribute Byte
            CSTRING  0;ARC_FNAM                   ; Print The Filename
            MDATE    ARC_DATE                     ; Print File Date
            MTIME    ARC_TIME                     ; Print File Time
            LDA      ARC_MTHD
            CMP      #1
            BNE      :SIZE1

; Print Old Storage Size
            DECOUT   8;LONG;ARC_NSIZ
            JMP      :SIZE2

; Print Original Size
:SIZE1      DECOUT   8;LONG;ARC_OSIZ
:SIZE2      TWOSPACE
            LDA      ARC_MTHD                     ; Show Packing Method
            CMP      #8+1                         ; Valid format?
            BLT      :METHOK                      ; Yes
            LDA      #9                           ; Make it unknown
:METHOK     ASL
            TAY
            LDX      :METHODS,Y
            LDA      :METHODS+1,Y
            JSR      PRINTFMT
            LDA      ARC_MTHD
            CMP      #1
            BNE      :DOPER

            PRINT    ' 100%'
            JMP      :NOCMP

; Print Compaction Percent
:DOPER      PERCENT  LONG;ARC_NSIZ;LONG;ARC_OSIZ
:NOCMP      CROUT                                 ; Next Line
            JSR      GET_MARK
            JSR      ADDXAY                       ; Add Compressed Code Size
            DA       ARC_NSIZ
            JSR      SET_POS                      ; Point To Next Entry
            JMP      :ARCLOOP                     ; Do Next Entry

:METHODS    DA       STORE
            DA       PACK
            DA       SQU
            DA       CRUNCH
            DA       CRUNCH
            DA       CRUNCH
            DA       SQUASH
            DA       CRUSH
            DA       DISTILL
            DA       UNK

