********************************
*                              *
*      LLUCE Version 1.0       *
*                              *
********************************
* Copyright 1986-1990 By L&L Productions
*-------------------------------
* Version 1.0
*-------------------------------
* This Follows Apple's Version Types.
* First Byte Is Main Version #.
* Second Byte Contains 2 Nibbles
* The First Nibble Is The Sub Version
* The Second Is A Description Character:
*
* 0 - Release Version
* A - Alpha Version
* B - Beta Version
* E - Experimental Version
*
* A And E Should Not Be Released At All
* B Only To Beta Testers
*-------------------------------
Version     =     $01F4
            LST   OFF
            XC
            TR
            TR    ADR
            EXP   ONLY
Y           =     1
y           =     1
N           =     0
n           =     0
NOLIST      =     Y
            DO    NOLIST
LISTOBJ     =     N
LISTSYM     =     N
            ELSE
LISTOBJ     KBD   'List This Source? (Y/N)'
LISTSYM     KBD   'List Symbol Table? (Y/N)'
            FIN
            DO    LISTOBJ
            LST
            FIN
            LST   OFF
            PUT   EQUATES/EQUATES
            PUT   EQUATES/OS.EQUATES
            PUT   EQUATES/PORTEQU

]TYPE       =     ^drivers                     ; set file type
]AUX        =     drivers                      ; and aux type
            ORG   ]AUX                         ; must be this way
            TYP   ]TYPE

            DSK   /MAIN/LLUCE/LLUCE.DRIVERS

            DO    LISTOBJ
            LST
            FIN
            TTL   'LLUCE - Make LLUCE.DRIVER'
            ORG   DRIVERS
            PUT   EQUATES/GLOBALS              ; Defaults
            PUT   PRINTERS/NOPRINT
            PUT   CLOCKS/GS                    ; Clock Driver
            PUT   MODEMS/GSPORT
            PUT   EQUATES/FILTER               ; Profanity Filter
            DS    \

            DO    LISTSYM
            LST
            FIN

