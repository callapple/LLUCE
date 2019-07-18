
            get                   i$

            gosub                 data.read                                /*

            print                 ct$"A"
            print                 date$"A"
            a$=date$
            print                 a$"A"

            b$="1":c$="1"
            if                    b$=c$                                    print

            b=150
            for                   x=                                       1
            if                    b<100                                    print
            if                    b=100                                    print
            if                    b>100                                    print
            b=b-10:next           x


            if                    ct$<>a$                                  print


            print                 c1\ct\ct$\wm$
            print                 nu\mn\tm\nn\lu$

            lu$="Dummy"

            gosub                 data.write

            get                   i$

            end

            flag=ram(2)
            byte=ram(1)+81
            set                   aa$=ram(1),30
            set                   ab$=ram(1)+31,30
            set                   ac$=ram(1)+61,20

            byte(1)=0:byte(2)=0:byte(3)=0


            open                  #1,"test.conf"
            position              #1,96,1
            read                  #1,ram(1),96
            close                 #1
            print                 aa$,ab$,ac$,byte(1),byte(2),byte(3)

            get                   i$

init
            fill                  ram(1),128,0
            a$="Lance Taylor-Warren"aa$=a$+Chr$(32,(30-len(a$)))
            b$="General Discussions":ab$=b$+chr$(32,(30-len(b$)))
            c$="LL Lance":ac$=c$+chr$(32,(20-len(c$)))
            byte(1)=11:byte(2)=22:byte(3)=33

            print                 aa$,ab$,ac$,d,e,f
            print                 "Check Memory":get                       i$

            create                "test.conf"
            open                  #1,"test.conf"
            position              #1,96,1
            write                 #1,ram(1),96
            close                 #1:get                                   i$:end

            for                   x=1                                      to

            open                  #1,"test.flags"
            read                  #1,ram(1),512
            close                 #1

            for                   x=1                                      to
            end



            get                   i$:
            x=flag
            print                 "Flag address is:"x
            flag=ram(2)
            x=flag
            print                 "flag address is:"x
            flag(512)=1
            flag(4096)=1
            print                 "Flag(1)="flag(1)
            print                 "Flag(512)="flag(512)
            print                 "flag(4096)="flag(4096)
            get                   i$

            end




            get                   i$:
            overlay               "rndsort","system/sys.names",16,1
            get                   i$
            end

            create                "system/test.data":open                  #1,"system/test.data"
            set                   pa$=ram,8:set                            ph$=ram+8,12
            fill                  ram,60,0
            fill                  ram2,60,0
            pa$="OUR2CUTE":ph$="303-420-3156"
            gosub                 check:position                           #1,64,1:write
            move                  ram,60                                   to
            gosub                 check
            pa$="LANCER   ":ph$="303-431-9183"
            gosub                 check:position                           #1,64,2:write
            move                  ram2,60                                  to
            gosub                 check:position                           #1,64,3:write
            print                 "Press a key":get                        i$
            end


check
            print                 \"Ram  ---"
            for                   x=768                                    to
            print                 \"Ram2 ---"
            for                   x=832                                    to
            get                   i$:return


            z=0:print             "Z="z
            if                    z                                        print
            if                    not                                      z
            if                    z>0                                      print
            if                    z<0                                      print
            z=1
            if                    z                                        print
            if                    not                                      z
            if                    z>0                                      print
            if                    z<0                                      print
            end


start
            disable:ready         "":f$="system/sys.log"
            gosub                 chkfile:if                               a
            ready                 f$:if                                    msg(0)=512
            a=msg(0)+1
            print                 #msg(a),date$" "time$
            print                 #6,a2$
            print                 #6,a3$,a4$
            print                 #6,(baud*300)
            print                 #6,cn$,cm$,lc$,un,ph$,node
            a=clock(1):print      #6,(a/60),(a                             mod
            clear                 #8:copy                                  #8,#6
            msg(a)=a:flush:ready  ""

            get                   i$:if                                    i$="Q"


chkfile
            open                  #1,f$:a=mark(1):si=size(1):close:return

makelog
            ready                 "":delete                                f$:create
            open                  #1,f$:ed=ram3:fill                       ed,255,0:poke
            write                 #1,ed,2:fill                             ed,255,0:for
            write                 #1,ed,22:close
            return

data.read   /*                    read                                     current
            disk                  lock:open                                #1,"system/sys.data"
            input                 #1,c1,ct,ct$,wm$
            input                 #1,nu,mn,tm,nn\lu$
            close:disk            unlock:return

data.write  /*                    write                                    current
            disk                  lock:open                                #1,"system/sys.data"
            print                 #1,c1,ct,ct$,wm$
            print                 #1,nu,mn,tm,nn\lu$
            close:disk            unlock:return

