            LST   RTN
            TTL   'LLUCE - Storage Areas'
            PAG
*===============================
* Standard Memory Allocation
*===============================

DOLOCL      =     $F800                    16
DOLOCH      =     $F810                    16
END_DO      =     $F820                    32

WHLOCL      =     $F840                    16
WHLOCH      =     $F850                    16
END_WHIL    =     $F860                    32

GSBSTKL     =     $F880                    16
GSBSTKH     =     $F890                    16

FORLOCL     =     $F8A0                    16
FORLOCH     =     $F8B0                    16

FORVARL     =     $F8C0                    16
FORVARML    =     $F8D0                    16
FORVARMH    =     $F8E0                    16
FORVARH     =     $F8F0                    16

FORENDL     =     $F900                    16
FORENDM     =     $F910                    16
FORENDH     =     $F920                    16

FORSTPL     =     $F930                    16
FORSTPM     =     $F940                    16
FORSTPH     =     $F950                    16

PFXSAVE     =     $F960                    64
FLNSV       =     $F9A0                    64

LNKLBL      =     $F9E0                    9

DEVUSE      =     $F9E9                    11

NUM         =     $F9F4                    10
TXTNUM      =     $F9FE                    9
FLPOS       =     $FA07                    9

DATA        =     $FA10                    6
NUMB        =     $FA16                    4

NEGFLG      =     $FA1A                    1

LNCNT       =     $FA1B                    1

CPASS       =     $FA1C                    1

REMAIN      =     $FA1D                    6
SIGN        =     $FA23                    1
RESULT      =     $FA24                    6

TIMEOUT     =     $FA2A                    5

AUTORST     =     $FA2F                    1

OVERLYID    =     $FA30                    8
OVIDTEST    =     $FA38                    8

CURREMUL    =     $FA40                    192
            LST   OFF

