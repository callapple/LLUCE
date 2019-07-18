            LST   RTN
            TTL   'LLUCE - No Printer'
            PAG
PRINTDVR    DB    0

PRINIT      JMP   P_INIT
LPROUT      JMP   P_PRINT
PRCLEAR     JMP   P_CLEAR

P_INIT      RTS                         ;Init Printer
P_PRINT     RTS                         ;Print Character In A
P_CLEAR     RTS                         ;Clear Print Buffer (Not Implemented)
            DS    \
            LST   OFF

