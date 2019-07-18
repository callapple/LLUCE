            LST    OFF
            LSTDO  OFF
            TR
            TR     ADR

**************************************************
*                                                *
*            ProDOS Link Command File            *
*                                                *
**************************************************

            ORG    $2000

            TYP    $FF
            DSK    /MAIN/CMDS/LIST

ACOS        =      0
Cr          =      $D
Cls         =      $8C

Open        =      $C8
Read        =      $CA
Close       =      $CC
Setmark     =      $CE
Getmark     =      $CF
Geteof      =      $D1

TEMP        =      0
TEMP2       =      2
TEMP3       =      $13
CSW         =      $36

BYTE        =      1
WORD        =      2
LADR        =      3
LONG        =      4

HDRBUF      =      $200
FBUF1       =      $800
DATABUF     =      $9600

MLI         =      $BF00
KYBD        =      $C000       ; Keyboard Data

CLR80STO    =      $C000       ; Clear 80 Column Store
DISP40      =      $C00C       ; Set 40 Column Mode

KBDSTRB     =      $C010       ; Clear Keyboard Data

SLOT3       =      $C300

MONINIT     =      $FB2F       ; Init Monitor Routine
MONSNORM    =      $FE84       ; Set Normal Routine
MONSKBD     =      $FE89       ; Set Keyboard Routine
MONSVID     =      $FE93       ; Set Video Routine
MONCOUT     =      $FDED       ; Character Out Routine

            USE    MACROS
            PUT    DOS
            PUT    MAIN
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
            PUT    ARJ
            PUT    DATA

