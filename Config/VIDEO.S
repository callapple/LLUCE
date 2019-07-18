              LST   OFF
              TR
              TR    ADR
*-------------------------------
* video driver for config
*-------------------------------
* Date: 3/11/88
*-------------------------------

              REL
cr            =     $D
lf            =     $A
bs            =     8

x_save        =     9
y_save        =     $A
base          =     $D
inverse       =     $10
ch            =     $24
cv            =     $25

page1         =     $C054
page2         =     $C055

              DSK   REL/VIDEO

VideoStartup  ENT
              STA   $C00D          ;set80vid
              STA   $C001          ;set80col
              STA   page1

              LDA   #0             ; set to page 1
              STA   inverse        ; set to normal mode
              RTS

*-------------------------------

cls           ENT
              LDA   #6             ;clear screen
              STA   cv             ;line 6 on down

clslup2       LDA   cv             ;clear to end of screen
              ASL                  ;cv := cv * 2
              TAY
              LDA   LineAddress,y
              STA   base
              INY
              LDA   LineAddress,y
              STA   base+1

              LDY   #39
              LDA   #" "
:loop         STA   (base),y
              DEY
              BPL   :loop

              STA   page2          ;do aux part
              LDY   #39
:loop2        STA   (base),y       ;do the line
              DEY
              BPL   :loop2
              STA   page1          ;back to page 1

              INC   cv
              LDA   cv
              CMP   #24
              BNE   clslup2

              LDA   #0             ;0,6
              STA   ch
              LDA   #7
              STA   cv
              RTS

*-------------------------------

cleos         ENT
              STX   cv
              JMP   clslup2

cleol         ENT
              PHA
              LDA   ch             ; save location of cursor
              PHA
              LDA   cv
              PHA

:cleol2       LDA   #' '
              JSR   cout           ; put space over char
              LDA   ch
              BNE   :cleol2        ; go until it wraps to next line

              PLA
              STA   cv             ; put cursor back
              PLA
              STA   ch
              PLA
              RTS

*-------------------------------

TopBox        ENT
              PHA

              LDA   #0
              STA   cv

              JSR   doILine
              INC   cv
              JSR   doEdge
              INC   cv
              JSR   doEdge
              INC   cv
              JSR   doEdge
              INC   cv
              JSR   doEdge
              INC   cv
              JSR   doILine

              STA   page2
              LDY   #0
              LDA   #' '
              STA   (base),y
              STA   page1

              LDY   #39
              LDA   #' '
              STA   (base),y

              PLA
              RTS

*-------------------------------

doEdge        JSR   makebase

              LDY   #39
              LDA   #" "
:loop         STA   (base),y
              DEY
              BPL   :loop

              STA   page2
              LDY   #39
:loop2        STA   (base),y
              DEY
              BPL   :loop2

              LDY   #0
              LDA   #' '
              STA   (base),y
              STA   page1

              LDY   #39
              LDA   #' '
              STA   (base),y
              RTS

*-------------------------------
* print an inverse line across the screen

doILine       JSR   makebase

              LDY   #39
              LDA   #"_"
:loop         STA   (base),y
              DEY
              BPL   :loop

              STA   page2
              LDY   #39
:loop2        STA   (base),y
              DEY
              BPL   :loop2
              RTS

*-------------------------------

makebase      LDA   cv
              ASL
              TAY                  ;setup indirect address
              LDA   LineAddress,y
              STA   base
              INY
              LDA   LineAddress,y
              STA   base+1
              RTS

*-------------------------------

plotchr       ENT
              PHA                  ; save

              JSR   makebase       ;setup indirect for screen address

              LDA   ch
              LSR
              TAY
              BCS   :odd           ;it's odd, so page 1
              STA   page2

:odd          PLA
              ORA   #$80           ;set high bit
              STA   (base),y       ;put it onto the screen
              STA   page1
              RTS

*-------------------------------
* output a character

cout          ENT
              STX   x_save         ; save everything
              STY   y_save
              PHA

              AND   #$7F           ; clear high
              CMP   #cr
              BEQ   :cout2
              CMP   #lf
              BEQ   :cout3
              CMP   #bs
              BEQ   :cout5
              CMP   #' '
              BCC   :cout4

              JSR   plotchr        ; plot the sucker

              INC   ch             ; move over 1 space
              LDY   ch
              CPY   #80            ; wrap-around?
              BNE   :cout4         ; nope

:cout2        LDY   #0             ; reset horiz
              STY   ch

:cout3        INC   cv             ; go down 1 line
              LDA   cv             ; is it in range?
              CMP   #24
              BNE   :cout4         ; nope

              DEC   cv             ; put it back

:cout4        PLA
              LDX   x_save         ; restore stuff
              LDY   y_save
              RTS

:cout5        DEC   ch             ; backup
              BPL   :cout4         ; all is well

              LDA   #79            ; move to end of line
              STA   ch

              LDA   cv             ; are we at the top
              CMP   #0
              BEQ   :cout4         ; yep

              DEC   cv
              JMP   :cout4         ; ok, we are done

*-------------------------------

LineAddress   DA    $400
              DA    $480
              DA    $500
              DA    $580
              DA    $600           ;first 1/3 of text screen
              DA    $680
              DA    $700
              DA    $780

              DA    $428
              DA    $4A8
              DA    $528
              DA    $5A8
              DA    $628           ;second 1/3 of text screen
              DA    $6A8
              DA    $728
              DA    $7A8

              DA    $450
              DA    $4D0
              DA    $550
              DA    $5D0
              DA    $650           ;last 1/3 of text screen
              DA    $6D0
              DA    $750
              DA    $7D0

