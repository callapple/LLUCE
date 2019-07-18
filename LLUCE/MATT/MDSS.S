; MDSS is copyright by Morgan Davis
; Adaptation by Matthew Montano
;
; This version Febuary 2nd, 1988
; Version .91a

            public                                                     out
            public                                                     connect
            on                                                         nocar                                             goto

            goto                                                       connect

out
            ou=1
            gosub                                                      send
            print                                                      #4,"S"
            gosub                                                      mdss

connect
            v1$="b":x=1:bt$="":echo=" ":kill                           "g:batch":create                                  "g:batch"
            print                                                      "id:";
            input                                                      @3                                                i$:if
            a=instr(";",i$):no$=left$(i$,a-1):c$=mid$(i$,a+1)
            open                                                       #1,"g:net.pass"
check.node
            input                                                      #1,b$
            b=instr(";",b$):n2$=left$(b$,b-1):c2$=mid$(b$,b+1)
            if                                                         (no$=n2$)                                         and
            if                                                         b$=""                                             close:r$="MDSS - connect1:"+no$+" attempted to use "+c$+" to login":gosub
            goto                                                       check.node
cp.1
            input                                                      #1,i$:if                                          i$=""
            a=instr(";",i$):if                                         left$(i$,a-1)<>no$                                goto
            i=val(mid$(i$,a+1)):close
            r$="MDSS - "+no$+" logged in @ "+date$+"-"+time$:print     #3,r$:gosub                                       mdss.log

mdss
            on                                                         nocar                                             goto
            gosub                                                      get.key
            if                                                         i$="H"                                            modem(1):print
            if                                                         i$="R"                                            goto
            if                                                         i$="S"                                            goto
            print                                                      chr$(24,5):goto                                   mdss

r.file
            f$="i:m"+str$(x)
            print                                                      #3,"Recieving file: "f$
            z=1:z=z*(z<>3):use                                         "b:x.up",z,f$
            x=x+1:r$="  recieved "+f$+" from "+no$+" at "+time$:gosub  mdss.log
            goto                                                       mdss

send
            b=1:lg$="i"+str$(i)+":":gosub                              getfnum
            f$="i"+str$(i)+":"+fx$
            gosub                                                      test.life
            print                                                      #3,"Attempting to send -"fx$"-"
            if                                                         ou                                                and
            if                                                         left$(fx$,3)="   "                                close:print
            if                                                         left$(fx$,3)="   "                                goto
send1.1
            if                                                         er=10                                             print
            print                                                      "R";
            z=1:z=z*(z<>3):use                                         "b:x.dn",z,f$
            kill                                                       f$:r$="  sent "+f$+" to "+no$+" at "+time$:gosub  mdss.log
            goto                                                       send

test.life
            z=key(0)
            if                                                         z=5                                               return
            y=y+1
            if                                                         y=5000                                            modem(1):pop:print
            goto                                                       test.life

get.key
            y=0
get.key1
            clear                                                      key:print                                         chr$(5);:zz=key(0)
            if                                                         (zz>96)                                           and
            i$=chr$(zz):if                                             i$="H"                                            return
            if                                                         i$="R"                                            or
            goto                                                       get.key1

getfnum
            fx$=chr$(32,15)
            print                                                      "fx$="fx$"-":print                                "b="b"-":print
            print                                                      "This works the first time but fails the second"
            use                                                        v1$+":xcat",b,lg$,fx$,bt$,bt$,bt$,bt$,bt$,bt$,bt$,bt$
            print                                                      "fx$="fx$"-":print                                "b="b"-":print
            return

hang.up
            close:call                                                 edit(5),250,1:close
            r$="Connection with "+no$+" lost at "+time$:gosub          mdss.log
            e$="amdss":link                                            "a:parse"

mdss.log
            close
            open                                                       #1,"g:mdss.log"
            a=mark(1):if                                               a                                                 close:create
            append                                                     #1
            print                                                      #1,r$
            close
            return

sort.mail
            r$="MDSS process ended at "+time$:gosub                    mdss.log

hangup
            modem(1):echo="":e$="amdss":link                           "a:parse"

