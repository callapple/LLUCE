*=================================================
* ARJ    (MS-DOS)
*=================================================
* FILE FORMAT
*-------------------------------------------------
*
*    File Header 1
*         File data 1
*    File Header 2
*         File data 2
*    .
*    .
*    File Header N
*         File data N
* EOF
*
*-------------------------------------------------
* MASTER HEADER
*-------------------------------------------------
*
            DUM    DATABUF
ARJ_ID      DW     $EA60       ;header id (main and local file)
;0xEA60 or 60000U
BASHDRSZ    DW     0           ;basic header size
;(from 'first_hdr_size' thru
;'comment' below)
; = first_hdr_size +
; strlen(filename) + 1 +
; strlen(comment) + 1
; = 0 if end of archive
HDRSIZE     DB     0           ; size up to and including 'extra data'
ARJVER      DB     0           ; archiver version number
ARJXVER     DB     0           ; minimum version to extract
ARJOS       DB     0           ; host OS
*
*  Operating system types
*
ARJMSDOS    =      0
ARJPRIM     =      1
ARJUNIX     =      2
ARJAMIGA    =      3
ARJMAC      =      4
*
ARJFLAGS    DB     0           ; arj flags
*
*  Flag bits
*
GARBLED     =      %00000001   ; passworded file
VOLUME      =      %00000100   ; continued file to next volume
EXFILE      =      %00001000   ; file starting position field
PATHSYM     =      %00010000   ; path translated ("\" changed to "/")
*
ARJMETH     DB     0           ; compression method
*
* Compression methods
*
ARJSTOR     =      0           ; stored
ARJLZW1     =      1           ; LZW/HUF-1
ARJLZW2     =      2           ; LZW/HUF-2
ARJLZW3     =      3           ; LZW/HUF-3
ARJLZW4     =      4           ; LZW/PLUNA
*
ARJFTYPE    DB     0           ; file type
*
*  File type codes
*
ARJBIN      =      0           ; binary
ARJTEXT     =      1           ; 7-bit text
ARJCOMHD    =      2           ; comment header
ARJDIR      =      3           ; directory
ARJVOL      =      4           ; volume label
*
ARJRES      DB     0           ; reserved
ARJDATE     ADRL   0           ; date time modified
ARJCOMP     ADRL   0           ; compressed size
ARJSIZE     ADRL   0           ; original size
ARJFCRC     ADRL   0           ; file's CRC
ARJSPEC     DW     0           ; filespec position in filename
ARJACCS     DW     0           ; file access mode
ARJDATA     DW     0           ; host data (not used)
ARJEXTRA    =      *           ; extra data
*
*EXTFILST ADRL 0          ; bytes for extended file
*                         ; starting position when used
*                         ; present when EXTFILE is set
*
*ARJFNAME CSTR ''         ; filename (null-terminated string)
*ARJCOMM  CSTR ''         ; comment  (null-terminated string)
*
*BASCRC  ADRL  0          ; basic header CRC
*
*HDR1SZ  DW    0          ; 1st extended header size (0 if none)
*HDR1    DS    HDR1SZ     ; 1st extended header (not used)
*HDR1CRC ADRL  0          ; 1st extended header's CRC
*                         ; not present when 0 extended header size
            DEND
*
*-------------------------------------------------
* POSITIONING IN FILE
*-------------------------------------------------
*
* First File Header     = Beginning Of File
*
* Beginning of filename = Beginning of header + 2 +
*                         HDRSIZE + (4 * EXTFILE)
*
* Beginning of comment  = Beginning of filename +
*                         len(FILENAME) + 1
*
* Begining Of Data      = Beginning Of comment +
*                         len(COMMENT) + 1 + 4
*
* Next File Header      = Begining of Data + ARJCOMP
*
DO_ARJ      ZEROSEEK
            JSR    SHOWSTR
            PRINT  'ARC'
            MSDOS              ; Show List Header
:ARJLOOP

