
            modem                  ready

start1
            input                  @2                                                         "Ready -> "i$

            OVERLAY                "SHELL","/MAIN/UTIL/PROSEL/CAT.DOCTOR","","","/RAM5/SAVE"

; ansi on
; commented out because the 1st gosub encountered will give a syntax error.

            end

start
            i7$="\I"
            sc$="\I\H\f"
            print                  sc$
            gosub                  header
            print                  "Press Return or Q to quit. \N";:get                       i$
            if                     i$="Q"                                                     end
            goto                   start

header
            print                  "\N";
            lf=0
            ve=up+1:ho=lf+1:print  gotoxy$(ho,ve);chr$(32,80)
            ho=8:print             gotoxy$(ho,ve)"Messages"
            ho=26:print            gotoxy$(ho,ve)"E-Mail"
            ho=38:print            gotoxy$(ho,ve)"Utilities"
            ho=54:print            gotoxy$(ho,ve)"Information"
            ve=up+2
line
            ho=1:ve=up+2
            print                  gotoxy$(ho,ve);i7$;chr$(223,80);
            return

            CHAIN                  "PROGRAM/LOGON.SEG2"

