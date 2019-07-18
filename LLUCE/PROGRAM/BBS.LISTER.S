; **********************
;    GBBS "Pro" V:1.3
;  By L & L Productions
;     Copyright 1987
; **********************

; BBS Update Seg 8/16/87

	on nocar goto link.term

start
	print '
Please take a few minutes and help
us update the GBBS Pro BBS List
by entering your boards information'

list
	input @3 "\nSystem Name: "z1$
phone
	input @3 "Phone Number [Form ###-###-####]: "i$
	if len(i$)!=12 goto phone
	z2$=left$(i$,3)+"-"+mid$(i$,5,3)+"-"+right$(i$,4)

	input @3 "Highest Baud: "z3$
	input @2 "Are you PCP'able (Y/N):"z4$
	z4$=left$(z4$,1)
	input "Your GBBS serial number:"z5$
	input @2 "Do you want the system listed (Y/N):"z6$
	z6$=left$(z6$,1)

	print "\nWe have the following:"
	print "\nSystem Name: "z1$
	print "Phone Number: "z2$
	print "Baud Rate: "z3$
	print "PC Pursuitable: "z4$
	print "GBBS Serial Number: "z5$
	print "System list: "z6$

	input @2 "\nIs this correct? "i$
	if i$<>"Y" print:goto list

	print "\nThank you for taking the time to"
	print "answer these questions.  Just a"
	print "moment while I save them."

	create "system/gbbs.list":open #1,"system/gbbs.list"
	append #1:print #1,a3$"\n"z1$"\n"z2$"\n"z3$"\n"z4$"\n"z5$"\n"z6$
	close:flag(30)=1:chain "program/main.seg"

link.term
	chain "program/main.seg","termin2"
