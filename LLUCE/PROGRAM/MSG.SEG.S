; ********************
; GBBS "Pro" V:2.1
; By L&L Productions
; Copyright 1986-1990
; ********************

; msg segment - 4/2/90

	public bulletins
	public rd.mail
	public sd.mail
	public wr.letter

bulletins
	zz=0:gosub start
	flag(37)=1:gosub pfilter:goto link.main
rd.mail
	gosub rd.mail0:goto link.main
sd.mail
	gosub snd.mail:goto link.main
wr.letter
	s=9:gosub wr.ltr
link.main
	chain "program/main.seg","return"
link.term
	chain "program/main.seg","termin2"

; *** bulletins / e-mail ***

start
	on nocar goto link.term
	gosub idinf
	if bf$="" print "\nThat board is down right now.":gosub cmd2c:return
	if ~b1 print "\nYou do not have access to that board.":gosub cmd2c:return
	if i$="Q" gosub qscan
cmd1
	if msg(0) goto cmd2
	print "\nThe "bn$"\n has no bulletins...";
	input @2 "Post a bulletin ([Y]/N) ?"i$
	if left$(i$,1)="N" return
	sb$="":ti$="All":d=0:gosub post:if ~b2 return
	goto cmd1

cmd2
	x=(clock-clock online)/60:y=clock:x$=right$("0"+str$(x),2)
	if clock online>clock:x$="!!"
	if x=0:x$="--"
	if ~y:x$="**"
	if exec:x$="::"
	free:print "\n"bn$"\n["x$"][Board #"bb"  1-"msg(0)"] ";
	input "Option (?=Help):"i$
cmd2a
	zz=0:a=val(i$):push cmd2
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
	if i$="H":f$="system/hlp.msg":goto show.file
	if i$="J":y=0:goto jump
	if i$="P":ti$="All":sb$="":d=0:goto post
	if i$="L":y=1:goto list
	if i$="T" goto terminate
	if i$=">" & (bb<ab):bb++:zz=1:pop:goto start
	if i$="<" & (bb>1):bb--:zz=2:pop:goto start
	if (a>0) & (a<=msg(0)):i$="F"+i$:goto fwd
	if i$="?" | i$="/" goto cmd.menu
	a1++:print "\nSorry, \""i$"\" is not a command. (?=Help)":if a1<3 return

cmd.menu
	a1=0:print "\n"bn$'\n
	Read #, OR: [N]ew   [F#]orward [S#]can [B]rowse [M]arked [L]ist
	            [R#]vse [G]lobal   [J#]ump [P]ost   [K#]ill  [H]elp
	            [Q]uit  [>] Next board     [<] Previous board

	Command letters followed with "#" have a numeric argument option.
	"F45" reads F)orward beginning at bulletin 45
	"K32" would K)ill bulletin #32"
':return

cmd2c
	if ~zz return
	if zz=1:bb++
	if zz=2:bb--
	zz=0:pop:goto start

; terminate connection

terminate
	print "\nTerminate Connection"
	input @2 "\nAre you sure (Y/[N]) ?"i$
	if left$(i$,1)<>"Y" return
	chain "program/main.seg","termin2"

; post a bulletin

post
	if ~b2 print "\nYou do not have access to that board.":return
	edit clear:if kl goto post2
	if msg(0)=mb print "\nSorry, no room on this board.":return
	if msg(0)=msg size print "\nBoard directory full.":return
	if msg free<29 print "\nBoard bit-map full.":return
post2
	print "\nPost Bulletin\n"
	if d open #1,"system/users":position #1,128,d:input #1,d1$,d2$|d3$:close
	if d:ti$=d3$+" (#"+str$(d)+")":if d=1:ti$="Sysop"
	if ti$<>"" print "  To ->"ti$" ([Y]/N):";:get i$
	if i$="\n":n=9:gosub backup:print:goto post2a
	if i$="N":n=len(ti$)+10:gosub backup:input @4 ti$:if ti$="" return
	if (ti$<>"") & left$(i$,1)<>"N":n=10:gosub backup:print
	if ti$="" input @4 "  To ->"ti$:if ti$="" return
post2a
	i$="":if sb$<>"" print " Sub ->"sb$" ([Y]/N):";:get i$
	if i$="\n":n=9:gosub backup:print:goto post2b
	if i$="N":n=len(sb$)+10:gosub backup:input @4 a$:if a$="" return
	if (sb$<>"" | a$<>"") & left$(i$,1)<>"N":n=10:gosub backup:print
	if sb$="" input @4 " Sub ->"a$:if a$="" return
	if a$<>"":sb$=a$
post2b
	a$=a3$:if (un=bs) & (bs$<>""):a$=bs$
	a$=a$+" (#"+str$(un)+")"
	if ~exec goto post2c
	i$="":print "From ->"a$" ([Y]/N):";:get i$
	if i$="\n":n=9:gosub backup:print:goto post2c
	if i$="N":n=len(a$)+10:gosub backup:input @3 a$:if a$="" return
	if (a$<>"") & left$(i$,1)<>"N":n=10:gosub backup:print
post2c
	i$="":if flag(36) print "\nAnonymous Posting (Y/[N]):";:get i$:print
	if (flag(36)) & (i$="Y"):flag(38)=1:else flag(38)=0
	input @2 "\nPost: [Y]es, N)o, X)modem " i$
	if i$="N" return
	if i$="X" gosub up.xmdm:else gosub editor
	if ~edit size return
	print "\n"edit size" bytes entered"
	print "Saving Message...wait..";:bp++
	print "\nkl="kl" kb="kb" a="a" b="b" msg(0)="msg(0)
	if (kl>0) & (kl<=msg(0)):kill #msg(kb):crunch:b--
	print "\nkl="kl" kb="kb" a="a" b="b" msg(0)="msg(0)
	a=msg(0)+1
	if flag(38) print #msg(a),"*"sb$:else print #msg(a),sb$
	print #7,tn,ti$
	if flag(38) print #7,0,a$:else print #7,un,a$
	if flag(38) print #7,"Date ->"date$"\n":else print #7,"Date ->"date$"  "time12$\
	copy #9,#7:msg(a)=mn:mn++:flush:tm++
	print ".saved":ti$="":a$="":return

; show new billetins

new
	print "\nNew Bulletins"
	if nn>msg(msg(0)) print "\nNo new bulletins":return
	x=msg(0):if ~lr:a=1:goto fwd2
new1
	if nn=<msg(x):a=x--:if x goto new1
	goto fwd2

; bulletin retrieval - Forward

fwd
	if len(i$)>1:a=val(mid$(i$,2)):goto fwd1
	print "\nSequential Retrieval - Forward"
	input @2 "\nStart where (#, F)irst, <CR>):"i$
	a=val(i$):if i$="F":a=1
fwd1
	if a<1 return
	if a>msg(0):a=msg(0)
fwd2
	print "\n"s$"\n"n$
fwd3
	gosub show:if x return
	if a<msg(0):a++:goto fwd3
	return

; bulletin retrieval - Reverse

rvs
	if len(i$)>1:a=val(mid$(i$,2)):goto rvs1
	print "\nSequential Retrieval - Reverse"
	input @2 "\nStart where (#, L)ast, <CR>):"i$
	a=val(i$):if i$="L":a=msg(0)
rvs1
	if a<1 return
	if a>msg(0):a=msg(0)
rvs2
	print "\n"s$"\n"n$
rvs3
	gosub show:if x return
	if a>1:a--:goto rvs3
	return

; kill bulletins

kill
	if len(i$)>1:a=val(mid$(i$,2)):goto kill.1
	print "\nKill a Bulletin"
	input @2 "\nKill Bulletin (#,<CR>):"a
kill.1
	if (a<1) | (un=0) return
	if a>msg(0) print "\nThat Bulletin Does Not Exist!":return
	input #msg(a),a$|x,b$|x,c$
	if (exec) | (un=bs) goto kill.2
	if x<>un print "\nThats not your bulletin!":return
kill.2
	if (flag(38)) & (left$(a$,1)="*"):a$=mid$(a$,2)
	print "\nNumb ->"a" of "msg(0)"\n Sub ->"a$
	input @2 "\nKill this bulletin (Y/[N]) ?"i$
	if left$(i$,1)<>"Y" return
kill.3
	tm--:y=msg(msg(0)):kill #msg(a):crunch
	b=msg(0):if b:msg(b)=y:flush
	print "\nBulletin #"a" killed..."
	return

; browse bulletins titles

browse
	m$="":a=0:print "\nScan Bulletin Titles"
	print "\nScan for what text [<CR>=Everything]?"
	input @3 ":"m$:a=1:if m$="":a=0:return
	goto scan.2

; scan bulletins

scan
	print "\nScan bulletins"
	if len(i$)>1:a=val(mid$(i$,2):goto scan.1
	input @3 "\nStart at (#,<CR>):"a
scan.1
	m$="":if a<1 return
	if a>msg(0) print "\nThat Bulletin Does Not Exist!":return
scan.2
	input @2 "\nAllow marking (Y/[N]) ?"i$
	ms=0:if left$(i$,1)="Y":ms=a
	d=0:x=15:print:z=flag:flag=ram(1)
scan.3
	a$=" ":if msg(a)>nn:a$="*"
	flag(a-ms)=0:input #msg(a),t$|b,b$
	if m$ if ~instr(m$,t$) goto scan.4
	if left$(t$,1)="*":t$=mid$(t$,2)
	x--:d++:print a$a". "t$"\n  Addressed to:"b$"\n"
	if i$<>"Y" goto scan.4
	print "Mark (Y/[N]/Q) ?";:get a$:print
	if a$="Q" goto scan.5
	flag(a-ms)=(a$="Y")
scan.4
	if a=msg(0) goto scan.5
	a++:if x goto scan.3
	input @2 "\nMore ([Y]/N/C) ?"a$
	if left$(a$,1)="C":x=msg(0)-a-1:goto scan.3
	if left$(a$,1)<>"N" print:x=15:goto scan.3
scan.5
	me=a:flag=z:if (~d) print "Sorry, no match":ms=0:return
	if left$(i$,1)<>"Y" return

; marked bulletins retrieval

mark
	print "\nRetrieve marked bulletins":a=ms
	if ~ms print "\nNo marked bulletins":return
mark.2
	z=flag:flag=ram(1):b=flag(a-ms):flag=z
	x=0:if b gosub show
	if x=0:a++:if a<me goto mark.2
	return

; jump to another board.

jump
	print \n"Jump to Another Board"
jmp2
	print "\nJump to (1-"ab",?,<CR>):";
	input @2 i$:if i$="" return
jmp3
	a=val(i$)
	if (a>0) & (a<=ab) pop:bb=a:goto start
	if i$<>"?" goto jmp2

; list of available boards.

list
	print cls"\n"s$"\n":open #1,"system/sys.data2"
	for x=1 to ab:position #1,128,x+8
	input #1,a$|b$|a:setint(1)
	if instr(left$(a$,1),"#$%"):a$=mid$(a$,2)
	b=1:if a:b=flag(a)
	if b & (b$<>"") print x". "a$
	if key end setint(""):x=ab
	next:close:if y return
	goto jmp2

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
	print "\nThe "bn$"\ncontains new message(s)"
	input @2 "\n[R]ead S)kip Q)uit ?" i$
	if left$(i$,1)="Q" return
	if left$(i$,1)="S" goto qs3
	gosub new:input @2 "\nPost a message (Y/[N]) ? "i$
	if i$="Y":sb$="":ti$="":gosub post
	i$="Y"
qs3
	bb++:if bb>ab goto qs4
	if i$<>"" goto qs1
	print "\b\b\b";:goto qs2
qs4
	if i$="" | i$=" " print
	setint(""):bb=ob:goto idinf

; bulletin show routine

show
	if nn<=msg(a):nn=msg(a)+1
	x=0:if lr<=msg(a):lr=msg(a)+1
show1
	if flag(36) goto anony
	input #msg(a),sb$|tn,ti$|d,fr$:setint(2)
	print #x,"\n Brd ->"bn$"\nNumb ->"a" of "msg(0)"\n Sub ->"sb$
	print #x,"  To ->"ti$
	print #x,"From ->"fr$
show1a
	copy #7,#x:x=0:setint("")
	if key end:x=1:return
	if key next return
show2
	if i$="+" return
	print "\n[B"bb" #"a" of "msg(0)"] ? or Cmd [N]#";
	get i$:print
	if i$="?" print "\nM)ail [N]ext R)eread X)modem Q)uit D)ump ";
	if i$="?" & (d=un | exec) print "E)dit K)ill ";
	if i$="?" & exec print "S)wap P)rint"
	if i$="?" print
	if i$="D":i$="+":return
	if i$="N" | i$="\n" | i$="+" return
	if i$="Q":x=1:return
	if i$="R" goto show
	if i$="P" & exec:x=6:goto show1
	if (i$="A" | i$="M") & flag(1):a$="":goto show5
	if i$="A" | i$="M" print "\nSecurity too low":goto show2
	if i$="X" goto dn.xmdm
	if ~flag(1) goto show2
	if ~((d=un) | (exec)) goto show2
	if i$="E" & (flag(2) | exec) goto show4
	if i$="W" & exec goto wrt.msg
	if i$="S" & exec goto mov.msg
	if i$<>"K" goto show2
	input @2 "\nKill: Are you Sure (Y/[N]) ?"i$
	if left$(i$,1)<>"Y" goto show2
	gosub kill.3:a--:return
show4
	input @2 "\nEdit: Are you Sure (Y/[N]) ?"i$
	if left$(i$,1)<>"Y" goto show2
	edit clear:input #msg(a),a$|b,b$|c,c$|d$|e$
	copy #7,#9:edit:if ~edit size goto show2
	x=msg(a):kill #msg(a):print #msg(a),a$"\n"b,b$"\n"c,c$"\n"d$"\n"e$
	copy #9,#7:msg(a)=x:flush:goto show2
show5
	input @2 "\nIs this a private letter (Y/[N]) ?"i$
	if left$(i$,1)="Y" goto show6
	if (d=0 & flag(36)):ti$="Anoymous User":goto show5a
	open #1,"system/users":position #1,128,d
	input #1,d1$,d2$|d3$:close:ti$=d3$
show5a
	if left$(sb$,3)<>"Re:":sb$="Re: "+sb$
	b=a:gosub post:a=b:goto show2
show6
	if d=0 print "\nSorry, anonymous sender":goto show2
	gosub editor:if ~edit size goto show2
	print "\n"edit size" bytes entered"
	print "Wait..";:s=9:gosub wr.ltr
	ready bf$:print ".reply sent":goto show2

wrt.msg
	input @2 "\nFilename (to write):"i$
	if i$="" goto show2
	create i$:open #1,i$:append #1
	copy #msg(a),#1:close:goto show2

mov.msg
; Bulletin Mover From Al Anderson
	print "\n\nBulletin Mover Utility\n\nBoards 1-"ab
	input @2 "\nMove this post to board #"i$:zx=val(i$)
	if (zx>ab) | (zx<1) goto show2
	edit clear:input #msg(a),a$|b,b$|c,c$:copy #7,#9
	x=msg(a):b5=bb:bb=zx:gosub idinf
	if (kl>0) & (kl<=msg(0)) kill #msg(kb):crunch
	zx=msg(0)+1:print #msg(zx),a$"\n"b,b$"\n"c,c$:copy #9,#7:msg(a)=zx:flush
	bb=b5:gosub idinf:msg(a)=x:print "On this board...";:gosub kill.3:a--
	print "Bulletin is now on other board.":goto show2

;show a bulletin on anoymous boards.

anony
	input #msg(a),sb$|tn,ti$|d,fr$:setint(2)
	if left$(sb$,1)="*":sb$=mid$(sb$,2):goto anony1
	print #x,"\n Brd ->"bn$"\nNumb ->"a" of "msg(0)"\n Sub ->"sb$
	print #x,"  To ->"ti$
	print #x,"From ->"fr$
	goto show1a
anony1
	print #x,"\n Brd ->"bn$"\nNumb ->"a" of "msg(0)"\n Sub ->"sb$
	print #x,"  To ->"ti$
	if exec print #x,"From ->"fr$:goto show1a
	print #x,"From ->Anonymous Poster":goto show1a

;xmodem d/l of bulletin by Keith Christian

dn.xmdm
	print "\nDownload bulletin #"a;
	input @2 " via Xmodem (Y/[N]) ?"i$
	if left$(i$,1)<>"Y" return
	f$="system/d":create f$:ready bf$:open #1,f$
	input #msg(a),sb$|b,ti$|c,fr$:setint(2)
	y=0:if left$(sb$,1)="*":sb$=mid$(sb$,2):y=1
	print #1,"\n Brd ->"bn$"\nNumb ->"a" of "msg(0)"\n Sub ->"sb$
	print #1,"  To ->"ti$
	if y print #1,"From ->Anonymous Poster":else print #1,"From ->"fr$
	copy #7,#1:close:print "\nReady to Send..."
	overlay "system/protocol.down",300,0,f$:kill f$:goto show2

;xmodem u/l of bulletin by Keith Christian

up.xmdm
	input @2 "\nUpload a message via Xmodem ([Y]/N) ?"i$
	if i$="N" pop:return
	print "\nReady to Receive..."
	f$="system/u":overlay "system/protocol.up",300,0,f$
	close:edit clear:copy f$,#9
	print "\n"edit size" bytes received"
	kill f$:edit:return

idinf
	flag(36)=0:flag(37)=1:flag(38)=0
	if bb=0:bf$="":bl=0:return
	me=0:bl=bb:open #1,"system/sys.data2"
	mark(1)=1120:input #1,ab
	if bb>ab close:bf$="":bl=0:return
	position #1,128,bb+8
	input #1,bn$|bf$|b3,b4|bs,bs$|mb,kl,kb
	if left$(bn$,1)="%":flag(36)=1:flag(37)=1:bn$=mid$(bn$,2)
	if left$(bn$,1)="$":flag(36)=1:flag(37)=0:bn$=mid$(bn$,2)
	if left$(bn$,1)="#":flag(36)=0:flag(37)=0:bn$=mid$(bn$,2)
	b1=1:if b3:b1=flag(b3)
	b2=1:if b4:b2=flag(b4)
	close:if bf$="":bl=0:return
	if (b1) ready bf$:nn=nb
pfilter
	if ~flag(37) edit on:else edit off
	return

; read e-mail

rd.mail0
	on nocar goto link.term
	print "\nRead Mail"
	if flag(0) print "\nGuests can not receive mail":return
	ready "email/mail"
	if ~msg(un) print "\nNo mail for you":return
	ready #msg(un)
rd.mail2
	x=0:input #7,i$:d=val(i$)
	if i$="":ma=1:return
rd.mail3
	print #x,"\n"md$:setint(2):copy #7,#x
	setint(""):print #x,md$
	if key next goto rd.mail2
rd.mail4
	input @2 "\n(A)uto reply, [C]ontinue, (R)e-read :"i$
	if i$="" | i$="C" | i$="N" goto rd.mail2
	if i$="Q" return
	if i$="R" rewind:x=0:goto rd.mail3
	if i$="P" & exec rewind:x=6:goto rd.mail3
	if i$="W" & exec goto wr.mail
	if i$="F" goto forward
	if i$<>"A" goto rd.mail4
	if d=0 print "\nSorry, anonymous sender":goto rd.mail4
	input @2 "\nSubject:"sb$:if sb$="" goto rd.mail4
	gosub editor:if ~edit size goto rd.mail4
	print "\n"edit size" bytes entered"
	print "Wait..";:h$="":s=9:gosub wr.ltr
	print ".reply sent":goto rd.mail2

wr.mail
	input @2 "\nFilename (to write):"i$:if i$="" goto rd.mail4
	create i$:rewind:open #1,i$:input #7,i$
	append #1:copy #7,#1:close:goto rd.mail4

forward
	print "\nForward letter"
	a=d:gosub mail.who
	if d=0:d=a:goto rd.mail4
	rewind:s=8
	input @2 "Subject:"sb$:if sb$="":sb$="For your information"
	h$="   --> A Forwarded Letter <--"
	r$=".letter forwarded":gosub snd.bulk
	d=a:goto rd.mail4

; send e-mail

snd.mail
	on nocar goto link.term
	print "\nSend Mail"
	gosub mail.who:if d=0 return
	input @3 "Subject:"sb$:if sb$="":sb$="None"
	gosub editor:if ~edit size return
	h$="":r$=".letter sent"
	s=9:goto snd.bulk

mail.who
	input @2 "\nTo who: Name, #, B)ulk mailing, <CR>):"i$
	clear #10:if i$="":d=0:return
	if i$<>"B" gosub mail.wh2:print #10,d"\n"0:return
	print "\nBulk Mailing":x=1
	y=5:if flag(2):y=25

bulk1
	input @2 "\nSend copy to (#,<CR>):"i$
	if i$="":d=0:if x=1 return
	if i$<>"" gosub mail.wh2:if d=0 goto bulk1
	print #10,d:x++:if d if x<y goto bulk1
	d=1:return

mail.wh2
	if left$(i$,1)="#":i$=mid$(i$,2):goto snd.num
	if val(left$(i$,1)) goto snd.num
	d$=i$:if (d$="SYSOP") | (d$=sys$):d=1:return
	if ~instr(" ",i$) goto snd.usr2
	open #1,"system/users":d=1

snd.user
	position #1,128,d
	input #1,a$,b$|c$
	if (a$+" "+b$=d$) | (a$+b$=d$) close:return
	if d<nu:d++:goto snd.user
	close:d=0
	print "\n"d$" is not a user":return
snd.usr2
	print "\nThat user does not exist"
	d=0:return

snd.num
	d=val(i$)
	if (d<1) | (d>nu) goto snd.usr2
	move ram,58 to ram(1):open #1,"system/users"
	position #1,128,d:input #1,a$,b$|c$
	position #1,128,d,70:read #1,ram,58
	close:i$=when$:move ram(1),58 to ram
	if a$="" goto snd.usr2
	print "\nSend to "c$"\nLast on "i$;
	input @2 " ([Y]\\N) ?"i$
	if left$(i$,1)="N":d=0
	return

; write a bunch of letters to disk

snd.bulk
	print "\n"edit size" bytes entered"
	print "Wait..";:mark(10)=0
snd.blk2
	input #10,d:if d=0 print r$:return
	gosub wr.ltr:print ".";:if s=8 rewind
	goto snd.blk2

; write the letter to disk

wr.ltr
	ready "email/mail"
	if msg free<29 print "\nMail bit-map full":return
	print #msg(d),un:if h$<>"" print #7,h$"\n"
	print #7,"Subj ->"sb$
	print #7,"From ->"a3$" (#"un")"
	print #7,"Date ->"date$" "time12$"\n"
	copy #s,#7:print #msg(d),"\x0400";
	msg(d)=1:flush:return

; *** sub - routines ***

; backspace over text

backup
	print chr$(8,n);chr$(0x20,n);chr$(8,n);
	return

; enter a message

editor
	print "\nEnter message now, "width" cols, [4k] max"
	print "[DONE] when finished, [.H] for help'
	cl=clock:clock=0:edit clear:edit:clock=cl:return

; show a disk file

show.file
	setint(1):print "\n"s$"\n":open #1,f$:if mark(1) close #1:return
showfl2
	copy (20) #1
	if (eof(1) | key end) setint(""):close #1:return
	if ~flag(35) goto showfl2
	print "Press [RETURN] ";:get i$:if i$="\n" print " ";
	print chr$(8,16);chr$(0x20,16);chr$(8,16);
	if i$=" " setint(""):close #1:return
	setint(1):goto showfl2
