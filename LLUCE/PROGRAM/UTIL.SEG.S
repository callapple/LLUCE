; *********************
;      LLUCE v1.0
;    Copyright 1990
; L&L Productions, Inc.
; *********************

; utility segment rev b - 2/1/90

	public dispatch

	on nocar goto link.term
	on error goto error

util
	gosub time:print "\n["x$"][Utility Level] Option (?=Help): ";
util1
	get i$
util2
	clear gosub:push util
	if i$="?" | i$="/" print "Menu":goto menu
	if i$="B" print "Set Backspace Mode":goto backspace
	if i$="C" print "Change Password":goto setpass
	if i$="E" print "Set Terminal Emulation":goto set.term
	if i$="H" print "Help":ns=2:goto help
	if i$="N" print "Set Nulls":goto nulls
	if i$="P" print "Set Page Pause Mode":goto paging
	if i$="S" print "Show Your Status":goto showstat
	if i$="T" print "Terminate":goto terminate
	if i$="U" print "View Userlist":goto userlist
	if i$="V" print "Set Video Width":goto video
	if i$="X" print "Exit back to Main Level":pop:goto link.main
	if i$="%" & exec print "System Segment":pop:chain "program/system.seg"
	if val(i$)<33 goto util1 /* mask out possible control characters */

	a1++:print "\n\""i$"\" is not a command":if a1<3 return

; *** sub - routines ***

menu
	a1=0:if ~flag(1) goto menu1
	if width<79:f$="system/mnu.util40":else f$="system/mnu.util80"
menu1
	if ~exist(f$) return
	open #1,f$:input #1,x$:setint(" "):addint(x$)
	cls:copy #1:if key flag goto menukey
	a=key:close:setint(""):goto util

menukey
	close:setint(""):a=key:i$=chr$(a):upper$(i$)
	if i$=" " goto util
	print "\n\n["x$"][Utility Level] Option (?=Help):";
	goto util2

; terminate connection

terminate
	print "\nTerminate From "sn$
	print "\nAre You Sure ["inverse$"(Yes)"normal$",No] :";
	get i$:if i$="N" print "No":return
	print "Yes":pop
link.term
	chain "program/main.seg","term1"
link.main
	chain "program/main.seg","otherseg"

; control program flow from other segments

dispatch
	print l$:get i$
	push dreturn
	if l$="HELP" goto help /* handle the request for help on a command */
	if l$="USERLIST" goto userlist /* handle request for a user list */
	if l$="SHOWSTAT" goto showstat /* handle request for show stats */
	if l$="BOARDS" goto ed.brds /* handle request for editting board info */
	if l$="DISPLAY" goto display /* handle request for system configuration */

dreturn
	chain y$,z$ /* return to calling segment at return point */

; show user's status

showstat
	print cls"Your Status on "sn$"\n"
	print "Your Name ..... "a1$
	print "Mail ID ....... "mi$
	print "Affillation ... "a3$
	print "From .......... "a4$", "a5$
	print "Phone Number .. "ph$
	print "User Number ... "un
	print "Last Date On .. "lc$
	print "Access Level .. ";
	for x=1 to 33:print flag(x);:next
	print "\n\nLast Caller ... "lu$
	print "\nCalls Total ... "tc
	print "Caller Number . "cn$
	print "Today's Calls . "ct
	print "nTotal Posts ... "bp
	print "Downloads ..... "dl
	print "Uploads ....... "ul
	print "Blocks Up ..... "ul$
	print "Blocks Down ... "dl$
	print "\nLogon time .... "cm$
	print "Actual time ... "date$" "time$:a=clock online
	print "Connected ..... "a/60" mins, "a % 60" secs"
	b=clock:if b print "Time left ..... "(b-a)/60" mins"
	print "\nOptions Available\n"
	open #1,"system/sys.data2":z=0:for x=0 to 34:a$=""
	if flag(x) position #1,32,x:input #1,a$
	if a$<>"" setint(1):print a$:z=1
	if key end:x=34
	next:close:if ~z print "Limited System Access"
	setint(""):return

; show list of system users

userlist
	input @2 "\nMatch letters (<CR>=All,?) -> "i$
	if i$="?":f$="system/hlp.user":gosub showfile:goto userlist
	print "\n"s$:open #1,"system/sys.names"
	open #2,"system/sys.users":x=1
	print "\nMail ID     User's Name           Last  On    From                ";
	if exec print " Pass    ":else print
	print "----------  --------------------  --------    --------------------";
	if exec print " --------":else print
usrlst2
	position #1,16,x:input #1,a$|a
	position #2,192,a:input #2,a$|b$|c$
	rtrim$(a$):setint(1):if a$="" goto usrlst4
	if instr(i$,a$) goto usrlst3
	if ~instr(i$,b$) goto usrlst4
usrlst3
	input #2,d$,e$:position #2,192,a,132
	move ram,60 to ram(1):on nocar goto usrlst5
	read #2,ram(0),60
	setint(1)
	print left$(a$+"..........",10)"  ";
	print left$(b$+"....................",20)"  ";
	print when$"    "left$(d$+", "+e$+"                      ",20);
	if exec print pa$:else print
	move ram(1),60 to ram:on nocar goto link.term
usrlst4
	if (not key end) & (x<nu):x++:goto usrlst2
	setint(""):close:return
usrlst5
	move ram(1),60 to ram:goto link.term

; set display characteristics

display
	push display:gosub get.term
	print "\nDisplay Characteristics\n"
	print "Video width now = "width+1
	print "Back-space mode = ";
	a=nibble(0)/4:if a=1 print "non-";
	if a=0 print "Unknown":else print "destruct"
	print "Nulls sent @ LF = "nulls
	print "Page pause mode = ";
	if flag(35) print "ON":else print "OFF"
	print "Terminal Emul.  = "i$
	print "Show phone numb = ";
	if mid$(ph$,4,1)=" " print "YES":else print "NO"
display2
	input @0 "\nSet: [V, B, N, P, T, S, or Q=Quit] ?" i$
	if i$="Q" pop:return
	if i$="B" goto backspace
	if i$="S" goto phone
	if i$="N" goto nulls
	if i$="T" goto set.term
	if i$="P" goto paging
	if i$<>"V" goto display2

video
	print "\nEnter new width ("width(1)","width(2)","width(3)","width(4);
	input @2 ", <cr>=No change) -> "i$:if i$="" return
	a=val(i$):for x=1 to 4
	if a=width(x):nibble(0)=nibble(0)/4*4+(x-1):width=a-1
	next:return

backspace
	print "\n123456"chr$(8,3):a=0
	input @2 "\nHow many numbers do you see (3, 6 or <CR>=No Change):" i$
	if i$="" return
	if i$="6":a=1
	if i$="3":a=2
	nibble(0)=(nibble(0) % 4)+(a*4)
	mode=a:return

nulls
	input @2 "\nSet new value to (0-127 or <CR>=No Change):" i$
	if i$<>"":nulls=val(i$)
	return

phone
	print "Show phone number to other users?";
	print " ["inverse$"(Yes)"normal$",No] :";:get i$
	if i$="N" print "No":ph$=left$(ph$,3)+"-"+mid$(ph$,5):return
	print "Yes":ph$=left$(ph$,3)+" "+mid$(ph$,5):return

paging
	if flag(35) print "ON":else print "OFF"
	input @2 "\nSet paging mode (ON, OFF or <CR>=No Change):" i$
	if i$="ON":flag(35)=1
	if i$="OFF":flag(35)=0
	return

; get a new password

setpass
	input @2 "\nEnter your current password -> "; i$
	if i$="" return
	i$=left$(i$+"    ",8):if i$<>pa$ print "\nIncorrect!":return
	print "\nYour password may be 4-8 chars long"
	echo="X":input @2 "\nEnter your new password -> "; i$
	if i$="":echo="":return
	input @2 "Please type it in again -> " a$
	echo="":a=len(i$)
	if a$<>i$ print "\nPasswords do not match":return
	if (a<4) | (a>8) print "\nPassword must be 4-8 chars":return
	pa$=left$(i$+"    ",8):print "\nNew Password Accepted":return

set.term
	print cls"Set Terminal Emulation\n"
	return

termemul
	inverse$="":normal$="":clrscn$="":i$="None"
	if ~online:i$="Local":return
	y=byte(14) if (y<1) | (y>9):return
	if y=1:i$="Datamedia 1500":\
	   inverse$="\x0F":normal$="\x0E":clrscn$="\x0C"
	if y=2:i$="Dec VT-52":\
	   inverse$="\x19":normal$="\x1F":clrscn$="\x0C"
	if y=3:i$="IBM 3101":\
	   inverse$="\x1B19":normal$="\x1B1F":clrscn$="\x1BK"
	if y=4:i$="Hazeltine 1500":\
	   inverse$="~\x19":normal$="~\x1F":clrscn$="~\x1A"
	if y=5:i$="Heathkit H-19":\
	   inverse$="\x1Bp":normal$="\x1Bq":clrscn$="\x1B\E"
	if y=6:i$="Soroc":\
	   inverse$="\x1B)":normal$="\x1B(":clrscn$="\x1B*"
	if y=7:i$="Adm3a":\
	   inverse$="\x19":normal$="\x1F":clrscn$="\x1A"
	if y=8:i$="Televideo 912":\
	   inverse$="\x1Bl":normal$="\x1Bm":clrscn$="\x1B1A"
	if y=9:i$="ViewPoint":\
	   inverse$="\x0E":normal$="\x0F:clrscn$="\x0C"
	return

; show help for a certain command

help
	cr$="\n":es$="\x1B"
	disk lock:if ~flag(1):f$="system/mnu.new":else f$="system/mnu.val.40"
	if exist(f$) open #1,f$:input #1,a$:close
	a$=a$+cr$+es$:ready "system/sys.help"
help2
	setint(""):print "\nHelp on what command?\n"
	print inverse$"[RETURN]"normal$" for all, "inverse$"[ESC]"normal$" to quit :";
help3
	get i$:if ~instr(i$,a$) goto help3
	if i$=es$ print "Quit":ready "":disk unlock:return
	push help2:if i$<>cr$:l=asc(i$):s=1:print i$:goto showhelp
	s=0:print "All\n\n"s$"\n"
	for l=33 to 95                            /* loop for all possible keys */
	gosub showhelp:if key flag:l=95             /* if any interrupt key, quit */
	next
	ready "":disk unlock:return

; show the entry of the help file for the command asked

showhelp
	x=(l-32)+(ns*64)                         /* convert key for segment */
	if msg(x)=0 goto showhlp2                /* if no message, exit */
	input #msg(x),y,i$                       /* bypass flag and header */
	if exec goto showhlp1                    /* if exec, show all help messages */
	if left$(i$,1)="*" & (len(i$)>1) goto showhlp2
showhlp1
	if left$(i$,1)="*" & (len(i$)>1):i$=mid$(i$,2)
	setint(1)
	print "\n"inverse$;i$;normal$"\n"
	copy #7 /* show the message */
	return

showhlp2
	if s print "\nNo help available on that command" /* show err if not loop */
	return

; edit boards

ed.brds
	disk lock:open #1,"system/sys.data2"
	mark(1)=1120:input #1,ab:close:disk unlock
ed.brd1
	gosub time:print "\n["x$"][Board Maintenance] ";
	input "Option (?=Help):" i$:push ed.brd1

	if i$="P" goto brd.prg
	if i$="A" goto brd.add
	if i$="D" goto brd.del
	if i$="E" goto brd.edt
	if i$="S" goto brd.swp
	if i$="L" goto brd.lst
	if i$="C" goto brd.cre
	if i$="X" pop:return
	if i$<>"?" print "\nSorry, \""i$"\" is not a valid command. (?=Help)":return

	setint(1):print cls"\n"s$'\n
::::::::::::::::::::::::::::::::::::::::::::::::::::::
:      Board Maintenance Section Vaild Commands      :
::::::::::::::::::::::::::::::::::::::::::::::::::::::
: A - Add a Subboard     : C - Create a Storage File :
: D - Delete a Subboard  : E - Edit a Subboard       :
: L - List all Subboards : P - Purge all Subboards   :
: S - Swap two Subboards : X - Exit to System Level  :
::::::::::::::::::::::::::::::::::::::::::::::::::::::':return

brd.lst
	print "\n"pr$"Send list to the printer? (Y/"inverse$"[N]"normal$"): ";
	get i$:if i$="Y" s=6:print "Yes":else s=0:print "No"
	print #s,"\n###  Board Name               File Name"
	print #s,"---------------------------------------"
	disk lock:open #1,"sys.data2":for a=1 to ab:position #1,128,a+8
	input #1,bn$|bf$:w1$=right$("00"+str$(a),3)
	if instr(left$(bn$,1),"^#$%"):bn$=mid$(bn$,2)
	bn$=left$(bn$+chr$(0x20,23),23):print #s,w1$"  " bn$"  "bf$:next
	close:disk unlock:print "\nPress [Return]";:get i$:return

brd.prg
	print "\n"pr$"This operation will erase your board configuration."
	print chr$(0x20,len(pr$)-2)"Do you really wish to continue? ";
	print "[Yes,"inverse$"(No)"normal$"] :";
	get i$:if i$<>"Y" print "No":return
	print "Yes":disk lock:open #1,"sys.data2":mark(1)=1120
	print #1,0:ab=0:close:disk unlock:goto brd.add1

brd.add
	print "\n"pr$"Do you wish to add another board to your system? (";
	print inverse$"[Y]"normal$"/N): ";:get i$
	if i$="N" print "No":return
	print "Yes"
brd.add1
	ab++:bn$=New Board":bf$="bulletins/b"+str$(ab):b3=0:b4=0:bs=0:mb=128
	kl=0:kb=0:z=1:a=ab:goto brd.edt2

brd.del
	print "\n"pr$"Delete Board (#1-#"ab",Q=quit):";:input i$:a=val(i$)
	if i$="Q" return
	if (a>ab) | (a<1) goto brd.del
	disk lock:open #1,"system/sys.data2":for x=a to ab
	position #1,128,x+9:input #1,bn$|bf$|b3,b4|bs,bs$|mb,kl,kb
	position #1,128,x+8:print #1,bn$"\n"bf$"\n"b3,b4"\n"bs,bs$"\n"mb,kl,kb
	next:ab--:mark(1)=1120:print #1,ab:close:disk unlock:return

brd.swp
	print "\n"pr$"Enter the numbers of the two bulletin"
	print chr$(0x20,len(pr$)-2)"boards that you wish to swap."
brd.swp1
	print  "\n"pr$"Swap Board (1-"ab",Q=Quit): ";:input i$:a1=val(i$)
	if i$="Q" return
	if (a1>ab) | (a1<1) goto brd.swp1
brd.swp2
	print "\n"pr$"With Board (1-"ab",Q=quit): ";:input i$:a2=val(i$)
	if i$="Q" return
	if (a2>ab) | (a2<1) goto brd.swp2
	disk lock:open #1,"system/sys.data2"
	position #1,128,a1+8:input #1,bn$|bf$|b3,b4|bs,bs$|mb,kl,kb
	position #1,128,a2+8:input #1,w1$|w2$|w3,w4|ws,ws$|wb,wl,kw
	position #1,128,a1+8:print #1,w1$"\n"w2$"\n"w3,w4"\n"ws,ws$"\n"wb,wl,kw
	position #1,128,a2+8:print #1,bn$"\n"bf$"\n"b3,b4"\n"bs,bs$"\n"mb,kl,kb
	close:disk unlock:return

brd.edt
	print "\nEnter the number of the bulletin board that you want to edit."
brd.edt1
	print "\n"pr$"Edit Board (1-"ab",Q=quit): ";:input i$:a=val(i$)
	if i$="Q" return
	if (a>ab) | (a<1) goto brd.edt1
	gosub brd.read
brd.edt2
	cls:if bs=0:bs$=""
	if bs$="" & (bs=0):w2$="[ No Aux Sysop ]"
	if bs$="" & (bs>0):w2$="[ Use Real Name ]"
	if bs$<>"" & (bs>0):w2$=bs$
	print "\n 1) Name: "bn$"\n 2) File: "bf$"\n\n 3) Access: "b3"  4) Write: "b4
	print "\n 5) Aux Sysop Numb: "bs"\n 6) Aux Sysop Name: "w2$
	print "\n 7) Max  # of  Messages: "mb"\n 8) Auto-kill Threshold: "kl
	print " 9) Bulletin # to  kill: "kb
	print "\n10) Abort without Saving\n11> Save changes and Quit"

	push brd.edt2:input "\nEdit #1 - #11:" i$:x=val(i$):i$=""
	if x=1 input @3 "\nBoard Name: " i$:if i$<>"":bn$=i$
	if x=2 input @3 "\nFile Name: " i$:if i$<>"":bf$=i$
	if x=3 input @3 "\nAccess Flag: " i$:if i$<>"":b3=val(i$)
	if x=4 input @3 "\nWrite Flag: " i$:if i$<>"":b4=val(i$)
	if x=5 input @3 "\nSubop #:" i$:if i$<>"":bs=val(i$)
	if x=6 input @3 "\nSubop Name:" i$:if i$<>"":bs$=i$
	if x=7 input @3 "\nMax # Messages:" i$:if i$<>"":mb=val(i$)
	if x=8 input @3 "\nKill Threshold:" i$:if i$<>"":kl=val(i$)
	if x=9 input @3 "\nMessage to kill:" i$:if i$<>"":kb=val(i$)
	if (x=10) & (z=1) input @2 "\nAbort: Are you sure? (Y/[N]): " i$
	if (x=10) & (z=1) & (i$="Y"):ab--:pop:return
	if x=10 input @2 "\nAbort: Are you sure? (Y/[N]): "i$:if i$="Y" pop
	if x=11 input @2 "\nSave: Are you sure? ([Y]/N): "i$:if i$="":i$="Y"
	if (x=11) & i$="Y" gosub brd.write:z=0:pop
	return

brd.read
	disk lock:open #1,"system/sys.data2":position #1,128,a+8
	input #1,bn$|bf$|b3,b4|bs,bs$|mb,kl,kb:close:disk unlock
	return

brd.write
	disk lock:open #1,"system/sys.data2":position #1,128,a+8
	print #1,bn$"\n"bf$"\n"b3,b4"\n"bs,bs$"\n"mb,kl,kb
	mark(1)=1120:print #1,ab:close:disk unlock
	if z=1 goto brd.cre2
	return

brd.cre
	print "\n"pr$"Enter the number of the board you"
	print chr$(0x20,len(pr$)-2)"wish to create a storage file for."
brd.cre1
	print "\n"pr$"Create storage file for board (#1 - #"ab",Q=quit):";
	input i$:a=val(i$):if i$="Q" return
	if (a>ab) | (a<1) goto brd.cre1
	gosub brd.read
brd.cre2
	print "\nBoard Specifications:"
	print "\nName: "bn$"\nFile: "bf$
	input @2 "\nIs the above Correct? ([Y]/N)?"i$:if i$="N" return
	w1=0:w1=instr("/",bf$):w1$=mid$(bf$,1,w1):if w1$="" goto brd.cre4
	print "\nMake sure "w1$" is on-line."
	print "\nAre you ready? ["inverse$"(Yes)"normal$",No] :";:get i$
	if i$="N" print "No":return
	print "Yes":disk lock: open #1,bf$:x=mark(1):close:disk unlock
	if ~x goto brd.cre5
brd.cre3
	print "\nCreating Storage File...";
	disk lock:create bf$,msg,128:disk unlock:print "Done.":return

brd.cre4
	print "\n"pr$"Error: This board does not have a drive"
	print chr$(0x20,len(pr$)-2)"specifier in its filename.
	input @3 "\nPress <Return> to continue..." i$:i$="":return
brd.cre5
	print "\n"pr$"There is already a message storage file with this"
	print chr$(0x20,len(pr$)-2)"name. If you preceed, the messages in that file"
	print chr$(0x20,len(pr$)-2)" will be destroyed"
	print "\n"chr$(0x20,len(pr$)-2)"Do you wish to continue? "
	print "(Y/"inverse$"[N]"normal$"): ";:get i$
	if i$="Y" print "Yes":delete bf$:goto brd.cre3
	print "No":return


; calculate time remaining

time
	x=(clock-clock online)/60:y=clock:x$=right$("00"+str$(x),3)
	if clock online>clock:x$="!!!":else if x=0:x$="---"
	if exec:x$=":::":else if ~y:x$="***"
	return

; show text file to screen with page mode

showfile
	if ~exist(f$) return
	setint(1):print "\n"s$"\n":open #1,f$
showfl2
	copy (20) #1
	if (eof(1) | key end) setint(""):close #1:return
	if ~flag(35) goto showfl2
	print "Press "inverse$"[RETURN]"normal$" ";:get i$
	print chr$(8,16);chr$(0x20,16);chr$(8,16);
	if i$=" " setint(""):close #1:return
	setint(1):goto showfl2

get.term
	if ~online:i$="Local":return
	y=byte(14) if (y<1) | (y>9):i$="None":return
	if y=1:i$="Datamedia 1500"
	if y=2:i$="Dec VT-52"
	if y=3:i$="IBM 3101"
	if y=4:i$="Hazeltine 1500"
	if y=5:i$="Heathkit H-19"
	if y=6:i$="Soroc"
	if y=7:i$="Adm3a"
	if y=8:i$="Televideo 912"
	if y=9:i$="ViewPoint"
	return

; routine to handle on error

error
	print "\nOne moment please, returning you to the Main Level."
	clear gosub:close:create "system/sys.errors"
	open #1,"system/sys.errors":append #1
	print #1,"Error #"err" occured at "time$" on "date$" in util.seg"
	close:chain "program/main.seg","fromsys"
