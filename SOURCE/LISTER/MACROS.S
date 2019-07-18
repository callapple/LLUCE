ZEROSEEK    MAC
            JSR   MARKZERO
            <<<

READ        MAC
            LDY   ]1
            JSR   DO_READ
            DA    ]2
            <<<

PUTMARK     MAC
            LDX   ]1
            LDA   ]1+1
            LDY   ]1+1
            JSR   SET_POS
            <<<

GETMARK     MAC
            JSR   GET_MARK
            STX   ]1
            STA   ]1+1
            STY   ]1+2
            <<<

PRINT       MAC
            JSR   SHOWSTR
            DCI   ]1
            <<<

APPLE       MAC
            IF    ]0=0
            LDA   #0
            ELSE
            LDA   #$80
            FIN
            JSR   APLHDR
            <<<

MSDOS       MAC
            IF    ]0=0
            LDA   #0
            ELSE
            LDA   #$80
            FIN
            JSR   MSHDR
            <<<

CROUT       MAC
            JSR   DO_CROUT
            <<<

SPACE       MAC
            JSR   DO_SPACE
            <<<

AUXTYPE     MAC
            JSR   DO_AUX
            DA    ]1
            <<<

TWOSPACE    MAC
            JSR   DO_TWOSP
            <<<

TWODOTS     MAC
            JSR   DO_DOTS
            <<<

CSTRING     MAC
            LDA   ]1
            JSR   DO_CSTR
            DA    ]2
            <<<

PSTRING     MAC
            LDA   ]1
            LDY   ]2
            JSR   DO_PSTR
            DA    ]3
            <<<

REVWORD     MAC
            JSR   REVTWO
            DA    ]1
            <<<

REVLONG     MAC
            JSR   REVFOUR
            DA    ]1
            <<<

PDATE       MAC
            JSR   PDOSDATE
            DA    ]1
            <<<

MDATE       MAC
            JSR   MSDATE
            DA    ]1
            <<<

PTIME       MAC
            JSR   PDOSTIME
            DA    ]1
            <<<

MTIME       MAC
            JSR   MSTIME
            DA    ]1
            <<<

GTIME       MAC
            JSR   GSTIME
            DA    ]1
            <<<

GDATE       MAC
            JSR   GSDATE
            DA    ]1
            <<<

MACDT       MAC
            JSR   SECONDS
            DA    ]1
            <<<

CONVDEC     MAC
            JSR   BINDEC8
            STA   ]1
            STX   ]1+1
            <<<

DIVIDE      MAC
            JSR   DO_DIV
            DB    ]1-1
            DA    ]2-1
            DB    ]3-1
            DA    ]4-1
            DB    ]5-1
            DA    ]6-1
            <<<

ADD         MAC
            JSR   DO_ADD
            DB    ]1
            DA    ]2
            DB    ]3
            DA    ]4
            DB    ]5
            DA    ]6
            <<<

SUB         MAC
            JSR   DO_SUB
            DB    ]1
            DA    ]2
            DB    ]3
            DA    ]4
            DB    ]5
            DA    ]6
            <<<

DECOUT      MAC
            JSR   DO_DEC
            DB    ]1
            DB    ]2-1
            DA    ]3
            <<<

PERCENT     MAC
            JSR   DO_PER
            DB    ]1-1
            DA    ]2
            DB    ]3-1
            DA    ]4
            <<<

STACK       MAC
            LDA   #]1
            JSR   ADDSTK
            <<<

P_ACCESS    MAC
            JSR   PD_ACCES
            DA    ]1
            <<<

M_ACCESS    MAC
            JSR   M_ACS
            DA    ]1
            <<<

FILETYPE    MAC
            JSR   PRTYPE
            DA    ]1
            <<<

