********************************
*                              *
*       Archive Lister         *
*                              *
********************************
            DATE
*-------------------------------

Id          =      1
Aux         =      10

            LST    OFF
            LSTDO  OFF
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
            PUT    EQUATES/EQUATES
            PUT    EQUATES/OS.EQUATES
            PUT    EQUATES/ENTRY
            PUT    EQUATES/DRIVEREQU

]TYPE       =      ^overlays                   ; set file type
]AUX        =      overlays                    ; and aux type
            ORG    ]AUX                        ; must be this way
            TYP    ]TYPE

            DSK    /RAM5/LIST

            TTL    'LLUCE - Archive Lister'
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
CODESTRT    =      *
ACOS        =      0

HDRBUF      =      $200
DATABUF     =      $9B00

BYTE        =      1
WORD        =      2
LADR        =      3
LONG        =      4

            PUT    OVERLAYS/LISTER/MACROS
            PUT    OVERLAYS/LISTER/MAIN
            PUT    OVERLAYS/LISTER/ACU
            PUT    OVERLAYS/LISTER/APL
            PUT    OVERLAYS/LISTER/BLU
            PUT    OVERLAYS/LISTER/SHK
            PUT    OVERLAYS/LISTER/LU
            PUT    OVERLAYS/LISTER/ARC
            PUT    OVERLAYS/LISTER/LZH
            PUT    OVERLAYS/LISTER/ZIP
            PUT    OVERLAYS/LISTER/ZOO
            PUT    OVERLAYS/LISTER/MAC
            PUT    OVERLAYS/LISTER/ARJ
            PUT    OVERLAYS/LISTER/DATA
            LST    OFF
            DO     LISTSYM
            LST
            FIN
            TTL    'Lister - Symbol Table'
            PAG

