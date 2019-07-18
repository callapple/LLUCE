; *********************
;      LLUCE v1.0
;    Copyright 1989
; L&L Productions, Inc.
; *********************

; email segment rev c - 5/12/90
; Original code written by Andy Nicholas

	public mailread
	public email

	on nocar goto link.term		/* setup loss of carrier vector */
;	on error goto error			/* setup error vector */
	gosub browse				/* show any possible mail first off */

email				/* get a command from the user and handle it for email */
	gosub time:print "\n[("x$")] E-Mail Level [?=Help] :";
email1
	get i$
email2
	push email
	if i$="Q" print "Quit to Main Level":pop:goto link.main
	if i$="?" print "Menu":goto menu
	if i$="H" print "Help":ns=2:l$="HELP":goto dispatch
	if i$="D" print "Delete Mail":goto delete
	if i$="R" print "Read Mail":goto read
	if i$="S" print "Send Mail":goto send
	if i$="B" print "Browse Mail":goto browse
	if i$="T" print "Terminate":goto terminate
	if i$="D" print "Delete Mail":goto delete
	if i$="X" print "Download all Mail":a=0:goto download
	if i$="\n" | i$=" " pop:goto email1
	if ~exec goto email3
	if i$="F" print "Read Feedback":mb$="email/feedback":goto read1
	if i$="L" print "Browse Feedback":mb$="email/feedback":goto browse1
email3
	a1++:print "\n\n"pr$"\""i$"\" is ~a valid command":if a1<3 return

menu									/* show menu of valid commands */
	if width<79:f$="system/mnu.email40":else f$="system/mnu.email80"
menu1
	a1=0:if ~exist(f$) goto email
	open #1,f$:input #1,z$:setint(" "):addint(z$)
	cls:copy #1:if key flag goto menukey
	a=key:close:setint(""):goto email

menukey							/* handle a ketpress during menu display */
	close:setint(""):a=key:i$=chr$(a):upper$(i$)
	if i$=" " goto email
	print "\n["x$"][E-Mail Level] Option (?=Help):"
	goto email2

dispatch							/* link to utility segment for help */
	y$="program/email.seg":z$="email"
	chain "program/util.seg"

terminate					/* does the user want to terminate off the system */
	print "\nAre You Sure ["inverse$"(Yes)"normal$",No] :";
	get i$:if i$="N" print "No":return
	print "Yes"
link.term					/* link back to main segment on loss of carrier */
	chain "program/main.seg","term1"
link.main					/* link back to the main.seg */
	chain "program/main.seg","otherseg"

send						/* send mail to a user */
	if ~flag(1) print "\n"pr$"Only validated users may send mail":return
	input @2 "\nTo whom: [Mail ID or Name] -> "i$:if i$="" return
	if (instr("!",i$) | instr("@",i$)) goto netsend
	gosub name.chk:if ~f print "\nSorry, No such user.":return
	if (a<1) | (a>nu) print "\nSorry, No such user":return
	move ram,60 to ram(1):open #1,"system/sys.users"
	position #1,192,a:input #1,a$|b$|c$
	position #1,192,a,132:read #1,ram,60
	close:rtrim$(a$)
	if a$="" move ram(1),60 to ram:print "\nSorry, No such user":return
	print "\nSend to "a$" ("b$")\nLast on - "when$;
	print "? ["inverse$"(Yes)"normal$"/No]: ";
send4
	get i$:move ram(1),60 to ram:if i$="N" print "No":return
	print "Yes"
	input @3 "\nSubject -> "sb$:if sb$="":sb$="None"
	gosub editor:if ~edit size goto abort
send5
	print "\nRegistered Mail? [Yes/"inverse$"(No)"normal$"]: ";
	get i$:if i$="Y" print "Yes":else print "No"
	rg=(i$="Y"):sb$=left$(sb$,25)
	if rg:st$="Registered Mail":else st$="Awaiting Reply"
	print:f$=a$:gosub chkbox:print "Sending "edit size" bytes...";
	ready mb$:if msg(0)=128 kill #msg(1):crunch
	a=msg(0)+1:a$=id$:rtrim$(a$)
	print #msg(a),date$" "time$"\n"a$" ("a1$")",un"\n"st$"\n"sb$"\n"rg
	copy #9,#7:msg(a)=a:flush:ready "":print "Message Sent"
	return

netsend								/* parse and handle possible net-mail */
	print "\nNetwork Mail is still being implimented.":return

read							/* read mail for the user currently logged in */
	mb$="email/"+id$:rtrim$(mb$):rs=0
read1
	if ~exist(mb$) print "\nNo letters waiting":return
	ready mb$:x=0
read2
	if rs gosub register
	a=0:push read2:x++:if x>msg(0) pop:ready "":goto delete
read3
	input #msg(x),dt$|fr$,un$|st$|sb$|rs
	print #a,"\n"md$
	print #a,"  From: "fr$
	print #a,"  Date: "dt$
	print #a,"Status: "st$
	print #a,"  Subj: "sb$"\n"
	setint(2):copy #7,#a:setint(""):print #a,md$:if key next return
read4
	print "\n[A]uto reply, "inverse$"[N]"normal$"ext, [R]e-read, [D]ownload, ";
	print "[K]ill, [Q]uit: ";:get i$
	if i$="Q" print "Quit":ready "":pop:return
	if i$="R" print "Re-read":a=0:goto read3
	if i$="F" print "Forward":goto forward
	if i$="A" print "Auto-Reply":goto reply
	if i$="K" print "Kill":goto kill
	if i$="X" print "Download Message":a=1:gosub download:goto read4
	if i$="P" & exec print "Print":a=6:goto read3
	print "Next":return

mailread		/* enter from logon seg if they want to read mail right away */
	gosub browse:print "\nPress a key to continue...";:get i$
	gosub read:chain "program/main.seg"

reply										/* reply to someone message */
	if (instr("!",fr$) | instr("@",fr$)) goto netsend
	z$=mb$:if left$(sb$,4)<>"Re: " sb$="Re: "+sb$
	f$=left$(fr$,(instr("(",fr$)-1)):rtrim$(f$)
	gosub chkbox:gosub editor:if ~edit size gosub abort:mb$=z$:goto reply1
	gosub send5:mb$=z$
reply1
	ready mb$:return

forward									/* forward a message to someone else */
	input @2 "\nForward to [Mail ID or Name] -> "i$:if i$="" goto read4
	if (instr("!",i$) | instr("@",i$)) goto netsend
	gosub name.chk:if ~f print "\nSorry, No such user.":goto read4
	if (a<1) | (a>nu) print "\nSorry, No such user":goto read4
	move ram,60 to ram(1):open #1,"system/sys.users"
	position #1,192,a:input #1,a$|b$|c$
	position #1,192,a,132:read #1,ram,60
	close:rtrim$(a$)
	if a$="" move ram(1),60 to ram:print "\nSorry, No such user"
	print "\nSend to "a$" ("b$")\nLast on - "when$;
	print "? ["inverse$"(Yes)"normal$"/No]: ";
	get i$:move ram(1),60 to ram:if i$="N" print "No":goto read4
	print "Yes"
forward4
	print "\nRegistered Mail? [Yes/"inverse$"(No)"normal$"]: ";
	get i$:if i$="Y" print "Yes":else print "No"
	rg=(i$="Y"):sb$=left$(sb$,25)
	f$=a$:input #msg(x),dt$|fr$,un$|st$|sb$|rs
	edit clear:print #9,"  From: "fr$
	print #9,"  Date: "dt$
	print #9,"Status: "st$
	print #9,"  Subj: "sb$"\n"
	copy #7,#9:z$=mb$
	st$="Forwarded":gosub chkbox:ready mb$
	if msg(0)=128 kill #msg(1):crunch
	a=msg(0)+1:a$=id$:rtrim$(a$)
	print #msg(a),date$" "time$"\n"a$" ("a1$")",un"\n"st$"\n"sb$"\n"rg
	copy #9,#7:msg(a)=a:flush:mb$=z$:ready mb$
	print "\nMessage Forwarded"
	return

kill								/* kill a message from someone mail file */
	if msg(0)=1 ready "":kill mb$:pop:return
	kill #msg(x):crunch:flush
	if x>msg(0) pop:ready "":return
	goto read3

register									/* Send registered mail receipt */
	edit clear:input #msg(x),dt$|fr$,un$|st$|sb$|rs	/* Update message to show */
	copy #7,#9:rs=0:st$="Receipt Sent"			/* Receipt having been sent */
	z=msg(x):kill #msg(x)
	print #msg(x),dt$"\n"fr$,un$"\n"st$"\n"sb$"\n"rs
	copy #9,#7:msg(x)=z:flush
	z$=mb$:f$=left$(fr$,(instr("(",fr$)-1))
	rtrim$(f$):a$=id$:rtrim$(a$)
	gosub chkbox:ready mb$
	st$="Reciept Notice":if left$(sb$,4)<>"Re: " sb$="Re: "+sb$
	rg=0:if msg(0)=128 kill #msg(1):crunch
	edit clear:print #9,"This letter is to let you know that "a1$
	print #9,"read your letter on "date$" at "time$"
	a=msg(0)+1:a$=id$:rtrim$(a$)
	print #msg(a),date$" "time$"\n"a$" ("a1$")",un"\n"st$"\n"sb$"\n"rg
	copy #9,#7:msg(a)=a:flush:mb$=z$:ready mb$
	print "\nReciept Sent"
regst1
	return

delete				/* find out if the user wants to delete there mailbox */
	print "\nDelete mailbox? [Yes/"inverse$"(No)"normal$"]: ";
	get i$:if i$="Y" print "Yes":else print "No":return
delete1
	ready "":close:kill mb$
	print "\nYour Mailbox has been deleted"
	return

browse					/* show the user a quick summary of any waiting mail */
	mb$="email/"+id$:rtrim$(mb$)
browse1
	if ~exist(mb$) print "\nNo letters waiting":return
	ready mb$:x=0:setint(1):print "\n"s$
	print "\nFrom                           Date     Time        R Subject"
	print chr$(0x2D,79)
browse2
	x++:if x>msg(0) ready "":setint(""):return
	input #msg(x),dt$|fr$,un$|st$|sb$|rg
	print left$(fr$+chr$(0x20,30),30)" ";
	print left$(dt$+chr$(0x20,20),20)" ";
	if rg print "Y ";:else print "N ";
	print left$(sb$,24):if key end ready "":setint(""):return
	goto browse2

download /* download a message xmodem */
	if ~exist(mb$) print "\nNo letters waiting":return
	if a=0: print "\nDownload all waiting mail? [Yes/"inverse$"(No)"normal$"]: ";
	if a=1: print "\nDownload this message? [Yes/"inverse$"(No)"normal$"]: ";
	get i$:if i$="Y" print "Yes":else print "No":goto down2
	print "\nWait, Creating File...";
	i$="email/mail.temp":kill i$:create i$:open #1,i$
	if a=0 ready mb$:for x=1 to msg(0)
down1
	input #msg(x),dt$|fr$,un$|st$|sb$|rg
	print #1,"  From: "fr$
	print #1,"  Date: "dt$
	print #1,"Status: "st$
	print #1,"  Subj: "sb$"\n"
	copy #7,#1:if a=0 next:ready ""
	print "done":si=size(1):close:if si=(-1):si=1
	print "\nSending "(si*2)+1" Xmodem blocks..."
	print "\nStart your Xmodem receive now..."
;	use "protocol.down",300,0,i$
	if peek(10)=255 print "\nError in transfer...":goto down2
	a=peek(10)
	if a=0:i$="Standard Xmdm"
	if a=1:i$="ProDOS Xmodem"
	if a=2:i$="CRC-16 Xmodem"
	if a=3:i$="ProDOS CRC-16"
	if a=4:i$="Standard Ymdm"
	if a=5:i$="ProDOS/Ymodem"
	print "\nSuccessful transfer via "i$"..."
down2
	return

; *** Sub - Routines ***

name.chk							/* check tree file for valid mail ID */
	a$=i$:rtrim$(a$):open #1,"system/sys.mailnames":t=nu:b=0:f=0
name1
	l=t-((t-b)/2):position #1,16,l:input #1,i$:upper$(i$)
	rtrim$(i$):if a$=i$:f=1:input #1,a:close #1:return
	if a$<i$:t=l-1:else b=l
	if b<t goto name1
	close #1:open #1,"system/sys.fullnames":t=nu:b=0:f=0
name2
	l=t-((t-b)/2):position #1,32,l:input #1,i$:upper$(i$)
	rtrim$(i$):if a$=i$:f=1:input #1,a:close #1:return
	if a$<i$:t=l-1:else b=l
	if b<t goto name2
	close #1:return

chkbox						/* check mailbox status and create if not present */
	ready "":mb$="email/"+f$
	if ~exist(mb$) print "Wait, Making Mailbox...";:create mb$,msg,128
	return

abort						/* kill off the message file if not mail was sent */
	ready mb$:if ~msg(0) ready "":kill mb$
	return

editor
	print cls"[ Enter/Edit Message Now : 4k or 4096 Bytes Maximum ]"
	print "[ Legal Commands : .A = Abort  .H = Help  .S = Save ]"
edit2
	cl=clock:clock=0:edit clear:edit:clock=cl:return

time
	x=(clock-clock online)/60:y=clock		/* Get minutes online & time limit */
	x$=right$("00"+str$(x),2 )
	if clock online>clock:x$="!!"
	if b=0:x$="--"
	if ~y:x$="**"
	if exec:x$="::"
	return

showfile
	if ~exist(f$) return
	setint(1):print "\n"s$"\n":open #1,f$
showfl2
	copy (20) #1
	if eof(1) | key end setint(""):close #1:return
	if ~flag(35) goto showfl2
	print "Press "inverse$"[RETURN]"normal$": ";:get i$
	print chr$(8,17);chr$(0x20,17);chr$(8,17);
	if i$=" " setint(""):close #1:return
	setint(1):goto showfl2

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


error				/* handle any possible errors that occur and report them */
	print "\n"pr$"One moment please, returning you to the Main Level."
	clear gosub:close:disk lock:create "system/sys.errors"
	open #1,"system/sys.errors":append #1
	print #1,"Error #"err" occured at "time$" on "fmtdate$" in mail.seg"
	close:disk unlock:chain "a:main.seg","fromsys"
