
            dra$="/Q3/LLUCE/program"
            drb$="/Q3/LLUCE/SYSTEMS"
            drc$="/Q3/LLUCE"
            drd$="/Q3/LLUCE/ANSI"
            drg$="/Q3/LLUCE/MAIL"
            drh$="/RAM5"

; main segment rev j - 7/21/87

            public                                                               fromsys
            public                                                               return
            public                                                               term1
            public                                                               termin2
            public                                                               autoread
            on                                                                   nocar                                        goto


            un=1:flag(1)=1:flag(34)=1

            print                                                                sc$\\
            if                                                                   flag(0)                                      goto
            ready                                                                drg$+"/mail"
            if                                                                   not                                          msg(un)
            print"   You have mail waiting.      Read it now ([Y]/n) ? ";:gosub  getkey
            if                                                                   (i$<>"N")                                    print
autoread
            x=(clock-clock                                                       online)/60:y=clock:x$=right$("0"+str$(x),2)
            if                                                                   x=0                                          x$="--"
            if                                                                   not                                          y
            if                                                                   exec                                         x$="::"
            if                                                                   yl                                           print
            gosub                                                                getkey
            if                                                                   i$<>"N"print                                 "New Messages":bb=1:push
            print                                                                "No, thank you."
            goto                                                                 main
fromsys
            on                                                                   nocar                                        goto
            print                                                                sc$\\
main
            on                                                                   nocar                                        goto
            x=(clock-clock                                                       online)/60:x$=right$(" "+str$(x),3)
            if                                                                   x=0                                          x$="---"
            if                                                                   exec                                         x$=":::"
            i$="":print\\"["x$" min] [ MAIN LEVEL ] (/=Menu) Option: ";:push     main
            if                                                                   exec                                         gf$="B?CQDFTGYENHIPUMLX/S(+A*":goto
            if                                                                   flag(1)                                      gf$="B?CQDFTGYENHIPUMLX/S(A*":goto
            gf$="B?CQDFTGYNHIPUMLS/":goto                                        get.key
getkey
            y=0
get.2
            z=peek(-16287)
            if                                                                   (z=129)                                      or
            z=key
            if                                                                   (z=>asc("a"))                                z=z-32
            if                                                                   z<>0                                         i$=chr$(z):return
            y=y+1
            if                                                                   y=4000                                       print
            if                                                                   y=7000                                       for
            if                                                                   y=10000                                      print
            goto                                                                 get.2
get.key
            gosub                                                                getkey
            a=instr(i$,gf$):if                                                   a                                            goto
            goto                                                                 get.key


