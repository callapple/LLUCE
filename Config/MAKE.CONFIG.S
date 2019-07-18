
*m_vers = '1' ; make into ascii # (Main Version)
*s_vers = '0' ; make into ascii # (Sub Version)
*p_vers = '5' ; make into ascii # (Patch Version)

            ORG   $2000                  ; org to where you want it
            TYP   $FF

            ASM   START
            ASM   ROUTINE
            ASM   DISK
            ASM   OSPJUNK
            ASM   VIDEO
            ASM   CMD
            ASM   MODEM
            ASM   PRINTER
            ASM   CLOCK
            ASM   FILTER
            ASM   DEFAULTS
            ASM   INIT

            ASM   INITSTR
            ASM   MODEMS/NULLMDM
            ASM   MODEMS/CAT103
            ASM   MODEMS/CAT212
            ASM   MODEMS/MM2
            ASM   MODEMS/SSC
            ASM   MODEMS/GSPORT.SLOT1
            ASM   MODEMS/GSPORT.SLOT2
            ASM   MODEMS/SINGLESPD
            ASM   MODEMS/MULTISPD
            ASM   MODEMS/NOCAR

            ASM   CLOCKS/THUNDER
            ASM   CLOCKS/SERIALPRO
            ASM   CLOCKS/ULTRA
            ASM   CLOCKS/NO.SLOT
            ASM   CLOCKS/IIC.SYS
            ASM   CLOCKS/PRODOS
            ASM   CLOCKS/MOUNTAIN
            ASM   CLOCKS/VERSA
            ASM   CLOCKS/IIGS
            ASM   CLOCKS/NULL

            ASM   PRINTERS/NULL
            ASM   PRINTERS/PARALLEL
            ASM   PRINTERS/SERIAL
            ASM   PRINTERS/GRAPPLER

            LINK  REL/START
            LINK  REL/ROUTINE
            LINK  REL/DISK
            LINK  REL/OSPJUNK
            LINK  REL/VIDEO
            LINK  REL/CMD
            LINK  REL/MODEM
            LINK  REL/PRINTER
            LINK  REL/CLOCK
            LINK  REL/FILTER
            LINK  REL/DEFAULTS
            LINK  REL/INIT

            LINK  REL/INITSTR
            LINK  MODEMS/REL/NULLMDM
            LINK  MODEMS/REL/CAT103
            LINK  MODEMS/REL/CAT212
            LINK  MODEMS/REL/MM2
            LINK  MODEMS/REL/SSC
            LINK  MODEMS/REL/GSPORT1
            LINK  MODEMS/REL/GSPORT2
            LINK  MODEMS/REL/SINGLESPD
            LINK  MODEMS/REL/MULTISPD
            LINK  MODEMS/REL/NOCAR

            LINK  CLOCKS/REL/THUNDER
            LINK  CLOCKS/REL/SERIALPRO
            LINK  CLOCKS/REL/ULTRA
            LINK  CLOCKS/REL/NOSLOT
            LINK  CLOCKS/REL/IICSYS
            LINK  CLOCKS/REL/PRODOS
            LINK  CLOCKS/REL/MOUNTAIN
            LINK  CLOCKS/REL/VERSA
            LINK  CLOCKS/REL/GSCLOCK
            LINK  CLOCKS/REL/NULL

            LINK  PRINTERS/REL/NULL
            LINK  PRINTERS/REL/PARALLEL
            LINK  PRINTERS/REL/SERIAL
            LINK  PRINTERS/REL/GRAPPLER

            SAV   CONFIG.SYSTEM

