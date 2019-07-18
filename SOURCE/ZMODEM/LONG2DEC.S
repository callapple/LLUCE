*
* July 15, 1991
*
* This file is hereby dedicated to the public domain.
*                                 -- Andrew Nicholas
*
            LST   RTN

*-------------------------------------------------
* Merlin 8 code extracted from Davex 1.27
*  Code by Dave Lyons and Steve Wozniak, with
*  tweeks for Zmodem by Andy Nicholas
*
* Input: num, num+1, num+2 (zero page)

LONG2DEC    LSR   DIGIT_FLAG  ;True if a digit has been printed

            LDY   #7          ;loop back to prd_L1 for each digit
            STZ   DIGIT

PRD_L1      LDX   #'0'        ;Digit so far, loop to prd_L2 while
PRD_L2      LDA   NUM+2       ;calculating one digit
            CMP   HIG10,Y
            BNE   PCMP_DUN
            LDA   NUM+1
            CMP   MED10,Y
            BNE   PCMP_DUN
            LDA   NUM
            CMP   LOW10,Y
PCMP_DUN    BCC   PR_DIGIT

*        SEC              ;always set
            LDA   NUM
            SBC   LOW10,Y
            STA   NUM
            LDA   NUM+1
            SBC   MED10,Y
            STA   NUM+1
            LDA   NUM+2
            SBC   HIG10,Y
            STA   NUM+2
            INX
            BNE   PRD_L2

PR_DIGIT    CPY   #0
            BEQ   PRINTIT
            CPX   #'0'
            BNE   PRINTIT

            BIT   DIGIT_FLAG
            BPL   PRINTED

PRINTIT     SEC
            ROR   DIGIT_FLAG

            TXA
            LDX   DIGIT
            STA   DECIMAL,X
            INC   DIGIT

PRINTED     DEY
            BPL   PRD_L1

            LDX   DIGIT
            STZ   DECIMAL,X
            RTS

DIGIT_FLAG  DB    0
DIGIT       DB    0

*-------------------------------------------------
* tables for base 10 printing

LOW10       DB    <1
            DB    <10
            DB    <100
            DB    <1000
            DB    <10000
            DB    <100000
            DB    <1000000
            DB    <10000000

MED10       DB    >1
            DB    >10
            DB    >100
            DB    >1000
            DB    >10000
            DB    >100000
            DB    >1000000
            DB    >10000000

HIG10       DB    ^1
            DB    ^10
            DB    ^100
            DB    ^1000
            DB    ^10000
            DB    ^100000
            DB    ^1000000
            DB    ^10000000

            LST   OFF

