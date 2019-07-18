; *********************
;      LLUCE v1.0
;    Copyright 1989
; L&L Productions, Inc.
; *********************

; main segment rev a - 01/14/88
; main segment rev b - 08/08/89
; main segment rev c - 11/14/89 - LPT
; main segmetn rev d - 05/01/90 - LPT

            public                       otherseg
            public                       return
            public                       term1

; Set No Carrier and On Error Vector

            on                           nocar                                                                goto
; on error goto error
            a1=0:if                      flag(0)                                                              goto

; Check for force voting

            if                           fv                                                                   chain

otherseg
            on                           nocar                                                                goto
; on error goto error

main
            gosub                        time:print                                                           "\n[("x$")] Main Level [?=Menu] Function :";
main1
            get                          i$
main2
            clear                        gosub:push                                                           main
            if                           i$="?"                                                               |
            if                           left$(i$,1)="B"                                                      print
            if                           left$(i$,1)="J"                                                      print
            if                           i$="E"                                                               print
            if                           i$="C"                                                               print
            if                           i$="F"                                                               print
            if                           i$="T"                                                               print
            if                           i$="N"                                                               print
            if                           i$="H"                                                               print
            if                           i$="D"                                                               print
            if                           i$="I"                                                               print
            if                           i$="S"                                                               print
            if                           i$="%"                                                               &

; If user is not validated, or the sysop is not in Executive Mode
; check to see if command is legal and return to main

            if                           (~flag(1))                                                           &

; All commands below this line are for validated users

            if                           i$="G"                                                               print
            if                           i$="Q"                                                               print
            if                           i$="L"                                                               print
            if                           i$="U"                                                               print
            if                           i$="X"                                                               print
            print                        "\nTransfer Section Still under Construction.":\
            return                       /*:pop:chain                                                         "program/supertac"*/
            if                           i$="V"                                                               print

main3
            if                           val(i$)<33                                                           pop:goto
            a1++:print                   "\n\""i$"\" is not a command":if                                     a1<3

; *** sub - routines ***

menu
            a1=0:f$="system/mnu.new":if  ~flag(1)                                                             goto
            if                           width<79:f$="system/mnu.val.40":else                                 f$="system/mnu.val.80"
menu.1
            if                           ~exist(f$)                                                           goto
            disk                         lock
            open                         #1,f$:input                                                          #1,x$:setint(" "):addint(x$)
            cls:copy                     #1:if                                                                key
            a=key:close:disk             unlock:setint(""):pop:goto                                           main
menu.key
            close:setint(""):a=key:i$=chr$(a):upper(i$)
            if                           i$=" "                                                               goto
            print                        "\n[("x$")] Main Level [?=More] Function :"
            goto                         main2

; terminate from system and recycle

terminate
            print                        "\nTerminate From "sn$
            print                        "\nAre You Sure ["inverse$"(Yes)"normal$",No] :";
            get                          i$:if                                                                i$="N"
            print                        "Yes"

term1
            on                           nocar:
            print                        "\nLog Out : "a1$" of "a4$", "a5$"."
            print                        "Caller #: "cn$"\n"
            print                        sn$                                                                  " - log out at "fmtdate$" "time$
            a=clock                      online:lo$=time$
            if                           a                                                                    print
            close:modem                  nocar:if                                                             a1$=""
            if                           ~un                                                                  goto

            nibble(5)++:byte(0)=nulls:tc++
            byte(1)=tc                   %                                                                    256:nibble(1)=tc/256
            byte(2)=bp                   %                                                                    256:nibble(2)=bp/256
            byte(3)=dn                   %                                                                    256:nibble(3)=dn/256
            byte(4)=up                   %                                                                    256:nibble(4)=up/256
            byte(7)+=(clock              online/60):when$="x"
            byte(10)=ul/65536:a=ul       %                                                                    65536
            byte(9)=a/256:byte(8)=a      %                                                                    256
            byte(13)=dl/65536:a=dl       %                                                                    65536
            byte(12)=a/256:byte(11)=a    %                                                                    256

            disk                         lock:open                                                            #1,"system/sys.users":position
            print                        #1,id$"\n"a1$"\n"a2$"\n"a4$,a5$
            position                     #1,192,un,132
            write                        #1,ram,60:close
            kill                         "system/batch"

termin3
            gosub                        data.read:da$=date$:rtrim$(id$):lu$=a1$+                             " ["+id$+"]":gosub
            f$="system/sys.log":if       ~exist(f$)                                                           goto
            disk                         lock:open                                                            #1,f$:input
            a=clock                      online:print                                                         #1,a/60,a
            close:disk                   unlock

termin4
            disk                         unlock:chain                                                         "program/logon.seg2"

; chat with sysop

chat
            if                           ch>5                                                                 print
            if                           ch>4                                                                 print
            if                           ch>3                                                                 print
            print                        "\nPaging "sy$" : ";:tone(100,100,100)
            if                           flag(2)                                                              tone(125,100,100):tone(150,100,100)
            print                        "Please Continue...":set                                             msg=1:ch++:return

; feedback to sysop

feedback
            print                        cls"Feedback To "sy$
            input                        @3                                                                   "\nSubject -> "sb$:if
            ready                        "":f$="email/feedback"
            gosub                        editor:if                                                            ~edit
            print                        "\nRegistered Mail? [Yes,"inverse$"(No)"normal$"] :";
            get                          i$:if                                                                i$="Y"
            rg=(i$="Y"):sb$=left$(sb$,25)
            if                           rg:st$="Registered Mail":else                                        st$="Awaiting Reply"
            print                        "\nSending "edit                                                     size" bytes...";
            if                           ~exist(f$)                                                           close:create
            ready                        f$:if                                                                msg(0)=64
            a=msg(0)+1:a$=id$:rtrim$(a$)
            print                        #msg(a),date$" "time$"\n"a$" ("a1$")",un"\n"st$"\n"sb$"\n"rg
            copy                         #9,#7:msg(a)=a:flush:ready                                           "":print
            return

feed2
            ready                        f$:if                                                                ~msg(0)
            ready                        "":return

; general files

general
            disk                         lock:a$="gfiles/"+a$
            if                           ~exist(a$)                                                           print
            open                         #1,a$:input                                                          #1,x:print
general2
            print                        "\nGeneral Files: Which 1-"x" (?=Menu,<CR>) -> ";
            input                        @3                                                                   i$:if
            if                           i$="?"                                                               goto
            a=val(i$):if                 (~a)                                                                 |
            f$=a$+"."+str$(a):gosub      show.file:goto                                                       general2

; show log of calls

showlog
            f$="system/sys.log"
            if                           ~exist(f$)                                                           print
            print                        "\n  # Mail ID    Name                  Called               Baud";
            print                        "    Online";:if                                                     nn
            print                        chr$(45,79):disk                                                     lock
            open                         #1,f$:input                                                          #1,x:y=x:z=1
shlog1
            position                     #1,80,x:if                                                           eof(1)
            input                        #1,f$,g$
            position                     #1,80,x,10
            input                        #1,a$,b$,c$,d$,e$
            setint(1):print              right$("00"+str$(z),3)" "left$(a$+chr$(46,10),10)" ";
            print                        left$(b$+chr$(46,21),21)" "left$(c$+chr$(32,10),20)" ";
            if                           d$="0":d$="LOCAL":else                                               d$="0"+d$
            print                        d$"   "right$("0"+f$,2)":"right$("0"+g$,2);
            if                           nn                                                                   print
            if                           key                                                                  flag:x=y+1
            x--:z++:if                   x=0:x=200
            if                           x<>y                                                                 goto
shlog3
            close:setint(""):disk        unlock:return

; conference area

conference
            cn=1:if                      len(i$)<2                                                            goto
            a=val(mid$(i$,2)):if         a:cn=a
link.conf
; print "cn="cn:chain "program/conf.seg","conference"
            print                        "cn="cn:chain                                                        "program/msg.seg","bulletins"

dispatch
            y$="program/main.seg"        /*                                                                   segment
            z$="otherseg"                /*                                                                   label
            chain                        "program/util.seg"

return
            on                           nocar                                                                goto
; on error goto error
            return

; *** sub - routines ***

; show a disk file

show.file
            if                           ~exist(f$)                                                           return
            setint(1):print              "\n"s$"\n":open                                                      #1,f$
showfl2
            copy                         (20)                                                                 #1
            if                           eof(1)                                                               |
            if                           ~flag(35)                                                            goto
            print                        "Press "inverse$"[RETURN]"normal$": ";:get                           i$
            print                        chr$(8,17);chr$(0x20,17);chr$(8,17);
            if                           i$=" "                                                               setint(""):close
            setint(1):goto               showfl2

; get time remaining before logoff

time
            x=(clock-clock               online)/60:y=clock:x$=right$("00"+str$(x),3)
            if                           clock                                                                online>clock:x$="!!"
            if                           x=0:x$="--"
            if                           ~y:x$="**"
            if                           exec:x$="::"
            return

; editor for feedback

editor
            print                        cls"[ Enter/Edit Message Now : 4k or 4096 Bytes Maximum ]"
            print                        "[ Legal Commands : .A = Abort  .H = Help  .S = Save ]"
edit2
            cl=clock:clock=0:edit        clear:edit:clock=cl:return

; check date to another date

check.date
            if                           val(mid$(d$,7,2))>val(mid$(lc$,7,2)):d=1:return
            if                           val(mid$(d$,7,2))<val(mid$(lc$,7,2)):d=0:return
            if                           val(mid$(d$,1,2))>val(mid$(lc$,1,2)):d=1:return
            if                           val(mid$(d$,1,2))<val(mid$(lc$,1,2)):d=0:return
            if                           val(mid$(d$,4,2))>=val(mid$(lc$,4,2)):d=1:return
            if                           val(mid$(d$,4,2))<val(mid$(lc$,4,2)):d=0:return
            d=0:return

chngdt
            print                        chr$(8,8);:input                                                     @2
            if                           i$=""                                                                return
            if                           len(i$)<>8                                                           return
            if                           mid$(i$,3,1)<>"/"                                                    |
            a=val(mid$(i$,1,2)):if       (a<1)                                                                |
            a=val(mid$(i$,4,2)):if       (a<1)                                                                |
            a=val(mid$(i$,7,2)):if       (a<1)                                                                |
            lc$=i$:return

data.read   /*                           read                                                                 current
            disk                         lock:open                                                            #1,"system/sys.data"
            input                        #1,c1,ct,ct$,wm$
            input                        #1,nu,mn,tm,nn|lu$
            close:disk                   unlock:return

data.write  /*                           write                                                                current
            disk                         lock:open                                                            #1,"system/sys.data"
            print                        #1,c1,ct,ct$,wm$
            print                        #1,nu,mn,tm,nn"\n"lu$
            close:disk                   unlock:return

error       /*                           print                                                                error
            print                        "One moment please, returning you to the Main Level."
            disk                         lock:close:clear                                                     gosub:create
            open                         #1,"system/sys.errors":append                                        #1
            print                        #1,"Error #"err" occured at "time$" on "date$" in main.seg"
            close:disk                   unlock:goto                                                          main

