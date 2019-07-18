            get                        i$


;* overlay "shell","system.prog"
;*   [,"startpath"][,"initial.pfx"][,"save.name"]
;*

            overlay                    "shell","/main/util/prosel/cat.doctor","","/main/util/prosel","/ram5/save"

            print                      "We should restart here after quitting Cat.Doctor"
            get                        i$


start
            cls
            input                      @2                                                                          "This will make a window. ";\
            "Checking for new line 1"\
            "Checking for new line 2"  i$
            for                        x=9                                                                         to
            gotoxy$(20,x)
            print"\I\R \x28"           /*print                                                                     40
            next
            window=9,16,20,60
            gotoxy$(31,13)
            print                      "This is a Window\N"
            get                        i$
            cls
            end
            copy                       "PROGRAM/MAIN.SEG.S"
            get                        i$
            goto                       start



            get                        i$

            MODEM                      READY

            input                      @2                                                                          "Ready -> "i$
            ansi                       on
; commented out because the 1st gosub encountered will give a syntax error.

start1
            i7$="\I"
            sc$="\I\H\f"
            print                      sc$
            gosub                      header
            print                      "Press Return or Q to quit. \N";:get                                        i$
            if                         i$="Q"                                                                      end
            goto                       start

header
            print                      "\N";
            lf=0
            ve=up+1:ho=lf+1:print      gotoxy$(ho,ve);chr$(32,80)
            ho=8:print                 gotoxy$(ho,ve)"Messages"
            ho=26:print                gotoxy$(ho,ve)"E-Mail"
            ho=38:print                gotoxy$(ho,ve)"Utilities"
            ho=54:print                gotoxy$(ho,ve)"Information"
            ve=up+2
line
            ho=1:ve=up+2
            print                      gotoxy$(ho,ve);i7$;chr$(223,80);
            return

            CHAIN                      "PROGRAM/LOGON.SEG2"

