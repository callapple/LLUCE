;E-mail
;Modified by Wabbit 10/01/91

            get                           i$

; define drb$ as the pathname for your USERS file
            drb$="SYSTEM"
; define drg$ as the pathname for your MAIL file
            drg$="EMAIL"
; specify number of users
            input                         "Enter user number to read -> "i$
            nu=300
            uget=1:gosub                  snd.num:uget=0
            un=d:a3$=c$
            print                         "User #"un" - "c$:get                               i$

            md$="=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"

            print                         "\f\n\n\n"
start
            push                          start
            if                            ~exist(drg$+"/mail")                                gosub
            ready                         drg$+"/mail"
            print                         "Email segment\n\n"
            print                         "Send mail"
            print                         "Read mail"
            print                         "Create new mail file on "drg$
            print                         "Delete mail"
            print                         "Quit (end program)"
            if                            msg(un)                                             gosub
            print                         "\n  Option (S,R,C,D,Q): ";

getopt
            get                           i$
            if                            i$="R"                                              goto
            if                            i$="S"                                              goto
            if                            i$="C"                                              goto
            if                            i$="D"                                              goto
            if                            i$="Q"                                              end
            goto                          getopt

rd.mail0
            on                            nocar                                               goto
            print                         "\nRead Mail"
            if                            flag(0)                                             print
            ready                         "email/mail"
            if                            ~msg(un)                                            print
            ready                         #msg(un)
rd.mail2
            x=0:input                     #8,i$:d=val(i$)
            if                            i$="":ma=1:return
rd.mail3
            print                         #x,"\n"md$:setint(2):copy                           #8,#x
            setint(""):print              #x,md$
            if                            key                                                 next
rd.mail4
            input                         @2                                                  "\n(A)uto reply, [C]ontinue, (R)e-read :"i$
            if                            i$=""                                               |
            if                            i$="Q"                                              return
            if                            i$="R"                                              rewind:x=0:goto
            if                            i$="P"                                              &
            if                            i$="W"                                              &
            if                            i$="F"                                              goto
            if                            i$<>"A"                                             goto
            if                            d=0                                                 print
            input                         @2                                                  "\nSubject:"sb$:if
            gosub                         editor:if                                           ~edit
            print                         "\n"edit                                            size" bytes entered"
            print                         "Wait..";:h$="":s=9:gosub                           wr.ltr
            print                         ".reply sent":goto                                  rd.mail2

wr.mail
            input                         @2                                                  "\nFilename (to write):"i$:if
            create                        i$:rewind:open                                      #1,i$:input
            append                        #1:copy                                             #8,#1:close:goto

forward
            print                         "\nForward letter"
            a=d:gosub                     mail.who
            if                            d=0:d=a:goto                                        rd.mail4
            rewind:s=8
            input                         @2                                                  "Subject:"sb$:if
            h$="   --> A Forwarded Letter <--"
            r$=".letter forwarded":gosub  snd.bulk
            d=a:goto                      rd.mail4

; send e-mail

snd.mail
            on                            nocar                                               goto
            print                         "\nSend Mail"
            gosub                         mail.who:if                                         d=0
            input                         @3                                                  "Subject:"sb$:if
            gosub                         editor:if                                           ~edit
            h$="":r$=".letter sent"
            s=9:goto                      snd.bulk

mail.who
            input                         @2                                                  "\nTo who: Name, #, B)ulk mailing, <CR>):"i$
            clear                         #10:if                                              i$="":d=0:return
            if                            i$<>"B"                                             gosub
            print                         "\nBulk Mailing":x=1
            y=5:if                        flag(2):y=25

bulk1
            input                         @2                                                  "\nSend copy to (#,<CR>):"i$
            if                            i$="":d=0:if                                        x=1
            if                            i$<>""                                              gosub
            print                         #10,d:x++:if                                        d
            d=1:return

mail.wh2
            if                            left$(i$,1)="#":i$=mid$(i$,2):goto                  snd.num
            if                            val(left$(i$,1))                                    goto
            d$=i$:if                      (d$="SYSOP")                                        |
            if                            ~instr(" ",i$)                                      goto
            open                          #1,"system/sys.users":d=1

snd.user
            position                      #1,192,d:input                                      #1,a$,b$|c$
            if                            (a$+" "+b$=d$)                                      |
            if                            d<nu:d++:goto                                       snd.user
            close:d=0
            print                         "\n"d$" is not a user":return
snd.usr2
            print                         "\nThat user does not exist"
            d=0:return

snd.num
            d=val(i$)
            if                            (d<1)                                               |
            move                          ram,58                                              to
            position                      #1,192,d:input                                      #1,a$,b$|c$
            position                      #1,192,d,70:read                                    #1,ram,58
            close:i$=when$:move           ram(1),58                                           to
            IF                            UGET                                                return
            if                            a$=""                                               goto
            print                         "\nSend to "c$"\nLast on "i$;
            input                         @2                                                  " ([Y]\\N) ?"i$
            if                            left$(i$,1)="N":d=0
            return

; write a bunch of letters to disk

snd.bulk
            print                         "\n"edit                                            size" bytes entered"
            print                         "Wait..";:mark(10)=0
snd.blk2
            input                         #10,d:if                                            d=0
            gosub                         wr.ltr:print                                        ".";:if
            goto                          snd.blk2

; write the letter to disk

wr.ltr
            PRINT                         "SENDING TO USER "D;
            ready                         "email/mail"
            if                            msg                                                 free<29
            print                         #msg(d),un:if                                       h$<>""
            print                         #7,"Subj ->"sb$
            print                         #7,"From ->"a3$" (#"un")"
            print                         #7,"Date ->"date$" "time12$"\n"
            copy                          #s,#7
            print                         #MSG(D),"\x0400";
            msg(d)=1:flush:return

delete
            ready                         "email/mail"
            ready                         #msg(un)
            msg(un)=0
            kill                          #msg(un)
            return

; enter a message

editor
            print                         "\n                   Enter message now, [4k] max"
            print"\n   /s  to save,   /h  for help,    /a  to abort,    done  for options"
            cl=clock:clock=0:edit         clear:debug:edit:clock=cl:return

waiting
            ve=18:ho=47:gotoxy$(ho,ve)
            print"  \x10Z\xF \xE";:ve++:gotoxy$(ho,ve)
            print"  \x10Z_";:ve++:gotoxy$(ho,ve)
            print" \xF       \xE";:ve++:gotoxy$(ho,ve)
            print"\x10Z\xF       \xE";:ve++:gotoxy$(ho,ve)
            print"\x10   VW";:ve++:gotoxy$(ho,ve)
            print"   VW\xE";
            ve=ve-3:gotoxy$(ho,ve)
            print" \xF       \xE /";:ve++:gotoxy$(ho,ve)
            print"\x10Z\xF       \xE/";
            ve--:gotoxy$(ho,ve)
            print" \xF      \x10N_\xE   ";:ve++:gotoxy$(ho,ve)
            print"\x10Z\xF      \x10NT\xE___\b\b\b\b\x10LLLL";
            ve--:gotoxy$(ho,ve)
            print" \xF      \x10N_\xE!\b\6g\b\6n\b\6i\b\6t\b\6i\b\6a\b\6w\b\6 ";
            print"\b\6l\b\6i\b\6a\b\6m\b\6 \b\6e\b\6v\b\6a\b\6h\b\6 \b\6u\b\6o\b\6Y";
            print"\n\n\xE"
            return

create
            ready                         ""
            kill                          drg$+"/mail"
            print                         "\n\nCreating mail file....";
            create                        drg$+"/mail",msg,512
            print                         "done.\n\n"
            return

link.term
            chain                         dra$+"/main.seg","termin2"

