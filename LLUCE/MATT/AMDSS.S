; AMDSS is copyright by Morgan Davis
; Adaptation by Matthew Montano
; 
; This version July 27th, 1989
; Version .91b of AMDSS

            public                                                   out
            public                                                   connect
            on                                                       nocar                                                   goto

            goto                                                     connect

out
            ou=1
            gosub                                                    send
            gosub                                                    r.file
            goto                                                     hangup

connect
            v1$="b":x=1:bt$="":echo=" ":kill                         "g:batch":create                                        "g:batch"
            print                                                    "id:";
            input                                                    @3                                                      i$:if
            a=instr(";",i$):no$=left$(i$,a-1):c$=mid$(i$,a+1)
            open                                                     #1,"g:net.pass"
check.node
            input                                                    #1,b$
            b=instr(";",b$):n2$=left$(b$,b-1):c2$=mid$(b$,b+1)
            if                                                       (no$=n2$)                                               and
            if                                                       b$=""                                                   close:r$="AMDSS - connect1:"+no$+" attempted to use "+c$+" to login":gosub
            goto                                                     check.node
cp.1
            input                                                    #1,i$:if                                                i$=""
            a=instr(";",i$):if                                       left$(i$,a-1)<>no$                                      goto
            i=val(mid$(i$,a+1)):close
            r$="AMDSS - "+no$+" logged in @ "+date$+"-"+time$:print  #3,r$:gosub                                             amdss.log

r.file
            print                                                    #3,"Recieving.."
            f$="               ":use                                 v1$+":protocol.up",250,1,"i:",f$
            if                                                       left$(f$,2)="  "                                        and
            if                                                       left$(f$,2)="  "                                        create
            if                                                       er>10:r$="Bad connection":gosub                         amdss.log:modem(1):goto
            if                                                       peek(10)>0                                              print
            x=x+1
            r$="  recieved "+f$+" from "+no$+" at "+time$:gosub      amdss.log
            goto                                                     r.file

send
            b=1:lg$="i"+str$(i)+":":print                            "Getting a file":gosub                                  getfnum
            f$="i"+str$(i)+":"+fx$
            if                                                       ou                                                      and
            if                                                       left$(fx$,3)="   "                                      close:print
            if                                                       left$(fx$,3)="   ":r$="AMDSS: connection with "+no$+" ended at "+time$:gosub  amdss.log:goto
send1.1
            use                                                      v1$+":protocol.down",140,1,f$
            if                                                       peek(10)>0                                              print
            if                                                       er=10                                                   print
            ready" ":kill                                            f$:close:r$="  sent "+f$+" to "+no$+" at "+time$:gosub  amdss.log
            goto                                                     send

getfnum
            fx$=chr$(32,15)
            print                                                    "fx$="fx$"-":print                                      "b="b"-":print
            print                                                    "This works the first time but fails the second"
            use                                                      v1$+":xcat",b,lg$,fx$,bt$,bt$,bt$,bt$,bt$,bt$,bt$,bt$
            return

hang.up
            close:call                                               edit(5),250,1:close
            r$="Connection with "+no$+" lost at "+time$:gosub        amdss.log
            e$="amdss":link                                          "a:parse"

amdss.log
            close
            open                                                     #1,"g:amdss.log"
            a=mark(1):if                                             a                                                       close:create
            append                                                   #1
            print                                                    #1,r$
            close
            return

sort.mail
            r$="AMDSS process ended at "+time$:gosub                 amdss.log

hangup
            modem(1):echo="":e$="amdss":link                         "a:parse"


