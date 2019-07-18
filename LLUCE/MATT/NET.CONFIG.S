; Network configuration Segment
;-------------------------------
;   Written by Matthew Montano
;               July 5th, 1989


            on     nocar                                                           goto

            print  \\" Network configuration segment"
            print  " Alpha version, July 5th, 1989"
            print  " -- Written by Matthew Montano"

            print  \"Do you want to delete DIR.MIN and NET.PASS and continue ->";
            input  @3                                                              i$:if
            kill   "g:dir.min":kill                                                "g:net.pass":create
            print  \"Input number of systems you are connected to -> ";:input\i

            for    x=1                                                             to
read1
            print  \"Enter system #"i"'s name ->":input                            @3
            print  \"Enter system #"i"'s password ->":input                        @3

            print  \\"For system #"i":"
            print  \"       Name of system -> "no$
            print  "       Password of system -> "pa$
            print  \\" Is everything ok? [Y/n] -> ";
            get    i$:print                                                        i$:if
            goto   read1

write1
            open   #1,"g:dir.min":append                                           #1:print
            open   #1,"g:net.pass":append                                          #1:print
            next

            print  \\"All complete, here is your DIR.MIN file:"
            open   #1,"g:dir.min":copy                                             #1:close
            print  \\"              here is your NET.PASS file:"
            open   #1,"g:net.pass":copy                                            #1:close

            print  \\"Quiting..":link                                              "a:system.seg"

