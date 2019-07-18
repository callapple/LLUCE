; *****************
;    LLUCE v1.0
;  Copyright 1992
; L&L  Productions
; *****************

; logon segment rev d - 01/31/90 - LTW

            public                                           start1

; setup node #

            poke                                             2048,1

;on error goto error
            clear
            DEBUG
            set                                              pa$=ram,8:set                                                               ph$=ram+8,12
            when$=ram+20:flag=ram+22
            nibble=ram+27:byte=ram+37

start
            close:gosub                                      data.read
            open                                             read                                                                        #1,"system/sys.data1"
            input                                            #1,sn$|sy$|sid$|spas$
            input                                            #1,md$|s$|n$
            input                                            #1,lg,fv,al:close

            if                                               ct$<>date$
            chain                                            "program/maint.seg"

start1
            cn$=str$(c1):window=0:cls
            print                                            @9,1                                                                        chr$(95,61)mouse$:copy
            print                                            @22,3                                                                       "LLUCE v1.0 - The Networking Version";
            print                                            @17,4                                                                       "(C) 1992 L&L Productions - All Rights Reserved";

            print                                            @                                                                           40-(len(sn$)/2),9
            x$="Awaiting call "+cn$+" on "+fmtdate$:gosub    center
            x$="This will be call "+str$(ct)+" today":gosub  center
            x$="Last Caller - "+lu$:gosub                    center
            z$="":f$="email/feedback"
            if                                               exist(f$)
            z$="feedback & "
            f$="email/"+sid$
            if                                               exist(f$)
            z$=z$+"mail"
            else
            if                                               len(z$)
            z$=left$(z$,(len(z$)-3))
            if                                               z$=""
            z$="no mail"
            x$=sy$+" has "+z$+" waiting":gosub               center
            f$="system/sys.errors"
            if                                               exist(f$)
            {
            x$="System errors have occured"
            gosub                                            center
            }
            x$="This is Node #"+str$(node):gosub             center

            t1$=mid$(" "+time$,2)
            modem                                            ready
            t2$=mid$(" "+time$,2)
            li$=t2$                                          /*                                                                          Get

            bb=0:cls:clock                                   clear:d=0:on                                                                nocar
            b4=val(mid$(t2$,1,2)):b5=val(mid$(t2$,4,2)):b6=val(mid$(t2$,7,2))
            a1=val(mid$(t1$,1,2)):a2=val(mid$(t1$,4,2)):a3=val(mid$(t1$,7,2))

            if                                               b6<a3
            {
            b3=60+(b6-a3)
            b5--
            }
            else
            b3=b6-a3
            if                                               b5<a2
            {
            b2=60+(b5-a3)
            b4--
            }
            else
            b2=b5-a2
            b1=(b4-a1)+((b4<a1)*24)

            cm$=date$+" "+li$:gosub                          data.read:i$="":if                                                          online
            print                                            "1) Auto Logon\n"inverse$"2) Normal Logon"normal$
            print                                            "3) System Logon\n4) Logon as a user\nWhich: ";:get                         i$
            if                                               i$="1"                                                                      |
            if                                               i$="3"                                                                      |
            if                                               i$<>"4"                                                                     &
            print                                            "User Logon":input                                                          "\nUser number to log on as -> "i$:x=val(i$)
            i$="AUTO":goto                                   autolog

normlog
            nc=0:print                                       cls"Press [Return]:\a";:get                                                 i$
            if                                               i$="\x1F":nc=1
            print                                            cls"\n*** Welcome to "sn$" ***"
            print                                            "\nConnected ";:if                                                          nn>1
            if                                               online\
            print                                            "at ["baud*300"] baud":\
            else\
            print
            setint(1):copy                                   "system/sys.intro"
            setint(""):clear                                 key

logon
            nibble(0)=width(0)-1:mode=0:width=width(nibble(0)+1)-1
            nibble(6)=3:byte(7)=0
            if                                               ~nu                                                                         goto
            print                                            "\nEnter Mail ID (\"NEW\" if New User/\"GUEST\" for one time access)"
            un=0:input                                       "->"i$:upper$(i$):rtrim$(i$)
            if                                               i$="NEW"                                                                    goto
            d3$=i$:gosub                                     name.chk:if                                                                 ~f

password
            print                                            "\nEnter Password"
            echo="X":input                                   "->"i$:echo=""
            print                                            "\nVerifying your account..."

logon2
            i$=left$(i$+"     ",8)
autolog
            gosub                                            rd.user:if                                                                  d1$=""
            if                                               i$=pa$                                                                      goto
            if                                               i$="AUTO"                                                                   goto

bad.user
            bb++
            if                                               bb<3                                                                        print
            print                                            "\nYou must have an account to access this system."
            print                                            "Please call back and logon as a \"NEW\" user."
            goto                                             start

; *** New User Logon ***

new.user
            z=0:print:copy                                   "system/sys.newinfo1"
new.usr1
            print                                            "\nEnter your real full name [20 chars max]"
            input                                            @3                                                                          "->"i$:if
            if                                               len(i$)>20                                                                  print
            if                                               instr(",",i$)                                                               print
            mixed$(i$):if                                    i$="Off"                                                                    goto
            d1$=i$:if                                        z                                                                           goto

get.aff
            print                                            "\nEnter Company or User Group affillation [20 chars max]"
            input                                            @3                                                                          "->"i$:if
            if                                               len(i$)>20                                                                  print
            if                                               instr(",",i$)                                                               print
            mixed$(i$):d2$=i$:if                             z                                                                           goto

get.id
            a=instr(" ",d1$):if                              ~a:a=1
            print                                            a
            x$=mid$(d1$,a):b=instr(" ",x$):if                b:a=a+b
            d3$=mid$(d1$,1,1)+mid$(d1$,a)
            if                                               len(d3$)>10:d3$=left$(d3$,10)
get.id1
            upper$(d3$):gosub                                name.chk:if                                                                 ~f
            a=len(d3$)
            if                                               a>9:b=val(right$(d3$,1):d3$=left$(d3$,9)+str$(b+1):goto                     get.id1
            b=val(mid$(d3$,a,1):d3$=left$(d3$,a-1)+str$(b+1)
            goto                                             get.id1

get.id2
            print                                            "\nYou must select a mail ID for the system"
get.id3
            print                                            "\nThe system has chosen "d3$" as your ID, if you wish to"
            print                                            "change it, please enter your new ID now. <RTN> to accept."
            input                                            @3                                                                          "->"i$:if
            upper$(i$):i$=left$(i$+chr$(32,10),10):d3$=i$
            gosub                                            name.chk:if                                                                 (~f)
            if                                               ~f                                                                          goto
            print                                            "\nSorry, that mail ID is in use. Try Again"
            goto                                             get.id3

get.city
            print                                            "\nCity [16 chars max]"
            input                                            @3                                                                          "->"d4$
            if                                               len(i$)>16                                                                  print
            mixed$(d4$)

get.state
            print                                            "\nState [Form: XX]"
            input                                            "->"d5$
            if                                               len(d5$)<>2                                                                 print
            if                                               z                                                                           goto
            fill                                             ram(0),60,0

get.phone
            print                                            "\nPhone number [Form: ###-###-####]"
            input                                            "->"i$
            if                                               len(i$)<>12                                                                 goto
            ph$=left$(i$,3)+"-"+mid$(i$,5,3)+"-"+right$(i$,4)

chk.info
            print                                            "\nWe have the following:\n"
            print                                            "1) Name   : "d1$
            print                                            "2)  of    : "d2$
            print                                            "3) Mail ID: "d3$
            print                                            "4) From   : "d4$", "d5$
            print                                            "5) Phone  : "ph$
            print                                            "\nEnter # to change or \"C\" for correct :";
            get                                              i$:if                                                                       i$="Y"
            z=1:x=val(i$):if                                 x>5:x=0

            if                                               x=0                                                                         goto
            if                                               x=1                                                                         goto
            if                                               x=2                                                                         goto
            flag(0)=0:on                                     nocar                                                                       goto
            if                                               x=4                                                                         goto
            if                                               x=5                                                                         goto

info.ok
            flag(0)=0:on                                     nocar                                                                       goto
            print                                            "\nHold: Finding your account...";
            disk                                             lock:gosub                                                                  data.read:f$="system/sys.users"
            if                                               (~exist(f$))                                                                |
            y=192:z=1:overlay                                "findopen",d1$,f$,y,z
            if                                               z=(-2)                                                                      close:print
            if                                               z=(-1)                                                                      close:print
            if                                               z=0:nu++:a=nu:close:goto                                                    got.user
            if                                               z>0:a=z:close

got.user
            copy                                             "system/sys.newinfo":x=0:print
            f$="system/sys.questions":if                     ~exist(f$)                                                                  goto
            open                                             read                                                                        #1,f$

info
            input                                            #1,a$:if                                                                    a$="*"
            if                                               left$(a$,1)="@"                                                             |
            print                                            a$:goto                                                                     info

info.1
; input "\n-> "i$:print #9,i$
            goto                                             info

info.2
            close:f$="system/temp":create                    f$:open                                                                     write
            close:disk                                       unlock
            print                                            "\nWould you like to leave the Sysop a Message?";
            print                                            " (Y/"inverse$"[N]"normal$"): ";
            get                                              i$:if                                                                       i$="Y"
            print                                            cls"[ Enter/Edit Message Now : 4k or 4096 Bytes Maximum ]"
            print                                            "[ Legal Commands : .A = Abort  .H = Help  .S = Save ]"
            edit                                             clear:edit:if                                                               ~edit
            disk                                             lock:open                                                                   write

info.3
            close:edit                                       clear:copy                                                                  "system/temp",#9:kill
info.3a
            print                                            "\nPlease enter a password [4-8 Characters]"
            input                                            @2                                                                          "-> "i$:if
            x=len(i$):if                                     x<4                                                                         print
            pa$=left$(i$+chr$(32,7),8)
            print                                            "\n\nYour Mail ID is: "d3$
            print                                            "       Password: "pa$
            print                                            "    User Number: "a                                                        /***
            print                                            "\nPlease write them down, you will need them next time you call."
            nibble(0)=width(0):nibble(6)=3                   /*                                                                          video
            disk                                             lock:when$=date$:open                                                       write
            position                                         #1,192,a
            print                                            #1                                                                          d3$"\n"d1$"\n"d2$"\n"d4$,d5$
            position                                         #1,192,a,132
            write                                            #1,ram,60:close

; update sys.mailnames and sys.fullnames files & sort 'em

            f$="system/sys.mailnames":open                   write                                                                       #1,f$
            input                                            #1,au:au++:mark(1)=0
            print                                            #1,au:position                                                              #1,16,au
            print                                            #1,d3$"\n"a:close:disk                                                      unlock
            gosub                                            data.write:sz=16:st=1
            disk                                             lock:overlay                                                                "rndsort",f$,sz,st
            f$="system/sys.fullnames":open                   write                                                                       #1,f$
            input                                            #1,au:au++:mark(1)=0
            print                                            #1,au:position                                                              #1,36,au
            print                                            #1,d1$"\n"a:close
            sz=36:st=1:overlay                               "rndsort",f$,sz,st:

; add responses to request file

            f$="system/request":create                       f$:open                                                                     write
            append                                           #1:print                                                                    #1,a"\n"a$"NEW USER DATA"
            print                                            #1,a$;d3$"\n"a$;d1$"\n"a$;d2$
            print                                            #1,a$;d4$", "d5$"\n"a$"#"a"-"pa$
            print                                            #1,a$;ph$"\n"a$;date$" @ "time$"\n":append                                  #1
            copy                                             #9,#1:append                                                                #1:print
            f$="email/"+di$:kill                             f$:disk                                                                     unlock
            print                                            "\nPress <return> to enter "sn$;

            input                                            @3                                                                          " "i$:x=a:i$=pa$:goto

; *** Main Logon Routine ***

login
            a$=date$:if                                      lc$<>a$:nibble(5)=0:flag(36)=0:byte(7)=0
            lr=byte(5)+byte(6)*256:if                        lr>mn:lr=mn
            nb=lr:un=x:nulls=byte(0):b=byte(7):if            flag(1):flag(0)=0
            exec=flag(34):if                                 ~flag(1):exec=0
            if                                               (b<(nibble(6)*10))                                                          |
            print                                            "\n\nDaily time limit expired.  Please call back tomarrow"
            goto                                             start

login1
            if                                               exec                                                                        &
            b=((nibble(6)*10)-byte(7))*60
login1a
            clock=b:b=((clock-clock                          online)/60)+1

            id$=d3$:a1$=d1$:a2$=d2$:a4$=d4$:a5$=d5$
            tc=byte(1)+nibble(1)*256:bp=byte(2)+nibble(2)*256
            dn=byte(3)+nibble(3)*256:up=byte(4)+nibble(4)*256
            ul=byte(10)*65536+byte(9)*256+byte(8)
            dl=byte(13)*65536+byte(12)*256+byte(11)

            if                                               (~exec)                                                                     |

            print                                            "\nRemote Password":echo="X":input                                          "-> "i$
            echo="":if                                       i$<>spas$:exec=0

login2
            print                                            "\nLogging you into the system\n"
            x$="Call: "+cn$+" / ID:"+a$+" / "+a1$+" of "+a4$+", "+a5$
            gosub                                            data.write:inverse$:window=0:cls
            print                                            #4,chr$(45,80);
            i$=chr$(32,14):a$=id$:rtrim$(a$)
            x$="Call: "+cn$+" / ID:"+a$+" / "+a1$+" of "+a4$+", "+a5$
            print                                            #4,left$(x$+chr$(32,59),59)"  Phone: "ph$;
            print                                            #4,"TC: "left$(str$(tc)+i$,7)"#UL: "left$(str$(up)+i$,7);
            print                                            #4,"#DL: "left$(str$(dn)+i$,7)"BU: "left$(str$(ul)+i$,7);
            print                                            #4,"BD: "left$(str$(dl)+i$,7)"BP: "left$(str$(bp)+i$,6)"/ ";
            print                                            #4,"Baud: "left$(str$(baud*300)+i$,5);
            print                                            #4,"Flg: ";:for                                                             x=1
            print                                            #4,"  LC:"lc$"  On:"date$" "left$(time$+i$,14);
            print                                            #4,chr$(45,80)
            window=5:normal$:cls

            f$="system/sys.log":create                       f$:open                                                                     write
            input                                            #1,x:x++:if                                                                 x>200:x=1
            a=clock                                          online
            position                                         #1,80,x:print                                                               #1,a/60,a
            position                                         #1,80,x,10
            print                                            #1,id$,a1$,date$" "time$,baud*300,node
            mark(1)=0:print                                  #1,x:close

login3
            gosub                                            termemul
            f$="email/"+id$:rtrim$(f$):em=exist(f$)
            print                                            "User Name      : "left$(a1$+chr$(32,20),20)"  ";
            print                                            "Last Date On   : "fmtwhen$
            print                                            "Caller Number  : "left$(cn$+chr$(32,20),20)"  ";
            print                                            "Today is       : "fmtdate$
            print                                            "Caller # Today : "left$(str$(ct)+chr$(32,20),20)"  ";
            print                                            "Mail Waiting   : ";:if                                                     em
            print                                            "Terminal Emul. : "left$(i$+chr$(32,20),20)"  ";
            if                                               ~exec:                                                                      print
            if                                               ~flag(34):                                                                  goto
            print                                            "Remote Pass    : ";:if                                                     exec
            if                                               b1=0:a$=" ":
            if                                               b1=1:a$=" "+str$(b1)+" hour ":else                                          a$=" "+str$(b1)+" hours "
            if                                               b2=1:b$=str$(b2)+" minute":else                                             b$=str$(b2)+" minutes"
            c$=" and ":if                                    b3=1:c$=c$+str$(b3)+" second":else                                          c$=c$+str$(b3)+" seconds"
            x=len(a$+b$+c$):x$=left$(sn$+" was idle "+chr$(32,80-x),80-x):rtrim$(x$)
            x$=x$+a$+b$+c$:print                             "\n"chr$(32,(80-len(x$))/2);x$

login3x
            a$=wm$:b$=lc$:gosub                              ckdate
            if                                               x=1                                                                         setint(1):print

            a=mn-lr:if                                       lr=0:a=tm
            bb=1:f$="bulletins/b1":if                        ~exist(f$)                                                                  goto
            ready                                            f$:z=msg(0):ready                                                           ""
            print                                            "\nMain Bulletins from 1 to "z
            if                                               a>1                                                                         print
login3a
            if                                               ~exec                                                                       goto
            if                                               exist("system/request")                                                     print

login4
            mode=nibble(0)/4:ch=1:width=width((nibble(0)     %                                                                           4)+1)-1
            if                                               exec                                                                        &
            if                                               ~em                                                                         goto
            print                                            "\nWould you like to read your mail now? ["inverse$"(Yes)"normal$",No] :";
            get                                              i$:if                                                                       i$="N"
            print                                            "Yes":chain                                                                 "program/email.seg"
login5
            chain                                            "program/main.seg"

get.guest
            d1$="Guest User":d2$="Visitor":d3$="GUEST":d4$="Unknown":d5$="XX"
            ph$="XXX-XXX-XXXX":x=0:pa$="GUEST   ":flag(0)=1:lc$="NEVER "
            nibble(6)=3:goto                                 login

; *** Sub - Routines ***

center      /*                                               Center                                                                      Text
            print                                            @                                                                           40-(len(x$)/2)

rd.user     /*                                               read                                                                        a
            open                                             read                                                                        #1,"system/sys.users"
            position                                         #1,192,x
            input                                            #1,d3$|d1$|d2$|d4$,d5$
            position                                         #1,192,x,132
            read                                             #1,ram,60:lc$=when$
            close                                            #1
            return

termemul
            inverse$="":normal="":i$="None"
            if                                               ~online:i$="Local":return
            y=byte(14):if                                    (y<1)                                                                       |
            if                                               y=1:i$="Datamedia 1500":inverse$="\xF":normal$="\xE":clrscn$="\xC"
            if                                               y=2:i$="Dec VT-52":inverse$="\x19":normal$="\x1F":clrscn$="\xC"
            if                                               y=3:i$="IBM 3101":inverse$="\x1B19":normal$="\x1B1F":clrscn$="\x1BK"
            if                                               y=4:i$="Hazeltine 1500":inverse$="~\x19":normal$="~\x1F":clrscn$="~\x1A"
            if                                               y=5:i$="Heathkit H-19":inverse$="\x1Bp":normal$="\x1Bq":clrscn$="\x1B\E"
;  NOTE, \E avoids the E being counted as hex
            if                                               y=6:i$="Soroc":inverse$="\x1B)":normal$="\x1B(":clrscn$="\x1B*"
            if                                               y=7:i$="Adm3a":inverse$="\x19":normal$="\x1F":clrscn$="\x1A"
            if                                               y=8:i$="Televideo 912":inverse$="\x1Bl":normal$="\x1Bm":clrscn$="\x1B1A"
            return

; check tree file for valid mail ID

name.chk
            a$=d3$:rtrim$(a$):open                           read                                                                        #1,"system/sys.mailnames":t=nu:b=0:f=0
name1
            l=t-((t-b)/2):position                           #1,16,l:input                                                               #1,i$:upper$(i$)
            rtrim$(i$):if                                    a$=i$:f=1:input                                                             #1,x:close
            if                                               a$<i$:t=l-1:else                                                            b=l
            if                                               b<t                                                                         goto
            close                                            #1:open                                                                     read
name2
            l=t-((t-b)/2):position                           #1,36,l:input                                                               #1,i$:upper$(i$)
            rtrim$(i$):if                                    a$=i$:f=1:input                                                             #1,x:close
            if                                               a$<i$:t=l-1:else                                                            b=l
            if                                               b<t                                                                         goto
            close                                            #1:return

; compare two dates and return x=1 if first is after second

ckdate
            if                                               val(mid$(b$,7,2))<val(mid$(a$,7,2):x=1:return
            if                                               val(mid$(b$,7,2))>val(mid$(a$,7,2):x=0:return
            if                                               val(mid$(b$,1,2))<val(mid$(a$,1,2):x=1:return
            if                                               val(mid$(b$,1,2))>val(mid$(a$,1,2):x=0:return
            if                                               val(mid$(b$,4,2))>val(mid$(a$,4,2):x=0:return
            x=1:return

data.read   /*                                               read                                                                        current
            disk                                             lock:open                                                                   read
            input                                            #1,c1,ct,ct$,wm$
            input                                            #1,nu,mn,tm,nn|lu$
            close:disk                                       unlock:return

data.write  /*                                               write                                                                       current
            disk                                             lock:open                                                                   write
            print                                            #1,c1,ct,ct$,wm$
            print                                            #1,nu,mn,tm,nn"\n"lu$
            close:disk                                       unlock:return

error       /*                                               report                                                                      error
            print                                            "\nUnable to recover from error, call again later"
            modem                                            nocar:disk                                                                  lock:close:create
            open                                             write                                                                       #1,"system/sys.errors":append
            print                                            #1,"Error #"err" occured at "time$" on "fmtdate$" in logon.seg"
            close:disk                                       unlock:goto                                                                 start

