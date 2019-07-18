            LST   RTN
            TTL   'LLUCE - ThunderClock'
            PAG
CLOCKDVR    DB    0
CLKMODE     DB    0

GETDATE     JMP   G_DATE
GETTIME     JMP   G_TIME
SETDATE     JMP   S_DATE

*-------------------------------
* Get The Date In Prodos Format
*-------------------------------

G_DATE      JSR   MLI                     ; MLI Call
            DB    Gettime
            DW    0                       ; No Parameter Table
            LDX   DATE
            LDA   DATE+1
S_DATE      RTS

*-------------------------------
* Get The Current Time
*-------------------------------

G_TIME      JSR   G_DATE
            LDA   #<:TIMESTR
            STA   :TIMELOC+1
            LDA   #' '                    ; Clear Out Any Am/Pm
            STA   :TIMESTR+9
            STA   :TIMESTR+10
            LDA   TIME+1                  ; Get Hours
            LDY   #8                      ; 24 Hour Format Is 8 Chars.
            BIT   CLKMODE                 ; Need To Convert?
            BPL   :GTIME1                 ; Nope, Want 24 Hour Format

            LDY   #11                     ; 12 Hour Format Is 11 Chars
            LDX   #'A'                    ; Set Far Am
            CMP   #12                     ; Are We In AM?
            BLT   :CONV2                  ; Yep, No Need To Convert

            LDX   #'P'                    ; It Is Pm, So We Need To
            SBC   #12                     ; Subtract 12
:CONV2      CMP   #0                      ; Was It Noon?
            BNE   :CONV3                  ; Nope

            LDA   #12                     ; Noon Must Be 12 Pm
:CONV3      STX   :TIMESTR+9              ; Save The A Or P
            LDX   #'m'                    ; And The M
            STX   :TIMESTR+10
:GTIME1     JSR   :BINDEC8                ; Translate To Ascii
            CMP   #'0'                    ; Strip Leading 0
            BNE   :GTIME2

            INC   :TIMELOC+1
            DEY
            LDA   #' '
:GTIME2     STA   :TIMESTR                ; Save Hour
            STX   :TIMESTR+1
            LDA   TIME                    ; Get Minutes
            JSR   :BINDEC8                ; Translate To Ascii
            STA   :TIMESTR+3              ; Save Minute
            STX   :TIMESTR+4
            LDA   LNBUF+15                ; Seconds
            STA   :TIMESTR+6
            LDA   LNBUF+16
            STA   :TIMESTR+7
:TIMELOC    LDX   #<:TIMESTR              ; Point To String
            LDA   #>:TIMESTR              ; Length Is In Y
            RTS

*-------------------------------
* Translate A Binary To Text [0-99]
*-------------------------------

:BINDEC8    CMP   #60                     ; Put Limit Of 59
            BLT   :BIN8

            LDA   #59
:BIN8       LDX   #0                      ; Start 10's Counter
]LOOP       CMP   #10
            BCC   :BIN8B                  ; Less Than 10, Were Done

            SBC   #10                     ; Minus 10
            INX                           ; Add 1 To The 10's Counter
            BNE   ]LOOP                   ; Loop

:BIN8B      ADC   #'0'                    ; Make 1's Into Text
            PHA
            TXA
            ADC   #'0'                    ; Make 10's Into Text
            PLX
            RTS                           ; Were Done

*-------------------------------
*              '01234567890
:TIMESTR    ASC   '12:00:00   '
            DS    \
            LST   OFF

