
; Fix board files

; turn off carrier detect

            on               nocar:

; get number of boards

            open             #1,"b:data2":mark(1)=1120:input     #1,ab:close:tb$="f:temp"

; loop for all boards

            for              bb=1                                to

; get board name and file name

            open             #1,"b:data2":position               #1,128,bb+8:input
            print            "Fixing board: "bn$" Messages 1-";

; get board info

            open             #1,bf$:read                         #1,ram2,2:close:l=peek(ram2)+peek(ram2+1)

; make new board file

            create           tb$,6:open                          #1,tb$:write
            for              x=1                                 to

; get number of messages on current board

            ready            bf$:mt=msg(0):print                 mt" - "0;:for
            print            chr$(8,len(str$(a-1)))a;:edit       clear

; read a message

            input            #msg(a),a$\b,b$\c,c$\d$\e$:copy     #6,#8:x=msg(a):ready

; write it back out

            print            #msg(a),a$\b,b$\c,c$\d$\e$:copy     #8,#6:msg(a)=x:next:print

; clear editor buffer, delete old file, and rename the new one

            edit             clear:ready                         " ":kill

; link back to the system

            next:close:end

            next:close:link  "a1:system.seg"

