             LST    OFF
             LSTDO  OFF
             EXP    ONLY
             XC
             TR
             TR     ADR
Y            =      1
y            =      1
N            =      0
n            =      0
LISTOBJ      KBD    'List This Source? (Y/N)'
LISTSYM      KBD    'List Symbol Table? (Y/N)'
SAVEOBJ      KBD    'Save Object Code? (Y/N)'

*
* July 15, 1991
*
* This file is hereby dedicated to the public domain.
*                                 -- Andrew Nicholas
*
             USE    MACROS/ZMACS
             USE    MACROS/PROMACS

             DO     LISTOBJ
             LST
             FIN
             ORG    $9E00

             PUT    EQUATES
             PUT    ZEQUATES

*-------------------------------------------------
* rzLoad -- load RZ into $9E00, save the CRC
*           tables into aux memory at $6000,
*           and take note that the loader is
*           left at $2000 if execution was
*           successful.
*
* Syntax is: use "L:rz.load",rz$
*
*     where rz$ is the pathname to get
*            RZ from
*
* If loader is successful, failflag (dec 10) = 0
* If loader is not successful, failflag has prodos
*  error in failflag (dec 10)
*

*-------------------------------------------------
* rzLoad -- load RZ (and have an oh so fun time doing it)

RZLOAD       STZ    FAILFLAG

             JSR    GOBCOM                      ;search for first delimiter
             JSR    MOVNAME                     ;get pathname in buff

             LDA    ACOSPATHLO
             STA    OPENPARMS+1
             LDA    ACOSPATHHI
             STA    OPENPARMS+2

*
* start by moving the CRC tables into aux memory at $7000.  The tables
* use $600 bytes of space (6 pages), and are moved into main memory
* whenever the main driver at $9E00 is run.
*
             JSR    SAVEPTRS                    ;save the zero page pointers we're about to use

             LDA    #<TABLES                    ;source begin
             STA    A1
             LDA    #>TABLES
             STA    A1+1

             LDA    #<TABLESEND                 ;source end
             STA    A2
             LDA    #>TABLESEND
             STA    A2+1

             LDA    #<$7000                     ;destination
             STA    A4
             LDA    #>$7000
             STA    A4+1

             SEC                                ;main to aux
             JSR    AUXMOVE

*
* now, save 2 pages of memory into aux memory from $2000
*
             LDA    #<$2000                     ;source begin
             STA    A1
             STA    A4                          ;destination
             LDA    #>$2000
             STA    A1+1
             STA    A4+1

             LDA    #<$2200                     ;source end
             STA    A2
             LDA    #>$2200
             STA    A2+1

             SEC                                ;main to aux
             JSR    AUXMOVE

*
* now go open the file using the pathname which we were passed
*
             JSR    MLI
             DB     $C8
             DA     OPENPARMS
             BCC    :OPENOK
:OSERROR     STA    FAILFLAG
             RTS
:OPENOK

*
* Now, move the "Loader" routine to $2000
*
             LDA    #<LOADER
             STA    A1
             LDA    #>LOADER
             STA    A1+1

             LDA    #<$2000
             STA    A2
             LDA    #>$2000
             STA    A2+1

:LOOP        LDA    (A1)
             STA    (A2)

             INC    A1
             BNE    :NC1
             INC    A1+1
:NC1         INC    A2
             BNE    :NC2
             INC    A2+1
:NC2         LDA    A1
             CMP    #<ENDOFLOADER
             BNE    :LOOP
             LDA    A1+1
             CMP    #>ENDOFLOADER

             JSR    RESTOREPTRS                 ;restore the zero page pointers we just used

*
* Finally, jump to the code which load RZ in at $9E00 from the pathname
* and executes it by calling $9E00
*
             LDA    OPENPARMS+5                 ;make sure refNum from open is in (A)
             JMP    $2000

*-------------------------------------------------
* SAVEPTRS -- save A1..A4 in 'PTRS'

SAVEPTRS     LDX    #7
:LOOP        LDA    A1,X
             STA    PTRS,X
             DEX
             BPL    :LOOP
             RTS

*-------------------------------------------------
* RESTOREPTRS -- restore A1..A4 from 'PTRS'

RESTOREPTRS
             LDX    #7
:LOOP        LDA    PTRS,X
             STA    A1,X
             DEX
             BPL    :LOOP
             RTS

*-------------------------------------------------
* data

PTRS         DW     0                           ;A1
             DW     0                           ;A2
             DW     0                           ;A3
             DW     0                           ;A4

OPENPARMS
             DB     3
             DA     0
             DA     FILEBUFFER2
             DB     0

*-------------------------------------------------
* CRC tables that get put at $6000 in aux memory and
* get moved back into main whenever RZ is called to
* actually do something

TABLES

*
* crc-16 table
*
*CRCTABLELO
             HEX    0021426384A5C6E7
             HEX    08294A6B8CADCEEF
             HEX    31107352B594F7D6
             HEX    39187B5ABD9CFFDE
             HEX    62432001E6C7A485
             HEX    6A4B2809EECFAC8D
             HEX    53721130D7F695B4
             HEX    5B7A1938DFFE9DBC
             HEX    C4E586A740610223
             HEX    CCED8EAF48690A2B
             HEX    F5D4B79671503312
             HEX    FDDCBF9E79583B1A
             HEX    A687E4C522036041
             HEX    AE8FECCD2A0B6849
             HEX    97B6D5F413325170
             HEX    9FBEDDFC1B3A5978
             HEX    88A9CAEB0C2D4E6F
             HEX    80A1C2E304254667
             HEX    B998FBDA3D1C7F5E
             HEX    B190F3D235147756
             HEX    EACBA8896E4F2C0D
             HEX    E2C3A08166472405
             HEX    DBFA99B85F7E1D3C
             HEX    D3F291B057761534
             HEX    4C6D0E2FC8E98AAB
             HEX    44650627C0E182A3
             HEX    7D5C3F1EF9D8BB9A
             HEX    75543716F1D0B392
             HEX    2E0F6C4DAA8BE8C9
             HEX    26076445A283E0C1
             HEX    1F3E5D7C9BBAD9F8
             HEX    1736557493B2D1F0

*CRCTABLEHI
             HEX    0010203040506070
             HEX    8191A1B1C1D1E1F1
             HEX    1202322252427262
             HEX    9383B3A3D3C3F3E3
             HEX    2434041464744454
             HEX    A5B58595E5F5C5D5
             HEX    3626160676665646
             HEX    B7A79787F7E7D7C7
             HEX    4858687808182838
             HEX    C9D9E9F98999A9B9
             HEX    5A4A7A6A1A0A3A2A
             HEX    DBCBFBEB9B8BBBAB
             HEX    6C7C4C5C2C3C0C1C
             HEX    EDFDCDDDADBD8D9D
             HEX    7E6E5E4E3E2E1E0E
             HEX    FFEFDFCFBFAF9F8F
             HEX    9181B1A1D1C1F1E1
             HEX    1000302050407060
             HEX    8393A3B3C3D3E3F3
             HEX    0212223242526272
             HEX    B5A59585F5E5D5C5
             HEX    3424140474645444
             HEX    A7B78797E7F7C7D7
             HEX    2636061666764656
             HEX    D9C9F9E99989B9A9
             HEX    5848786818083828
             HEX    CBDBEBFB8B9BABBB
             HEX    4A5A6A7A0A1A2A3A
             HEX    FDEDDDCDBDAD9D8D
             HEX    7C6C5C4C3C2C1C0C
             HEX    EFFFCFDFAFBF8F9F
             HEX    6E7E4E5E2E3E0E1E

*
* CRC polynomial = $EDB88320
*
*CRC32LIST1
             HEX    00962CBA
             HEX    198F35A3
             HEX    32A41E88
             HEX    2BBD0791
             HEX    64F248DE
             HEX    7DEB51C7
             HEX    56C07AEC
             HEX    4FD963F5
             HEX    C85EE472
             HEX    D147FD6B
             HEX    FA6CD640
             HEX    E375CF59
             HEX    AC3A8016
             HEX    B523990F
             HEX    9E08B224
             HEX    8711AB3D
             HEX    9006BC2A
             HEX    891FA533
             HEX    A2348E18
             HEX    BB2D9701
             HEX    F462D84E
             HEX    ED7BC157
             HEX    C650EA7C
             HEX    DF49F365
             HEX    58CE74E2
             HEX    41D76DFB
             HEX    6AFC46D0
             HEX    73E55FC9
             HEX    3CAA1086
             HEX    25B3099F
             HEX    0E9822B4
             HEX    17813BAD
             HEX    20B60C9A
             HEX    39AF1583
             HEX    12843EA8
             HEX    0B9D27B1
             HEX    44D268FE
             HEX    5DCB71E7
             HEX    76E05ACC
             HEX    6FF943D5
             HEX    E87EC452
             HEX    F167DD4B
             HEX    DA4CF660
             HEX    C355EF79
             HEX    8C1AA036
             HEX    9503B92F
             HEX    BE289204
             HEX    A7318B1D
             HEX    B0269C0A
             HEX    A93F8513
             HEX    8214AE38
             HEX    9B0DB721
             HEX    D442F86E
             HEX    CD5BE177
             HEX    E670CA5C
             HEX    FF69D345
             HEX    78EE54C2
             HEX    61F74DDB
             HEX    4ADC66F0
             HEX    53C57FE9
             HEX    1C8A30A6
             HEX    059329BF
             HEX    2EB80294
             HEX    37A11B8D

*
* CRC polynomial = $EDB88320
*
*CRC32LIST2
             HEX    00306151
             HEX    C4F4A595
             HEX    88B8E9D9
             HEX    4C7C2D1D
             HEX    10207141
             HEX    D4E4B585
             HEX    98A8F9C9
             HEX    5C6C3D0D
             HEX    20104171
             HEX    E4D485B5
             HEX    A898C9F9
             HEX    6C5C0D3D
             HEX    30005161
             HEX    F4C495A5
             HEX    B888D9E9
             HEX    7C4C1D2D
             HEX    41712010
             HEX    85B5E4D4
             HEX    C9F9A898
             HEX    0D3D6C5C
             HEX    51613000
             HEX    95A5F4C4
             HEX    D9E9B888
             HEX    1D2D7C4C
             HEX    61510030
             HEX    A595C4F4
             HEX    E9D988B8
             HEX    2D1D4C7C
             HEX    71411020
             HEX    B585D4E4
             HEX    F9C998A8
             HEX    3D0D5C6C
             HEX    83B3E2D2
             HEX    47772616
             HEX    0B3B6A5A
             HEX    CFFFAE9E
             HEX    93A3F2C2
             HEX    57673606
             HEX    1B2B7A4A
             HEX    DFEFBE8E
             HEX    A393C2F2
             HEX    67570636
             HEX    2B1B4A7A
             HEX    EFDF8EBE
             HEX    B383D2E2
             HEX    77471626
             HEX    3B0B5A6A
             HEX    FFCF9EAE
             HEX    C2F2A393
             HEX    06366757
             HEX    4A7A2B1B
             HEX    8EBEEFDF
             HEX    D2E2B383
             HEX    16267747
             HEX    5A6A3B0B
             HEX    9EAEFFCF
             HEX    E2D283B3
             HEX    26164777
             HEX    6A5A0B3B
             HEX    AE9ECFFF
             HEX    F2C293A3
             HEX    36065767
             HEX    7A4A1B2B
             HEX    BE8EDFEF

*
* CRC polynomial = $EDB88320
*
*CRC32LIST3
             HEX    00070E09
             HEX    6D6A6364
             HEX    DBDCD5D2
             HEX    B6B1B8BF
             HEX    B7B0B9BE
             HEX    DADDD4D3
             HEX    6C6B6265
             HEX    01060F08
             HEX    6E696067
             HEX    03040D0A
             HEX    B5B2BBBC
             HEX    D8DFD6D1
             HEX    D9DED7D0
             HEX    B4B3BABD
             HEX    02050C0B
             HEX    6F686166
             HEX    DCDBD2D5
             HEX    B1B6BFB8
             HEX    0700090E
             HEX    6A6D6463
             HEX    6B6C6562
             HEX    0601080F
             HEX    B0B7BEB9
             HEX    DDDAD3D4
             HEX    B2B5BCBB
             HEX    DFD8D1D6
             HEX    696E6760
             HEX    04030A0D
             HEX    05020B0C
             HEX    686F6661
             HEX    DED9D0D7
             HEX    B3B4BDBA
             HEX    B8BFB6B1
             HEX    D5D2DBDC
             HEX    63646D6A
             HEX    0E090007
             HEX    0F080106
             HEX    62656C6B
             HEX    D4D3DADD
             HEX    B9BEB7B0
             HEX    D6D1D8DF
             HEX    BBBCB5B2
             HEX    0D0A0304
             HEX    60676E69
             HEX    61666F68
             HEX    0C0B0205
             HEX    BABDB4B3
             HEX    D7D0D9DE
             HEX    64636A6D
             HEX    090E0700
             HEX    BFB8B1B6
             HEX    D2D5DCDB
             HEX    D3D4DDDA
             HEX    BEB9B0B7
             HEX    080F0601
             HEX    65626B6C
             HEX    0A0D0403
             HEX    6760696E
             HEX    D1D6DFD8
             HEX    BCBBB2B5
             HEX    BDBAB3B4
             HEX    D0D7DED9
             HEX    6661686F
             HEX    0B0C0502

*
* CRC polynomial = $EDB88320
*
*CRC32LIST4
             HEX    0077EE99
             HEX    0770E99E
             HEX    0E79E097
             HEX    097EE790
             HEX    1D6AF384
             HEX    1A6DF483
             HEX    1364FD8A
             HEX    1463FA8D
             HEX    3B4CD5A2
             HEX    3C4BD2A5
             HEX    3542DBAC
             HEX    3245DCAB
             HEX    2651C8BF
             HEX    2156CFB8
             HEX    285FC6B1
             HEX    2F58C1B6
             HEX    760198EF
             HEX    71069FE8
             HEX    780F96E1
             HEX    7F0891E6
             HEX    6B1C85F2
             HEX    6C1B82F5
             HEX    65128BFC
             HEX    62158CFB
             HEX    4D3AA3D4
             HEX    4A3DA4D3
             HEX    4334ADDA
             HEX    4433AADD
             HEX    5027BEC9
             HEX    5720B9CE
             HEX    5E29B0C7
             HEX    592EB7C0
             HEX    ED9A0374
             HEX    EA9D0473
             HEX    E3940D7A
             HEX    E4930A7D
             HEX    F0871E69
             HEX    F780196E
             HEX    FE891067
             HEX    F98E1760
             HEX    D6A1384F
             HEX    D1A63F48
             HEX    D8AF3641
             HEX    DFA83146
             HEX    CBBC2552
             HEX    CCBB2255
             HEX    C5B22B5C
             HEX    C2B52C5B
             HEX    9BEC7502
             HEX    9CEB7205
             HEX    95E27B0C
             HEX    92E57C0B
             HEX    86F1681F
             HEX    81F66F18
             HEX    88FF6611
             HEX    8FF86116
             HEX    A0D74E39
             HEX    A7D0493E
             HEX    AED94037
             HEX    A9DE4730
             HEX    BDCA5324
             HEX    BACD5423
             HEX    B3C45D2A
             HEX    B4C35A2D
TABLESEND

*-------------------------------------------------
* now that we've moved the CRC tables into aux memory, we need to move the
* rest of the code down to $2000 after saving the portion of memory that
* we're going to blast into aux memory so that the real RZ routines can
* move the aux memory back to main
*
* IN: (A) = refNum for open file which we're going to read into
*     $9E00
*
LOADER
             ORG    $2000

             STA    READPARMS+1
             STA    CLOSEPARMS+1
             STA    EOFPARMS+1

             JSR    MLI                         ;find out how long we are
             DB     $D1
             DA     EOFPARMS
             BCS    :OSERROR

             LDA    #<$9E00                     ;where
             STA    READPARMS+2
             LDA    #>$9E00
             STA    READPARMS+3

             LDA    EOFPARMS+2                  ;how much (eof)
             STA    READPARMS+4
             LDA    EOFPARMS+3
             STA    READPARMS+5

             JSR    MLI                         ;load rz
             DB     $CA
             DA     READPARMS
             BCS    :OSERROR

             JSR    MLI                         ;close us
             DB     $CC
             DA     CLOSEPARMS
             BCS    :OSERROR
             JMP    $9E00

:OSERROR     STA    FAILFLAG
             JMP    $9E00

*-------------------------------------------------
* some parameters

READPARMS
             DB     4                           ;pcount
             DB     0                           ;refnum
             DA     $9E00                       ;where
             DW     0                           ;howmuch
             DW     0                           ;actual

EOFPARMS     DB     2                           ;pcount
             DB     0                           ;refnum
             DS     3                           ;eof

CLOSEPARMS
             DB     1
             DB     0
ENDOFLOADER

             LST    OFF
             DO     SAVEOBJ
             SAV    RZ.LOAD
             FIN
             DO     LISTSYM
             LST
             FIN

