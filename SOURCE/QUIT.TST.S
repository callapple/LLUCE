            ORG   $2000
            JSR   $BF00
            DB    $65
            DA    QUITLST
            BRK   00

QUITLST     DB    4
            DS    6

