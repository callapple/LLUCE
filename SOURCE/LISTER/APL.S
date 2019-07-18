*=================================================
* APPLESINGLE  (APPLE)
* APPLEDOUBLE  (APPLE)
*=================================================
* Master Header
*-------------------------------------------------
*
            DUM       HDRBUF
APL_MAG     ADRL      0                                    ; Magic Number Field
;   Single (00051600)
;   Double (00051607)
APL_VER     ADRL      0                                    ; Version Number
;   (00010000)
APL_OS      DS        16                                   ; ID String
; 'ProDOS          '
; 'Macintosh       '
; 'MS-DOS          '
; 'Unix            '
; 'VAX VMS         '
APL_RECS    DA        0                                    ; Number Of Entries In File
*
*-------------------------------------------------
* File Header
*-------------------------------------------------
*
APL_E_ID    ADRL      0                                    ; Entry ID
*
* APL_E_ID   1    Data Fork
*            2    Resource Fork
*            3    Real Name
*                   (The File's Name In The Home File System)
*            4    Comment*
*                   (Standard Macintosh Comment)
*            5    Icon, B&W*
*                   (Standard Macintosh Black And White Icon)
*            6    Icon, Color*
*                   (Reserved For Macintosh Color Icon)
*            7    File Info
*                   (File Attributes, Dates, Etc.)
*            9    Finder Info*
*                   (Standard Macintosh Finder Info)
*          100    Data File Pathname
*
APL_OFS     ADRL      0                                    ; Offset From File Start To Entry Data
APL_ELEN    ADRL      0                                    ; Length Of Entry
*
* Standard Entries: See SINENTID
*
* ProDOS: SINENTID = 7
*
APL_CDAT    DA        0                                    ; Creation Date, ProDOS 8 Format.
            DA        0                                    ; Creation Time, ProDOS 8 Format.
APL_MDAT    DA        0                                    ; Modification Date, ProDOS 8 Format.
APL_MTIM    DA        0                                    ; Modification Time, ProDOS 8 Format.
APL_ACS     DA        0                                    ; The File's Access.
; This May Be Used Directly In ProDOS 16
; Or GS/OS Calls; Only The Low Byte Is
; Significant To ProDOS 8.
APL_FTYP    DA        0                                    ; The File Type Of The Original File.
; Only The Low Byte Is Significant To ProDOS 8.
APL_ATYP    ADRL      0                                    ; The Auxiliary Type Of The Original File.
            DEND                                           ; Only The Low Word Is Significant To ProDOS 8.
*
* Macintosh:
*
            DUM       APL_CDAT
            ADRL      0                                    ; Seconds From Jan 1, 1904
;   To File Create Time
APL_MMDT    ADRL      0                                    ; Seconds From Jan 1, 1904
;   To File Last Mod Time
            ADRL      0                                    ; Seconds From Jan 1, 1904
;   To File Last Backup Time
APL_ATR     ADRL      0                                    ; Flags.  Bit0 = Locked, Bit1 = Protected
            DEND
*
* MS-DOS:
*-------------------------------------------------
* MS-DOS Attribute Flags:
*
* Bit 7: Not Used
*     6: Not Used
*     5: File Not Archived
*     4: Subdirectory File
*     3: Volume Label
*     2: System File
*     1: Hidden File
*     0: File Is Read-Only
*-------------------------------------------------

            DUM       APL_CDAT
APL_MSDT    ADRL      0                                    ; MS-DOS Format Modification Date.
APL_MSAT    DA        0                                    ; MS-DOS Attributes.
            DEND
*
* Unix:
*
            DUM       APL_CDAT
            ADRL      0                                    ; Unix Creation Date And Time.
            ADRL      0                                    ; Unix Time
;   Last Time This File Was Used.
            ADRL      0                                    ; Unix Time
;   Last Time This File Was Modified.
            DEND
*
* The Finder Info Entry: SINENTID = 9
*
            DUM       APL_CDAT
            DS        16                                   ; IoFlFndrInfo
            DS        16                                   ; ExtioFlFndrInfo
            DEND

            DUM       DATABUF
APL_FNAM    DS        64
            DEND
*
DO_APL      ZEROSEEK
DO_APL2     GETMARK   START
            READ      26;APL_MAG                           ; Read In Master Header
            LDA       APL_MAG+3
            BNE       :DO_DBL

            PRINT     'AppleSingle V'
            JMP       :DO_VER

:DO_DBL     PRINT     'AppleDouble V'
:DO_VER     REVLONG   APL_VER
            DECOUT    $80;1;APL_VER+2
            PRINT     '.'
            DECOUT    $80;1;APL_VER
            PRINT     '  OS: '
            JSR       :CHECKID
            LDA       OSID
            BPL       :OSOK

            JSR       SHOWSTR
            ASC       'Unknown'0D0D
            ASC       'OPERATION ABORTED'0D8D
            RTS

:OSOK       PSTRING   0;#16;APL_OS                         ; Show Operating System
            LDX       #3                                   ; Zero Any Old Length
            LDA       #0
:ZLOOP      STA       CDLEN,X
            DEX
            BPL       :ZLOOP

:ENTLOOP    READ      12;APL_E_ID                          ; Read In Entry
            CPX       #7                                   ; Is It An Info Entry?
            BEQ       :INFO                                ; Yes

            CPX       #100                                 ; Data Filename?
            BEQ       :DFILE                               ; Yes

            CPX       #4                                   ; Is It Not Needed?
            BGE       :COUNTDN                             ; Throw It Out
            DEX                                            ; Data Thread?
            BEQ       :ADDLEN                              ; Yes
            DEX                                            ; Resource Thread?
            BEQ       :ADDLEN                              ; Yes

            LDX       #<FNOFS                              ; Save Filename Info
            LDA       #>FNOFS
            JSR       :REVINFO
            JMP       :COUNTDN

:INFO       LDX       #<INFOFS                             ; Save File Info Info
            LDA       #>INFOFS
            JSR       :REVINFO
            JMP       :COUNTDN

:DFILE      LDX       #<DATOFS                             ; Save Data Filename Info
            LDA       #>DATOFS
            JSR       :REVINFO
            JMP       :COUNTDN

:ADDLEN     REVLONG   APL_ELEN                             ; Add In Thread Length
            ADD       LONG;CDLEN;LONG;APL_ELEN;LONG;CDLEN
:COUNTDN    LDA       APL_RECS+1                           ; Count Down Threads
            BNE       :DEC1
            DEC       APL_RECS
:DEC1       DEC       APL_RECS+1
            LDA       APL_RECS+1                           ; More Threads?
            ORA       APL_RECS
            BNE       :ENTLOOP                             ; Yes

:RDSTUFF    LDA       APL_MAG+3                            ; Doing AppleDouble?
            BEQ       :DO_SNG                              ; Nope

            LDA       DATOFS                               ; Any Data Filename
            ORA       DATOFS+1
            ORA       DATOFS+2
            BEQ       :DO_SNG

            LDX       DATOFS                               ; Point To Data File Name
            LDA       DATOFS+1
            LDY       DATOFS+2
            JSR       :SETMARK
            READ      DATLEN;APL_FNAM                      ; Read In Pathname
            JSR       SHOWSTR                              ; Show It
            DB        Cr,Cr
            DCI       'Data File Pathname: '
            PSTRING   $80;APL_FNAM;APL_FNAM+1
:DO_SNG     LDX       FNOFS                                ; Point To Filename
            LDA       FNOFS+1
            LDY       FNOFS+2
            JSR       :SETMARK
            READ      FNLEN;APL_FNAM                       ; Read In Filename
            LDX       INFOFS                               ; Point To Information
            LDA       INFOFS+1
            LDY       INFOFS+2
            JSR       :SETMARK
            READ      INFLEN;APL_CDAT                      ; Read In Information
            LDX       OSID                                 ; ProDOS Data?
            BNE       :ID1                                 ; Nope

            APPLE                                          ; No Compression
            REVWORD   APL_ACS
            P_ACCESS  APL_ACS                              ; Print File's Access
; Print Filename
            PSTRING   0;FNLEN;APL_FNAM
            REVWORD   APL_FTYP
            FILETYPE  APL_FTYP                             ; Show File Type
            REVWORD   APL_MDAT                             ; Show ProDOS Date/Time
            REVWORD   APL_MTIM
            PDATE     APL_MDAT
            PTIME     APL_MTIM
            REVWORD   APL_ATYP
            AUXTYPE   APL_ATYP                             ; Show aux type
            JMP       :DO_SIZE

:ID1        DEX                                            ; Macintosh Info?
            BNE       :ID2                                 ; Nope

            MSDOS                                          ; No Compression
            REVWORD   APL_ATR
            M_ACCESS  APL_ATR                              ; Print File's Access
; Print Filename
            PSTRING   0;FNLEN;APL_FNAM
            MACDT     APL_MMDT                             ; Show Macintosh Date/Time
            JMP       :DO_SIZE

:ID2        DEX                                            ; MS-DOS Info?
            BNE       :ID3                                 ; Nope

            MSDOS                                          ; No Compression
            REVWORD   APL_MSAT
            M_ACCESS  APL_MSAT
            REVWORD   APL_MSDT                             ; Show MS-DOS Date/Time
            REVWORD   APL_MSDT+2
            MDATE     APL_MSDT
            MTIME     APL_MSDT+2
            JMP       :DO_SIZE

:ID3        JSR       SHOWSTR                              ; All Others, No Date/Time
            ASC       ' Filename'
            DB        1,14,' '
            ASC       'Size'0D
            ASC       ' '
            DB        1,18,'-'
            ASC       '  '
            DB        1,8,'-'
            DB        $D," "
; Print Filename
            PSTRING   0;FNLEN;APL_FNAM
:DO_SIZE    DECOUT    8;WORD;CDLEN                         ; Show Code Length
            CROUT
            RTS

:REVINFO    PHA                                            ; Move Entry Info
            TXA
            PHA
            REVLONG   APL_OFS
            REVLONG   APL_ELEN
            PLA
            STA       TEMP
            PLA
            STA       TEMP+1
            LDY       #7
:LOOP       LDA       APL_OFS,Y
            STA       (TEMP),Y
            DEY
            BPL       :LOOP
            RTS

:CHECKID    LDX       #0                                   ; Find OS Type
            STX       OSID
            LDY       #0
:CKLOOP     LDA       OSID                                 ; Get System ID Number
            ASL                                            ; Multiply By 16
            ASL
            ASL
            ASL
            TAX
:TESTIT     LDA       APL_OS,Y                             ; Compare Characters
            CMP       :OSNAMES,X
            BNE       :NEXTOS                              ; Not This One

            INX                                            ; Check Next Character
            INY
            CPY       #16                                  ; Done With This Item?
            BNE       :TESTIT                              ; Nope, Continue

            RTS

:NEXTOS     INC       OSID
            LDA       OSID
            CMP       #5
            BLT       :CKLOOP

            LDA       #-1
            STA       OSID
            RTS

:SETMARK    JSR       ADDXAY                               ; Set Mark, Adding In Start
            DA        START
            JMP       SET_POS

:OSNAMES    ASC       'ProDOS          '
            ASC       'Macintosh       '
            ASC       'MS-DOS          '
            ASC       'Unix            '
            ASC       'VAX VMS         '

