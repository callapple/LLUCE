;-----------------------------------------------------------------------
;SuperTac 5.0e - January, 1988
;Written by Larry Hawkins
;Copyright (c), 1987-1988 - L & L Productions
;Auto Directory Segment
;-----------------------------------------------------------------------

scan
            lo=1:hi=50
            ed=edit:v1$="l":v2$="j"
            push                   link.sys
            print                  "\nAuto-Directory 5.0"
            print                  "Thrashing Hard Drive..."
            i$=v1$+":directory"
            gosub                  message:ready                                         i$:x=lo:gosub
            print                  "\nScanning Volume [";
dir10
            in$=right$("0"+str$(x),2)
            print                  in$"]";
            x$=v1$+str$(x)+":":if  (fv>0)                                                &
            overlay                "xcat",0,x$,fn$,ta$,th$,bu$,mo$,mt$,xd$,xt$,by$
            clear                  #8
            print                  #msg(x),date$" "time$
dir2
            if                     fn$="               "                                 copy
            si=peek(ed+22)+(peek(ed+23)<<8)
            print                  #6,fn$" "ta$" "bu$" "right$("    "+str$(si),5)" "xd$
            call                   ed+3,0,fn$,ta$,th$,bu$,mo$,mt$,xd$,xt$,by$
            goto                   dir2

nxtvol
            x=x+1:if               (x>hi)                                                close:update:print
            print                  "\b\b\b";:goto                                        dir10

link.sys
            chain                  "program/logon.seg"

message
            ready                  " ":close:kill                                        i$:create
            fill                   ed,255,0:poke                                         ed,16:poke
            write                  #1,ed,2:fill                                          ed,255,0:for
            write                  #1,ed,22:close
            return

makestr
            fn$="               ":ta$="   ":th$="   ":bu$="     "
            mo$="         ":mt$="     "
            xd$="         ":xt$="     "
            by$="         ":a=0
            return

;Janurary, 1988

