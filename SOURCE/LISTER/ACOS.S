**************************************************
*                                                *
*                Archive Lister                  *
*                                                *
**************************************************
            DATE
*-------------------------------------------------

            LST    OFF
            LSTDO  OFF
            TR
            TR     ADR
Y           =      1
y           =      1
N           =      0
n           =      0
LISTOBJ     KBD    'List This Source? (Y/N)'
LISTSYM     KBD    'List Symbol Table? (Y/N)'
            ORG    $9E00
            DSK    /RAM5/PROLIST

            TTL    'ACOS - Archive Lister'
            DO     LISTOBJ
            LST
            FIN

ACOS        =      1
Cr          =      $D

Read        =      $CA
Set_Mark    =      $CE
Get_Mark    =      $CF

TEMP        =      0
TEMP2       =      2
TEMP3       =      $13
INTOUT      =      $34

BYTE        =      1
WORD        =      2
LADR        =      3
LONG        =      4

HDRBUF      =      $200
REFNUM      =      $3CD
DATABUF     =      $AA00

MLI         =      $BF00

SET80COL    =      $C001
PAGE1       =      $C054
PAGE2       =      $C055
LORES       =      $C056
HIRES       =      $C057

********************************
*                              *
*        Entry Points          *
*                              *
********************************

GOBCOM      =      $386
MOVNAME     =      $38F
COUT        =      $3A4
OPEN        =      $3AD
CLOSE       =      $3B0

            PUT    MACROS
            PUT    MAIN
            PUT    DATA
LOWSUBS     =      *
            ORG    $2000
            PUT    ACU
            PUT    APL
            PUT    BLU
            PUT    SHK
            PUT    LU
            PUT    ARC
            PUT    LZH
            PUT    ZIP
            PUT    ZOO
            PUT    MAC
            LST    OFF
            DO     LISTSYM
            LST
            FIN
            TTL    'Lister - Symbol Table'
            PAG

