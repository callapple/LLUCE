;Parse.s mail
;by Matthew Montano
;Part of the LLUCE-NET package
;(c) 1989, Venture Tech developement
;written March 28th,1989
;final revision June 31st, 1989
; another revision July 9th, 1989
; yet another revision (tr$ parsing added) July 31st, 1989
; minor revision and cleaned up August 5th, 1989
; minor revision August 18th, 1989

;remember outlets for domains
;remember outlets for aliases
;fix write to local account
;allow for outlet to proline system

            on                                      nocar                                           goto
            v1$="a":bg$="!"

            if                                      (e$="amdss")                                    or
            if                                      e1$="pass"                                      gosub

            close:open                              #1,e$:input                                     #1,i$:close
            print                                   "First line :"i$" -"
            if                                      left$(i$,5)="From "                             gosub
            close:ready                             e$
            if                                      (msg(0)=0)                                      and
            if                                      (msg(0)=0)                                      and
            if                                      msg(0)                                          goto
            ready" ":kill                           e$:goto                                         outahere

parse
            print                                   \"[Parse v.0951 - "msg(0)" messages]: parsing"
            if                                      msg(0)>256                                      print
            for                                     x=1                                             to
            gosub                                   rd.msg
            a=instr(" ",tr$):if                     a                                               gosub
            gosub                                   parse.it
            pp$="":tr$="":fr$="":sb$="":dt$="":ft$="":a=0:b=0:fn$="":pt$="":f2$="":f1$=""
            next
            link                                    "a:parse"

parse.it
            if                                      fr$=""                                          ready
            if                                      pp$="out"                                       gosub
            i$=pp$:gosub                            lcase:pp$=i$
pit1.1
            a=instr(bg$,pp$):fn$=left$(pp$,a-1)
            if                                      fn$=sn$:pp$=mid$(pp$,a+1):goto                  pit1.1
            if                                      a=0                                             goto
            pt$=mid$(pp$,a+1)

parse3
            close:open                              #1,"g:dir.min"
parse3.1
            input                                   #1,i$:b=instr(";",i$):f1$=left$(i$,b-1)
            if                                      i$=""                                           close:goto
            if                                      f1$=fn$:fd$=mid$(i$,b+1):close
            if                                      (f1$=fn$)                                       and
            if                                      f1$=fn$:f$="i"+fd$+":ML.01":gosub               wr.msg:return
            goto                                    parse3.1

parse4
            close:open                              #1,"g:paths"
parse4.1
            input                                   #1,i$
            if                                      i$=""                                           close:goto
            a=instr(":",i$)
            i$=left$(i$,len(i$)-2)
            if                                      left$(i$,a-1)=fn$:pp$=mid$(i$,a+2)+bg$+pt$
            if                                      left$(i$,a-1)=fn$                               close:goto
            goto                                    parse4.1

domain
            a=instr(".",fn$):if                     a=0                                             close:r$="No path to site could be found":goto
            f1$=left$(fn$,a-1):f2$=mid$(fn$,a):b=1
            a=instr(bg$,pp$):f4$=mid$(pp$,a)
            close:open                              #1,"g:paths"
dom1
            input                                   #1,i$
            if                                      i$=""                                           close:goto
            a=instr(":",i$):f3$=left$(i$,a-1)
            if                                      f2$=f3$:pp$=mid$(i$,a+2)+f4$
            if                                      f2$=f3$:a=instr("*",pp$):pp$=left$(pp$,a-1)+f1$+mid$(pp$,a+1):close
            if                                      f2$=f3$                                         gosub
            goto                                    dom1
dom2
            if                                      not                                             a:r$="Domain could not be parsed":goto
            f2$=mid$(f2$,2):a=instr(".",f2$):f1$=f1$+"."+left$(f2$,a-1):f2$=mid$(f2$,a)
            open                                    #1,"g:paths":b=b+1:goto                         dom1

out
            a=instr("@",tr$):if                     a:pp$=mid$(tr$,a+1)+bg$+left$(tr$,a-1):return
            pp$=tr$:return

bounce
            tr$=fr$:a=instr(" ",tr$):tr$=left$(tr$,a-1)
            fr$=sn$+"!mailer "+date$+" "+time$:pp$=tr$
            sb$="Returned Mail"
            print                                   #8,\"-----"
            print                                   #8,\"The above message had this problem:"
            print                                   #8,r$\
            print                                   #8,\                                            "  Please correct the problem and try resending it."
            print                                   #8,\\"Sincerly,"
            print                                   #8,                                             "         mailer@"sn$
            f$=e$
            print                                   "Message:":copy                                 #8
            close:ready                             e$:kill                                         #msg(x):update:close
            close:ready                             f$:c=msg(0)+1:print                             #msg(c),fr$,tr$,sb$\dt$,pp$,ft$:copy
            return

local
            a=instr(bg$,pp$):if                     a:tl$=mid$(pp$,a+1)
            if                                      not                                             a:tl$=pp$
            a=instr("#",tl$):if                     a:b=val(mid$(tl$,2):goto                        feed
; note!
            i$=tl$:gosub                            lcase:tl$=i$
            if                                      tl$="root":du=1:goto                            local.1.1
            if                                      tl$="mailer":du=1:goto                          local.1.1
            if                                      tl$="sysop":du=1:goto                           local.1.1
            if                                      tl$="amdss":du=1:goto                           local.1.1
            if                                      tl$="postmaster":du=1:goto                      local.1.1
            a=instr("user",tl$):if                  a:du=val(mid$(tl$,a+4)):goto                    local.1.1
            ifleft$(tl$,1)="#":a=instr("#",tl$):if  a:du=val(mid$(tl$,a+1)):gotolocal.1.1
            open                                    #1,"b:users"
            z=1
local.01
            position                                #1,128,z
            input                                   #1,a$,b$\c$
            i$=c$:gosub                             lcase:c$=i$:print                               "c$="c$
local.001
            a=instr(" ",c$):if                      a:c$=left$(c$,a-1)+"."+mid$(c$,a+1):goto        local.001
            if                                      a$+str$(z)=tl$:du=z:goto                        local.1.1
            if                                      c$=tl$:du=z:goto                                local.1.1
            if                                      z<nu:z=z+1:goto                                 local.01
            close:goto                              alias
local.1.1
            if                                      du>nu:r$="local user account "+str(du)+" on "+sn$+" was invalid":goto  bounce
            f$="g:mail."+str$(du)
            db$="":a=instr(" ",dt$):ti$=mid$(dt$,a+1):dt$=left$(dt$,a-1)
            close:open                              #1,f$:if                                        mark(1)
            close:edit(0):gosub                     rd2.msg
            ready                                   f$:c=msg(0)+1:print                             #msg(c),0,sb$,fr$\dt$,ti$,0,ft$:copy
            close:ready                             e$:kill                                         #msg(x):update:close:return

wr.msg
            gosub                                   rd2.msg
; a=instr(bg$,fr$):if left$(fr$,a-1)<>sn$
            fr$=sn$+"!"+fr$
            close:open                              #1,f$:if                                        mark(1)
            close:ready                             e$:kill                                         #msg(x):crunch:update:close
            close:ready                             f$:c=msg(0)+1:print                             #msg(c),fr$,tr$,sb$\dt$,pp$,ft$:copy
            return

plinewr
            f$="i"+fd$+":m"+str$(x)+str$(random(9999))
            create                                  f$:open                                         #1,f$:append
            a=instr(" ",fr$):fr$=left$(fr$,(a-1)):fr$=sn$+"!"+fr$
            print                                   #1,"From "fr$" "date$" "time$
            print                                   #1,"Date: "dt$
            print                                   #1,"Subject: "sb$
            print                                   #1,"To: "tr$
            print                                   #1,"Ppath: "pp$
            print                                   #1,"From: "ft$\
            copy                                    #8,#1:print                                     #1\"*  Sent from "sn$" at "time$" on "date$
            close:ready                             e$:kill                                         #msg(x):update:close
            return

msg
            kill                                    f$:create                                       f$:open
            write                                   #1,ed,2:fill                                    ed,255,0:for
            close                                   #1:return

rd.msg
            close:ready                             e$:input                                        #msg(x),fr$,tr$,sb$\dt$,pp$,ft$:edit(0):copy
            return

rd2.msg
            close:ready                             e$:input                                        #msg(x),i$,i$,i$\i$,i$,i$:edit(0):copy
            return

rdunix
            edit(0)
            f$="i:x"+mid$(e$,3):gosub               msg
            close:open                              #1,e$:input                                     #1,fr$
            fr$=mid$(fr$,6)
rdunix2
            input#1,i$
            if                                      left$(i$,4)="To: ":tr$=mid$(i$,5)
            if                                      left$(i$,9)="Subject: ":sb$=mid$(i$,10)
            if                                      left$(i$,6)="Date: ":dt$=mid$(i$,7)
            if                                      left$(i$,7)="Ppath: ":pp$=mid$(i$,8)
            if                                      left$(i$,6)="From: ":ft$=mid$(i$,7):
            if                                      i$<>""                                          goto
            edit(0):copy                            #1,#8:close
rdun2.1
            a=instr(",",dt$):if                     a:dt$=left$(dt$,a-1)+" "+mid$(dt$,a+1):goto     rdun2.1
            ready                                   f$:print                                        #msg(1),fr$,tr$,sb$\dt$,pp$,ft$:copy
            kill                                    e$
            return

multitr
            kill                                    #msg(x)
multi2
            a=instr(" ",tr$):if                     not                                             a
            to$=left$(tr$,a-1):tr$=mid$(tr$,a+1)
            ready                                   e$:print                                        #msg(msg(0)+1),fr$,to$,sb$\dt$,pp$,ft$:copy
            update
            goto                                    multi2

alias
            close:open                              #1,"g:aliases"
al1
            input                                   #1,i$
            if                                      i$=""                                           close:r$="Alias of "+tl$+" could not be parsed":goto
            if                                      i$<>tl$                                         goto
al10
            input                                   #1,i$
            if                                      left$(i$,1)<>" "                                ready
            pp$="out":tr$=mid$(i$,2)
            ready                                   e$:print                                        #msg(msg(0)+1),fr$,tr$,sb$\dt$,pp$:copy
            goto                                    al10

feed
; this code will post the message into the local message base # b
; install at a later date.

outahere
            if                                      e1$="AMDSS"                                     or
            if                                      e1$="pass":e1$="":link                          "a:system.seg"
            link                                    "a:mail","net7"

fromamdss
            b=1:lg$="I:":gosub                      getfnum:e$=fx$:e$="i:"+e$
            if                                      left$(fx$,3)="   "                              pop:goto
            return

lcase
            a$="":forl=1tolen(i$)
            y=asc(mid$(i$,l,1)):if                  (y>65)                                          and
            a$=a$+chr$(y):next
            i$=a$
            return

getfnum
            fx$="               ":bt$=""
            use                                     v1$+":xcat",b,lg$,fx$,bt$,bt$,bt$,bt$,bt$,bt$,bt$,bt$
            return

