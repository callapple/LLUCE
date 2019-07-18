            LST   OFF
            TR
            TR    ADR
*-------------------------------
* Config Program - Ospjunk
*-------------------------------
* Date: 12/2/89
*-------------------------------

            REL
temp        =     0
temp2       =     2
temp3       =     4
temp4       =     6

fmparm      =     $60
doszero     =     $62
dosptr      =     $64
part        =     $66
dosbyt      =     $68

lnbuf       =     $200
flname      =     $300
devnam      =     $800
fbuf1       =     $1C00
fnam1       =     $1E00
fbuf2       =     fbuf1
fnam2       =     fnam1
msgbuf      =     fbuf1
msgnam      =     fnam1
miscbuf     =     fbuf1
miscnam     =     fnam1

copybuf     =     $6000
copymax     =     $5800
mli         =     $BF00

            DSK   REL/OSPJUNK

cls         EXT
print       EXT
inpln       EXT
inpmode     EXT
maxlen      EXT
ld_drvs     EXT
getname     EXT
open        EXT
geteof      EXT
rdblk       EXT
close       EXT
create      EXT
wrblk       EXT
refnum      EXT
slot        EXT
drive       EXT

*-------------------------------
* load the acos.obj file after find out where it is

drv_path    ENT
            JSR   cls          ; clear screen

            JSR   print
            ASC   'Please enter the pathname of the volume or'
            ASC   ' subdirectory which contains the'0D0D
            ASC   'file:  LLUCE.DRIVERS'0D0D0D
            ASC   'Path: /'00

            LDA   #32          ; set maximum pathname at 32
            STA   maxlen
            LDA   #%11000000
            STA   inpmode      ; set input mode

            JSR   inpln
            INY
            STY   lnbuf-2      ; save length
            LDA   #'/'
            STA   lnbuf-1      ; save initial '/'

            JSR   mli
            DB    $C6          ; set prefix
            DA    p_spfx
            BCS   drv_p2       ; error

            JSR   mli
            DB    $C7          ; get prefix and put into
            DA    p_pfx4       ; program byffer

            JSR   ld_drvs      ; load in the stats
            BCC   logcon       ; all is ok

drv_p2      JMP   drv_path     ; opps, error


*-------------------------------
* log back to the config disk
; log back to config disk
logcon      ENT
            JSR   mli
            DB    $C6          ; set prefix
            DA    p_pfx2
; ... later, add in error checking
            RTS

*-------------------------------
* log the destination disk

logdst      ENT
            JSR   mli
            DB    $C6
            DA    p_pfx3
; ... later, add in error checking
            RTS

*-------------------------------
* log the program disk

logprg      ENT
            LDA   prgpfx       ; has a program prefix been defined?
            BEQ   logcon       ; nope, log to config disk

            JSR   mli
            DB    $C6          ; log to program disk (with LLUCE.SYSTEM)
            DA    p_pfx4
            RTS

*-------------------------------
* move filename to user routine

movname     ENT
            STX   dosbyt       ; point to filename
            STA   dosbyt+1

            LDY   #15
:movnam2    LDA   (dosbyt),y   ; copy filename
            STA   flname,y
            DEY
            BPL   :movnam2
            RTS
; variables and stuff
msgref      ENT
            DB    0
module      DB    0
sdvparm     DB    0,0,0


copyrts     JMP   logcon       ; log back to main

*-------------------------------
* copy a list of files

copy        ENT
            STX   temp4        ; save pointer for getname
            STA   temp4+1

:copy2      JSR   getname      ; get source name
            BCS   copyrts

            JSR   logcon       ; log to config disk

            LDX   #<flname     ; get info on file
            LDA   #>flname
            JSR   getinfo
            BNE   :copy2       ; opps, error, skip this file

            JSR   open
            JSR   geteof       ; get eof marker
            STX   p_geof+2
            STA   p_geof+3     ; save marker
            STA   temp
            CPX   #0           ; save number of pages to read
            BEQ   *+4
            INC   temp

            LDX   #<copybuf
            LDA   #>copybuf
            LDY   #>copymax*2  ; get maximum ram space
            JSR   rdblk

            JSR   close        ; close the file

            JSR   logdst       ; log to destination

            LDY   #0           ; use type $00
            JSR   create       ; create file

            JSR   open         ; open file

            LDA   temp
            ASL                ; get number of blocks (1/2 pages) to write
            TAY
            LDX   #<copybuf
            LDA   #>copybuf
            JSR   wrblk        ; write out the block

            JSR   seteof       ; set end of file
            JSR   close

            LDX   #<flname
            LDA   #>flname
            JSR   setinfo      ; set file info
            JMP   :copy2

*-------------------------------
* get info on a file

getinfo     ENT
            STX   p_ginfo+1    ; point to filename
            STA   p_ginfo+2
            LDA   #10
            STA   p_ginfo

            JSR   mli
            DB    $C4          ; get info
            DA    p_ginfo
            RTS

*-------------------------------
* set the file info

setinfo     ENT
            STX   p_ginfo+1    ; point to filename
            STA   p_ginfo+2
            LDA   #7
            STA   p_ginfo

            JSR   mli
            DB    $C3          ; set info
            DA    p_ginfo
            RTS

*-------------------------------
* set the current end of file

puteof      ENT
            STX   p_geof+2     ; set eof marker
            STA   p_geof+3

seteof      ENT
            LDA   refnum
            STA   p_geof+1

            JSR   mli
            DB    $D0          ; set eof
            DA    p_geof
            RTS

*-------------------------------
* rename a file

rename      ENT
            STX   temp4        ; point to data
            STA   temp4+1
            JSR   getname      ; get first name

            LDY   #63
:ren2       LDA   flname,y     ; copy first name
            STA   lnbuf+128,y
            DEY
            BPL   :ren2

            JSR   getname      ; get new name

            JSR   mli
            DB    $C2          ; rename file
            DA    p_ren
            RTS

*-------------------------------
* find the config disk

findcon     ENT
            LDX   #23
            LDA   #0
:loop       STA   $BF58,x      ; clear prodos system bit-map
            DEX
            BNE   :loop

            JSR   mli
            DB    $C7          ; get prefix
            DA    p_pfx2       ; point to path

            LDA   conpfx       ; is prefix set to null?
            BNE   :findc2      ; nope

            LDA   $BF30        ; get current slot/drive
            STA   p_onlin+1

            JSR   mli
            DB    $C5          ; find out prefix of volume
            DA    p_onlin

            LDA   conpfx+1
            AND   #$F          ; just save name length
            clc
            adc   #1           ; advance length of prefix
            STA   conpfx

            LDA   #'/'         ; add leading slash for volume name
            STA   conpfx+1

:findc2     JMP   logcon       ; log to config

*-------------------------------
* check free space on volume

chkspc      ENT
            LDA   drive
            ASL
            ASL
            ASL
            ORA   slot         ; make into #dsss0000 format
            ASL
            ASL
            ASL
            ASL

            STA   p_onln+1
            JSR   mli
            DB    $C5          ; get drive name
            DA    p_onln
            BEQ   :chkspc2     ; all is well

            LDA   #0           ; return 0 blocks free -- error
            TAX
            RTS

:chkspc2    LDA   dstpfx+1
            AND   #$F
            TAX                ; make into volume name
            INX
            STX   dstpfx
            LDA   #'/'
            STA   dstpfx+1

            LDX   #<dstpfx
            LDA   #>dstpfx     ; get info on volume
            JSR   getinfo

            SEC
            LDA   p_ginfo+5    ; return total number of free blocks
            SBC   p_ginfo+8
            TAX
            LDA   p_ginfo+6
            SBC   p_ginfo+9
            RTS

*-------------------------------
* setup initial drive spec list

setspec     ENT
            JSR   chkspc       ;reset path to original drive

            JSR   makesegs     ;tack the /mpro.segs on path

            LDY   #0
            LDA   #1
            JSR   coppath      ;copy 1 path (A:)

            STY   temp
            JSR   chkspc       ;reset path
            JSR   makesys
            LDY   temp

            LDA   #3           ;copy 3 more paths
            JSR   coppath      ;b: - d:

            LDA   settrans     ;transfer wanted?
            BNE   :trans
            LDA   #3           ;paths to copy
            JMP   :notrans

:trans      STY   temp
            JSR   maketac1
            JSR   maketac2
            LDY   temp

            LDA   #1
            JSR   coppath      ;copy one path (E:)

            STY   temp
            JSR   chkspc
            JSR   makesys
            LDY   temp

            LDA   #2           ;fill out 2 specs
:notrans    JSR   coppath

            LDA   #0           ; mark end of path's
            STA   devnam,y

            RTS

settrans    ENT
            DB    0

*-------------------------------
* copy a path onto the pathname

coppath     STA   temp

:loop6      LDX   #-1
:loop5      INX
            LDA   dstpfx,x     ; copy in pathname
            STA   devnam,y
            INY
            CPX   dstpfx       ; done?
            BNE   :loop5       ; nope

            DEC   temp         ; count down paths to enter
            BNE   :loop6
            RTS

*-------------------------------
* setup /xxx/mpro.segs and log it

makesegs    ENT
            LDX   #0
            LDY   dstpfx
:loop       LDA   pfxname+1,x  ; copy on /xxxx/mpro.segs
            STA   dstpfx+1,y
            INX
            INY
            INC   dstpfx       ; update length
            CPX   pfxname
            BNE   :loop
            RTS

setdrv      ENT
            JSR   makesegs
            JSR   mli
            DB    $C0          ; create new path
            DA    p_crpth
            RTS

*-------------------------------
* setup /mpro.sys and log it

makesys     ENT
            LDX   #0
            LDY   dstpfx
:loop       LDA   sysname+1,x  ; copy on /xxxx/mpro.sys
            STA   dstpfx+1,y
            INX
            INY
            INC   dstpfx       ; update length
            CPX   sysname
            BNE   :loop
            RTS

setsys      ENT
            JSR   makesys

            JSR   mli
            DB    $C0          ; create new path
            DA    p_crpth
            RTS

*-------------------------------
* setup /stac and log it

maketac1    ENT
            LDX   #0
            LDY   dstpfx
:loop       LDA   tac1+1,x     ; copy on /xxxx/mpro.sys/stac
            STA   dstpfx+1,y
            INX
            INY
            INC   dstpfx       ; update length
            CPX   tac1
            BNE   :loop
            RTS

maketac2    ENT
            LDX   #0
            LDY   dstpfx
:loop       LDA   tac2+1,x     ; copy on /xxxx/mpro.sys/stac/vol./
            STA   dstpfx+1,y
            INX
            INY
            INC   dstpfx       ; update length
            CPX   tac2
            BNE   :loop
            RTS

settac      ENT
            JSR   maketac1
            JSR   mli          ; create /xxx/mpro.sys/stac/
            DB    $C0          ; create new path
            DA    p_crpth

            JSR   maketac2
            JSR   mli          ; create /xxx/mpro.sys/stac/vol./
            DB    $C0          ; create new path
            DA    p_crpth
            RTS

*-------------------------------
* variables

pfxname     STR   '/MPRO.SEGS'
sysname     STR   '/MPRO.SYS'
tac1        STR   '/STAC'
tac2        STR   '/VOL.'

p_spfx      DB    1
            DA    lnbuf-2

p_geof      DB    2
            DB    0
            DB    0,0,0

p_ginfo     DB    $A
            DA    0
            DB    0
            DB    0
            DA    0
            DB    0
            DA    0
            DA    0
            DA    0
            DA    0
            DA    0

p_ren       DB    2
            DA    lnbuf+128
            DA    flname

p_pfx       DB    1
            DA    lnbuf

p_pfx2      ENT
            DB    1
            DA    conpfx

p_pfx3      DB    1
            DA    dstpfx

p_pfx4      DB    1
            DA    prgpfx

conpfx      DS    40           ; max length

dstpfx      ENT
            DS    40           ; max length

prgpfx      DS    40           ; max length

p_onlin     DB    2
            DB    0
            DA    conpfx+1

p_onln      DB    2
            DB    0
            DA    dstpfx+1

p_crpth     ENT
            DB    7
            DA    dstpfx
            DB    $C3
            DB    $F
            DA    0
            DB    $D
            DA    0
            DA    0

