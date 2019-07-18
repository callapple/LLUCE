; ********************
;    GBBS Pro v1.3
;  By L&L Productions
;   (C)opyright 1987
; ********************

; Bulletin Copy Utility
; By GS @ 04/30/85
; Modified by Lance @ 4/20/87

            public                            start

            input                             "press [ret] to continue..."i$

            flag=ram
            s1$="<\b":s2$=">\b"
            s3$="{\b":s4$="}\b"

start
            home
            print                             "Bulletin Copy Utility v1.3"
            print                             "\nWritten by Greg Schaefer"
            print                             "Modified for v1.3 by Lance"
            input                             "\nSource Bulletin File (ex: bulletins/B1):"f1$
            if                                ~exist(f1$)                                      print
            ready                             f1$:print                                        "\b";:sz=(peek(36)=79)
            fill                              ram,64,0:if                                      msg(0)
            print                             "\nThat message file is empty."
            gosub                             getret:goto                                      start

status
            home:z=1:b=(msg(0)/20)*5+1
            for                               x=1                                              to
            a=20:if                           x=b:a=msg(0)                                     mod
            for                               y=5                                              to
            print                             @x,y;z;a$;:z=z+1:next:next

cmd
            print                             @1,1                                             "R=Restart, Q=Quit, V=View, C=Copy"
            print                             "K=Kill, T=Tag, U=Untag, W=Write"
            print                             "Enter Cmd: "chr$(0x20,28);chr$(8,28);
            get                               i$:if                                            i$>"a":i$=chr$(asc(i$)-32)
            print                             "\b"i$;:z=1
            if                                i$="Q"                                           goto
            if                                i$="V"                                           goto
            if                                i$="C"                                           goto
            if                                i$="K"                                           goto
            if                                i$="T"                                           goto
            if                                i$="U"                                           goto
            if                                i$="R"                                           goto
            if                                i$="W"                                           goto
            goto                              cmd

quit
            input                             @0                                               "uit Y/N ?"i$:if
            home:goto                         doquit

restart
            input                             @0                                               "estart Y/N ?"i$:if
            home:goto                         start

tag
            input                             @2                                               "ag (#[,#] or ALL):"i$
            if                                i$=""                                            goto
            if                                left$(i$,1)="A"                                  fill
tag2
            a=val(i$):if                      ~((a=0)                                          |
            a=instr(",",i$):if                a:i$=mid$(i$,a+1):goto                           tag2
            goto                              status

untag
            input                             @2                                               "ntag (#[,#] or ALL):"i$
            if                                i$=""                                            goto
            if                                left$(i$,1)="A"                                  fill
untag2
            a=val(i$):if                      ~((a=0)                                          |
            a=instr(",",i$):if                a:i$=mid$(i$,a+1):goto                           untag2
            goto                              status

view
            input                             @2                                               "iew (ALL,TAG,#[,#]):"i$
            gosub                             inprng:if                                        i$=""
            home:print                        "Viewing Bulletin(s):"
view2
            d=0:gosub                         show:if                                          a
            gosub                             getret:goto                                      status

write
            input                             @2                                               "rite (ALL,TAG,#[,#]):"i$
            gosub                             inprng:if                                        i$=""
write2
            home:print                        "Write these bulletins:\n"
            gosub                             list:input                                       @2
            if                                f$=""                                            goto
            create                            f$:open                                          #1,f$:append
            print                             "\nWait...Writing bulletin(s)"
write3
            d=1:gosub                         show:if                                          a
            close:goto                        status

kill
            input                             @2                                               "ill (ALL,TAG,#[,#]):"i$
            gosub                             inprng:if                                        i$=""
            home:print                        "Kill these bulletins:\n":gosub                  list
            input                             @0                                               "\nKill: Are you sure Y/N ?"i$
            if                                i$<>"Y"                                          goto
            print                             "Wait...Killing bulletin(s)"
            b=msg(msg(0)):for                 x=1                                              to
            if                                flag(x+512)                                      kill
            next:crunch:a=msg(0):if           a:msg(a)=b
            update:if                         a                                                goto
            home:print                        "\nAll bulletins killed."
            gosub                             getret:goto                                      start

copy
            input                             @2                                               "opy (ALL,TAG,#[,#]):"i$
            gosub                             inprng:if                                        i$=""
            home:print                        "Copy these bulletins:\n":gosub                  list
            input                             @0                                               "\nCopy: Are you sure Y/N ?"i$
            if                                i$<>"Y"                                          goto
copy2
            print                             "\nEnter destination bulletin file"
            input                             @2                                               "\nDestin Bulletin File (ex: bulletins/B2):"f$
            if                                f$=""                                            goto
            open                              #1,f$:a=mark(1):close:b=msg(0)
            if                                a                                                print
            print                             "\nWait...Copying bulletin(s): ";
            open                              #1,"b:data":input                                #1,c1,c2,ct,ct$,da$
            input                             #1,nu,mn,wm|lu$:close:ready                      f$

            for                               x=1                                              to
            print                             s1$;:kill                                        "dummy":create
            print                             s2$;:ready                                       f1$:copy
            print                             s3$;:b=msg(0)+1:copy                             "dummy",#msg(b):msg(b)=mn
            update:mn=mn+1:print              s4$;
copy3
            next:open                         #1,"b:data":print                                #1,c1,c2,ct,ct$,da$
            print                             #1,nu,mn,wm"\n"lu$:close:ready                   f1$:goto

inprng
            if                                left$(i$,1)="T"                                  move
            if                                left$(i$,1)="A"                                  fill
            fill                              ram2,64,0
inprng2
            a=val(i$):if                      (a=0)                                            |
            flag(a+512)=1:a=instr(",",i$):if  ~a                                               return
            i$=mid$(i$,a+1):goto              inprng2

list
            a$="":for                         x=1                                              to
            if                                flag(x+512)                                      print
            next:if                           peek(36)>0                                       print
            return

show
            if                                z>msg(0):a=0:return
            if                                flag(z+512)=0:z++:goto                           show
            input                             #msg(z),sb$|b,b$|c,c$
            print                             #d,"\nNumb ->"z" of "msg(0)"\n Sub ->"sb$
            print                             #d,                                              "  To ->"b$"\nFrom ->"c$
            copy                              #6,#d:a=1:z++:return

getret
            input                             @2                                               "\nPress [RETURN] to continue... "i$
            return

doquit
            end

