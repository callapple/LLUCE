            LST   OFF
            TR
            TR    ADR
            TTL   'LLUCE - Global page'
            PAG
*-------------------------------
* History:
*
* 11/07/89 AMW
* 1. Added history section
* 2. Added segment titles
* 3. Renamed this section to GLOBALS
*
* 11/10/89 AMW
* Added AppleShare flag
*
* 11/14/89 AMW
* Added ProDOS entry point vector
*
* 11/21/89 AMW
* Moved startup filename to LLUCE
*
* 11/23/89 AMW
* Added CRC16 location
*
* 11/28/89 AMW
* Added time display flag
*-------------------------------

; to be created by the config program
NODENUM     DB    0
            DW    SEG_NAME
MODULE      DW    0

VERSION     DDB   version

STPCHR      DB    ' '                    ; stop message char
NXTCHR      DB    'N'                    ; next message char

WIDTH       DB    4                      ; index for default
            DB    32,40,64,80

FILTLOC     DB    0

WWFLAG      DB    -1                     ; word-wrap flag for editor

REFNUM      DB    0
MSGREF      DB    0
            DW    FBUF2

SHWTXT      DB    0
SHWTRC      DB    0                      ; show program trace

TOCONST     DW    159

EDLOC       DW    EDBUF
EDITLEN     DW    EDBUF+EBUFEND
EDMEMORY    DB    0                      ; if negative, buffer in aux
FILTFLAG    DB    1

ASHARE      DB    0                      ; AppleShare flag
PDOSVEC     DA    0

CRC         DA    0

TIMEDISP    DB    $80                    ; 0=24 hour, $80=12 hour

                                         ; modem(0) commands in LLUCE
M_QUIT      DB    'Q'-ctrl               ; quit
M_LOGIN     DB    'G'-ctrl               ; enter
M_ANSWER    DB    'A'-ctrl               ; answer

            DS    $840-*

FLNAME      DS    $40                    ; last filename used
SEG_NAME    DS    $40                    ; start up segment pathname
SYSPFX      DS    $40                    ; system files prefIX

