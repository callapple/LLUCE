            LST   OFF
            TR
            TR    ADR
            TTL   'LLUCE - Error Messages'

drivers     =     $2E8005

]TYPE       =     ^drivers                  ; set file type
]AUX        =     drivers                   ; and aux type
            ORG   ]AUX                      ; must be this way
            TYP   ]TYPE

            DSK   /MAIN/LLUCE/LLUCE.TEXT

**************************************************
*                                                *
*  ProTerm special control equates               *
*                                                *
**************************************************

Ctrl        =     $40

begin       =     'A'-Ctrl                  Cursor
endline     =     'B'-Ctrl                  Cursor
delchar     =     'D'-Ctrl                  Delete
inschar     =     'F'-Ctrl                  Insert
bell        =     'G'-Ctrl                  Ring
back        =     'H'-Ctrl                  Cursor
tab         =     'I'-Ctrl                  Tab
down        =     'J'-Ctrl                  Cursor
up          =     'K'-Ctrl                  Cursor
clrscn      =     'L'-Ctrl                  Clear
cr          =     'M'-Ctrl                  Do
normal      =     'N'-Ctrl                  Normal
inverse     =     'O'-Ctrl                  Inverse
mouse       =     'P'-Ctrl                  Real
repeat      =     'R'-Ctrl                  Repeat
tone        =     'T'-Ctrl                  ProTERM
right       =     'U'-Ctrl                  Cursor
insline     =     'V'-Ctrl                  insert
clreos      =     'W'-Ctrl                  Clear
home        =     'X'-Ctrl                  Home
clreol      =     'Y'-Ctrl                  Clear
delline     =     'Z'-Ctrl                  Delete
gotoxy      =     '^'-Ctrl                  GotoXY

txtend      =     $80

**************************************************
*                                                *
* Error messages                                 *
*                                                *
**************************************************

ERRMSGS     DB    -1
            DCI   '1: Syntax error'
            DCI   '2: END of program'
            DCI   '3: Missing symbol error'
            DCI   '4: Missing data'
            DCI   '5: Type mismatch error'
            DCI   '6: String overflow'
            DCI   '7: Numeric overflow'
            DCI   '8: Division by zero'
            DCI   '9: Bad device number'
            DCI   '10: Bad filename'
            DCI   '11: Link label not found'
            DCI   '12: Message file not found'
            DCI   '13: Cannot load overlay'
            DCI   '14: Prefix not found'
            DCI   '15: Module not found'
            DCI   '16: Disk write error'
            DCI   '17: A label was not defined'
            DCI   '18: GOSUB stack full'
            DCI   '19: RETURN without GOSUB error'
            DCI   '20: FOR stack full'
            DCI   '21: NEXT without FOR error'
            DCI   '22: RESUME with no error'
            DCI   '23: Bad system overlay version'
            DCI   '24: SYSOP call termination'
            DCI   '25: DO stack full'
            DCI   '26: No pending DO'
            DCI   '27: WHILE stack full'
            DCI   ': User Defined error'
            DB    0,0

            DS    $400-*+ERRMSGS
            ERR   *-$2E8405

**************************************************
*                                                *
* Other messages                                 *
*                                                *
**************************************************

PROGTEXT    DB    -1                        ;0
            DB    cr                        ;1
            DCI   'Starting Module Not Found'
            DB    cr                        ;2
            ASC   'One Moment Please...'
            DB    cr+txtend
;3
            ASC   '...Exiting Exec Mode...'
            DB    cr,cr+txtend
            DB    cr,cr                     ;4
            ASC   'Sysop Is On-Line...'
            DB    cr,cr+txtend
            DB    cr                        ;5
            ASC   'Sysop Is Off-Line...'
            DB    cr,cr+txtend
            DB    cr,cr                     ;6
            ASC   'Sorry, Time Limit Exceeded'
            DB    cr+txtend
            DB    cr                        ;7
            ASC   'One Moment Please...'
            DB    cr+txtend
;8
            DB    repeat,back,20            ; back up over it
            DB    repeat,' ',20             ; cover it up
            DB    repeat,back,19            ; back up again
            DB    back+txtend
            DB    0,0

            DS    $400-*+PROGTEXT
            ERR   *-$2E8805

**************************************************
*                                                *
* These are the top of screen messages.          *
* The format must be followed or the results can *
* be unpredictable.                              *
*                                                *
* Byte 1:  Horizontal position                   *
* Additional bytes:                              *
*          Printed text.  May contain PTSE       *
*          control characters, last character    *
*          must have its high bit set.           *
*                                                *
* This pattern is to be repeated for as many     *
* messages are desired up to 1K                  *
*                                                *
**************************************************

VIDMSGS     DB    0
            DB    inverse
            DB    repeat,'-',79
            DCI   '-'
            DB    33
            DB    inverse
            DCI   '[ Page: On ]'
            DB    33
            DB    inverse
            DCI   '[ Chat: On ]'
            DB    33
            DB    inverse
            DCI   '[ Exec: On ]'
            DB    0,0                       ; This MUST be at the end
; to denote the end of
; messages
            DS    $300-*+VIDMSGS
            ERR   *-$2E8B05
            LST   OFF

