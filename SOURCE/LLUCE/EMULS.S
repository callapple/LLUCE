**************************************************
*
* Emulation sequence tables.
*
* Contains:
*
*  Datamedia 1500
*  HeathKit H-19
*  TeleVideo 1500, SOROC IQ, ADM-3A
*  Hazeltine 1500
*  IBM
*  VT-52
*  ProTerm special
*  ANSI (VT-100)
**************************************************

DM15LST     =     *
DM15home    HEX   0119        ; Home
            DS    8-*+DM15home
DM15up      HEX   011F        ; Cursor up
            DS    8-*+DM15up
DM15down    HEX   010A        ; Cursor down
            DS    8-*+DM15down
DM15left    HEX   0108        ; Cursor left
            DS    8-*+DM15left
DM15rght    HEX   011C        ; Cursor right
            DS    8-*+DM15rght
DM15eos     HEX   010B        ; Clear to eos
            DS    8-*+DM15eos
DM15bos     HEX   00          ; Clear to bos
            DS    8-*+DM15bos
DM15cls     HEX   010C        ; Clear screen
            DS    8-*+DM15cls
DM15eol     HEX   011D        ; Clear to eol
            DS    8-*+DM15eol
DM15bol     HEX   00          ; Clear to bol
            DS    8-*+DM15bol
DM15cll     HEX   020D1D      ; Clear line
            DS    8-*+DM15cll
DM15iln     HEX   00          ; Insert line
            DS    8-*+DM15iln
DM15dln     HEX   00          ; Delete line
            DS    8-*+DM15dln
DM15ich     HEX   00          ; Insert char
            DS    8-*+DM15ich
DM15dch     HEX   00          ; Delete char
            DS    8-*+DM15dch
DM15nor     HEX   010E        ; Normal
            DS    8-*+DM15nor
DM15inv     HEX   010F        ; Inverse
            DS    8-*+DM15inv
DM15goxy    HEX   011E        ; Goto XY
            DS    8-*+DM15goxy
DM15mous    HEX   00          ; Mouse text on
            DS    8-*+DM15mous
DM15offs    DB    32          ; XY offset and order
            DS    \

H19LST      =     *
H19home     HEX   021B48      ; Home
            DS    8-*+H19home
H19up       HEX   021B41      ; Cursor up
            DS    8-*+H19up
H19down     HEX   021B42      ; Cursor down
            DS    8-*+H19down
H19left     HEX   021B44      ; Cursor left
            DS    8-*+H19left
H19rght     HEX   021B43      ; Cursor right
            DS    8-*+H19rght
H19eos      HEX   021B4A      ; Clear to eos
            DS    8-*+H19eos
H19bos      HEX   00          ; Clear to bos
            DS    8-*+H19bos
H19cls      HEX   021B45      ; Clear screen
            DS    8-*+H19cls
H19eol      HEX   021B4B      ; Clear to eol
            DS    8-*+H19eol
H19bol      HEX   00          ; Clear to bol
            DS    8-*+H19bol
H19cll      HEX   030D1B4B    ; Clear line
            DS    8-*+H19cll
H19iln      HEX   021B4C      ; Insert line
            DS    8-*+H19iln
H19dln      HEX   021B4D      ; Delete line
            DS    8-*+H19dln
H19ich      HEX   00          ; Insert char
            DS    8-*+H19ich
H19dch      HEX   021B4E      ; Delete char
            DS    8-*+H19dch
H19nor      HEX   021B70      ; Normal
            DS    8-*+H19nor
H19inv      HEX   021B71      ; Inverse
            DS    8-*+H19inv
H19goxy     HEX   021B59      ; Goto XY
            DS    8-*+H19goxy
H19mous     HEX   00          ; Mouse text on
            DS    8-*+H19mous
H19offs     DB    32+128      ; XY offset and order
            DS    \

TV          =     *
TVhome      HEX   011E        ; Home
            DS    8-*+TVhome
TVup        HEX   010B        ; Cursor up
            DS    8-*+TVup
TVdown      HEX   010A        ; Cursor down
            DS    8-*+TVdown
TVleft      HEX   0108        ; Cursor left
            DS    8-*+TVleft
TVrght      HEX   010C        ; Cursor right
            DS    8-*+TVrght
TVeos       HEX   021B59      ; Clear to eos
            DS    8-*+TVeos
TVbos       HEX   00          ; Clear to bos
            DS    8-*+TVbos
TVcls       HEX   011A        ; Clear screen
            DS    8-*+TVcls
TVeol       HEX   021B54      ; Clear to eol
            DS    8-*+TVeol
TVbol       HEX   00          ; Clear to bol
            DS    8-*+TVbol
TVcll       HEX   030D1B54    ; Clear line
            DS    8-*+TVcll
TViln       HEX   021B45      ; Insert line
            DS    8-*+TViln
TVdln       HEX   021B52      ; Delete line
            DS    8-*+TVdln
TVich       HEX   021B51      ; Insert char
            DS    8-*+TVich
TVdch       HEX   021B57      ; Delete char
            DS    8-*+TVdch
TVnor       HEX   021B6B      ; Normal
            DS    8-*+TVnor
TVinv       HEX   021B6A      ; Inverse
            DS    8-*+TVinv
TVgoxy      HEX   021B3D      ; Goto XY
            DS    8-*+TVgoxy
TVmous      HEX   00          ; Mouse text on
            DS    8-*+TVmous
TVoffs      DB    32+128      ; XY offset and order
            DS    \

HAZLLST     =     *
HAZLhome    HEX   027E12      ; Home
            DS    8-*+HAZLhome
HAZLup      HEX   027E0B      ; Cursor up
            DS    8-*+HAZLup
HAZLdown    HEX   010A        ; Cursor down
            DS    8-*+HAZLdown
HAZLleft    HEX   0108        ; Cursor left
            DS    8-*+HAZLleft
HAZLrght    HEX   0110        ; Cursor right
            DS    8-*+HAZLrght
HAZLeos     HEX   027E18      ; Clear to eos
            DS    8-*+HAZLeos
HAZLbos     HEX   00          ; Clear to bos
            DS    8-*+HAZLbos
HAZLcls     HEX   047E127E18  ; Clear screen
            DS    8-*+HAZLcls
HAZLeol     HEX   027E0F      ; Clear to eol
            DS    8-*+HAZLeol
HAZLbol     HEX   00          ; Clear to bol
            DS    8-*+HAZLbol
HAZLcll     HEX   030D7E0F    ; Clear line
            DS    8-*+HAZLcll
HAZLiln     HEX   027E1A      ; Insert line
            DS    8-*+HAZLiln
HAZLdln     HEX   027E13      ; Delete line
            DS    8-*+HAZLdln
HAZLich     HEX   027E1C      ; Insert char
            DS    8-*+HAZLich
HAZLdch     HEX   00          ; Delete char
            DS    8-*+HAZLdch
HAZLnor     HEX   027E1F      ; Normal
            DS    8-*+HAZLnor
HAZLinv     HEX   027E19      ; Inverse
            DS    8-*+HAZLinv
HAZLgoxy    HEX   027E11      ; Goto XY
            DS    8-*+HAZLgoxy
HAZLmous    HEX   00          ; Mouse text on
            DS    8-*+HAZLmous
HAZLoffs    DB    0           ; XY offset and order
            DS    \

IBMLST      =     *
IBMhome     HEX   021B48      ; Home
            DS    8-*+IBMhome
IBMup       HEX   021B41      ; Cursor up
            DS    8-*+IBMup
IBMdown     HEX   021B42      ; Cursor down
            DS    8-*+IBMdown
IBMleft     HEX   021B44      ; Cursor left
            DS    8-*+IBMleft
IBMrght     HEX   021B43      ; Cursor right
            DS    8-*+IBMrght
IBMeos      HEX   021B4A      ; Clear to eos
            DS    8-*+IBMeos
IBMbos      HEX   00          ; Clear to bos
            DS    8-*+IBMbos
IBMcls      HEX   041B481B4A  ; Clear screen
            DS    8-*+IBMcls
IBMeol      HEX   021B49      ; Clear to eol
            DS    8-*+IBMeol
IBMbol      HEX   00          ; Clear to bol
            DS    8-*+IBMbol
IBMcll      HEX   030D1B49    ; Clear line
            DS    8-*+IBMcll
IBMiln      HEX   00          ; Insert line
            DS    8-*+IBMiln
IBMdln      HEX   00          ; Delete line
            DS    8-*+IBMdln
IBMich      HEX   00          ; Insert char
            DS    8-*+IBMich
IBMdch      HEX   00          ; Delete char
            DS    8-*+IBMdch
IBMnor      HEX   00          ; Normal
            DS    8-*+IBMnor
IBMinv      HEX   00          ; Inverse
            DS    8-*+IBMinv
IBMgoxy     HEX   021B59      ; Goto XY
            DS    8-*+IBMgoxy
IBMmous     HEX   00          ; Mouse text on
            DS    8-*+IBMmous
IBMoffs     DB    32          ; XY offset and order
            DS    \

VT52LST     =     *
VT52home    HEX   021B48      ; Home
            DS    8-*+VT52home
VT52up      HEX   021B41      ; Cursor up
            DS    8-*+VT52up
VT52down    HEX   021B42      ; Cursor down
            DS    8-*+VT52down
VT52left    HEX   021B44      ; Cursor left
            DS    8-*+VT52left
VT52rght    HEX   021B43      ; Cursor right
            DS    8-*+VT52rght
VT52eos     HEX   021B4A      ; Clear to eos
            DS    8-*+VT52eos
VT52bos     HEX   00          ; Clear to bos
            DS    8-*+VT52bos
VT52cls     HEX   010C        ; Clear screen
            DS    8-*+VT52cls
VT52eol     HEX   021B4B      ; Clear to eol
            DS    8-*+VT52eol
VT52bol     HEX   00          ; Clear to bol
            DS    8-*+VT52bol
VT52cll     HEX   030D1B4B    ; Clear line
            DS    8-*+VT52cll
VT52iln     HEX   00          ; Insert line
            DS    8-*+VT52iln
VT52dln     HEX   00          ; Delete line
            DS    8-*+VT52dln
VT52ich     HEX   00          ; Insert char
            DS    8-*+VT52ich
VT52dch     HEX   00          ; Delete char
            DS    8-*+VT52dch
VT52nor     HEX   0E          ; Normal
            DS    8-*+VT52nor
VT52inv     HEX   0F          ; Inverse
            DS    8-*+VT52inv
VT52goxy    HEX   021B5A      ; Goto XY
            DS    8-*+VT52goxy
VT52mous    HEX   00          ; Mouse text on
            DS    8-*+VT52mous
VT52offs    DB    32          ; XY offset and order
            DS    \

PTLST       =     *
PThome      HEX   0118        ; Home
            DS    8-*+PThome
PTup        HEX   010B        ; Cursor up
            DS    8-*+PTup
PTdown      HEX   010A        ; Cursor down
            DS    8-*+PTdown
PTleft      HEX   0108        ; Cursor left
            DS    8-*+PTleft
PTrght      HEX   0115        ; Cursor right
            DS    8-*+PTrght
PTeos       HEX   0117        ; Clear to eos
            DS    8-*+PTeos
PTbos       HEX   00          ; Clear to bos
            DS    8-*+PTbos
PTcls       HEX   010C        ; Clear screen
            DS    8-*+PTcls
PTeol       HEX   0119        ; Clear to eol
            DS    8-*+PTeol
PTbol       HEX   00          ; Clear to bol
            DS    8-*+PTbol
PTcll       HEX   020119      ; Clear line
            DS    8-*+PTcll
PTiln       HEX   0116        ; Insert line
            DS    8-*+PTiln
PTdln       HEX   011A        ; Delete line
            DS    8-*+PTdln
PTich       HEX   0106        ; Insert char
            DS    8-*+PTich
PTdch       HEX   0104        ; Delete char
            DS    8-*+PTdch
PTnor       HEX   010E        ; Normal
            DS    8-*+PTnor
PTinv       HEX   010F        ; Inverse
            DS    8-*+PTinv
PTgoxy      HEX   011E        ; Goto XY
            DS    8-*+PTgoxy
PTmous      HEX   0110        ; Mouse text on
            DS    8-*+PTmous
PToffs      DB    32          ; XY offset and order
            DS    \

ANSILST     =     *
ANSIhome    HEX   031B5B48    ; Home
            DS    8-*+ANSIhome
ANSIup      HEX   031B5B41    ; Cursor up
            DS    8-*+ANSIup
ANSIdown    HEX   031B5B42    ; Cursor down
            DS    8-*+ANSIdown
ANSIleft    HEX   031B5B44    ; Cursor left
            DS    8-*+ANSIleft
ANSIrght    HEX   031B5B43    ; Cursor right
            DS    8-*+ANSIrght
ANSIeos     HEX   041B5B304A  ; Clear to eos
            DS    8-*+ANSIeos
ANSIbos     HEX   041B5B314A  ; Clear to bos
            DS    8-*+ANSIbos
ANSIcls     HEX   041B5B324A  ; Clear screen
            DS    8-*+ANSIcls
ANSIeol     HEX   041B5B304B  ; Clear to eol
            DS    8-*+ANSIeol
ANSIbol     HEX   041B5B314B  ; Clear to bol
            DS    8-*+ANSIbol
ANSIcll     HEX   041B5B324B  ; Clear line
            DS    8-*+ANSIcll
ANSIiln     HEX   031B5B4C    ; Insert line
            DS    8-*+ANSIiln
ANSIdln     HEX   031B5B4D    ; Delete line
            DS    8-*+ANSIdln
ANSIich     HEX   031B5B40    ; Insert char
            DS    8-*+ANSIich
ANSIdch     HEX   031B5B50    ; Delete char
            DS    8-*+ANSIdch
ANSInor     HEX   041B5B306D  ; Normal
            DS    8-*+ANSInor
ANSIinv     HEX   061B5B303B376D  ; Inverse
            DS    8-*+ANSIinv
ANSIgoxy    HEX   00          ; GotoXY (handled special)
            DS    8-*+ANSIgoxy
ANSImous    HEX   00
            DS    8-*+ANSImous
ANSIoffs    DB    0
            DS    \

BLNKLST     =     *
BLNKhome    HEX   00          ; Home
            DS    8-*+BLNKhome
BLNKup      HEX   00          ; Cursor up
            DS    8-*+BLNKup
BLNKdown    HEX   00          ; Cursor down
            DS    8-*+BLNKdown
BLNKleft    HEX   00          ; Cursor left
            DS    8-*+BLNKleft
BLNKrght    HEX   00          ; Cursor right
            DS    8-*+BLNKrght
BLNKeos     HEX   00          ; Clear to eos
            DS    8-*+BLNKeos
BLNKbos     HEX   00          ; Clear to bos
            DS    8-*+BLNKbos
BLNKcls     HEX   00          ; Clear screen
            DS    8-*+BLNKcls
BLNKeol     HEX   00          ; Clear to eol
            DS    8-*+BLNKeol
BLNKbol     HEX   00          ; Clear to bol
            DS    8-*+BLNKbol
BLNKcll     HEX   00          ; Clear line
            DS    8-*+BLNKcll
BLNKiln     HEX   00          ; Insert line
            DS    8-*+BLNKiln
BLNKdln     HEX   00          ; Delete line
            DS    8-*+BLNKdln
BLNKich     HEX   00          ; Insert char
            DS    8-*+BLNKich
BLNKdch     HEX   00          ; Delete char
            DS    8-*+BLNKdch
BLNKnor     HEX   00          ; Normal
            DS    8-*+BLNKnor
BLNKinv     HEX   00          ; Inverse
            DS    8-*+BLNKinv
BLNKgoxy    HEX   00          ; Goto XY
            DS    8-*+BLNKgoxy
BLNKmous    HEX   00          ; Mouse text on
            DS    8-*+BLNKmous
BLNKoffs    DB    32          ; XY offset and order
            DS    \

