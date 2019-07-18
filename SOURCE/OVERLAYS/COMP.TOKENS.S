            LST   RTN
            PAG
WHERES      DA    T?,TA,TB,TC
            DA    TD,TE,TF,TG
            DA    TH,TI,TJ,TK
            DA    TL,TM,TN,TO
            DA    TP,TQ,TR,TS
            DA    TT,TU,TV,TW
            DA    TX,TY,TZ

TZ          DB    0

TY          DB    0

TX          TKN   'XOR';Xor            ; Eor Operand
            DB    0

TW          TKN   'WRITE';Writetkn     ; Write Statement
            TKN   'WORD';Word          ; Word Function
            TKN   'WINDOW';Window      ; Window Cmd, R/W
            TKN   'WIDTH';Width        ; Width Function
            TKN   'WHILE';WhileTkn
            TKN   'WHEN$';Whenstr      ; When$ Statement
            DB    0

TV          TKN   'VAL';Val            ; Val Function
            DB    0

TU          TKN   'UPPER$';Upper       ; Convert To Upper
            TKN   'UNLOCK';Unlock      ; Unlock Command
            DB    0

TT          TKN   'TYPE';Type          ; Type Disk File Cmd
            TKN   'TONE';Tone          ; Tone Function
            TKN   'TO';ToTkn           ; To Statement
            TKN   'TIME12$';Time12     ; 12 Hour Time
            TKN   'TIME$';Timestr      ; Time$ Statement
            TKN   'THEN';Then          ; Then Statement
            TKN   'TERMINAL';Terminal  ; Set Terminal #
            DB    0

TS          TKN   'STR$';Strstr        ; Str$ Statement
            TKN   'STORE';Store        ; Store Statement
            TKN   'STEP';StepTkn       ; Step Statement
            TKN   'SIZE';Size          ; Size Function
            TKN   'SETINT';SetInt      ; Set Interrupt Keys
            TKN   'SET';Set            ; Set Statement
            DB    0

TR          TKN   'RTRIM$';Rtrim       ; Trim Trailing Spaces
            TKN   'RND$';Rndstr        ; Rnd$ Function
            TKN   'RIGHT$';Rightstr    ; Right$ Statement
            TKN   'REWIND';Rewind      ; Rewind Statement
            TKN   'RETURN';Return      ; Return Statement
            TKN   'RESUME';Resume      ; Resume From Error
            TKN   'RECALL';Recall      ; Recall Statement
            TKN   'READY';Ready        ; Ready Statement
            TKN   'READ';Readtkn       ; Read Statement
            TKN   'RANDOM';Rnd         ; Random Function
            TKN   'RAM';Ram            ; Ram Value
            DB    0

TQ          DB    0

TP          TKN   'PUSH';Push          ; Push Statement
            TKN   'PUBLIC';Public      ; Public Directive
            TKN   'PRINT';Print        ; Print Statement
            TKN   'PREFIX';PrefixTkn   ; Get Or Set Prefix
            TKN   'POSITION';Position  ; Position Statement
            TKN   'POP';Pop            ; Pop Statement
            TKN   'POKE';Poke          ; Poke Statement
            TKN   'PEEK';Peek          ; Peek Function
            TKN   'PDL';Pdl            ; Pdl Function
            DB    0

TO          TKN   'OVERLAY';Overlay    ; Overlay Command
            TKN   'OR';Or              ; Or Operand
            TKN   'OPEN';OpenTkn       ; Open A File
            TKN   'ONLINE';OnlineTkn   ; Online Cmd, R/O
            TKN   'ON';On              ; On Statement
            TKN   'OFFSET';OffsTkn     ; Offset Cmd, R/W
            TKN   'OFF';Off            ; Off statement
            DB    0

TN          TKN   'NULLS';Nullcmd      ; Nulls, Cmd R/W
            TKN   'NOT';LogicNot       ; Not Statement
            TKN   'NORMAL$';Normal     ; Normal Cmd
            TKN   'NODE';Node          ; Node Cmd,   R/O
            TKN   'NOCAR';Nocar        ; On No Carrier
            TKN   'NIBBLE';Nibble      ; Nibble Function
            TKN   'NEXT';Next          ; Next Statement
            TKN   'NAME';Name          ; Rename Command
            DB    0

TM          TKN   'MSG';Msg            ; Msg Function
            TKN   'MOVE';Move          ; Move Statement
            TKN   'MOUSE$';Mouse       ; Mousetxt Cmd
            TKN   'MODEM';Modem        ; Modem Statement
            TKN   'MODE';Mode          ; Back Space Mode Cmd
            TKN   'MOD';Mod            ; Mod
            TKN   'MIXED$';Mixed       ; Convert To Mixed
            TKN   'MID$';Midstr        ; Mid$ Statement
            TKN   'MARK';Mark          ; Get/Set Function
            DB    0

TL          TKN   'LTRIM$';Ltrim       ; Trim Leading Spaces
            TKN   'LOWER$';Lower       ; Convert To Lower
            TKN   'LOCK';Lock          ; Lock Command
            TKN   'LINEINS$';InsLnTkn  ; Insert line
            TKN   'LINEDEL$';DelLnTkn  ; Delete line
            TKN   'LEN';Len            ; String Length
            TKN   'LEFT$';Leftstr      ; Left$ Statement
            DB    0

TK          TKN   'KILL';Kill          ; Kill Statement
            TKN   'KEY';Key            ; Key Function
            DB    0

TJ          DB    0

TI          TKN   'INVERSE$';Inverse   ; Inverse Cmd
            TKN   'INSTR';Instr        ; Instr Function
            TKN   'INPUT';Input        ; Input A Line
            TKN   'IF';If              ; If Statement
            DB    0

TH          TKN   'HOME$';Home         ; Home Cmd
            DB    0

TG          TKN   'GOTOXY$';Gotoxy     ; Gotoxy Cmd
            TKN   'GOTO';Goto          ; Goto Statement
            TKN   'GOSUB';Gosub        ; Gosub Statement
            TKN   'GET';Get            ; Get A Character
            DB    0

TF          TKN   'FREE';Free          ; Free Statement
            TKN   'FOR';For            ; For Statement
            TKN   'FMTWHEN$';Fmtwhen   ; Format When$ Statement
            TKN   'FMTDATE$';Fmtdate   ; Formated Date Statement
            TKN   'FLUSH';FlushTkn     ; Update Statement
            TKN   'FLASH';Flash        ; Flash statement
            TKN   'FLAG';Flag          ; User Flags
            TKN   'FILL';Fill          ; Fill Statement
            DB    0

TE          TKN   'EXIT';ExitTkn       ; Exit from LLUCE
            TKN   'EXIST';Exist        ; Check For File
            TKN   'EXEC';Exec          ; Exec Cmd,   R/W
            TKN   'ERROR';Onerr        ; On No Error
            TKN   'ERR';Err            ; Err Cmd, R/O
            TKN   'EOR';Xor            ; Eor Operand
            TKN   'EOF';Eof            ; Eof Function
            TKN   'END';End            ; End Of Module
            TKN   'ELSE';ElseTkn       ; Else Statement
            TKN   'EDIT';Edit          ; Edit Statement
            TKN   'ECHO';Echo          ; Set Video Echo
            DB    0

TD          TKN   'DO';DoTkn
            TKN   'DISK';Disk          ; Network Lock/Unlock
            TKN   'DEBUG';Debug        ; Debug
            TKN   'DATE$';Datestr      ; Date Statement
            DB    0

TC          TKN   'CURSORU$';CsrUTkn   ; Cursor up
            TKN   'CURSORR$';CsrRTkn   ; Cursor right
            TKN   'CURSORL$';CsrLTkn   ; Cursor left
            TKN   'CURSORD$';CsrDTkn   ; Cursor down
            TKN   'CRUNCH';Crunch      ; Crunch Statement
            TKN   'CREATE';CreateTkn   ; Create Statement
            TKN   'COPY';Copy          ; Copy A File
            TKN   'CONVERT';Convert
            TKN   'CONTINUE';Continue  ; continue a WHILE
            TKN   'CLS';Cls            ; Clear Screen Cmd
            TKN   'CLRSCN$';CscnTkn
            TKN   'CLRLN$';ClnTkn      ; Clear line
            TKN   'CLREOS$';CeosTkn    ; Clear to EOS
            TKN   'CLREOL$';CeolTkn    ; Clear to EOL
            TKN   'CLRBOS$';CbosTkn    ; Clear to BOS
            TKN   'CLRBOL$';CbolTkn    ; Clear to BOL
            TKN   'CLOSE';CloseTkn     ; Close A File
            TKN   'CLOCK';Clock        ; Time Function
            TKN   'CLEAR';Clear        ; Clear Statement
            TKN   'CHR$';Chrstr        ; CHR$ Statement
            TKN   'CHARINS$';InsChTkn  ; Insert char
            TKN   'CHARDEL$';DelChTkn  ; Delete char
            TKN   'CHAIN';ChainTkn     ; Chain Command
            TKN   'CALL';Call          ; Call Statement
            DB    0

TB          TKN   'BYTE';Byte          ; Byte Function
            TKN   'BREAK';Break
            TKN   'BAUD';Baud          ; Baud Rate, R/O
            DB    0

TA          TKN   'ASC';Asc            ; Ascii Function
            TKN   'APPEND';Append      ; Append Statement
            TKN   'ANSI';AnsiTkn       ; ANSI command
            TKN   'AND';And            ; And Operand
            TKN   'ADDINT';AddInt      ; Add Interrupt Keys
            TKN   'ABS';Abs            ; Absolute Value
            DB    0

T?          TKN   '~';Not              ; ~, bitwise NOT Statement
            TKN   '{';CompStrt         ; Block start
            TKN   '||';LogicOr         ; ||, logical OR
            TKN   '|=';OrEqu           ; |=, n = n | x
            TKN   '|';Or               ; |, bitwise OR Operand
            TKN   '}';CompEnd          ; Block end
            TKN   '^=';XorEqu          ; ^=, n = n ^ x
            TKN   '^';Xor              ; ^, bitwise EOR Operand
            TKN   '?';Print            ; alternate print statement
            TKN   '><';Notequ          ; ><, not equal
            TKN   '>>=';ShftREqu       ; >>=, n = n >> x
            TKN   '>>';ShftRght        ; >>, shift right
            TKN   '>=';Grequ           ; >=, greater or equal
            TKN   '>';Greater          ; >, greater
            TKN   '=<';Lessequ         ; =<, equal or less
            TKN   '==';Equal           ; ==, equal
            TKN   '=>';Grequ           ; =>, equals or greater
            TKN   '=';Equal            ; =, equals
            TKN   '<>';Notequ          ; <>, not equals
            TKN   '<=';Lessequ         ; <=, less or equal
            TKN   '<<=';ShftLEqu       ; <<=, n = n << x
            TKN   '<<';ShftLeft        ; <<, shift left
            TKN   '<';Less             ; <, less
            TKN   ':';Chain            ; Colon (Chain)
            TKN   '/=';DivEqu          ; /=, n = n / x
            TKN   '/';Div              ; Division
            TKN   '-=';MinusEqu        ; -=, n = n - x
            TKN   '--';Decremnt        ; --, n = n - 1
            TKN   '-';Minus            ; Minus
            TKN   '+=';PlusEqu         ; +=, n = n + x
            TKN   '++';Incremnt        ; ++, n = n + 1
            TKN   '+';Plus             ; Plus
            TKN   '*=';MultEqu         ; *=, n = n * x
            TKN   '*';Mult             ; Multiplication
            TKN   '&=';AndEqu          ; &=, n = n AND x
            TKN   '&&';LogicAnd        ; logical AND
            TKN   '&';And              ; Bitwise AND Operand
            TKN   '%=';ModEqu          ; %=, n = n MOD x
            TKN   '%';Mod              ; MOD
            TKN   '!=';Notequ          ; Not equal
            TKN   '!';LogicNot         ; logical NOT
CODEEND     =     *
            LST   OFF

