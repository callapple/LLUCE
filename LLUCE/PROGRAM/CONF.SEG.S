; *********************
;      LLUCE v1.0
;    Copyright 1991
; L&L Productions, Inc.
; *********************

; msg segment rev a - 4/5/91

	public quickscan
	public conference
	public return

conference
	on nocar goto link.term
;	on error goto error
	of=flag:ob=byte					/* save old locations of flag and byte */
	set aa$=ram(1),30:set ab$=ram(1)+31,30
	set ac$=ram(1)+61,20:byte=ram(1)+81
	flag=ram(2)	/* allocate 4092 flags for user status (Overlaps into ram(3) */
;	edit on							/* Turn on Profanity Filter */
	prefix:prefix "conferences/":rp$=prefix
	f$="conf.0":if exist(f$) goto conf1
	nc=0:f$="conf.0":create f$:open #1,f$
	print #1,nc						/* Set #number of conferences to zero */
conf.init
	close #1:gosub add.conf:if nc=0 goto link.main
conf1
	open #1,"conf.0"
	input #1,nc:if nc=0 goto conf.init
	x=cn:gosub rd.head:close #1
	cc$=aa$:cs$=ab$:si$=ac$:gosub start

link.main								/* reset prefix and return */
	prefix:chain "program/main.seg","otherseg"

terminate
	print "\nTerminate Connection"
	input @2 "\nAre you sure? ([Y]/N):"i$
	if left$(i$,1)="N" return
link.term								/* reset prefix and return */
	prefix:chain "program/main.seg","term1"

;	Ready message file and check status

start
	gosub time:print "\nCurrent Conference:"cc$
	print "[("x$")] Conference Level [?=Menu] Function :";
start1
	get i$
start2
	push start
	if i$="?" | i$="/" print "Menu":goto start4
	if i$="L" print "List Conferences Available":goto list.conf
	if i$="J" print "Jump to a Conference":goto join.conf
	if i$="D" print "Drop Conference":goto quit.conf
	if i$="Q" print "Quit to Mail Level":pop:goto link.main
	if i$="T" print "Terminate Connection":goto terminate
	if i$="C" print "Check for New Messages":goto scan.conf
	if i$="M" print "Mail to Conference Sysop":goto mail.sysop
	if i$="X" print "Conference Transfer System":goto exfer.start

	if ~exec goto start3	/* They are not the sysop so ignore the following */
	if i$="A" print "Add a Conference":goto add.conf
	if i$="K" print "Kill a Conference":goto kill.conf
	if i$="E" print "Edit a Conference":goto edit.conf
	if i$="M" print "Reorder Conferences":goto move.conf

start3
	if val(i$)<33 pop:goto start1	/* mask out possible control characters */
	a1++:print "\n\""i$"\" is not a command":if a1<3 return
start4
	a1=0:print '\n Valid commands:
  C - Check for New Messages  D - Drop Conference
  J - Jump to a Conference    L - List Conferences Available
  Q - Quit to Main Level      M - Send Mail to Conference Sysop
  T - Terminate Connection    ? - This Menu';
	if exec print '
  -------------------------------------------------------------
  A - Add a Conference        E - Edit a Conference
  K - Kill a Conference       M - Reorder Conferences';
	print "\n":return


mail.sysop
quit.conf
pick.conf
scan.conf
kill.conf
edit.conf
move.conf
	print "\nCommand structure works"
	return

exfer.start
	print "\nEntering Exfer...to be completed!!"
	return

add.conf
	print "\nWould you like to add a conference to the system? ([Y]/N):";
	get i$:if i$="N":print:return
add1
	input @3 "\nConference Title: "ct$
	input @3 "Conference Sysop: "cs$
	input @3 "Sysop Mail ID   : "sid$
	input "Access Flag     : "aa:byte(1)=aa
	input "Read Flag       : "aa:byte(2)=aa
	input "Write Flag      : "aa:byte(3)=aa
	print "\nThis is what we have:\n"
	print "Conference Title: "ct$
	print "Conference Sysop: "cs$
	print "Sysop Mail ID   : "sid$
	print "Access Flag     : "byte(1)
	print "Read Flag       : "byte(2)
	print "Write Flag      : "byte(3)
	input "\nIs this correct? ([Y]/N):"i$
	if i$="N" goto add.conf

	open #1,f$:input #1,nc
	nc++:position #1,96,nc
	fill ram(1),128,0
	aa$=ct$+chr$(0x20,(30-len(ct$)))
	ab$=cs$+chr$(0x20,(30-len(cs$)))
	ac$=sid$+chr$(0x20,(30-len(sid$)))
	x=nc:gosub wr.head
	mark(1)=0:print #1,nc:close
	return

join.conf
	print "\nWhich Conference do you wish to Jump to? (1-"nc;
	input ", L)ist, Q)uit):"i$
	if i$="L":f$="conf.0":ti$="Conference":gosub list.conf:goto join.conf
	if ~val(i$) return							/* they must want to quit */
	if val(i$)>nc goto join.conf				/* Value out of range */
	open #1,"conf.0":x=val(i$):gosub rd.head:close #1
	goto start.cat

list.conf
	flag=ram(0)+22:open #1,f$
	x$=ti$+" Name"+chr$(0x20,(32-len(ti$)))+ti$+" Sysop"+chr$(0x20,(21-len(ti$)))
	x$=x$+"Sysop ID"
	print x$"\n"chr$(0x2D,79)
	for x=1 to nc
		gosub rd.head
		if flag(aa) print aa$;chr$(0x20,(37-len(aa$)));ab$;chr$(0x20,(27-len(ab$)));ac$
	next x
	flag=ram(2):return

start.cat
	get i$
	return

ld.flags
	open #1,f$
	read #1,ram(2),512
	close #1:return

wr.flags
	open #1,f$
	write #1,ram(2),512
	close #1:return

quickscan
	print "\nThis is the quickscan routine!!"
	return

	gosub idinf
	if bf$="" print "\nThat board is not active.":return
	if ~b1 print "\nYou do not have access to that board.":return
	if i$="Q" gosub qscan
cmd1
	if msg(0) goto cmd2
	print "\nThe "bn$" has no messages..."
	input @2 "\nPost a message? ([Y]/N):"i$
	if left$(i$,1)="N" return
	sb$="":ti$="":gosub post:if ~b2 return
	goto cmd1

cmd2
	gosub time:print "\n"bn$" - #"bb
	print "["x$"]["inverse$"Board Level"normal$"][1-"msg(0)"] ";
	input "Option (?=Help):"i$
cmd2a
	a=val(i$):push cmd2
	if left$(i$,1)="J":i$=mid$(i$,2):goto jmp3
	if left$(i$,1)="F" goto fwd
	if left$(i$,1)="R" goto rvs
	if left$(i$,1)="K" goto kill
	if left$(i$,1)="S" goto scan
	if i$="A" | i$="Q" pop:return
	if i$="M" goto mark
	if i$="N" goto new
	if i$="B" goto browse
	if i$="G" goto qscan
	if i$="H":f$="b:hlp.msg":goto show.file
	if i$="J" goto jump
	if i$="P":ti$="All":sb$="":d=0:goto post
	if i$="L":y=0:goto list
	if i$="T" goto terminate
	if i$=">" & (bb<ab):bb++:pop:goto start
	if i$="<" & (bb>1):bb--:pop:goto start
	if (a>0) & (a<=msg(0)):i$="F"+i$:goto fwd
	if i$="?" | i$="/" goto cmd.menu
	a1++:print "\nSorry, \""i$"\" is not a command. (?=Help)":if a1<3 return

cmd.menu
	a1=0:print "\n"bn$'\n
	Read #, OR: [N]ew   [F#]orward [S#]can [B]rowse [M]arked [L]ist
             [R#]vse [G]lobal   [J#]ump [P]ost   [K#]ill  [H]elp
             [Q]uit  [>] Next board     [<] Previous board\n':return

;	terminate connection

terminate
	print "\nTerminate Connection"
	input @2 "\nAre you sure? ([Y]/N):"i$
	if left$(i$,1)="N" return
	prefix:chain "program/main.seg","term1"

; post a bulletin

post
	if ~b2 print "\nYou do not have access to that board.":return
	edit clear:if msg(0)=mb+128 print "\nSorry, no room on this board.":return
	if msg(0)=msg size print "\nBoard directory full.":return
	if msg free<29 print "\nBoard bit-map full.":return
post2
	print "\nPost Bulletin\n"
	if d open #1,"b:sys.users":position #1,128,d:input #1,d1$,d2$|d3$:close
	if d ti$=d3$+" (#"+str$(d)+")":if d=1 ti$="Sysop"
	if ti$<>"" print "  To ->"ti$" ([Y]/N):";:get i$
	if i$="\n":n=9:gosub backup:print:goto post2a
	if i$="N":n=len(ti$)+10:gosub backup:input @4 ti$:if ti$="" return
	if (ti$<>"") & left$(i$,1)<>"N":n=10:gosub backup:print
	if ti$="" input @4 "  To ->"ti$:if ti$="" return
post2a
	i$="":if sb$<>"" print " Sub ->"sb$" ([Y]/N):";:get i$
	if i$="\n"n=9:gosub backup:print:goto post2b
	if i$="N":n=len(sb$)+10:gosub backup:input @4 a$:if a$="" return
	if (sb$<>"" | a$<>"") & left$(i$,1)<>"N":n=10:gosub backup:print
	if sb$="" input @4 " Sub ->"a$:if a$="" return
	if a$<>"":sb$=a$
post2b
	a$=a3$:if (un=bs) & (bs$<>""):a$=bs$
	a$=a$+" (#"+str$(un)+")"
	if ~exec goto post2c
	i$="":print "From ->"a$" ([Y]/N):";:get i$
	if i$="\n"n=9:gosub backup:print:goto post2c
	if i$="N":n=len(a$)+10:gosub backup:input @3 a$:if a$="" return
	if (a$<>"") & left$(i$,1)<>"N":n=10:gosub backup:print
post2c
	i$="":if flag(36) print "\nAnonymous Posting (Y/[N]):";:get i$:print
	if (flag(36)) & (i$="Y"):flag(37)=1:else flag(37)=0
	input @2 "\nPost: [Y]es, N)o, P)rotocol Upload? "i$
	if i$="N" return
	if i$="P" gosub ptcl.up:else gosub editor
	if ~edit size return
	print "\n"edit size" bytes entered"
	print "Saving Message...wait..";:bp++:disk lock:a=msg(0)+1
	if flag(37) print #msg(a),"*"sb$:else print #msg(a),sb$
	print #6,tn,ti$
	if flag(37) print #6,0,a$:else print #6,un,a$
	if flag(37) print #6,"   Date: "date$"\n"
	if ~flag(37) print #6,"   Date: "date$" at "time$"\n"
	copy #8,#6:msg(a)=mn:mn++:update:tm++
	print ".saved":ti$="":a$="":disk unlock:return

; show new messages

new
	print "\nNew messages"
	if nn>msg(msg(0)) print "\nSorry, no new messages.":return
	x=msg(0):if ~lr:a=1:goto fwd2
new1
	if nn=<msg(x):a=x:x--:if x goto new1
	goto fwd2

; message retrieval - Forward

fwd
	if len(i$)>1:a=val(mid$(i$,2)):goto fwd1
	print "\nMessage Retrieval - Forward"
	input @2 "\nStart where (#, F)irst, <CR>):"i$
	a=val(i$):if i$="F":a=1
fwd1
	if a=0 return
	if a>msg(0):a=msg(0)
fwd2
	print "\n"s$"\n"n$
fwd3
	gosub show:if x return
	if a<msg(0):a++:goto fwd3
	return

;	message retrieval - Reverse

rvs
	if len(i$)>1:a=val(mid$(i$,2)):goto rvs1
	print "\nMessage Retrieval - Reverse"
	input @2 "\nStart where (#, L)ast, <CR>):"i$
	a=val(i$):if i$="L":a=msg(0)
rvs1
	if a=0 return
	if a>msg(0):a=msg(0)
rvs2
	print "\n"s$"\n"n$
rvs3
	gosub show:if x return
	if a>1:a--:goto rvs3
	return

; kill messages

kill
	if len(i$)>1:a=val(mid$(i$,2)):goto kill.1
	print "\nKill a message"
	input @2 "\nKill message (#,<CR>):"a
kill.1
	if (a=0) | (un=0) return
	if a>msg(0) print "\nThat message is out of range.":return
	input #msg(a),a$|x,b$|x,c$
	if exec | (un=bs) goto kill.2
	if x!=un print "\nThats not your message!":return
kill.2
	if flag(37) & (left$(a$,1)="*"):a$=mid$(a$,2)
	print "\n Number :"a" of "msg(0)"\nSubject :"a$
	input @2 "\nKill this message? (Y/[N]):"i$
	if left$(i$,1)!="Y" return
kill.3
	disk lock:tm--:y=msg(msg(0)):delete #msg(a):crunch
	b=msg(0):if b:msg(b)=y:update
	print "\nBulletin #"a" killed..."
	disk unlock:return

; browse message titles

browse
	m$="":a=0:print "\nBrowse message titles"
	print "\nScan for what text? [<CR>=All]"
	input @3 ":"m$:a=1:if m$="":a=0:return
	goto scan.2

; scan messages

scan
	print "\nScan messages"
	if len(i$)>1:a=val(mid$(i$,2):goto scan.1
	input @3 "\nStart at (#,<CR>):"a
scan.1
	m$="":if a=0 return
	if a>msg(0) print "\nThat message is out of range.":return
scan.2
	input @2 "\nAllow message marking? (Y/[N]):"i$
	ms=0:if left$(i$,1)="Y":ms=a
	d=0:x=15:print:z=flag:flag=ram2
scan.3
	a$=" ":if msg(a)>nn:a$="*"
	flag(a-ms)=0:input #msg(a),t$
	if m$ if ~instr(m$,t$) goto scan.4
	if left$(t$,1)="*":t$=mid$(t$,2)
	x--:d++:print a$a". "t$"\n"
	if i$<>"Y" goto scan.4
	print "Mark message? (Y/[N]/Q):";:get a$:print
	if a$="Q" goto scan.5
	flag(a-ms)=(a$="Y")
scan.4
	if a=msg(0) goto scan.5
	a=a+1:if x goto scan.3
	input @2 "\nMore messages? ([Y]/N/C):"a$
	if left$(a$,1)="C":x=msg(0)-a-1:goto scan.3
	if left$(a$,1)!="N" print:x=15:goto scan.3
scan.5
	me=a:flag=z:if ~d print "Sorry, no match":ms=0:return
	if left$(i$,1)!="Y" return

; marked message retrieval

mark
	print "\nRetrieve marked messages":a=ms
	if ~ms print "\nSorry, no marked messages.":return
mark.2
	z=flag:flag=ram2:b=flag(a-ms):flag=z
	x=0:if b gosub show
	if x=0:a++:if a<me goto mark.2
	return

;	jump to another board.

jump
	print "\nJump to another board"
jmp2
	print "\nJump to (1-"ab",?,<CR>):";
	input @2 i$:if i$="" return
jmp3
	a=val(i$)
	if (a>0) & (a<=ab) pop:bb=a:goto start
	if i$<>"?" goto jmp2
	y=1

;	list of available boards.

list
	print cls"\n"s$"\n":open #1,"b:sys.data2"
	for x=1 to ab:position #1,128,x+8
	input #1,a$|b$|a:setint(1)
	if instr(left$(a$,1),"^#$%"):a$=mid$(a$,2)
	b=1:if a:b=flag(a)
	if b & (b$<>"") print right$("00"+str$(x),3)". "a$
	if key end setint(""):x=ab
	next:close:if y goto jmp2
	return

; global quickscan

qscan
	ob=bb:bb=1
	print "\nGlobal Quickscan...Spacebar Exits"
qs1
	setint(1):print "\nChecking board: [";
qs2
	i$="":a$=right$("0"+str$(bb),2)
	print a$"]";:gosub idinf:setint(1):if key end goto qs4
	if (~b1) | (bf$="") | (msg(0)=0) goto qs3
	if nn>msg(msg(0)) goto qs3
	print "\n\nThe "bn$"\ncontains new message(s)."
	input @2 "\n[R]ead S)kip Q)uit :"i$
	if left$(i$,1)="Q" return
	if left$(i$,1)="S" goto qs3
	gosub new:input @2 "\nPost a message? (Y/[N]):"i$
	if i$="Y":sb$="":ti$="":gosub post
	i$="Y"
qs3
	bb=bb+1:if bb>ab goto qs4
	if i$<>"" goto qs1
	print "\b\b\b";:goto qs2
qs4
	if i$="" | i$=" " print
	setint(""):bb=ob:goto idinf

; message show routine

show
	if nn<=msg(a):nn=msg(a)+1
	x=0:if lr<=msg(a):lr=msg(a)+1
show1
	if flag(36) goto anony
	input #msg(a),sb$|tn,ti$|d,fr$:setint(2)
	print #x,"\n  Board: "bn$"\n Number: "a" of "msg(0)"\nSubject: "sb$
	print #x,"     To: "ti$
	print #x,"   From: "fr$
show1a
	copy #6,#x:x=0:setint("")
	if key end x=1:return
	if key next return
show2
	if i$="+" return
	gosub time:print "\n["x$"][B"bb" #"a" of "msg(0)"] ? or Cmd [N]#";
	get i$:print
	if i$="?" print "\nM)ail [N]ext R)eread X)modem Q)uit D)ump ";
	if i$="?" & (d=un | exec) print "E)dit K)ill ";
	if i$="?" & exec print "S)wap P)rint"
	if i$="?" print
	if i$="D":i$="+"
	if (i$="N") | (i$="\n") | (i$="+") return
	if i$="Q":x=1:return
	if i$="R" goto show
	if i$="P" & exec:x=5:goto show1
	if (i$="A" | i$="M") & flag(1):a$="":goto show5
	if i$="A" | i$="M" print "\nYou must be verified to reply.":goto show2
	if i$="X" goto ptcl.dn
	if ~flag(1) goto show2
	if ~((d=un) | (exec)) goto show2
	if i$="E" & (flag(2) | exec) goto show4
	if i$="W" & exec goto wrt.msg
	if i$="S" & exec goto mov.msg
	if i$<>"K" goto show2
	input @2 "\nKill: Are you Sure? (Y/[N]):"i$
	if left$(i$,1)!="Y" goto show2
	gosub kill.3:a--:return
show4
	input @2 "\nEdit: Are you Sure? (Y/[N]):"i$
	if left$(i$,1)!="Y" goto show2
	edit clear:input #msg(a),a$|b,b$|c,c$|d$|e$
	copy #6,#8:edit:if ~edit size goto show2
	x=msg(a):delete #msg(a):print #msg(a),a$"\n"b,b$"\n"c,c$"\n"d$"\n"e$
	copy #8,#6:msg(a)=x:update:goto show2
show5
	input @2 "\nIs this a private letter? (Y/[N]):"i$
	if left$(i$,1)="Y" goto show6
	if (d=0 & flag(36)):ti$="Anoymous User":goto show5a
	open #1,"system/sys.users":position #1,128,d
	input #1,d1$,d2$|d3$:close:ti$=d3$
show5a
	if left$(sb$,3)<>"Re:":sb$="Re: "+sb$
	b=a:gosub post:a=b:goto show2
show6
	if d=0 print "\nSorry, anonymous post.":goto show2
	input @2 "\nSend this mail with a return receipt? (Y/[N]):"i$
	if i$="Y":rf=1:z=0:else rf=0:z=1
	k$="program/msg.seg"
	print "\n ":chain "program/mail.seg","msg.link"
return
	on nocar goto link.term
	ready bf$:goto show2

wrt.msg
	input @2 "\nFilename (to write):"i$
	if i$="" goto show2
	disk lock:create i$:open #1,i$:append #1
	copy #msg(a),#1:close:disk unlock:goto show2

;	message mover routine

mov.msg
	print "\n\nMessage Mover\n\nBoards 1-"ab
	input @2 "\nMove this message to board #" i$:zx=val(i$)
	if (zx>ab) | (zx<1) goto show2
	print "Message #"a" from this board...";
	edit clear:input #msg(a),a$|b,b$|c,c$:copy #6,#8
	x=msg(a):b5=bb:bb=zx:disk lock:gosub idinf
	if (kl>0) & (kl<=msg(0)) delete #msg(kb):crunch
	zx=msg(0)+1:print #msg(zx),a$"\n"b,b$"\n"c,c$:copy #8,#6:msg(a)=zx:update
	bb=b5:gosub idinf:msg(a)=x:gosub kill.3:a--
	print "is now on board #"i$".":disk unlock:goto show2

;show a message on anoymous boards.

anony
	input #msg(a),sb$|tn,ti$|d,fr$:setint(2)
	if left$(sb$,1)="*":sb$=mid$(sb$,2):goto anony1
	print #x,"\n  Board :"bn$"\n Number :"a" of "msg(0)"\nSubject :"sb$
	print #x,"     To :"ti$
	print #x,"   From :"fr$
	goto show1a

anony1
	print #x,"\n  Board :"bn$"\n Number :"a" of "msg(0)"\nSubject :"sb$
	print #x,"     To :"ti$
	if exec print #x,"   From :"fr$:goto show1a
	print #x,"   From :Anonymous Poster":goto show1a

; Protocol download of a message

ptcl.dn
	print "\nDownload message #"a;
	input @2 " via Protocol Transfer? (Y/[N]):"i$
	if left$(i$,1)<>"Y" return
	print "\nPreparing Message..."
	f$="/ram5/d"+str$(un):disk lock:create f$:ready bf$:open #1,f$
	input #msg(a),sb$|b,ti$|c,fr$:setint(2)
	y=0:if left$(sb$,1)="*":sb$=mid$(sb$,2):y=1
	print #1,"\n  Board :"bn$"\n Number :"a" of "msg(0)"\nSubject :"sb$
	print #1,"     To :"ti$
	if y print #1,"  From :Anonymous Poster":else print #1,"  From :"fr$
	copy #6,#1:close:print "\nReady to Send...":disk unlock
	overlay "protocol.down",180,0,f$:delete f$:goto show2

; Protocol upload of bulletin

ptcl.up
	print "\nReady to Receive...":f$="/ram5/u"+str$(un)
	disk lock:overlay "protocol.up",180,0,f$:disk unlock
	close:edit clear:copy f$,#8:print \edit size" bytes received"
	delete f$:edit:return

idinf
	flag(36)=0:flag(37)=0
	if bb=0:bf$="":bl=0:return
	me=0:bl=bb:open #1,"system/sys.data2"
	mark(1)=1120:input #1,ab
	if bb>ab close:bf$="":bl=0:return
	position #1,128,bb+8
	input #1,bn$|bf$|b3,b4|bs,bs$|mb,kl,kb
	if left$(bn$,1)="%":flag(36)=1:bn$=mid$(bn$,2)
	if left$(bn$,1)="$":flag(36)=1:bn$=mid$(bn$,2)
	if left$(bn$,1)="#":flag(36)=0:bn$=mid$(bn$,2)
	b1=1:if b3:b1=flag(b3)
	b2=1:if b4:b2=flag(b4)
	close:if bf$="":bl=0:return
	if (b1) ready bf$:nn=nb
	return

;	*** sub - routines ***

;	read header file

rd.head
	position #1,96,x
	read #1,ram(1),96
	return

wr.head
	position #1,96,x
	write #1,ram(1),96
	return

;	backspace over text

backup
	print chr$(8,n);chr$(0x20,n);chr$(8,n);
	return

;	enter a message

editor
	print cls"[ Enter/Edit Message Now : 4k or 4096 Bytes Maximum ]"
	print "[ Legal Commands : .A = Abort  .H = Help  .S = Save ]"
edit2
	cl=clock:clock=0:edit clear:edit:clock=cl:return

;	show a disk file

show.file
	setint(1):print "\n"s$"\n":open #1,f$:if mark(1) close #1:return
showfl2
	copy (20) #1
	if (eof(1) | key end) setint(""):close #1:return
	if ~flag(35) goto showfl2
	print "Press [RETURN] ";:get i$:if i$=chr$(13) print " ";
	print chr$(8,16);chr$(0x20,16);chr$(8,16);
	if i$=" " setint(""):close #1:return
	setint(1):goto showfl2

;	calculate time remaining

time
	z=(clock-clock online)/60:y=clock:x$=right$("00"+str$(z),3 )
	if clock online>clock:x$="!!!":else if z=0 x$="---"
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

error								/* print error message and handle */
	print "\nOne moment please, returning you to the Main Level."
	disk lock:close:clear gosub:create "system/sys.errors"
	open #1,"system/sys.errors":append #1
	print #1,"Error #"err" occured at "time$" on "date$" in conf.seg"
	close:disk unlock:chain "a:main.seg","fromsys"
