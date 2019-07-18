            LST   RTN
            TTL   'LLUCE - Entry Points'
            PAG
ENTPOINT    JMP   GETBYT                  ; Get a program byte and inc
            LDA   (PRGPTR)                ; Get raw data, no inc
            RTS
            JMP   GOBCOM                  ; Check for and eat comma
            JMP   INPNUM                  ; Get a 24 bit number
            JMP   INPSTR                  ; Get a string
            JMP   INPNARG                 ; Get a numeric argument
            JMP   INPSARG                 ; Get a string argument
            JMP   ZNUMIN                  ; Get number from (TEMP3)
            JMP   DO_MATH                 ; Save number for math rtns
            JMP   MOVNAME                 ; Get a filename from program
            JMP   BADERR                  ; Generate an error

            JMP   SETIVEC                 ; Set input vector
            JMP   CHKKEY                  ; Check for a key
            JMP   GETCHR                  ; Get a char from buffer
            JMP   INPLN                   ; Input a line
            JMP   RDKEY                   ; Read keystroke

            JMP   SETOVEC                 ; Set output vector
            JMP   COUT                    ; Output a char
            JMP   DECOUT0                 ; Convert number to string
            JMP   DO_SED                  ; Set interrupts

            JMP   PD_MAKE                 ; Create file
            JMP   PD_KILL                 ; Delete file
            JMP   PD_OPEN                 ; Open a file
            JMP   IFOPEN                  ; Open an unused channel
            JMP   PD_CLOSE                ; Close file
            JMP   PD_FLUSH                ; Flush file
            JMP   PD_RDBYT                ; Read a byte from file
            JMP   PD_WRBYT                ; Write a byte to file
            JMP   PD_RDBLK                ; Read block(s) from file
            JMP   PD_WRBLK                ; Write block(s) to file
            JMP   PD_RDLN                 ; Read a line from file
            JMP   PD_GMARK                ; Get a files mark
            JMP   PD_SPOS                 ; Set files mark
            JMP   PD_GPFX                 ; Get current prefix
            JMP   PD_SPFX                 ; Set prefix
            JMP   LOGSYS                  ; Log to system prefix
            DB    NoLbl                   ; force a no label error
            BRA   GONLBL
            JMP   SHOWSTR                 ; Show a string
            JMP   PD_NEWLN                ; Set newline mode

            JMP   ED_CLR                  ; Clear the editor
            JMP   EDIN                    ; Get char from editor
            JMP   EDOUT                   ; Add char to editor
            JMP   ADDCRC                  ; Add byte val to CRC

            JMP   PD_RBYTS                ; Read byte(s) from file
            JMP   PD_WBYTS                ; Write byte(s) to file

            JMP   SYSSTORE                ; Store current variables
            JMP   SYSRCAL                 ; Recall variables

            JMP   COMPRES                 ; Compress Variables
            JMP   UNCOMP                  ; Un-Compress Variables
            JMP   RELOAD                  ; Reload segment
            JMP   DO_CL3                  ; Close all files

            JMP   TOFLN                   ; Move string (X,A) to fn
            JMP   FRMFLN                  ; Move fn to string (X,A)

GONLBL      JMP   NOLABEL                 ; Actual no label routine

WHATSTK     =     $F1E0                   32
            LST   OFF

