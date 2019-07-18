 LST RTN
 TTL 'LLUCE - Compiler Main Line'
 PAG
********************************
*                              *
*          Compiler            *
*                              *
********************************
 DATE
*-------------------------------

COMPILER JMP COMP_A ; Skip Version Number
 DW Version

COMP_A LDX #MLI_END-MLICODE
MOVMLI MOV MLICODE,X;INFOLST,X
 DBPL X;MOVMLI

 LDX FLNAME ; Change Name Back To Source
 MOV #'S';FLNAME,X ; '.S' For Source
 PDOS Getinfo;INFOLST
 BCS COMP_A2
 JSR PD_OPEN ; Open Source File
 BCC COMP_B ; Opps, Problem

COMP_A2 RTS

COMP_B JSR PD_NEWLN ; Setup For Rdline
 MOVD MODULE;TEMP ; Point To Module Space
 STZ LBLNUM
 STZ SYMNUM ; Zero Sym/Lbl Counters
 STZ ONFLAG
 STZ PUBCNT
 STZ ERRFLG
 STZ LINENUM
 STZ LINENUM+1
 JSR SHOWSTR
 DCI 'One Moment, Compiling Segment.'
 TSTPL SHWTXT;PASS1

 PUSHA #23
 MOV CH;OLDCH ; Save Old Values
 MOV CV;OLDCV

 STZ CH ; Position To 0,[Inparg]
 PULL CV

 JSR PR ; Print Message
 ASC 'CMP:'00
 PHXY ; Save Both X & Y
 LDX OLDCH ; Position
 LDY OLDCV
 JSR VIDPOS
 PLXY

*===============================
* ----- Pass 1 ------
*===============================

PASS1 STZ LNCNT ; reset line pointer
 JSR COMPSHOW ; get line of input
 BCC CHECKLBL
 JMP PASS2

CHECKLBL IFEQ LNBUF2;#cr;PASS1 ; is it a space?
 CPEQ #' ';COMMANDS ; is it a space?
 CPEQ #tab;COMMANDS ; or a TAB?
 CPNE #'/';CHKLBL2 ; Start of comment?
 IFNE LNBUF2+1;#'*';LINEERR ; is it a comment?
 JMP DO_COMM

CHKLBL2 CPEQ #'_';CHKLBL3

 JSR TST_ALF
 BCS LINEERR

CHKLBL3 JSR ADD_SYM ; Add To Symbol Table
 BCC PASS1

 LDA #SymFull
 JSR CHECKERR
 BRA PASS1

LINEERR LDA #InvalChr
 JSR CHECKERR
 BRA PASS1

COMMANDS INC LNCNT ; Advance Pointer
CONTINUE LDY LNCNT
 IFNE LNBUF2,Y;#cr;CHECKSPC ; If End Of Line

ENDLINE IFEQ LSTTOK;#Public;JPASS1 ; last tkn public, no chain

 MOV #Chain2;(TEMP) ; Insert A Chain Command
 INCD TEMP ; Increment Temp By 1
JPASS1 JMP PASS1

CHECKSPC CPEQ #tab;COMMANDS
 CPEQ #' ';COMMANDS ; Go Until A Legal Character Of Some Sort
 BLT LINEERR

 CPEQ #'\';JPASS1 ; line continuation?
 CPEQ #'$';DO_NUM ; is it a hex number?
 CPEQ #'"';DOBLOCK ; Check For Text Mode
 CPEQ #''';DOBLOCK ; check for block text
 CPNE #'/';CHKTOKEN ; Start of comment?
 IFEQ LNBUF2+1,Y;#'/';ENDLINE ; end of line comment
 CPNE #'*';NOT_COMM ; make sure its comment
 JMP DO_COMM ; it is a comment

DOBLOCK JMP BLOCK

NOT_COMM LDA #'/'
CHKTOKEN JSR TST_ALF ; is it a letter?
 BCC FINDTKN

CHKNUM JSR TST_NUM
 BCS FINDTKN

DO_NUM JSR NUMBER ; handle the number
 BRA CONTINUE ; continue line

FINDTKN JSR TOKEN ; Get Token Type
 BCC HNDLTKN
 JSR TST_ALF ; was it a letter?
 BCS NORMTKN ; nope, can't be variable
 JMP CHKVAR ; Check For Variable

HNDLTKN CPPL #0;NORMTKN

 PHA
 LDY #1 ; save token
 AND #Clrhi
 STA (TEMP),Y
 MOV #Hitoken;(TEMP) ; and hi flag
 CLC ; gotta add 2 here..
 AD TEMP;#2;TEMP
 BCC DONEHITK
 INC TEMP+1
DONEHITK PLA
 STA LSTTOK
 JMP CONTINUE

NORMTKN CPNE #Public;PUTTKN ; Is It Public?
 INC PUBCNT
 IFGE PUBCNT;#9;PUBERR

 STA LSTTOK
 JSR ADD_LBL ; Add Label To Table
 JMP CONTINUE

PUBERR LDA #PubFull
 JSR CHECKERR
 JMP PASS1

PUTTKN STA (TEMP)
 INCD TEMP ; Increment Temp By 1
 CPEQ #Push;LABELTOK ; Check To See If Label Follows
 CPEQ #Goto;LABELTOK
 CPNE #Gosub;CHKON
 IFEQY LSTTOK;#Clear;CHKON ; Skip Lbl Chk If clear gosub

LABELTOK JMP DOLABEL

CHKON LDY LSTTOK
 STA LSTTOK
 CPEQ #On;SETUPON ; Is It An ON Command?
 CPEQ #Nocar;CLEARON ; Is This An NOCAR Command?
 CPNE #Onerr;TOKDONE ; How About ERROR?
CLEARON STZ ONFLAG ; Clear ON Flag
 JMP CONTINUE

SETUPON CPEQY #AnsiTkn;TOKDONE
 CPEQY #Edit;TOKDONE
 CPEQY #Flash;TOKDONE
 CPEQY #Convert;TOKDONE
 DEC ONFLAG ; Flag It
 STZ ONCOUNT ; Zero The Count
TOKDONE JMP CONTINUE

*===============================
* ----- Handle Variables -----
*===============================

CHKVAR ORA #Hibit
 STA LSTVNAM ; Save First Char Of Name
 STZ LSTVNAM+1 ; Clear rest of name
 STZ LSTVNAM+2
 STZ LSTVNAM+3
 LDY #1
GETNAME LDX LNCNT
 LDA LNBUF2,X ; See If There Is Another
 JSR TST_ALF
 BCC NAMESAVE
 JSR TST_NUM
 BCS SKIPXTRA

NAMESAVE JSR CONV
 ORA #Hibit
 STA LSTVNAM,Y ; Save next char of name
 INY
 INC LNCNT
 CPNEY #4;GETNAME

SKIPXTRA DEC LNCNT
 LDX LNCNT
GOBBLEX INX
 LDA LNBUF2,X ; Gobble Rest Of Name
 JSR TST_ALF
 BCC GOBBLEX
 JSR TST_NUM
 BCC GOBBLEX

SETVAR STX LNCNT
 LDX #Number
 CPNE #'$';PUTVTYPE ; check if its number or string
 INC LNCNT
 LDX #String
PUTVTYPE TXA  ; Save variable type
 STA (TEMP)
 INCD TEMP ; Increment Temp By 1
 MOV LSTVNAM;(TEMP) ; Move to code space
 INCD TEMP ; Increment Temp By 1
 LDEQ LSTVNAM+1;VARDONE
 STA (TEMP)
 INCD TEMP ; Increment Temp By 1
 LDEQ LSTVNAM+2;VARDONE
 STA (TEMP)
 INCD TEMP ; Increment Temp By 1
 LDEQ LSTVNAM+3;VARDONE
 STA (TEMP)
 INCD TEMP ; Increment Temp By 1
VARDONE JMP CONTINUE

*===============================
* ----- Handle Labels -----
*===============================

DOLABEL TSTPL ONFLAG;FLAGLBL ; Doing An ON Statement?
 MOVD TEMP;TEMP3 ; Save Position for ON count
 INCD TEMP ; skip count location
FLAGLBL MOV #Label;(TEMP) ; Flag As Label
 INCD TEMP ; Increment Temp By 1
 JSR ADD_LBL ; Add Label To Table 2
 BCC PUTLBLN
 JMP ENDLINE ; Restart With State 0

PUTLBLN STA (TEMP) ; save label number
 INCD TEMP ; Increment Temp By 1
 TSTPL ONFLAG;LBLDONE ; Doing An ON Command?
 INC ONCOUNT ; Increment Count
 LDY LNCNT ; Get Next Character
 LDA LNBUF2,Y
 INC LNCNT ; Bump Counter In Case
 CPNE #',';SETONCNT ; More Labels?
 INY
 IFNE LNBUF2,Y;#'\';FLAGLBL ; line link?

NXTLBLIN STZ LNCNT ; Reset Line Pointer
 JSR COMPSHOW ; Get Line Of Input
 BCC GETLBCHR
 JMP PASS2

NXTLBCHR INC LNCNT
GETLBCHR LDY LNCNT ; Check Character In Line
 IFEQ LNBUF2,Y;#'\';NXTLBLIN ; Line Link, Get Another
 CPEQ #tab;NXTLBCHR
 CPEQ #' ';NXTLBCHR ; Invalid Character?
 BGE FLAGLBL ; get next label
 JMP LINEERR ; bad char, show it

SETONCNT DEC LNCNT ; Back Down Count
 MOV ONCOUNT;(TEMP3) ; Insert Count
 STZ ONFLAG
LBLDONE JMP CONTINUE ; Continue Compile

*===============================
* Do Text/Block Mode Processing
*===============================

BLOCK STA TEMP2 ; Save Delimiter Char For Text/Block Mode
 LDRA #'"'+Hibit;CHKBLKCH

NXTBLKCH LDY LNCNT
 IFEQ LNBUF2,Y;TEMP2;BLKDONE ; Check For Delimiter

CHKBLKCH CPNE #'\';CHKBLKCR ; is it an escape?
 IFEQ LNBUF2+1,Y;#cr;GETBLKLN ; continue line?
 JSR TEXTESC ; handle it
 BRA NXTBLKCH ; do next

CHKBLKCR CPNE #cr;PUTBLKCH ; End Of Line?

 IFEQ TEMP2;#'"';TEXTDONE ; Text, Do Finish Up

 LDA #cr ; Stick In cr If In Block
PUTBLKCH STA (TEMP)
 INCD TEMP ; Increment Temp By 1
 INC LNCNT
 CPNE #cr;NXTBLKCH ; Check Byte

 STZ LNCNT ; Reset Line Counter
 MOV #-1;BLOCKFLG ; Flag reading a block

GETBLKLN JSR COMPSHOW ; Read New Line
 STZ BLOCKFLG
 BCC NXTBLKCH ; Keep Checking

 LDA #NoQuote
 JSR CHECKERR ; Print In Text Warning
 JMP PASS2 ; Were done

BLKDONE INC LNCNT ; Bump Pointer
TEXTDONE MOV #'"'+Hibit;(TEMP)
 INCD TEMP ; Increment Temp By 1
CONTCOMP JMP CONTINUE

*===============================
* Handle comments
*===============================

NXT_COMM JSR COMPSHOW ; Read New Line
 STZ LNCNT ; Reset Line Counter
 BRA COMM_LUP

DO_COMM INC LNCNT ; Bypass the /*
 MOV #-1;BLOCKFLG ; Check all lines
COMM_LUP INC LNCNT
 LDY LNCNT
 IFEQ LNBUF2,Y;#cr;NXT_COMM
 CPNE #'*';COMM_LUP ; check for */
 IFNE LNBUF2+1,Y;#'/';COMM_LUP
 STZ BLOCKFLG
 INC LNCNT
 IBRA LNCNT;CONTCOMP

*===============================
* ----- Pass 2 -----
*===============================

PASS2 JSR SHOWSTR
 DCI '..'
 STZ LINENUM
 STZ LINENUM+1
 MOV #End;(TEMP) ; Make Sure Segment Ends
 INCD TEMP ; Increment Temp By 1
 MOV #Labelend;(TEMP) ; Save End Pointer
 INCD TEMP ; Increment Temp By 1
 JSR PD_CLOSE
 LDX #$80 ; Zero Out The Input Buffer
ZEROPUB STZ LNBUF,X
 IBNE X;ZEROPUB

 LDX SYMNUM ; Mark End Of Tables
 STZ SYMTAB,X
 LDX LBLNUM
 STZ LBLTAB,X

 MOV TEMP;LOMEM ; Setup Pointers To Variable Space
 STA LNBUF+142
 MOV TEMP+1;LNBUF+143 ; Save For Compiled Segments
 STA LOMEM+1

*-------------------------------
* Copy First 8 Labels (For Public)
*-------------------------------

 LDEQ PUBCNT;VFYLABS ; Any labels??

 LDX #$80 ; Start Counters
 LDY #0
COPYPUB PHX
 MOV #>LBLTAB;COPYPUB2+2
COPYPUB2 LDA LBLTAB,Y ; *** Self-Modified
 INC COPYPUB2+2 ; Changes Code
 STA LNBUF,X ; Save Data
 ASL A ; This makes it so only
 BCS COPYPUB3 ; the actual label is copied
 INX
 TXA
 AND #%00001000 ; Have We Done 8 Yet?
 BEQ COPYPUB2 ; Nope

COPYPUB3 INY ; Ready For Next
 CPEQY PUBCNT;COPYPUB4 ; Any more labels?
 BLT COPYPUB4
 PLA
 BRA COPYPUB5 ; nope

COPYPUB4 PLA
 CLC
 ADC #$10 ; Add It Up.
 TAX
 BCC COPYPUB ; Keep Going

COPYPUB5 MOV #>LBLTAB;COPYPUB2+2 ; Reset Byte For CRC

VFYLABS LDX #-1 ; Start At Beginning Of Table
VERLBLS INX
 LDNE LBLTAB,X;LBLSRCH
 JMP PASS3 ; Are We Done?

LBLSRCH LDY #-1
NXTLBL INY
 LDNE SYMTAB,Y;VERLBLSE ; keep checking

 PHX
 LDNE ERRFLG;LBNFERR ; has an error happened before?

 JSR CROUT

LBNFERR MOV #1;ERRFLG ; makes sure it doesn't pass 0
 JSR SHOWSTR
 DB inv
 DCI 'A Label Was Not Found [' ; 5 NoLabel
 PLX ; Get Back Label Number
 MOV #>LBLTAB;SHOWLBL+2 ; start at first char
SHOWLBL LDA LBLTAB,X
 PHP
 AND #Clrhi
 JSR COUT ; Print Char
 INC SHOWLBL+2 ; Get Ready For Next
 PLP
 BPL SHOWLBL ; Loop Until Finished

 MOV #>LBLTAB;SHOWLBL+2 ; Reset Byte For CRC

 JSR SHOWSTR
 DB ']',norm,cr+Hibit
 MOV #<NOLABEL;LBLTAB+L0,X ; Put Bad Branch Error Routine
 MOV #>NOLABEL;LBLTAB+L1,X
 TSTMI REMOTE;VERLBLS
 JSR PAUSEIT
 BRA VERLBLS

BRNXTLBL BRA NXTLBL ; Extension From Branches

VERLBLSE IFNE LBLTAB+L0,X;SYMTAB+L0,Y;BRNXTLBL
 ASL A
 BCS CPYLBLAD ; High Bit Means Were Done
 IFNE LBLTAB+L1,X;SYMTAB+L1,Y;BRNXTLBL
 ASL A
 BCS CPYLBLAD
 IFNE LBLTAB+L2,X;SYMTAB+L2,Y;BRNXTLBL
 ASL A
 BCS CPYLBLAD
 IFNE LBLTAB+L3,X;SYMTAB+L3,Y;BRNXTLBL
 ASL A
 BCS CPYLBLAD
 IFNE LBLTAB+L4,X;SYMTAB+L4,Y;BRNXTLBL
 ASL A
 BCS CPYLBLAD
 IFNE LBLTAB+L5,X;SYMTAB+L5,Y;BRNXTLBL
 ASL A
 BCS CPYLBLAD
 IFNE LBLTAB+L6,X;SYMTAB+L6,Y;BRNXTLBL
 ASL A
 BCS CPYLBLAD
 IFNE LBLTAB+L7,X;SYMTAB+L7,Y;BRNXTLBL
CPYLBLAD MOV SYMTAB+L8,Y;LBLTAB+L0,X ; Copy Label Address
 MOV SYMTAB+L9,Y;LBLTAB+L1,X
 JMP VERLBLS

*===============================
* ----- Pass 3 -----
*===============================

PASS3 LDEQ PUBCNT;ADDPTRS ; Any labels??

 LDX #$80 ; Start Counters
 LDY #0
CPYPUBAD MOV LBLTAB+L0,Y;LNBUF+8,X ; Move First Address
 MOV LBLTAB+L1,Y;LNBUF+9,X

 INY ; Inc address #
 CPEQY PUBCNT;CPYPUBA2 ; Any more labels?
 BGE ADDPTRS ; nope
CPYPUBA2 TXA
 CLC
 ADC #$10 ; Move Dest Pointer
 TAX
 BCC CPYPUBAD ; More Data, Keep Going

ADDPTRS MOVD MODULE;TEMP ; Point At Module
 STZ TEMP2 ; flag no text
 STZ TEMP2+1
 LDY #1 ; Offset Was 0 Or 1 Only
SCAN LDA TEMP2+1
 STA LSTTOK
SCAN2 LDA (TEMP)
 CPNE #Labelend;SCANTEST
 JMP SAVESEG

SCANTEST CPNE #'"'+Hibit;NOTTXT ; is it text?

 PHA ; set mode flag
 EOR TEMP2
 STA TEMP2
 PLA
SCAN3 INCD TEMP
 BRA SCAN2

NOTTXT TSTMI TEMP2;SCAN3 ; if in text mode, just skip

 CPNE #Hitoken;NOT_HIGH ; high order token?
 INCD TEMP ; get next token
 LDA (TEMP)
 ORA #Hibit ; make it high
NOT_HIGH STA TEMP2+1
 CPEQ #Number;SCANVAR ; If number or string
 CPNE #String;CHKCONST ; skip all used bytes

SCANVAR INCD TEMP ; Increment Temp By 1
 LDPL (TEMP);SCAN ; if positive, not var name
 JSR TST_ALF
 BCC SCANVAR
 JSR TST_NUM
 BCC SCANVAR
G_SCAN BRA SCAN

CHKCONST CPEQ #ThreeByte;SCANCON4 ; 3 byte number?
 CPEQ #TwoByte;SCANCON3 ; 2 byte number?
 CPEQ #OneByte;SCANCON2 ; 1 byte number?
 CPEQ #On;SKIPON
 CPEQ #Hitoken;SCANCON2 ; is it a high token?
 CPNE #Label;SCANSKIP ; is it a label?

 LDA (TEMP),Y ; Get Label Address
 TAX ; And Insert Into Code
 MOV LBLTAB+L1,X;(TEMP),Y
 MOV LBLTAB+L0,X;(TEMP)
SCANCON2 LDA #2
 SKIP2
SCANCON4 LDA #4
 SKIP2
SCANCON3 LDA #3
 SKIP2
SCANSKIP LDA #1
 CLC
 ADA TEMP;TEMP
 BCC G_SCAN
 INC TEMP+1
 BRA G_SCAN

SKIPON IFEQX LSTTOK;#AnsiTkn;SCANSKIP
 CPEQX #Convert;SCANSKIP
 CPEQX #Flash;SCANSKIP
 CPEQX #Edit;SCANSKIP
 INCD TEMP ; point to next token
 IFEQ (TEMP);#Onerr;G_SCAN
 CPEQ #Nocar;G_SCAN
 CPEQ #Goto;SCANCON2 ; is it a goto?
 CPEQ #Gosub;SCANCON2 ; or gosub
 CPEQ #Push;SCANSKIP ; or push
 BRA SKIPON

*===============================
* ----- Save segment -----
*===============================

SAVESEG LDX FLNAME ; Add '.C' Back On
 MOV #'C';FLNAME,X
 MOV #7;INFOLST
 LDY #^compiled ; LLUCE Compiled File
 LD16 #compiled ; aux type ($8003)
 JSR PD_MAKE
 JSR PD_OPEN
 BCS SAVEERR ; If Problem

 PUSHA MSGREF ; Save Msg Refnum
 MOV REFNUM;MSGREF ; And Replace With Current

 MOVD MODULE;LNBUF+138 ; Put Seg Start In

 MOV #'L';LNBUF+140 ; Save I/D Bytes
 MOV #'P';LNBUF+141

 MOVD VERSION;LNBUF+254 ; Save Version Bytes

 LD16 #LNBUF+$80 ; Write Out Header (With Label Info)
 LDY #1
 JSR PD_WRBLK

 SEC
 LDA LOMEM+1
 SBC MODULE+1 ; Find # Of Pages In Module
 ASL A ; Multiply By 2 Into Blocks
 TAY
 INY ; Add In Extra Page Just In Case
 INY
 LD16 MODULE ; Write Rest Of Data
 JSR PD_WRBLK

 JSR PD_CLOSE ; Finish Up

 MOV #^compiled;I_FTYPE ; LLUCE Compiled File
 MOVD #compiled;I_ATYPE ; aux type ($8003)
 INC I_MODT ; Make the file newer
 PDOS Setinfo;INFOLST ; than the source
 PULL MSGREF ; And Restore

SAVEERR BCC SAVENERR
 LDA #WriteErr
 JSR CHECKERR

SAVENERR TSTPL SHWTXT;TSTWIPE

 PUSHA #23
 MOV CH;OLDCH ; Save Old Values
 MOV CV;OLDCV

 STZ CH ; Position To 0,[Inparg]
 PULL CV

 JSR PR
 ASC 'INP:'00
 PHXY ; Save Both X & Y
 LDX OLDCH ; Position
 LDY OLDCV
 JSR VIDPOS
 PLXY

TSTWIPE LDNE ERRFLG;EXITCOMP ; Any Error While Compiling?

 JSR SHOWSTR
 DS 32,bs
 DS 32,' '
 DS 31,bs
 DB bs+Hibit
 LDA KYBD ; Check Local Keyboard
 ORA #Hibit
 CPNE #'Z'-Ctrl+Hibit;EXITCOMP

PAUSEIT STA KBDSTRB
 JSR RDKEY ; Wait For A Keypress
EXITCOMP CLC
 RTS

MLICODE ORG FREESPACE

INFOLST DB 10
I_PATH DA FLNAME
I_ACC DB 0
I_FTYPE DB 0
I_ATYPE DW 0
I_STYPE DB 0
I_BLKS DW 0
I_MODD DW 0
I_MODT DW 0
I_CRTD DW 0
I_CRTT DW 0
 ORG
MLI_END = *
 LST OFF
