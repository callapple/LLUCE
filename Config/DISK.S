            LST   OFF
            TR
            TR    ADR
*-------------------------------
* Disk stuff for config
*-------------------------------
* Date: 3/11/88
*-------------------------------

            REL
cr          =     $D

lnbuf       =     $200
drvbuf      =     $800
flname      =     $300
fbuf1       =     $1C00
fbuf2       =     fbuf1
fnam1       =     $1E00
msgbuf      =     fbuf1
mli         =     $BF00

            DSK   REL/DISK

p_pfx2      EXT
logprg      EXT
drvname     EXT
movname     EXT
msgref      EXT

*-------------------------------
* verify a that a disk is online

verify      ENT
            STX   verify_p+1  ; point to wanted path
            STA   verify_p+2

            JSR   mli
            DB    $C6         ; set prefix
            DA    verify_p
            BCS   :error

            JSR   mli         ;get prefix for source volume
            DB    $C7         ;get prefix
            DA    p_pfx2      ;point to path
:error      RTS

verify_p    DB    1
            DA    0           ;address of path to set

*-------------------------------
* load config/acos.obj from disk

ld_drvs     ENT
            JSR   logprg      ; log to the program disk
            LDX   #<drvname
            LDA   #>drvname
            JSR   movname     ; move filename
            JSR   open        ; open 'LLUCE.DRIVERS'
            BCS   :error      ; error

            LDX   #<drvbuf    ; load config part into buffer
            LDA   #>drvbuf
            LDY   #18         ; read 9 pages (4 blocks)
            JSR   rdblk
            JSR   close       ; close file
            CLC
:error      RTS

*-------------------------------
* write config/acos.obj back to disk

sv_drvs     ENT
            JSR   logprg      ; log to program disk
            LDX   #<drvname
            LDA   #>drvname
            JSR   movname     ; move filename
            JSR   open
            BCS   :error

            LDX   #<drvbuf    ; write config back to disk
            LDA   #>drvbuf
            LDY   #18         ; write 9 pages (4 blocks)
            JSR   wrblk
            JSR   close
            CLC
:error      RTS

refnum      ENT
            DB    0

create      ENT
            STY   p_creat+4   ; save filetype
            JSR   mli
            DB    $C0
            DA    p_creat
            RTS

open        ENT
            LDY   #0
bfopen      ENT
            LDA   bufadr,y    ; point at buffer
            STA   p_open+4

            JSR   mli
            DB    $C8         ; open
            DA    p_open
            BNE   :open2

            LDA   p_open+5    ; save refnum
            STA   refnum
            CLC
            RTS

:open2      LDA   #-1         ; make sure refnum is illegal
            STA   refnum
            SEC
            RTS

bufadr      DB    >fbuf1,>fbuf2,>msgbuf

close       ENT
            LDA   refnum      ; use refnum
            STA   p_close+1
            JSR   mli
            DB    $CC         ; close
            DA    p_close
            RTS

flush       ENT
            LDA   refnum      ; use refnum
            STA   p_close+1
            JSR   mli
            DB    $CD         ; flush
            DA    p_close
            RTS

; setup for single line read
rdlnset     ENT
            LDA   refnum
            STA   p_new0+1    ; save refnum
            STA   p_new1+1
            STA   p_rdln+1

            JSR   mli
            DB    $C9         ; enable newline
            DA    p_new1
            RTS

; read a line from a file
rdline      ENT
            JSR   mli
            DB    $CA         ; read
            DA    p_rdln
            BNE   :rdline2    ; read error

            LDX   p_rdln+6    ; is there a cr at end of line?
            LDA   lnbuf-1,x
            AND   #$7F
            CMP   #cr
            BNE   :rdline2    ; no more stuff
            CLC
            RTS

:rdline2    LDA   #0          ; no data in line
            STA   lnbuf
            SEC               ; eof
            RTS

; read a single byte
rdbyte      ENT
            LDA   refnum      ; save refnum
            BEQ   :rdbyte2

            STA   p_rbyt+1
            JSR   mli
            DB    $CA         ; read 1 byte
            DA    p_rbyt
            BNE   :rdbyte2

            LDA   p_byte      ; get byte
            CLC               ; were done
            RTS

:rdbyte2    LDA   #0          ; fake data
            SEC
            RTS

; write a block for the msg routines
wrblk       ENT
            PHA
            LDA   #$CB        ; use write call
            STA   rwtype      ; --- does modify
            PLA
            BRA   rwblk

; read a block for the msg routines
rdblk       ENT
            PHA
            LDA   #$CA        ; use read call
            STA   rwtype      ; --- does modify
            PLA

rwblk       STX   p_rdblk+2
            STA   p_rdblk+3   ; save read address

            LDA   #0
            STA   p_rdblk+4
            STY   p_rdblk+5   ; save number of blocks to read

            LSR   p_rdblk+5   ; divide by 2 and
            ROR   p_rdblk+4   ; put remainder

            LDA   refnum      ; get refnum
            STA   p_rdblk+1

            JSR   mli         ; call mli
rwtype      DB    $CA         ; *** modified ***
            DA    p_rdblk
            RTS

; write a byte of data
wrbyte      ENT
            STA   p_byte      ; save data
            PHA
            LDA   refnum
            BEQ   :wrbyte2    ; if no refnum

            STA   p_rbyt+1
            JSR   mli
            DB    $CB         ; write byte
            DA    p_rbyt
            CLC               ; all is well
            BEQ   :wrbyte3

:wrbyte2    SEC               ; opps, problem
:wrbyte3    PLA               ; get back data
            RTS

; position file
posmsg      ENT
            LDY   msgref      ; save refnum
            STY   refnum

            LSR               ; setup Y,A,X w/exact byte
            TAY
            TXA
            ROR
            PHA
            LDA   #16
            ROR
            TAX
            PLA
            JMP   setpos

; find the end of file
geteof      ENT
            LDA   refnum      ; save refnum
            STA   p_mark+1
            JSR   mli
            DB    $D1         ; get eof
            DA    p_mark
            LDX   p_mark+2
            LDA   p_mark+3    ; get length
            LDY   p_mark+4
            RTS

; set a mark into a file
setmark     ENT
            LDY   #0
; do actual position set within file
setpos      ENT
            STX   p_mark+2
            STA   p_mark+3    ; point to new location
            STY   p_mark+4

            LDA   refnum
            STA   p_mark+1    ; save refnum

:setpos2    JSR   mli
            DB    $CE         ; set mark
            DA    p_mark
            CMP   #$4D        ; check for out-of-range
            BNE   :setpos3

            JSR   mli
            DB    $D0         ; set eof
            DA    p_mark
            BEQ   :setpos2    ; position again

:setpos3    RTS

; get current file marker
getmark     ENT
            LDA   refnum      ; save refnum
            STA   p_mark+1
            JSR   mli
            DB    $CF         ; get mark
            DA    p_mark
            SEC
            BNE   :getmrk2    ; opps, error

            CLC
            LDX   p_mark+2    ; all is well
            LDA   p_mark+3
:getmrk2    RTS

; ------ parms ------
p_open      DB    3
            DA    flname
            DA    fbuf1
            DB    0

p_close     DB    1
            DB    0

p_rbyt      DB    4
            DB    0
            DA    p_byte
            DA    1
            DA    0

p_byte      DB    0

p_mark      DB    2
            DB    0
            DB    0,0,0

p_new0      DB    3
            DB    0
            DB    0
            DB    0

p_new1      DB    3
            DB    0
            DB    $7F
            DB    $D

p_rdln      DB    4
            DB    0
            DA    lnbuf
            DA    $FF
            DA    0

p_rdblk     DB    4
            DB    0
            DA    0
            DA    $80
            DA    0

p_del       DB    1
            DA    flname

p_creat     DB    7
            DA    flname
            DB    $c3
            DB    0
            DA    0
            DB    1
            DA    0
            DA    0

