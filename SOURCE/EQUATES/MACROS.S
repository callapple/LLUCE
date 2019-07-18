*-------------------------
*      Macro library
*-------------------------

INCD MAC ;Two byte INC
 INC ]1
 BNE NC
 INC ]1+1
NC
 <<<

DECD MAC ;Two byte DEC
 LDA ]1
 BNE NC
 DEC ]1+1
NC DEC ]1
 <<<

MOV MAC
 LDA ]1
 STA ]2
 <<<

MOVY MAC
 LDY ]1
 STY ]2
 <<<

MOVX MAC
 LDX ]1
 STX ]2
 <<<

MOVDY MAC
 MOVY ]1;]2
 MOVY ]1+1;]2+1
 <<<

MOVD MAC
 MOV ]1;]2
 IF (=]1 ;Syntax MOVD (ADR1),Y;????
 INY
 IF (=]2 ; MOVD (ADR1),Y;(ADR2),Y
 MOV ]1;]2
 ELSE ; MOVD (ADR1),Y;ADR2
 MOV ]1;]2+1
 FIN
 ELSE
 IF (=]2 ;Syntax MOVD ????;(ADR2),Y
 INY
 IF #=]1 ; MOVD #ADR1;(ADR2),Y
 MOV ]1/$100;]2
 ELSE ; MOVD ADR1;(ADR2),Y
 MOV ]1+1;]2
 FIN
 ELSE ;Syntax MOVD ????;ADR2
 IF #=]1 ; MOVD #ADR1;ADR2
 MOV ]1/$100;]2+1
 ELSE ; MOVD ADR1;ADR2
 MOV ]1+1;]2+1
 FIN
 FIN
 FIN
 <<<

MOV24 MAC
 MOV ]1;]2
 MOV ]1+1;]2+1
 MOV ]1+2;]2+2
 <<<

LDHI MAC ;For calls from other macs
 IF #=]1
 LDA ]1/$100
 ELSE
 LDA ]1+1
 FIN
 <<<

AD MAC
 LDA ]1
 ADC ]2
 STA ]3
 <<<

ADA MAC
 ADC ]1
 STA ]2
 <<<

ADD MAC
 IF #=]2
 IF #=]1
 ERR 1 ;Error if ADD #lab1;#lab2..
 FIN
 FIN
 CLC
 LDA ]1 ;Syntax ADD lab1;lab2;lab3
 ADC ]2 ; or ADD #lab1;lab2;lab3 etc
 DO ]0/3
 STA ]3 ;If 3 parms
 ELSE ;2 parm cases:
 IF #=]2
 STA ]1 ;Syntax ADD lab1;#lab2
 ELSE ;Syntax ADD lab1;lab2
 STA ]2 ; or ADD #lab1;lab2 -> lab2
 FIN
 FIN
 LDHI ]1
 IF #=]2
 ADC ]2/$100
 ELSE
 ADC ]2+1
 FIN
 DO ]0/3
 STA ]3+1 ;If 3 parms
 ELSE ;Two parm cases:
 IF #=]2
 STA ]1+1 ;Syntax ADD lab1;#lab2
 ELSE ; -> lab1
 STA ]2+1 ;Syntax ADD lab1;lab2 -> lab2
 FIN ; or ADD #lab1;lab2 -> lab2
 FIN
 <<<

SB MAC
 LDA ]1
 SBC ]2
 STA ]3
 <<<

SBA MAC
 SBC ]1
 STA ]2
 <<<

SUB MAC
 IF #=]2
 IF #=]1
 ERR 1 ;Error if SUB #lab1;#lab2..
 FIN
 FIN
 SEC
 LDA ]1 ;Syntax SUB lab1;lab2;lab3
 SBC ]2 ; or SUB #lab1;lab2;lab3 etc
 DO ]0/3
 STA ]3 ;If 3 parms
 ELSE ;Two parm cases:
 IF #=]2
 STA ]1 ;Syntax SUB lab1;#lab2
 ELSE ;Syntax SUB lab1;lab2
 STA ]2 ; or SUB #lab1;lab2 -> lab2
 FIN
 FIN ;Of 2 parm cases
 LDHI ]1
 IF #=]2
 SBC ]2/$100 ;Case #lab2
 ELSE
 SBC ]2+1 ;Case lab2
 FIN
 DO ]0/3
 STA ]3+1 ;If 3 parms
 ELSE ;Two parm cases:
 IF #=]2
 STA ]1+1 ;Syntax SUB lab1;#lab2
 ELSE ; -> lab1
 STA ]2+1 ;Syntax SUB lab1;lab2 -> lab2
 FIN ; or SUB #lab1;lab2 -> lab2
 FIN ;Of 2 parm cases
 <<<

*=================================================
* Save and restore registers macros.  Recommended
* for use at the start and end of subroutines
* which might be called from unknown status and
* which must set up register lengths.
*-------------------------------------------------

SVXAY MAC ;Save registers & status
 PHX
 PHA
 PHY
 <<<

RSTXAY MAC ;Restore regs & status
 PLY ; have correct length.
 PLA
 PLX ; so register restores
 <<<

PHAX MAC
 PHA
 PHX
 <<<

PLAX MAC
 PLX
 PLA
 <<<

PHXY MAC
 PHX
 PHY
 <<<

PLXY MAC
 PLY
 PLX
 <<<

PHXA MAC
 PHX
 PHA
 <<<

PLXA MAC
 PLA
 PLX
 <<<

PUSHA MAC
 LDA ]1
 PHA
 <<<

PUSHX MAC
 LDX ]1
 PHX
 <<<

PUSHW MAC
 PUSHA ]1+1
 PUSHA ]1
 <<<

PUSH3 MAC
 PUSHA ]1+2
 PUSHW ]1
 <<<

PULL MAC
 PLA
 STA ]1
 <<<

PULLX MAC
 PLX
 STX ]1
 <<<

PULLY MAC
 PLY
 STY ]1
 <<<

PULLW MAC
 PULL ]1
 PULL ]1+1
 <<<

PULL3 MAC
 PULLW ]1
 PULL ]1+2
 <<<

LD16 MAC
 LDX ]1
 LDHI ]1
 FIN
 <<<

ST16 MAC
 STX ]1
 STA ]1+1
 <<<

LD24 MAC
 LD16 ]1
 LDY ]1+2
 <<<

ST24 MAC
 ST16 ]1
 STY ]1+2
 <<<

LDXY MAC
 LDX ]1
 LDY ]1+1
 <<<

STXY MAC
 STX ]1
 STY ]1+1
 <<<

ZERO24 MAC
 STZ ]1
 STZ ]1+1
 STZ ]1+2
 <<<

BREQW MAC
 LDA ]1
 ORA ]1+1
 BEQ ]2
 <<<

BRNEW MAC
 LDA ]1
 ORA ]1+1
 BNE ]2
 <<<

BREQ3 MAC
 LDA ]1
 ORA ]1+1
 ORA ]1+2
 BEQ ]2
 <<<

BRNE3 MAC
 LDA ]1
 ORA ]1+1
 ORA ]1+2
 BNE ]2
 <<<

SKIP2 MAC
 HEX 2C
 <<<

SKIPCS MAC
 HEX B0
 <<<

SKIPCC MAC
 HEX 90
 <<<

PDOS MAC
 JSR MLI
 DB ]1
 DA ]2
 <<<

IFEQ MAC
 LDA ]1
 CPEQ ]2;]3
 <<<

CPEQ MAC
 CMP ]1
 BEQ ]2
 <<<

IFEQX MAC
 LDX ]1
 CPEQX ]2;]3
 <<<

CPEQX MAC
 CPX ]1
 BEQ ]2
 <<<

IFEQY MAC
 LDY ]1
 CPEQY ]2;]3
 <<<

CPEQY MAC
 CPY ]1
 BEQ ]2
 <<<

IFNE MAC
 LDA ]1
 CPNE ]2;]3
 <<<

CPNE MAC
 CMP ]1
 BNE ]2
 <<<

IFNEX MAC
 LDX ]1
 CPNEX ]2;]3
 <<<

CPNEX MAC
 CPX ]1
 BNE ]2
 <<<

IFNEY MAC
 LDY ]1
 CPNEY ]2;]3
 <<<

CPNEY MAC
 CPY ]1
 BNE ]2
 <<<

IFLT MAC
 LDA ]1
 CPLT ]2;]3
 <<<

CPLT MAC
 CMP ]1
 BLT ]2
 <<<

IFLTX MAC
 LDX ]1
 CPLTX ]2;]3
 <<<

CPLTX MAC
 CPX ]1
 BLT ]2
 <<<

IFLTY MAC
 LDY ]1
 CPLTY ]2;]3
 <<<

CPLTY MAC
 CPY ]1
 BLT ]2
 <<<

IFGE MAC
 LDA ]1
 CPGE ]2;]3
 <<<

CPGE MAC
 CMP ]1
 BGE ]2
 <<<

IFGEX MAC
 LDX ]1
 CPGEX ]2;]3
 <<<

CPGEX MAC
 CPX ]1
 BGE ]2
 <<<

IFGEY MAC
 LDY ]1
 CPGEY ]2;]3
 <<<

CPGEY MAC
 CPY ]1
 BGE ]2
 <<<

IFMI MAC
 LDA ]1
 CPMI ]2;]3
 <<<

CPMI MAC
 CMP ]1
 BMI ]2
 <<<

IFMIX MAC
 LDX ]1
 CPMIX ]2;]3
 <<<

CPMIX MAC
 CPX ]1
 BMI ]2
 <<<

IFMIY MAC
 LDY ]1
 CPMIY ]2;]3
 <<<

CPMIY MAC
 CPY ]1
 BMI ]2
 <<<

IFPL MAC
 LDA ]1
 CPPL ]2;]3
 <<<

CPPL MAC
 CMP ]1
 BPL ]2
 <<<

IFPLX MAC
 LDX ]1
 CPPLX ]2;]3
 <<<

CPPLX MAC
 CPX ]1
 BPL ]2
 <<<

IFPLY MAC
 LDY ]1
 CPPLY ]2;]3
 <<<

CPPLY MAC
 CPY ]1
 BPL ]2
 <<<

DBNE MAC
 IF Y=]1
 DEY
 ELSE
 IF X=]1
 DEX
 ELSE
 IF A=]1
 DEC A
 ELSE
 DEC ]1
 FIN
 FIN
 FIN
 BNE ]2
 <<<

DBEQ MAC
 IF Y=]1
 DEY
 ELSE
 IF X=]1
 DEX
 ELSE
 IF A=]1
 DEC A
 ELSE
 DEC ]1
 FIN
 FIN
 FIN
 BEQ ]2
 <<<

DBMI MAC
 IF Y=]1
 DEY
 ELSE
 IF X=]1
 DEX
 ELSE
 IF A=]1
 DEC A
 ELSE
 DEC ]1
 FIN
 FIN
 FIN
 BMI ]2
 <<<

DBPL MAC
 IF Y=]1
 DEY
 ELSE
 IF X=]1
 DEX
 ELSE
 IF A=]1
 DEC A
 ELSE
 DEC ]1
 FIN
 FIN
 FIN
 BPL ]2
 <<<

DBRA MAC
 IF Y=]1
 DEY
 ELSE
 IF X=]1
 DEX
 ELSE
 IF A=]1
 DEC A
 ELSE
 DEC ]1
 FIN
 FIN
 FIN
 BRA ]2
 <<<

IBEQ MAC
 IF Y=]1
 INY
 ELSE
 IF X=]1
 INX
 ELSE
 IF A=]1
 INC A
 ELSE
 INC ]1
 FIN
 FIN
 FIN
 BEQ ]2
 <<<

IBNE MAC
 IF Y=]1
 INY
 ELSE
 IF X=]1
 INX
 ELSE
 IF A=]1
 INC A
 ELSE
 INC ]1
 FIN
 FIN
 FIN
 BNE ]2
 <<<

IBPL MAC
 IF Y=]1
 INY
 ELSE
 IF X=]1
 INX
 ELSE
 IF A=]1
 INC A
 ELSE
 INC ]1
 FIN
 FIN
 FIN
 BPL ]2
 <<<

IBMI MAC
 IF Y=]1
 INY
 ELSE
 IF X=]1
 INX
 ELSE
 IF A=]1
 INC A
 ELSE
 INC ]1
 FIN
 FIN
 FIN
 BMI ]2
 <<<

IBRA MAC
 IF Y=]1
 INY
 ELSE
 IF X=]1
 INX
 ELSE
 IF A=]1
 INC A
 ELSE
 INC ]1
 FIN
 FIN
 FIN
 BRA ]2
 <<<

LDEQ MAC
 LDA ]1
 BEQ ]2
 <<<

LDEQX MAC
 LDX ]1
 BEQ ]2
 <<<

LDEQY MAC
 LDY ]1
 BEQ ]2
 <<<

LDNE MAC
 LDA ]1
 BNE ]2
 <<<

LDNEX MAC
 LDX ]1
 BNE ]2
 <<<

LDNEY MAC
 LDY ]1
 BNE ]2
 <<<

LDPL MAC
 LDA ]1
 BPL ]2
 <<<

LDPLX MAC
 LDX ]1
 BPL ]2
 <<<

LDPLY MAC
 LDY ]1
 BPL ]2
 <<<

LDMI MAC
 LDA ]1
 BMI ]2
 <<<

LDMIX MAC
 LDX ]1
 BMI ]2
 <<<

LDMIY MAC
 LDY ]1
 BMI ]2
 <<<

LDRA MAC
 LDA ]1
 BRA ]2
 <<<

LDRAX MAC
 LDX ]1
 BRA ]2
 <<<

LDRAY MAC
 LDY ]1
 BRA ]2
 <<<

TSTPL MAC
 BIT ]1
 BPL ]2
 <<<

TSTMI MAC
 BIT ]1
 BMI ]2
 <<<

TSTVC MAC
 BIT ]1
 BVC ]2
 <<<

TSTVS MAC
 BIT ]1
 BVS ]2
 <<<

TSTRA MAC
 BIT ]1
 BRA ]2
 <<<

TKN MAC
 DCI ]1
 DB ]2
 <<<

CHR MAC
 IF '=]1
 ASC ]1
 ELSE
 DB ]1
 FIN
 DA ]2
 <<<
