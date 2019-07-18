********************************
*                              *
*      LLUCE Version 1.0F4     *
*                              *
********************************
* Copyright 1986-1993 By L&L Productions
*-------------------------------
* Version 1.0 Final 4
*-------------------------------
* This follows Apple's version types.
* First byte is main version #.
* Second byte contains 2 nibbles
* The first nibble is the sub version
* The second is a description character:
*
* 0 thru 9 - Release      version
* A        - Alpha        version
* B        - Beta         version
* D        - Development  version
* E        - Experimental version
* F        - Final test   version
*
* E should not be released at all
* A, B, D, F only to beta testers
*-------------------------------

Version     =      $01F4

            LST    OFF
            LSTDO  OFF
            XC
            TR
            TR     ADR
Y           =      1
y           =      1
N           =      0
n           =      0
NOLIST      =      Y
NODEMO      =      Y
            DO     NOLIST
LISTOBJ     =      N
LISTSYM     =      N
            ELSE
LISTOBJ     KBD    'List this source? (Y/N)'
LISTSYM     KBD    'List symbol table? (Y/N)'
            FIN
            DO     NODEMO
DEMOPGM     =      N
            ELSE
DEMOPGM     KBD    'Create LLUCE demo? (Y/N)'
            FIN
            DO     LISTOBJ
            LST
            FIN
            LST    OFF

            USE    EQUATES/MACROS
            PUT    EQUATES/EQUATES
            PUT    EQUATES/OS.EQUATES
            PUT    EQUATES/ERRORS
            PUT    EQUATES/DRIVEREQU
            PUT    EQUATES/RAMAREA             ; Ramcard storage area

]TYPE       =      ^sysfile                    ; set file type
]AUX        =      sysfile                     ; and aux type
            ORG    ]AUX                        ; must be this way
            TYP    ]TYPE

            DSK    /MAIN/LLUCE/LLUCE.SYSTEM
            LST    RTN

            TTL    'LLUCE - Starting'
HEADER      JMP    ENCODE                      ; System file standard start
            HEX    EEEE                        ; There is room for filename
            DB     65                          ; 65 bytes for filename
ST_NAME     STR    'PROGRAM/LOGON.SEG'
            DS     \
            LST    OFF
MOV_F00     ORG    MAINPGM
            PUT    LLUCE/CONSOLE               ; Video driver
            DS     \
            PUT    LLUCE/START                 ; Main loop, error handler
            PUT    LLUCE/IO.SUBS               ; I/O subroutines
            PUT    LLUCE/PROG.SUBS             ; Misc subroutines
            PUT    LLUCE/VAR                   ; Variable handlers
            PUT    LLUCE/MATH                  ; Math functions
            PUT    LLUCE/DISK                  ; Disk function handlers
            PUT    LLUCE/MSG                   ; Message file handlers
            PUT    LLUCE/DISKIO                ; Disk I/O routines
            PUT    LLUCE/LOAD                  ; Segment/overlay loader
            PUT    LLUCE/FLOW                  ; Program flow commands
            PUT    LLUCE/STRING                ; String related commands
            PUT    LLUCE/MEMORY                ; Memory related commands
            PUT    LLUCE/DATETIME              ; Date/time commands
            PUT    LLUCE/IO.CMDS               ; I/O commands
            PUT    LLUCE/MISC.CMDS             ; Unrelated commands
            DS     \
CODEND      =      *
            ORG                                ; End of moved code
MOV_D800    ORG    XTRAPGM
            PUT    LLUCE/HIGH.SUBS             ; High end subroutines
            DS     \
            ORG
MOV_F100    ORG    ENTRYPTS
            PUT    LLUCE/ENTRY                 ; Entry points
            DS     \
            PUT    LLUCE/TOKENS.JMP            ; Token jump table/text
            DS     \
            ORG
MOV_D400    ORG    $D400
            PUT    LLUCE/TOKENS.TXT
            DS     \
            ORG
MOV_F800    ORG    RAMCARD
            PUT    LLUCE/RAMCARD               ; Ramcard data area
            ORG
MOV_END     PUT    LLUCE/INIT                  ; Program initialization
            PUT    LLUCE/ENCODE                ; Copyright/sn encoder

            LST    OFF
            DO     LISTSYM
            LST
            FIN
            TTL    'LLUCE - Symbol Table'

