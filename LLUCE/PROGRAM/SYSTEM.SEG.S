; *********************
;      LLUCE v1.0
;    Copyright 1989
; L&L Productions, Inc.
; *********************

; system segment rev b - 4/10/89

	public return

	on nocar goto link.term
; on error goto error
	pr$=inverse$+"[System]"+normal$+"...":pl=len(pr$)-2

system
	gosub time:print "\n[("x$")] System Level [?=Menu] Function";
system1
	l1$="?/LSRWNTEKGBFPQ%*":gosub getone
system2
	clear gosub:push system
	if i$="?" | i$="/" print "Menu":goto menu
	if i$="L" print "View System Log":goto log
	if i$="S" print "Show a Text File":goto file
	if i$="R" print "Read Request File":goto request
	if i$="W" print "Update System Welcome Message":goto welcome
;	if i$="D" print "Dos Command":goto dos.cmd
	if i$="N" print "Add a New User":goto new.user
	if i$="T" print "Terminate":goto terminate
	if i$="E" print "Edit Users Status":goto edit.pass
	if i$="H" print "Help":ns=4:l$="HELP":goto dispatch
	if i$="K" print "Kill a Users Account":goto kill.pass
	if i$="G" print "Edit a Text FIle":goto edit.file
	if i$="B" print "Edit Conference/Board Status":l$="BOARDS":pop:goto dispatch
	if i$="F" print "Edit Flag Access Level Prompts":goto ed.flags
	if i$="P" print "Print User List":pop:chain "program/maint.seg","userlist"
	if i$="Q" print "Quit to Main Level":pop:goto link.main
	if i$="%" print "Edit Help File":goto hlp.edit
	if i$="*" print "Configure Auto Validation":goto val.flags
system2
	a1++:print "\n"pr$"\""i$"\" is not a command":if a1<3 return

; *** sub - routines ***

menu
	a1=0:f$="system/mnu.system80":if width<79:f$="system/mnu.system40"
menu1
	if ~exist(f$) return
	disk lock:open #1,f$:input #1,x$:setint(" "):addint(x$)
	cls:copy #1:if key flag goto menukey
	a=key:close:disk unlock:setint(""):pop:goto system

menukey
	close:disk unlock:setint(""):a=key:i$=chr$(a):upper$(i$)
	if i$=" " goto system
	print "\n\n["x$"][System Level] Option (?=Help) :";
	goto system2

; terminate connection from system

terminate
	print "\nTerminate From "sn$
	print "\nAre You Sure";:yn=2:gosub getyn
	if i$="N" return
	pop
link.term
	chain "program/main.seg","term1"
link.main
	chain "program/main.seg","otherseg"

; edit/verifiy users accounts

edit.pass
	input @2 "\nAccount # ->"i$:if i$="" return
	a=val(i$):if i$="C":a=un:v$="0"

ed.pass0
	if (a<1) | (a>nu) print "\nUser does not exist.":return
	d1$=a1$:d2$=a2$:d3$=id$:d4$=a4$:d5$=a5$
	move ram,60 to ram(1):gosub rd.user
	if d1$<>"" goto ed.pass2
	print "\nUser does not exist - create?";:yn=2:gosub getyn
	if i$="N" move ram(1),60 to ram:return
ed.pass1
	fill ram,60,0:d3$="NOMAILID":d1$="New User"
	d2$="Unknown":d4$="Somewhere":d5$="ST"
	pa$="PASSWORD":ph$="XXX-XXX-XXXX":nibble(6)=3

ed.pass2
	ul=(byte(10)<<16)+(byte(9)<<8)+byte(8)
	dl=(byte(13)<<16)+(byte(12)<<8)+byte(11)
	print "\nA) Mail ID:"d3$"\nB) Name   :"d1$
	print "C) Affil. :"d2$"\nD) From   :"d4$", "d5$
	print "E) Pass   :"a"-"pa$"\nF) Phone  :"ph$
	print "G) Flags  :";
	for x=1 to 34:print flag(x);:next
	print "\nH) Time   :"nibble(6)*10
	print "I) Blks Up:"ul"\nJ) Blks Dn:"dl"\nK) Mins On:"byte(7)
	input @2 "\nWhich [A-K] or press \"*\" to Auto-Validate : "i$

	if i$="A" gosub edit.id
	if i$="B" input @3 "\nFull name ->"d1$:mixed$(d1$)
	if i$="C" input @3 "\nAffilication ->"d2$:mixed$(d2$)
	if i$="D" input "\nCity ->"d4$:mixed$(d4$)
	if i$="D" input "State ->"d5$:d5$=left$(d5$,2):upper$(d5$)
	if i$="E" input "\nPass :"pa$:pa$=left$(pa$+chr$(0x20,8),8)
	if i$="F" input "\nPhone :"ph$
	if i$="G" gosub edit.flg
	if i$="H" input "\nTime Limit :"x:nibble(6)=x/10
	if i$="I" gosub edit.up
	if i$="J" gosub edit.dn
	if i$="K" input "\nMinutes online today: "x:byte(7)=x
	if i$="*" gosub ed.val
	if i$="" goto ed.pass5
	goto ed.pass2

ed.pass5
	b=len(d1$+d2$):if b<60 goto ed5a
	print "\n"pr$"Name and affiliation are too long."
	print chr$(0x20,pl)"Max len=60, current len="b
	goto ed.pass2

ed5a
	b=len(d4$+d5$):if b<22 goto ed.pass6
	print "\n"pr$"City and State are too long."
	print chr$(0x20,pl)"Max len=22, current len="b
	goto ed.pass2

ed.pass6
	input "\nSave, Abort, or Return? "i$
	if i$="A" goto ed.exit
	if i$="R" goto ed.pass2
	if i$<>"S" goto ed.pass6
	print "\n"pr$"Saving...";:if a>nu:nu=a
	if a=un:a1$=d1$:a2$=d2$:id$=d3$:a4$=d4$:a5$=d5$
	gosub wr.user:print ".Done":if a=un return
ed.exit
	move ram(1),60 to ram
	ul=(byte(10)<<16)+(byte(9)<<8)+byte(8)
	dl=(byte(13)<<16)+(byte(12)<<8)+byte(11)
	return

edit.flg
	gosub flg.ttl:input @2 a$:if a$="" goto ed.flg2
	if a$="?" goto ed.flg1
	y=len(a$):if y>35:y=34
	for x=1 to y:flag(x)=(mid$(a$,x,1)="1"):next:goto ed.flg2

ed.flg1
	disk lock:open #1,"system/sys.data2"
	for x=0 to 34:i$=""
	position #1,32,x:input #1,a$
	if a$<>"" print "\n"a$:input "Set Flag? [Y,N,S,Q]:"i$
	if i$="Q":x=34
	if i$="Y":flag(x)=1
	if i$="N":flag(x)=0
	next:close #1
ed.flg2
	disk unlock:if flag(1):flag(0)=0:return

edit.id
	x$=d3$:input "\nMail ID ->"a$
	if a$="" goto edit.id1
	upper$(a$):a$=left$(a$+chr$(0x20,10),10):d3$=a$
	gosub name.chk:if ~f:x$=d3$:goto edit.id1
	print "\nSorry, that mail ID is in use. Try Again"
	goto edit.id

edit.id1
	d3$=x$:return

edit.up
	input "\nUploaded Blocks ->"a$
	if a$="" return
	ul=val(a$)
	byte(10)=(ul>>16):b=ul & 0xFFFF
	byte(9)=(b>>8):byte(8)=b & 0xFF
	return

edit.dn
	input "\nDownloaded Blocks ->"a$
	if a$="" return
	dl=val(a$)
	byte(13)=(dl>>16):b=dl & 0xFFFF
	byte(12)=(b>>8):byte(11)=b & 0xFF
	return

ed.val
	f$="system/sys.autoval":if ~exist(f$) return
	disk lock:open #1,f$:input #1,i$:close:disk unlock
	for x=1 to 34:flag(x)=val(mid$(i$,x,1)):next
	return

val.flags
	print "\nDo you want to modify the auto-validation flags?";
	yn=2:gosub getyn:if i$="N" return
	f$="system/sys.autoval"
	if ~exist(f$):i$=chr$(48,34):create f$:goto val.fl2
	disk lock:open #1,f$:input #1,i$:close:disk unlock
val.fl2
	print "\nCurrent Auto-Validation flags are set as:"
	gosub flg.ttl:print left$(i$,34)
	print "\nEnter the new auto-valadation flags:\n"
	gosub flg.ttl:input @2 i$:if i$="" return
	i$=left$(i$+chr$(0x30,34),34)
	disk lock:open #1,f$:print #1,i$:close:disk unlock
	return

flg.ttl
	print '
Flag: 0000000001111111111222222222233333
     _1234567890123456789012345678901234_
Lvl : ';:return

kill.pass
	print "\n"pr$"Kill User # ->";:input a
	if (a<1) | (a>nu) return
	move ram,60 to ram(1):gosub rd.user
	a$=mid$(" "+when$,2)
	if d1$="" print "\n"pr$"That user does not exist":\
		move ram(1),60 to ram:return
	print "\n"pr$"Kill "d1$"\n"chr$(0x20,pl)"Last on - "a$"?";
	yn=2:gosub getyn:if i$="N" move ram(1),60 to ram:return
	d1$="":disk lock:gosub wr.user:disk unlock
	print "\nUser Killed"
	move ram(1),60 to ram:return

request
	f$="system/request"
	if ~exist(f$) print "\n"pr$"Sorry, no new users":return
	disk lock:open #2,f$
	print "\n"pr$"Send file to printer?";:yn=1:es=1:gosub getyn
	if i$="\x1B" close:return
	if i$="Y" setint(1):copy #2,#5:mark(2)=0
req2
	input #2,a:b=mark(2):if a goto req3
	close:disk unlock:print "\n"pr$"Delete File?";
	yn=2:gosub getyn:if i$="Y" delete "system/request"
	return

req3
	mark(2)=b:print "\n"md$
req3a
	input #2,i$:if i$<>chr$(1) print i$:goto req3a
	print md$
req4
	print "\nRequest [V, K, "inverse$"C"normal$", R, A, Q, ?]";
	l1$="RQ?CKVA\n":gosub getone
	if i$="R" print "Re-read":goto req3
	if i$="Q" print "Quit":close:return
	if i$="?" print 'Help

(V)alidate, (K)ill, (C)ontinue/skip, (R)e-read, (A)uto-reply, (Q)uit'
	if i$="?" goto req4
	if i$="C" | i$="\n" print "Continue":goto req2
	if i$="K" print "Kill"::d1$="":gosub wr.user:goto req2
	if i$="V" print "Validate":gosub ed.pass0:goto req2
	print "Auto-reply":k=mark(2):close:disk unlock
	k$="program/system.seg":d=a
	chain "program/mail.seg","message.link"

return
	on nocar goto link.term
	disk lock:open #2,"system/request":mark(2)=k
	goto req4

dispatch
	y$="program/system.seg"			/* segment to return to upon compleation */
	z$=""							/* enter segment at beginning */
	chain "program/util.seg","dispatch"

file
	input @2 "\nFile Name (to read) ->"i$
	f$=i$:if i$="" return
	print "\nShow file on printer?";
	yn=1:gosub getyn:if i$="N" goto show.file
	setint(1):copy f$,#5:return

log
	f$="system/log.system"
	print "\n"pr$"[ SysOp Log ] : D)elete, S)how, P)rint, Q)uit";
	l1$="DSPAQ\n":gosub getone
	if i$="D" print "Kill":delete f$:return
	if i$="S" print "Show":gosub show.file
	if i$="P" print "Print":setint(1):copy f$,#5:setint("")
	if i$="A" | i$="Q" | i$="\n" print "Quit":return
	goto log

welcome
	print "\n"pr$"Show current welcome to all users?";
	yn=2:gosub getyn:if i$="N" return
	gosub data.read:wm$=da$:disk lock:gosub data.write
	disk unlock:print "\n"pr$"News updated":return

edit.file
	print "\n"pr$"File Name (to load) ->";:input @2 i$
	edit clear:if i$<>"" disk lock:copy i$,#9:disk unlock
	print "\nEnter/Edit File Now: "width" cols, 4k max"
	print "Type \"DONE\" when finished \".h\" for help"
	edit:if ~edit size return
	print "\n"pr$"File Name (to save) ->";:input @2 i$
	if i$="" return
	disk lock:delete i$:create i$:open #1,i$
	copy #9,#1:close:disk unlock
	return

dos.cmd
	print "\n"pr$"DOS:";:input @2 i$:if i$="" return
	overlay "xdos",i$:return

new.user
	print "\n"pr$"Add a new user?";
	yn=1:gosub getyn:if i$="N" return
	move ram,60 to ram(1)
	a=nu+1:goto ed.pass1

hlp.edit
	f$="system/sys.help"
	if ~exist(f$) create f$,msg,1024:msg(1023)=1		/* if no file, make it */
hlp.ed1
	print cls'\nSelect section to edit

0.  Return to system
1.  Main level commands
2.  Email commands
3.  Utility commands
4.  Bulletin board commands
5.  System level commands
6.  Transfer system commands

    Select section';
	l1$="0123456\n\x1B":gosub getone
	if i$="\n" | i$="\x1B" | i$="0" print "Quit":ns=4:return
	ns=(val(i$)-1)*64
	ready f$:cls										/* ready the file */
	for x=0 to 15:i$=""									/* doing 16 lines */
	for y=0 to 3										/* doing 4 columns */
	t=x+(y*16)											/* calculate character */
	x$=chr$(t+32)
	input #msg(t+ns),z,a$								/* read in msg info */
	i$=i$+x$+"-"+left$(a$+chr$(0x20,17),17)+" "			/* make string */
	next:i$=left$(i$,79):print i$:next
hlp.ed2
	l1$="":for x=33 to 95:l1$=l1$+chr$(x):next:l1$=l1$+"\n\x1B"
	print "\nWhich selection?";:gosub getone			/* get message key */
	if i$="\n" | i$="\x1B" print "Quit":goto hlp.ed1	/* if no entry, exit */

	print i$:l=(asc(i$)-32)+(64*ns)				/* calculate message number */

hlp.ed2a
	push hlp.ed2						/* save return */
	if l=0 return						/* if it's 0, exit */
	edit clear							/* clear the editor */
	input #msg(l),z,a$					/* read the header */
	if z copy #7,#9						/* if a message, copy to editor */
	print "\nRead in a file?";
	yn=1:es=1:gosub getyn				/* check if file to be read */
	if es return						/* if escape pressed, exit */
	if i$="N" goto hlp.ed3				/* no, check for Xmodem */
	input @2 "\nFile to read -> "i$		/* get file to read */
	if i$<>"" edit clear:copy i$,#9		/* if name given, read it */
hlp.ed3
	print "\nUpload by Xmodem?";
	yn=1:es=1:gosub getyn				/* check if message upload */
	if es return						/* if escape, exit */
	if i$="Y" gosub up.xmdm				/* yes, do it */
	print "\nEditing command: "a$"\n"	/* print header */
	print "Enter/Edit File Now: "width+1" cols, \"4k\" max"
	print "Type 'DONE' when finished \".H\" for help"
	edit								/* edit the message */
	s=1									/* set aborting flag */
	if edit size goto hlp.ed4			/* if data in editor, go save it */
	print "\nZero this message?";
	yn=1:es=1:gosub getyn				/* message to be zeroed? */
	s=0									/* flag yes */
	if i$="N" return					/* no, exit */

hlp.ed4
	print "\nCurrent message  name is: "a$		/* show original header */
	input @3 "Enter new name or <CR> -> "i$		/* get new header (maybe) */
	if i$<>"":a$=i$								/* not blank entry, new header */
	delete #msg(l)								/* remove old message */
	print #msg(l),edit size,a$					/* save size and header */
	copy #9,#7									/* copy the editor to record */
	msg(l)=s									/* save deleted flag */
	flush										/* write to disk */
	return										/* back to system file editor */

/*
		Standard Xmodem upload routine
		NOTE:	old Xmodem upload routine used here
				can be replaced with new protocol routine
*/

up.xmdm
	print "\nSelect Xmodem type:\n"
	print "P)roDOS  D)OS3.3  S)tandard";
	l1$="PDS\n\x1B":gosub getone:z=instr(i$,"PDS")
	if z=0 pop:return
	z=z*(z<>3):print i$"\n\nReady to Receive..."
	f$="u":overlay "x.up",z,f$:close:edit clear
	copy f$,#9:print "\n"edit size" bytes received"
	kill f$:return

/*
		This routine gets a Yes/No answer
		A prompt is printed, hilighting the default
		response (if any)

		Input parameters are:

		yn	= 0:	No default
		yn	= 1:	Default is no
		yn	= 2:	Default is yes

		es	= 0:	Escape not accepted
		es	= 1:	Escape returns a No
		es	= 2:	Escape returns a Yes

		Output parameters are:

		i$	=		Entered response, see possibilities above
		es	=		0: no escape pressed
					1: escape pressed
					NOTE: es = 0 if escape not active
*/

;

getyn
	print " (";:l1$="YN"
	if yn=2 print inverse$"[Y]"normal$;:l1$=l1$+"\n":else print "y";
	print "/";
	if yn=1 print inverse$"[N]"normal$;:l1$=l1$+"\n":else print "n";
	print ")";
	if es>0:l1$=l1$+"\x1B"							/* if escape active, add it */
	gosub getone:l1$=i$								/* get the response */
	if (i$="\x1B") and (es>0):i$=mid$("NY",es,1)	/* check escape response */
	if (i$="\n") and (yn>0):i$=mid$("NY",yn,1)		/* check default response */
	es=0:yn=0										/* zero the codes */
	if l1$="\x1B":es=1:print "Esc":return			/* if escape pressed, print it */
	if i$="Y" print "Yes":else print "No"			/* print response */
	return

;		l1$ is the available keys

getone
	print ": ";							/* print standard single key prompt */
getonex
	get i$								/* get a key */
	if instr(i$,l1$) return				/* if valid key, exit */
	goto getonex						/* try again */

;	Edit access level prompts

ed.flags
	print "\n"pr$"Edit Access Flags Text - "inverse$"[Q]"normal$"uit, V)iew, E)dit";
ed.flgs0
	l1$="QEV\n\x1B":gosub getone
	if i$="Q" | i$="\n" | i$="\x1B" print "Quit":return
	push ed.flags:if i$="E" print "Edit":goto ed.flgs1
	print "View\n":disk lock:open #1,"system/sys.data2":for l=0 to 16
	position #1,32,l:input #1,a$:position #1,32,l+17:input #1,b$
	print right$(sp$+str$(l),2)". "left$(a$+chr$(0x20,32),32)"  ";
	print right$(sp$+str$(l+17),2)". "b$:next
	position #1,32,34:input #1,a$:print chr$(0x20,38)"34. "a$:close
	disk unlock:return

ed.flgs1
	input "\nEdit text for flag #" i$:if i$="" return
	l=val(i$)
	if (l<0) | (l>34) print "\n"pr$"Invalid flag number":goto ed.flgs1
	disk lock:open #1,"system/sys.data2":position #1,32,l:input #1,a$
ed.flgs2
	print "\nOld Text: "a$
	input @3 "New Text: "i$
	if len(i$)>31 print "\n"pr$"Entry too long.. Try again..':goto ed.flgs2
	if i$<>"" goto ed.flgs3
	print pr$"\nClear this flag?";:yn=1:gosub getyn:if i$="N" return
	i$=""
ed.flgs3
	if len(i$)<31:i$=i$+"\n"
	position #1,32,l:print #1,i$:close:disk unlock:goto ed.flgs1


;	check tree file for valid mail ID

name.chk
	a$=d3$:rtrim$(a$):disk lock:open #1,"system/sys.mailnames":t=nu:b=0:f=0
name1
	l=t-((t-b)/2):position #1,16,l:input #1,i$:upper$(i$)
	print "t="t":l="l":b="b":i$="i$":d3$="d3$	/* REMOVE THIS LINE WHEN DONE */
	rtrim$(i$):if a$=i$:f=1:input #1,x:close #1:return
	if a$<i$:t=l-1:else b=l
	if b<t goto name1
	close #1:disk unlock:return

;	get time remaining before logoff

time
	x=(clock-clock online)/60:y=clock:x$=right$("00"+str$(x),3)
	if clock online>clock:x$="!!!"
	if x=0:x$="---"
	if ~y:x$="***"
	if exec:x$=":::"
	return

data.read							/* read current info from the data file */
	disk lock:open #1,"system/sys.data"
	input #1,c1,ct,ct$,wm$
	input #1,nu,mn,tm,nn|lu$
	close:disk unlock:return

data.write							/* write current into to the data file */
	disk lock:open #1,"system/sys.data"
	print #1,c1,ct,ct$,wm$
	print #1,nu,mn,tm,nn"\n"lu$
	close:disk unlock:return

;	read a users info into temp areas

rd.user
	disk lock:open #1,"system/sys.users"
	position #1,192,a
	input #1,d3$|d1$|d2$|d4$,d5$
	position #1,192,a,132
	read #1,ram,60
	close #1:disk unlock
	return

;	write a users stats back to disk (kill mail if user purged)

wr.user
	disk lock:open #1,"system/sys.users"
	position #1,192,a:x$=d3$
	if d1$="":d2$="":d3$=""
	print #1,d3$"\n"d1$"\n"d2$"\n"d4$","d5$
	position #1,192,a,132
	write #1,ram,60:close #1:disk unlock
	if d1$="":f$="email/"+x$:delete f$
	return

;	show a file w/ page pause (if active)

show.file
	if ~exist(f$) return
	setint(1):print "\n"s$"\n":disk lock:open #1,f$
showfl2
	copy (20) #1
	if (eof(1) | key end) setint(""):close #1:return
	if ~flag(35) goto showfl2
	print "Press ["inverse$"RETURN"normal$"] ";:get i$
	print chr$(8,16);chr$(0x20,16);chr$(8,16);
	if i$=" " setint(""):close #1:disk unlock:return
	setint(1):goto showfl2

;	routine to handle on error

error
	print "\n[System]...One moment please, returning you to the Main Level."
	disk lock:close:clear gosub:create "system/sys.errors"
	open #1,"system/sys.errors":append #1
	print #1,"Error #"err" occured at "time$" on "date$" in system.seg"
	close:disk unlock:chain "program/main.seg","fromsys"
