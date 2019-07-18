            LST   RTN

            TTL   'LLUCE - Token Jump Table'
            PAG
SYMADR      DW    0

Number      =     *-SYMADR/2
            DW    LET                         ; 01
String      =     *-SYMADR/2
            DW    LET                         ; 02
OneByte     =     *-SYMADR/2
            DW    SYNTAX                      ; 03
TwoByte     =     *-SYMADR/2
            DW    SYNTAX                      ; 04
ThreeByte   =     *-SYMADR/2
            DW    SYNTAX                      ; 05

            DW    SYNTAX                      ; 06
            DW    SYNTAX                      ; 07
NoLbl       =     *-SYMADR/2
            DW    NOLABEL                     ; 08

Public      =     *-SYMADR/2
            DW    SYNTAX                      ; 09
CompStrt    =     *-SYMADR/2
            DW    RUNBLOCK                    ; 0A
CompEnd     =     *-SYMADR/2
            DW    BLKEND                      ; 0B

            DW    IF                          ; 0C
Else        =     *-SYMADR/2
            DW    ELSE                        ; 0D

            DW    FOR                         ; 0E
To          =     *-SYMADR/2
            DW    SYNTAX                      ; 0F To Command
Step        =     *-SYMADR/2
            DW    SYNTAX                      ; 10 Step Command
Next        =     *-SYMADR/2
            DW    NEXT                        ; 11

DoTkn       =     *-SYMADR/2
            DW    DO_DO                       ; 12
While       =     *-SYMADR/2
            DW    WHILE                       ; 13
Continue    =     *-SYMADR/2
            DW    END                         ; 14 continue
Break       =     *-SYMADR/2
            DW    END                         ; 15 break

Then        =     *-SYMADR/2
Chain       =     *-SYMADR/2
            DW    NIL                         ; 16
Chain2      =     *-SYMADR/2
            DW    NIL                         ; 17

End         =     *-SYMADR/2
            DW    END                         ; 18

ClsTkn      =     *-SYMADR/2
            DW    DO_CLS                      ; 19 Cls Command
HomeTkn     =     *-SYMADR/2
            DW    SCRN                        ; 1A Home Command
            DW    SCRN                        ; 1B Cursor Up
            DW    SCRN                        ; 1C Cursor Down
            DW    SCRN                        ; 1D Cursor Left
            DW    SCRN                        ; 1E Cursor Right
            DW    SCRN                        ; 1F Clear to EOS
            DW    SCRN                        ; 20 Clear to BOS
ClsTkn2     =     *-SYMADR/2
            DW    SCRN                        ; 21 Clear screen
            DW    SCRN                        ; 22 Clear to EOL
            DW    SCRN                        ; 23 Clear to BOL
            DW    SCRN                        ; 24 Clear line
            DW    SCRN                        ; 25 Insert line
            DW    SCRN                        ; 26 Delete line
            DW    SCRN                        ; 27 Insert character
            DW    SCRN                        ; 28 Delete character
            DW    SCRN                        ; 29 Normal characters
            DW    SCRN                        ; 2A Inverse characters
Gotoxy      =     *-SYMADR/2
            DW    SCRN                        ; 2B Gotoxy Command
            DW    SCRN                        ; 2C MouseText command
EndEmul     =     *-SYMADR/2
            DW    TONE                        ; 2D Tone command

Goto        =     *-SYMADR/2
            DW    GOTO                        ; 2E
Gosub       =     *-SYMADR/2
            DW    GOSUB                       ; 2F
Push        =     *-SYMADR/2
            DW    PUSH                        ; 30

On          =     *-SYMADR/2
            DW    ON                          ; 31
Off         =     *-SYMADR/2
            DW    SYNTAX                      ; 32

            DW    PRINT                       ; 33
            DW    INPUT                       ; 34
Key         =     *-SYMADR/2
            DW    KEY                         ; 35

Clear       =     *-SYMADR/2
            DW    CLEAR                       ; 36
Free        =     *-SYMADR/2
            DW    FREE                        ; 37
Set         =     *-SYMADR/2
            DW    SET                         ; 38

Flag        =     *-SYMADR/2
            DW    FLAG                        ; 39
            DW    NIBBLE                      ; 3A
            DW    BYTE                        ; 3B
            DW    WORD                        ; 3C

Nocar       =     *-SYMADR/2
            DW    SYNTAX                      ; 3D
Onerr       =     *-SYMADR/2
            DW    SYNTAX                      ; 3E

Ready       =     *-SYMADR/2
            DW    READY                       ; 3F
OnlineTkn   =     *-SYMADR/2
            DW    ONLINE                      ; 40
Msg         =     *-SYMADR/2
            DW    MSG                         ; 41
Lock        =     *-SYMADR/2
            DW    LOCK                        ; 42
Unlock      =     *-SYMADR/2
            DW    UNLOCK                      ; 43

Readtkn     =     *-SYMADR/2
            DW    READ                        ; 44
Writetkn    =     *-SYMADR/2
            DW    WRITE                       ; 45

            DW    EOF                         ; 46
Size        =     *-SYMADR/2
            DW    SIZE                        ; 47

            DW    LEN                         ; 48
            DW    VAL                         ; 49
            DW    ASC                         ; 4A
            DW    INSTR                       ; 4B

            DW    UPPERSTR                    ; 4C
            DW    LOWERSTR                    ; 4D
            DW    MIXEDSTR                    ; 4E
            DW    RGTTRIM                     ; 4F
            DW    LEFTTRIM                    ; 50

Strtyp      =     *-SYMADR/2
Timestr     =     *-SYMADR/2
            DW    TIMESTR                     ; 51
            DW    TIME2STR                    ; 52

            DW    DATESTR                     ; 53
            DW    FMTDATE                     ; 54
            DW    WHENSTR                     ; 55
            DW    FMTWHEN                     ; 56

            DW    LEFTSTR                     ; 57
            DW    RIGHTSTR                    ; 58
            DW    MIDSTR                      ; 59
            DW    CHRSTR                      ; 5A
            DW    STRSTR                      ; 5B
            DW    RNDSTR                      ; 5C

Compare     =     *-SYMADR/2
            DW    NOTEQU                      ; 5D <> or !=
            DW    LESSEQU                     ; 5E <=
            DW    GREQU                       ; 5F =>
Equal       =     *-SYMADR/2
            DW    EQUAL                       ; 60 =
            DW    LESS                        ; 61 <
            DW    GREATER                     ; 62 >

Logic       =     *-SYMADR/2
            DW    AND                         ; 63 or &
            DW    LOGICAND                    ; 64 && logical AND
Or          =     *-SYMADR/2
            DW    OR                          ; 65 or |
            DW    LOGICOR                     ; 66 || logical OR
            DW    XOR                         ; 67 or ^
            DW    BIN_NOT                     ; 68 or ~
            DW    LOGICNOT                    ; 69 or !
            DW    SHFTLFT                     ; 6A << shift left
            DW    SHFTRGT                     ; 6B >> shift right

Math        =     *-SYMADR/2
            DW    ADDITION                    ; 6C +
Minus       =     *-SYMADR/2
            DW    SUBTRACT                    ; 6D -
            DW    MULTIPLY                    ; 6E *
            DW    DIVIDE                      ; 6F /
Incremnt    =     *-SYMADR/2
            DW    INCREMNT                    ; 70 ++ increment
            DW    DECREMNT                    ; 71 -- decrement
            DW    ADDITION                    ; 72 +=
            DW    SUBTRACT                    ; 73 -=
            DW    MULTIPLY                    ; 74 *=
            DW    DIVIDE                      ; 75 /=
            DW    MOD                         ; 76 %=
            DW    AND                         ; 77 &=
            DW    OR                          ; 78 |=
            DW    XOR                         ; 79 ^=
            DW    SHFTLFT                     ; 7A <<=
            DW    SHFTRGT                     ; 7B >>=
Mod         =     *-SYMADR/2
            DW    MOD                         ; 7C or %
            DW    ABS                         ; 7D
Hitoken     =     *-SYMADR/2
            DW    DO_TOK2                     ; 7E
TOK_END     DW    SYNTAX                      ; 7F

SYMADR2     DW    SYNTAX                      ; 7E00
            DW    SYNTAX                      ; 7E01
            DW    SYNTAX                      ; 7E02
            DW    SYNTAX                      ; 7E03
            DW    SYNTAX                      ; 7E04
            DW    SYNTAX                      ; 7E05
            DW    SYNTAX                      ; 7E06
            DW    SYNTAX                      ; 7E07
            DW    SYNTAX                      ; 7E08
            DW    SYNTAX                      ; 7E09
            DW    SYNTAX                      ; 7E0A

            DW    BAUD                        ; 7E0B
            DW    EXEC                        ; 7E0C
            DW    NODE                        ; 7E0D
            DW    MODE                        ; 7E0E

            DW    PDL                         ; 7E0F
            DW    RND                         ; 7E10
            DW    ECHOSTR                     ; 7E11
            DW    SETINT                      ; 7E12
            DW    ADDINT                      ; 7E13
            DW    ERR                         ; 7E14
            DW    RAM                         ; 7E15

            DW    RETURN                      ; 7E16
            DW    POP                         ; 7E17
            DW    RESUME                      ; 7E18
            DW    GET                         ; 7E19

            DW    CLOCK                       ; 7E1A
            DW    FLASH                       ; 7E1B
            DW    ANSI                        ; 7E1C
            DW    TERMINAL                    ; 7E1D
            DW    WIDTH                       ; 7E1E
            DW    WINDOW                      ; 7E1F

            DW    EDIT                        ; 7E20
            DW    MODEM                       ; 7E21

            DW    POKE                        ; 7E22
            DW    PEEK                        ; 7E23
            DW    CALL                        ; 7E24
            DW    MOVE                        ; 7E25
            DW    FILL                        ; 7E26

            DW    COPY                        ; 7E27
            DW    TYPE                        ; 7E28

            DW    STORE                       ; 7E29
            DW    RECALL                      ; 7E2A

            DW    CHAIN                       ; 7E2B
            DW    PREFIX                      ; 7E2C
            DW    OVERLAY                     ; 7E2D
            DW    NET                         ; 7E2E

            DW    REWIND                      ; 7E2F
            DW    CRUNCH                      ; 7E30

            DW    CREATE                      ; 7E31
            DW    KILL                        ; 7E32
            DW    NAME                        ; 7E33
            DW    OPEN                        ; 7E34
            DW    CLOSE                       ; 7E35
            DW    FLUSH                       ; 7E36
            DW    MARK                        ; 7E37
            DW    POSITION                    ; 7E38
            DW    APPEND                      ; 7E39
            DW    EXIST                       ; 7E3A
            DW    EXIT                        ; 7E3B

Offset      =     *-SYMADR/2
            DW    DO_OFFSET                   ; 7E3C Offset command
Nullcmd     =     *-SYMADR/2
            DW    DO_NULLS                    ; 7E3D Null Command

            DW    CONVERT                     ; 7E3E Convert emulation cmd
            DW    DEBUG                       ; 7E3F
            DW    SYNTAX                      ; 7E40
            DW    SYNTAX                      ; 7E41
            DW    SYNTAX                      ; 7E42
            DW    SYNTAX                      ; 7E43
            DW    SYNTAX                      ; 7E44
            DW    SYNTAX                      ; 7E45
            DW    SYNTAX                      ; 7E46
            DW    SYNTAX                      ; 7E47
            DW    SYNTAX                      ; 7E48
            DW    SYNTAX                      ; 7E49
            DW    SYNTAX                      ; 7E4A
            DW    SYNTAX                      ; 7E4B
            DW    SYNTAX                      ; 7E4C
            DW    SYNTAX                      ; 7E4D
            DW    SYNTAX                      ; 7E4E
            DW    SYNTAX                      ; 7E4F
            DW    SYNTAX                      ; 7E50
            DW    SYNTAX                      ; 7E51
            DW    SYNTAX                      ; 7E52
            DW    SYNTAX                      ; 7E53
            DW    SYNTAX                      ; 7E54
            DW    SYNTAX                      ; 7E55
            DW    SYNTAX                      ; 7E56
            DW    SYNTAX                      ; 7E57
            DW    SYNTAX                      ; 7E58
            DW    SYNTAX                      ; 7E59
            DW    SYNTAX                      ; 7E5A
            DW    SYNTAX                      ; 7E5B
            DW    SYNTAX                      ; 7E5C
            DW    SYNTAX                      ; 7E5D
            DW    SYNTAX                      ; 7E5E
            DW    SYNTAX                      ; 7E5F
            DW    SYNTAX                      ; 7E60
            DW    SYNTAX                      ; 7E61
            DW    SYNTAX                      ; 7E62
            DW    SYNTAX                      ; 7E63
            DW    SYNTAX                      ; 7E64
            DW    SYNTAX                      ; 7E65
            DW    SYNTAX                      ; 7E66
            DW    SYNTAX                      ; 7E67
            DW    SYNTAX                      ; 7E68
            DW    SYNTAX                      ; 7E69
            DW    SYNTAX                      ; 7E6A
            DW    SYNTAX                      ; 7E6B
            DW    SYNTAX                      ; 7E6C
            DW    SYNTAX                      ; 7E6D
            DW    SYNTAX                      ; 7E6E
            DW    SYNTAX                      ; 7E6F
            DW    SYNTAX                      ; 7E70
            DW    SYNTAX                      ; 7E71
            DW    SYNTAX                      ; 7E72
            DW    SYNTAX                      ; 7E73
            DW    SYNTAX                      ; 7E74
            DW    SYNTAX                      ; 7E75
            DW    SYNTAX                      ; 7E76
            DW    SYNTAX                      ; 7E77
            DW    SYNTAX                      ; 7E78
            DW    SYNTAX                      ; 7E79
            DW    SYNTAX                      ; 7E7A
            DW    SYNTAX                      ; 7E7B
            DW    SYNTAX                      ; 7E7C
            DW    SYNTAX                      ; 7E7D
            DW    SYNTAX                      ; 7E7E
            DW    SYNTAX                      ; 7E7F
TOK_NUM     =     256
            LST   OFF

