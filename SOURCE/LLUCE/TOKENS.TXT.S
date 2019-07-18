            LST   RTN
            TTL   'LLUCE - Token Text'
            PAG
*===============================
* ----- Actual Tokens -----
*===============================

SYMTXT      DB    -1                    ; 00 Reserved
            DB    -1                    ; 01 Reserved
            DB    -1                    ; 02 Reserved
            DB    -1                    ; 03 Reserved
            DB    -1                    ; 04 Reserved
            DB    -1                    ; 05 Reserved
            DB    -1                    ; 06 Reserved
            DB    -1                    ; 07 Reserved
            DB    -1                    ; 08 Reserved
            DB    -1                    ; 09 Reserved
            DCI   '{'                   ; 0A Reserved
            DCI   '}'                   ; 0B Reserved

            DCI   'IF'                  ; 0C If Statement
            DCI   'ELSE'                ; 0D Else Statement

            DCI   'FOR'                 ; 0E For Statement
            DCI   'TO'                  ; 0F To Statement
            DCI   'STEP'                ; 10 Step Statement
            DCI   'NEXT'                ; 11 Next Statement

            DCI   'DO'                  ; 12
            DCI   'WHILE'               ; 13

            DCI   'CONTINUE'            ; 14
            DCI   'BREAK'               ; 15

            DCI   ':'                   ; 16 Colon (Chain)
            DB    -1                    ; 17 Reserved (Chain2)

            DCI   'END'                 ; 18 End Of Module

            DCI   'CLS'                 ; 19 Clear Screen Cmd
            DCI   'HOME$'               ; 1A Cursor to home Cmd
            DCI   'CURSORU$'            ; 1B Cursor up
            DCI   'CURSORD$'            ; 1C Cursor down
            DCI   'CURSORL$'            ; 1D Cursor left
            DCI   'CURSORR$'            ; 1E Cursor right
            DCI   'CLREOS$'             ; 1F Clear to EOS
            DCI   'CLRBOS$'             ; 20 Clear to BOS
            DCI   'CLRSCN$'             ; 21 Clear screen string
            DCI   'CLREOL$'             ; 22 Clear to EOL
            DCI   'CLRBOL$'             ; 23 Clear to BOL
            DCI   'CLRLN$'              ; 24 Clear line
            DCI   'LINEINS$'            ; 25 Insert line
            DCI   'LINEDEL$'            ; 26 Delete line
            DCI   'CHARINS$'            ; 27 Insert char
            DCI   'CHARDEL$'            ; 28 Delete char
            DCI   'NORMAL$'             ; 29 Normal chars
            DCI   'INVERSE$'            ; 2A Inverse chars
            DCI   'GOTOXY$'             ; 2B Gotoxy Cmd
            DCI   'MOUSE$'              ; 2C Mousetext Cmd
            DCI   'TONE'                ; 2D Tone Function

            DCI   'GOTO'                ; 2E Goto Statement
            DCI   'GOSUB'               ; 2F Gosub Statement
            DCI   'PUSH'                ; 30 Push Statement

            DCI   'ON'                  ; 31 On Statement
            DCI   'OFF'                 ; 32 Off statement

            DCI   'PRINT'               ; 33 Print Statement
            DCI   'INPUT'               ; 34 Input A Line
            DCI   'KEY'                 ; 35 Key Function

            DCI   'CLEAR'               ; 36 Clear Statement
            DCI   'FREE'                ; 37 Free Statement
            DCI   'SET'                 ; 38 Set Statement

            DCI   'FLAG'                ; 39 User Flags
            DCI   'NIBBLE'              ; 3A Nibble Function
            DCI   'BYTE'                ; 3B Byte Function
            DCI   'WORD'                ; 3C Word Function

            DCI   'NOCAR'               ; 3D On No Carrier
            DCI   'ERROR'               ; 3E On Error

            DCI   'READY'               ; 3F Ready Statement
            DCI   'ONLINE'              ; 40 Online Cmd, R/O
            DCI   'MSG'                 ; 41 Msg Function

            DCI   'LOCK'                ; 42 Lock Command
            DCI   'UNLOCK'              ; 43 Unlock Command

            DCI   'READ'                ; 44 Read Statement
            DCI   'WRITE'               ; 45 Write Statement
            DCI   'EOF'                 ; 46 Eof Function
            DCI   'SIZE'                ; 47 Size Function

            DCI   'LEN'                 ; 48 String Length
            DCI   'VAL'                 ; 49 Val Function
            DCI   'ASC'                 ; 4A Ascii Function
            DCI   'INSTR'               ; 4B Instr Function

            DCI   'UPPER$'              ; 4C Convert To Upper
            DCI   'LOWER$'              ; 4D Convert To Lower
            DCI   'MIXED$'              ; 4E Convert To Mixed
            DCI   'RTRIM$'              ; 4F Trim Trailing Spaces
            DCI   'LTRIM$'              ; 50 Trim Leading Spaces

            DCI   'TIME$'               ; 51 Time$ Statement
            DCI   'TIME12$'             ; 52 12 Hour Time

            DCI   'DATE$'               ; 53 Date Statement
            DCI   'FMTDATE$'            ; 54 Formated Date Statement
            DCI   'WHEN$'               ; 55 When$ Statement
            DCI   'FMTWHEN$'            ; 56 Format When$ Statement

            DCI   'LEFT$'               ; 57 Left$ Statement
            DCI   'RIGHT$'              ; 58 Right$ Statement
            DCI   'MID$'                ; 59 Mid$ Statement
            DCI   'CHR$'                ; 5A Chr$ Statement
            DCI   'STR$'                ; 5B Str$ Statement
            DCI   'RND$'                ; 5C Rnd$ Function

            DCI   '!='                  ; 5D <> or !=
            DCI   '<='                  ; 5E <=
            DCI   '>='                  ; 5F =>
            DCI   '='                   ; 60 =
            DCI   '<'                   ; 61 <
            DCI   '>'                   ; 62 >

            DCI   '&'                   ; 63 or &, And Operand
            DCI   '&&'                  ; 64 &&, logical AND
            DCI   '|'                   ; 65 or |, Or Operand
            DCI   '||'                  ; 66 ||, logical OR
            DCI   '^'                   ; 67 or EOR or ^, Eor Operand
            DCI   '~'                   ; 68 Not Statement
            DCI   '!'                   ; 69 logical NOT
            DCI   '<<'                  ; 6A << shift left
            DCI   '>>'                  ; 6B >> shift right

            DCI   '+'                   ; 6C Plus
            DCI   '-'                   ; 6D Minus
            DCI   '*'                   ; 6E Multiplication
            DCI   '/'                   ; 6F Division
            DCI   '++'                  ; 70 ++ increment
            DCI   '--'                  ; 71 -- decrement
            DCI   '+='                  ; 72 +=
            DCI   '-='                  ; 73 -=
            DCI   '*='                  ; 74 *=
            DCI   '/='                  ; 75 /=
            DCI   '%='                  ; 76 %=
            DCI   '&='                  ; 77 &=
            DCI   '|='                  ; 78 |=
            DCI   '^='                  ; 79 ^=
            DCI   '<<='                 ; 7A <<=
            DCI   '>>='                 ; 7B >>=
            DCI   '%'                   ; 7C or %, Mod
            DCI   'ABS'                 ; 7D Absolute Value
            DB    -1                    ; 7E For Next Table
            DB    0                     ; 7F

SYMTXT2     DB    -1                    ; 7E00
            DB    -1                    ; 7E01
            DB    -1                    ; 7E02
            DB    -1                    ; 7E03
            DB    -1                    ; 7E04
            DB    -1                    ; 7E05
            DB    -1                    ; 7E06
            DB    -1                    ; 7E07
            DB    -1                    ; 7E08
            DB    -1                    ; 7E09
            DB    -1                    ; 7E0A

            DCI   'BAUD'                ; 7E0B Baud Rate,  R/O
            DCI   'EXEC'                ; 7E0C Exec Cmd,   R/W
            DCI   'NODE'                ; 7E0D Node Cmd,   R/O
            DCI   'MODE'                ; 7E0E Back Space Mode Cmd

            DCI   'PDL'                 ; 7E0F Pdl Function
            DCI   'RANDOM'              ; 7E10 Random Function
            DCI   'ECHO'                ; 7E11 Set Video Echo
            DCI   'SETINT'              ; 7E12 Set Interrupt Keys
            DCI   'ADDINT'              ; 7E13 Add Interrupt Keys
            DCI   'ERR'                 ; 7E14 Err Cmd, R/O
            DCI   'RAM'                 ; 7E15 Ram Value

            DCI   'RETURN'              ; 7E16 Return Statement
            DCI   'POP'                 ; 7E17 Pop Statement
            DCI   'RESUME'              ; 7E18 Resume From Error
            DCI   'GET'                 ; 7E19 Get A Character

            DCI   'CLOCK'               ; 7E1A Time Function
            DCI   'FLASH'               ; 7E1B GS screen flashing
            DCI   'ANSI'                ; 7E1C set ANSI mode
            DCI   'TERMINAL'            ; 7E1D Set Terminal #
            DCI   'WIDTH'               ; 7E1E Width Function
            DCI   'WINDOW'              ; 7E1F Window Cmd, R/W

            DCI   'EDIT'                ; 7E20 Edit Statement
            DCI   'MODEM'               ; 7E21 Modem Statement

            DCI   'POKE'                ; 7E22 Poke Statement
            DCI   'PEEK'                ; 7E23 Peek Function
            DCI   'CALL'                ; 7E24 Call Statement
            DCI   'MOVE'                ; 7E25 Move Statement
            DCI   'FILL'                ; 7E26 Fill Statement

            DCI   'COPY'                ; 7E27 Copy A File
            DCI   'TYPE'                ; 7E28 Type Disk File Cmd

            DCI   'STORE'               ; 7E29 Store Statement
            DCI   'RECALL'              ; 7E2A Recall Statement

            DCI   'CHAIN'               ; 7E2B Chain Command
            DCI   'PREFIX'              ; 7E2C Get Or Set Prefix
            DCI   'OVERLAY'             ; 7E2D Overlay Command
            DCI   'DISK'                ; 7E2E Network Lock/Unlock

            DCI   'REWIND'              ; 7E2F Rewind Statement
            DCI   'CRUNCH'              ; 7E30 Crunch Statement

            DCI   'CREATE'              ; 7E31 Create Statement
            DCI   'KILL'                ; 7E32 Kill Statement
            DCI   'NAME'                ; 7E33 Rename Command

            DCI   'OPEN'                ; 7E34 Open A File
            DCI   'CLOSE'               ; 7E35 Close A File
            DCI   'FLUSH'               ; 7E36 Update Statement

            DCI   'MARK'                ; 7E37 Get/Set Function
            DCI   'POSITION'            ; 7E38 Position Statement
            DCI   'APPEND'              ; 7E39 Append Statement

            DCI   'EXIST'               ; 7E3A Check For File

            DCI   'EXIT'                ; 7E3B Exit LLUCE

            DCI   'OFFSET'              ; 7E3C GotoXY offset
            DCI   'NULLS'               ; 7E3D Nulls, Cmd R/W

            DCI   'CONVERT'             ; 7E3E Convert emulation cmd
            DCI   'DEBUG'               ; 7E3F Debug
            DB    0
            LST   OFF

