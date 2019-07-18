            public   copy.1


begin
            on       nocar                  goto
            f$="":f2$=""

copy
            input    @2                     \"Input source file (ex. a:filename): "f$
            if       f$=""                  print
            open     #1,f$:a=mark(1):close
            if       a:print                \"That file doesn't exist!":goto
            input    @2                     \"Input target file ................: "f2$:print
            if       f2$=""                 print

copy.1
            overlay  "x.copy",f$,f2$
            a=peek(-25085)
            if       a=71:input             @2
            if       a<>0:print             \"Copy aborted....error #"a:print\

link.net
            if       not                    exec
            link     "a:network.seg"

link.term
            link     "a:main.seg","term1"

