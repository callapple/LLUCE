*=================================================
* ZOO  (MS-DOS)
*=================================================
* FILE FORMAT
*-------------------------------------------------
*
*    Master Header
*         File 1 Header
*              File 1
*         File 2 Header
*              File 2
*         .
*         .
*         File N Header
*              File N
* EOF
*
*-------------------------------------------------
* MASTER HEADER
*-------------------------------------------------
*
            DUM      HDRBUF
ZOO_VER     DS       20                           ; ZOO Version Number
            HEX      DCA7C4FD                     ; File Signature
ZOO_FHDR    ADRL     0                            ; Pointer To 1St Header
            ADRL     0                            ; ?
            DB       0                            ; Version Making Archive
            DB       0                            ; Minimum Version Needed To Extract
; 34 Bytes
*
*-------------------------------------------------
* FILE HEADER
*-------------------------------------------------
*
ZOO_ID2     HEX      DCA7C4FD                     ; Signature
            DB       0                            ; ?
ZOO_MTHD    DB       0                            ; Compression Method
*
* ZOO_MTHD   0   Stored    No Compression Used
*            1   Crunched  Packing, LZW, 4K Buffer
*                            Variable Length (9-12 Bits)
*
ZOO_NHDR    ADRL     0                            ; Nxt Hdr Ofst Frm Start Of ZOO File
ZOO_THDR    ADRL     0                            ; Offset Of This Hdr
ZOO_MDAT    DW       0                            ; Last Mod File Date (MS-DOS)
ZOO_MTIM    DW       0                            ; Last Mod File Time (MS-DOS)
            DW       0                            ; CRC-16
ZOO_OSIZ    ADRL     0                            ; Uncompressed Size
ZOO_NSIZ    ADRL     0                            ; Compressed Size
            DW       0                            ; Version That Made This File
            DW       0                            ; Minimum Version Needed To Extract
ZOO_DEL     DB       0                            ; 1 If File Deleted From Archive
            ADRL     0                            ; Pointer To Comment, 0 If None
            DB       0                            ; Length Of Comment
ZOO_FNAM    DS       13                           ; Filename
            DEND                                  ; 50 Bytes
*
*-------------------------------------------------
* POSITIONING IN FILE
*-------------------------------------------------
*
* Beginning Of 1St File Header = Begining Of File + ZOO_FHDR
*       Or
*                             = Begining Of File + 34
*
* Begining Of File Data = Begining Of File Header + 50
*
* Begining Of Next File = Begining Of File + ZOO_NHDR
*
* Begining Of File Comment = Begining Of File Header + ZOO_CPNT
*
DO_ZOO      LDX      #0                           ; Print ZOO Header
:PRTZOO     LDA      ZOO_VER,X
            CMP      #' '
            BLT      :DONE
            JSR      COUT
            INX
            CPX      #20
            BNE      :PRTZOO

:DONE       MSDOS    1                            ; Print List Header
            PUTMARK  ZOO_FHDR                     ; Set Mark To First File Hdr
:ZOOLOOP    READ     #50;ZOO_ID2                  ; Read File Header
            LDA      ZOO_DEL                      ; Was It Deleted?
            BNE      :SKIPENT                     ; Yes, Skip It

            LDX      #3                           ; Check For Valid Entry
:TESTID     LDA      :HDRID,X
            CMP      ZOO_ID2,X
            BNE      :ZOODONE
            DEX
            BPL      :TESTID

            LDA      #0                           ; Check For Data In Record
            LDX      #3
:TESTENT    ORA      ZOO_THDR,X
            DEX
            BPL      :TESTENT

            CMP      #0                           ; Any Data?
            BEQ      :ZOODONE                     ; Nope

            JSR      :SHOWENT

:SKIPENT    BIT      INTOUT
            BMI      :ZOODONE

            LDA      ZOO_NHDR                     ; Any More Records?
            ORA      ZOO_NHDR+1
            ORA      ZOO_NHDR+2
            BEQ      :ZOODONE                     ; Nope, Done

            PUTMARK  ZOO_NHDR                     ; Point To Next Header
            JMP      :ZOOLOOP                     ; Do Another

:ZOODONE    RTS

:SHOWENT    SPACE                                 ; No Attribute Byte
; Print File Name
            CSTRING  #0;ZOO_FNAM
            MDATE    ZOO_MDAT                     ; Print Date
            MTIME    ZOO_MTIM                     ; Print Time
; Print Uncompressed Size
            DECOUT   8;LONG;ZOO_OSIZ
            TWOSPACE
            LDA      ZOO_MTHD                     ; Print Compression Method
            CMP      #1+1                         ; Valid method?
            BLT      :METHOK                      ; Yes

            LDA      #2                           ; Make it unknown
:METHOK     ASL
            TAY
            LDX      :METHODS,Y
            LDA      :METHODS+1,Y
            JSR      PRINTFMT
; Print Compression Percentage
            PERCENT  LONG;ZOO_NSIZ;LONG;ZOO_OSIZ
            CROUT                                 ; Next Line
            RTS

:METHODS    DA       STORE
            DA       CRUNCH
            DA       UNK

:HDRID      HEX      DCA7C4FD

