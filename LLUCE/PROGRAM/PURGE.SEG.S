;	SuperTac 5.30
;	Written by Larry Hawkins
;	Copyright (c), 1987-1988 - L & L Productions
;	Purge Segment

warespur
            poke                      220,106
            on                        nocar                                                             goto
            ed=edit:sc$="\f":si=99:nc=0:nl=0:nk=0
            wk=3:wc$="C":cn$="Y":ac$="L":nd$="Y":x=0
            gosub                     chngvl:gosub                                                      find.sdate
            print                     cls"\nPurge since "lc$;
            gosub                     chngdt
            print                     "\nWhich date:\n C)reation (uploaded) [Default]\n M)odification"
            gosub                     chngwc
            print                     "\nInclude [No Date] as date 00/00/00\n Y)es [Default]\n N)o"
            gosub                     chngnd
            print                     "Action:\n L)ist [Default]\n P)urge"
            gosub                     chngac:if                                                         ac$="L"
            print                     "\nConfirm actions:\n Y)es [Default]\n N)o\n Q)uit"
            gosub                     chngcn
wares1
            gosub                     chkok
            push                      link.sys
            print                     "\n\nPurge 5.30"
            print                     "Thrashing Hard Drive..."
            xx=lo:gosub               makestr
dir10
            z=key:if                  z!=0                                                              return
            ready                     v1$+":vol.headers"
            input                     #msg(xx),vp$
            if                        (un!=1)                                                           &
            if                        si!=0                                                             print
            in$=right$("0"+str$(xx),2)
            print                     #x,in$"]";
            x$=v1$+str$(xx)+":":if    (fv>0)                                                            &
            overlay                   "xcat",0,x$,fn$,ta$,th$,bu$,mo$,mt$,xd$,xt$,by$
            si=0:ww=0
dir2
            if                        fn$="               "                                             goto
            gosub                     check.date:if                                                     d
            si=peek(ed+22)+(peek(ed+23)<<8)
            ww++:nc++:if              ww=1                                                              print
            print                     #x,fn$" "ta$" "bu$" "right$("    "+str$(si),5)" "xd$" "mo$" ";
            gosub                     kill.list
dir3
            call                      ed+3,0,fn$,ta$,th$,bu$,mo$,mt$,xd$,xt$,by$
            goto                      dir2

nxtvol
            xx=xx+1:if                (xx>hi)                                                           close:update:gosub
            print                     #x,"\b\b\b";:goto                                                 dir10

prnt.done
            print                     #x,"\nNumber considered: "nc
            if                        ac$="L"                                                           print
            if                        ac$="P"                                                           print
            print                     "\nSuccessfully Thrashed":return

link.sys
            chain                     "program/supertac.sys"

check.date
            gosub                     find.date
            if                        val(mid$(d$,7,2))>val(mid$(lc$,7,2)):d=1:return
            if                        val(mid$(d$,7,2))<val(mid$(lc$,7,2)):d=0:return
            if                        val(mid$(d$,1,2))>val(mid$(lc$,1,2)):d=1:return
            if                        val(mid$(d$,1,2))<val(mid$(lc$,1,2)):d=0:return
            if                        val(mid$(d$,4,2))>=val(mid$(lc$,4,2)):d=1:return
            if                        val(mid$(d$,4,2))<val(mid$(lc$,4,2)):d=0:return
            d=0:return

chngvl
            print                     "\nLow Volume  #"vl;:print                                        chr$(8,len(str$(vl)));
            input                     @2                                                                i$:if
            lo=val(i$):if             lo<vl:lo=vl
            print                     "High Volume #"vh;:print                                          chr$(8,len(str$(vh)));
            input                     @2                                                                i$:if
            hi=val(i$):if             hi>vh:hi=vh
            return

chngdt
            print                     chr$(8,8);:input                                                  @2
            if                        i$=""                                                             return
            if                        len(i$)!=8                                                        return
            if                        (mid$(i$,3,1)!="/")                                               |
            a=val(mid$(i$,1,2)):if    (a<1)                                                             |
            a=val(mid$(i$,4,2)):if    (a<1)                                                             |
            a=val(mid$(i$,7,2)):if    (a<1)                                                             |
            lc$=i$:return

chngwc
            print                     "Which: "wc$"\b";:input                                           @2
            if                        i$=""                                                             return
            if                        len(i$)!=1                                                        return
            if                        i$="C"                                                            |
            return

chngnd
            print                     "Which: "nd$"\b";:input                                           @2
            if                        i$=""                                                             return
            if                        len(i$)!=1                                                        return
            if                        i$="Y"                                                            |
            return

chngac
            print                     "Which: "ac$"\b";:input                                           @2
            if                        i$=""                                                             return
            if                        len(i$)!=1                                                        return
            if                        i$="L"                                                            |
            return

chkprt
            print                     \"Use the printer: N\b";:input                                    @2
            if                        i$=""                                                             return
            if                        len(i$)!=1                                                        return
            if                        i$="Y":x=5
            return

chngcn
            print                     "Which: "cn$"\b";:input                                           @2
            if                        i$=""                                                             return
            if                        len(i$)!=1                                                        return
            if                        i$="Y"                                                            |
            return

find.sdate
            mo=val(left$(date$,2))
            da=val(mid$(date$,4,2))
            yr=val(mid$(date$,7,2))
            da-=(wk*7):if             da<1:da+=30:mo=mo-1:if                                            mo<1:mo=1:yr--
            lc$=right$("00"+str$(mo),2)+"/"+right$("00"+str$(da),2)+"/"+str$(yr)
            return

find.date
            d$="98/98/98":dc$=xd$:if  wc$="M"                                                           dc$=mo$
            if                        dc$="[No Date]"                                                   &
            if                        mid$(dc$,4,3)="Jan":d$="01/":goto                                 find.fin
            if                        mid$(dc$,4,3)="Feb":d$="02/":goto                                 find.fin
            if                        mid$(dc$,4,3)="Mar":d$="03/":goto                                 find.fin
            if                        mid$(dc$,4,3)="Apr":d$="04/":goto                                 find.fin
            if                        mid$(dc$,4,3)="May":d$="05/":goto                                 find.fin
            if                        mid$(dc$,4,3)="Jun":d$="06/":goto                                 find.fin
            if                        mid$(dc$,4,3)="Jul":d$="07/":goto                                 find.fin
            if                        mid$(dc$,4,3)="Aug":d$="08/":goto                                 find.fin
            if                        mid$(dc$,4,3)="Sep":d$="09/":goto                                 find.fin
            if                        mid$(dc$,4,3)="Oct":d$="10/":goto                                 find.fin
            if                        mid$(dc$,4,3)="Nov":d$="11/":goto                                 find.fin
            if                        mid$(dc$,4,3)="Dec":d$="12/":goto                                 find.fin
            return
find.fin
            d$=d$+mid$(dc$,1,2)+"/"+mid$(dc$,8,2)
            return

makestr
            fn$="               ":ta$="   ":th$="   ":bu$="     "
            mo$="         ":mt$="     "
            xd$="         ":xt$="     "
            by$="         ":a=0
            return

chkok
            print                     cls"\nYou have chosen the following:"
            Print                     "Starting volume   : "lo
            print                     "Stopping volume   : "hi
            print                     "Action            : ";
            If                        ac$="L"                                                           print
            print                     "Printer           : ";
            if                        x=0                                                               print
            print                     "Date for action   : ";
            if                        wc$="C"                                                           print
            print                     "Include [No Date] : ";
            if                        nd$="Y"                                                           print
            print                     "Date of action    : "lc$:if                                      ac$="L"
            Print                     "Confirm each      : ";
            if                        cn$="Y"                                                           print
chkok1
            print                     "\nIs this selection correct: Y\b";:input                         @2
            if                        i$=""                                                             return
            if                        len(i$)!=1                                                        return
            if                        i$="Q"                                                            pop:goto
            if                        i$="N"                                                            pop:goto
            return

kill.list
            sb=peek(ed+7)
            if                        (ac$="L")                                                         &
            if                        ac$="L"                                                           print
            if                        cn$="N"                                                           goto
            gosub                     chk.kill:if                                                       kf$="N"
kill.it
            if                        sb!=227                                                           print
            print                     "Killed":nk++
            kill                      fn$
            return

chk.kill
            kf$="Y"
            print                     "Kill: "kf$"\b";:gosub                                            getkey
            if                        i$=""                                                             return
            if                        len(i$)!=1                                                        return
            if                        i$="Y"                                                            |
            return

getkey
            xy=0
get2
            if                        (clock!=0)                                                        &
            print                     "\nTime Limit Exceeded":pop:modem                                 nocar:goto
            zx=peek(-16384)
            if                        (zx=129)                                                          |
            zx=key:if                 (zx>96)                                                           &
            if                        zx!=0:i$=chr$(zx):return
            zy++
            if                        zy=1500:print                                                     "\a";:goto
            if                        zy=3000:print                                                     "\aTimeout...":pop:modem
            goto                      get2

link.term
            chain                     "progran/main.seg","term1"

