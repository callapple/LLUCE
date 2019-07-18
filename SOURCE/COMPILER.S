********************************
*                              *
*    LLUCE Segment Compiler    *
*                              *
********************************
* Copyright 1986-1993 By L&L Productions
*-------------------------------
* Version 1.0 Final 4
*-------------------------------
* This Follows Apple's Version Types.
* First Byte Is Main Version #.
* Second Byte Contains 2 Nibbles
* The First Nibble Is The Sub Version
* The Second Is A Description Character:
*
* 0 - Release      Version
* A - Alpha        Version
* B - Beta         Version
* D - Development  Version
* E - Experimental Version
* F - Final test   Version
*
* E Should Not Be Released At All
* A, B, D, F Only To Beta Testers
*-------------------------------
            DATE
*-------------------------------

Version     =      $01F4

Id          =      1
Aux         =      1

            LST    OFF
            LSTDO  OFF
            XC
            TR
            TR     ADR
            EXP    ONLY
Y           =      1
y           =      1
N           =      0
n           =      0
NOLIST      =      Y
GSBUG       =      N
            DO     NOLIST
LISTOBJ     =      N
LISTSYM     =      N
            ELSE
LISTOBJ     KBD    'List This Source? (Y/N)'
LISTSYM     KBD    'List Symbol Table? (Y/N)'
            FIN
            LST    OFF
            USE    EQUATES/MACROS
            PUT    EQUATES/EQUATES
            PUT    EQUATES/OS.EQUATES
            PUT    EQUATES/ENTRY
            PUT    EQUATES/DRIVEREQU
            PUT    EQUATES/RAMAREA
            PUT    EQUATES/TOKENS

]TYPE       =      ^overlays                   ; set file type
]AUX        =      overlays                    ; and aux type
            ORG    ]AUX                        ; must be this way
            TYP    ]TYPE

            DSK    /MAIN/LLUCE/SYSTEM/COMPILER
            TTL    'LLUCE - Segment Compiler'
            DO     LISTOBJ
            LST
            FIN

            DB     Id
            DA     Aux
            DB     Aux/256!Aux!Id!$A5

*-------------------------------
* Size Of Code To Check For CRC
*-------------------------------

            DA     CODEEND-CODESTRT
            DA     0                           ; CRC Goes Here
            LST    OFF
            ORG    $D000

LBLTAB      =      $9B00
LNBUF2      =      $9B00+$800
SYMTAB      =      $E600

CODESTRT    =      *
            PUT    OVERLAYS/COMP.MAIN          ; Compiler Main Line Code
            PUT    OVERLAYS/COMP.SUBS          ; Compiler Subroutines
            PUT    OVERLAYS/COMP.TOKENS        ; Compiler Token List
            LST    RTN
SYMNUM      DB     0
LBLNUM      DB     0
LNCNT2      DB     0
TOKTYP      DB     0
ERRFLG      DB     0
COMMENT     DB     0
ONCOUNT     DB     0
ONFLAG      DB     0
PUBCNT      DB     0
LINENUM     DW     0
            LST    OFF
            DO     LISTSYM
            LST
            FIN
            TTL    'Compiler - Symbol Table'
            PAG

