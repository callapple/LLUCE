; *********************
;      LLUCE v1.0
;    Copyright 1989
; L&L Productions, Inc.
; *********************

; voting segment rev a - 3/06/89

	public force

start
	on nocar goto link.term
;	on error goto error
	create "voting/v.catalog":open #1,"voting/v.catalog"
	position #1,64,0:input #1,y,vl:
	if (~y) goto v.sysop

v.select
	cls:print "Num  Topics Available           Online"
	print "--------------------------------------"
	for x=1 to y:position #1,64,x
	input #1,tp$:y1=len(tp$):x$=right$("  "+str$(x),2)
	print x$".  "left$(tp$+chr$(0x20,25),25);
	f$="voting/v"+str$(x)+".1":a=exist(f$)
	if a print "     Yes":else print "      No"
	next

v.input
	s=0:edit clear:gosub time
	print "\n["x$"][Select a topic: (1-"y", Q=Quit, ?=More)] ->";:input @2 i$
	x2=val(i$)
	if (i$="%") & (exec | (un=vl)):goto v.sysop
	if i$="Q" close:goto link.main
	if i$="?" goto v.select
	if (x2<1) | (x2>y) print "\n\""i$"\" is not a valid choice":goto v.input
	a$="voting/v"+i$:close #1:gosub voting:goto start


voting
	s=0:zx=18:i$="":t4=0:t2=0:t1=0
	if ~(un=vl) | exec goto voting1
	print "\nVoting Booth"
	print "------------"
	gosub time
	input @0 "\n[Voting Sysop][ P)ost, D)ump or V)iew results ] Cmd:"i$
	if i$="V":s=0:goto voting1
	if i$="B":s=8
	if i$="P":s=5:goto voting1
	print "\n{Default board #18}":input @3 "Post Voting Results on board #"i$
	if i$<>"":zx=val(i$)
	if zx=0 goto voting
voting1
	close:edit clear
	create a$:open #1,a$:mark(1)=(un/512)*64
	x=mark(1):fill ram(1),64,0
	read #1,ram(1),64:z=flag:flag=ram(1):a=flag(un % 512)
	flag(un % 512)=1:flag=z:mark(1)=x
	write #1,ram(1),64:x=1:z=byte:byte=ram(1)
	if t2:x=d

vote2
	open #2,a$+"."+str$(x):if mark(2) goto vote5
	input #2,y,x1,x4,u
	if u:t1=1:t2=1:t3=0:t4=1
	if ~a goto vote2.2
	setint(1):print #s "\n":x1=x1-1
	for y=1 to x1:input #2,i$
	if ~t3 print #s,i$
	next:t3=0:goto vote2.3
vote2.2
	copy (x1-1) #2:print "\nNum  Option":print chr$(0x3D,78):copy #2
vote2.3
	position #1,32,x+7:fill ram(1),32,0:read #1,ram(1),32
	b=byte(0)+byte(1)*256:if a goto vote4

vote3
	print "\n":if x4 print "A)dd option or ";
	input "Your vote : "i$
	if i$="A" & x4=1:gosub add.o:close #2:goto vote2
	d=val(i$):if (d<1) | (d>y) goto vote3
vote3.1
	print "\nTabulating...";
	b++:byte(0)=b % 256:byte(1)=b/256
	c=byte(d*2)+byte(d*2+1)*256:c++
	byte(d*2)=c % 256:byte(d*2+1)=c/256
	position #1,32,x+7:write #1,ram(1),32
	print".Done!"
	if t1 close:p5=x:a$="voting/a"+str$(x2):t1=0:t3=1:i$="":goto voting1
	if t2:x=p5:a$="voting/v"+str$(x2)
	close
	open #1,a$:position #1,32,x+7
	fill ram(1),32,0:read #1,ram(1),32
	b=byte(0)+byte(1)*256

vote4
	t2=0:c=0:c3=0:b=b+(b=0)
	print #s,"\nOption"chr$(0x20,57)"Percent [Votes]"
	print #s,chr$(0x3D,78)
	close:open #2,a$+"."+str$(x):input #2,y,x1
	copy (x1-1)#2,#9:clear #9:y4=y:for c=1 to y
	y=byte(c*2)+byte(c*2+1)*256
	b1$=str$((y*100)/b)+"%":y3=len(b1$):y3=4-y3
	input #2,b$:y2=len(b$):b$=right$(b$,y2-5):y2=len(b$)
	y2=67+y3-y2:goto vote4.1
vote4.1
	c3=c3+y
	if t2 print #s,"\n";
	if t4:t2=1
	print #s,b$chr$(0x2E,y2) (y*100)/b"% ["right$("000"+str$(y),3)"]"
	if ~t2 goto vote4.2
	print "x2="x2
	a=mark(2):close:gosub show.vo
	a$="voting/v"+str$(x2):close
	open #1,a$
	position #1,32,x+7
	fill ram(1),32,0:read #1,ram(1),32
	b=byte(0)+byte(1)*256
	open #2,a$+"."+str$(x)
	mark(2)=a
vote4.2
	next:b1$=str$((c3*100)/b)+"%":y3=len(b1$)
	y3=4-y3:y2=11:y2=67+y3-y2
	print #s chr$(0x20,y2-1);"----------------------"
	print #s chr$(0x20,y2-1);"Users Voted "right$("000"+str$((c3*100)/nu),3);
	print #s "% ["right$("000"+str$(c3),3)"]"
	if ~s print "\nPress Return :";:get i$
	close:x++:print "\n":open #1,a$:goto vote2

vote5
	close:byte=z
	if edit size gosub vo.resu
	gosub v.remove
	return

v.sysop
	print '

Sysop Control Section
---------------------

{T} Edit Voting Topics      {E}  Edit Voting Questions
{C} Number of Categories    {A}  View option additions
{Q} Quit'

	input @2 "\nCmd :"i$
	if i$="T" goto v.catalog
	if i$="E" goto v.edit
	if i$="C" goto v.num
	if i$="A" goto opt
	if i$="Q" close:goto start
	goto v.sysop

opt
	f$="voting/add.vote":open #2,f$:copy #2:close #2
	input @2 "\nDelete [(Yes),No]: "i$
	if i$<>"N" delete f$
	goto v.sysop

v.catalog
	print "Edit Category Topics"
	print "--------------------\n\n"
	for x=1 to y:position #1,64,x
	input #1,tp$:print x". "tp$:next
	print "\n[1-"y" Q)uit] Edit: ";:input i$
	if i$="Q" goto v.sysop
	x=val(i$):if (x<1) | (x>y) goto v.catalog
	position #1,64,x
	input @3 "\nEnter new topic ->";tp$
	print #1,tp$:goto v.catalog

v.num
	print "\nTotal Categories? ";:input i$
	y=val(i$)
	if exec print "\nCurrent user sysop num #:"vl
	if exec input " Voting user sysop num  #:"i$
	if exec:vl=val(i$)
	position #1,64,0:print #1,y,vl:goto v.sysop

v.edit
	print  "\nEditing Questions"
	print  "-----------------\n\n"
	print "Edit which category (1-"y") ? ";:input i$
	z1=val(i$):x1=1
	input @2 "\nAllow for sub-category votes? [Y/N]:"i$
	t=0:if i$="Y":t=1

v.edit0
	close
	print "\n\n             -+- Enter question #"x1" now at "width" columns -+-\n"
	print "Type 'DONE' on seperate line when completed -  'Exit' when thru.\n"
	z=2:edit clear

v.edit1
	input @3 ">" i$
	if (i$="EXIT") | (i$="exit") goto v.edit3a
	if (i$="DONE") | (i$="done") goto v.edit2
	print #9,i$:z++:goto v.edit1

v.edit2
	print "\n\nEnter possible answers now at 65 columns - \"Done\" when thru.\n"
	a=width:width=65:y1=0

v.edit2a
	print "\nAnswer #"y1+1" >";:input @3 i$
	if (i$="DONE") | (i$="done") goto v.edit3
	y1++:i$=right$("00"+str$(y1),2)+".  "+i$
	print #9,i$
	if ~t goto v.edit2a
	gosub v.1sub
	print "\n\nEnter possible answers now at 65 columns, for the question:\n"
	copy #9:print "\nType \"DONE\" when completed:"
	goto v.edit2a

v.edit3
	if t:x3=0:goto v.edit3b
	input @2 "\nAllow for user to add options? [Y/N]:"i$
	if i$="Y":x3=1:else x3=0

v.edit3b
	i$="voting/a"+str$(z1):delete i$
	i$="voting/v"+str$(z1):delete i$:i$=i$+"."+str$(x1)
	delete i$:create i$:open #2, i$:print #2,y1,z+1,x3,t
	print #2,"Created by: "left$(a1$+chr$(0x20,37),27);
	print #2,"Creation date: "fmtdate$" "time$" "
	copy #9,#2:close #2:width=a:x1++
	if t=0 goto v.edit0

v.edit3a
	close:open #1,"voting/v.catalog":goto v.sysop
	i$="voting/v"+str$(z1)+"."+str$(x1):open #2,i$:a=mark(2)
	if a close:open #1,"voting/v.catalog":goto v.sysop
	delete i$:goto v.edit3a

v.1sub
	close:delete "voting/scratch":create "voting/scratch"
	open #1,"voting/scratch"
	input @2 "\nAllow for user to add options? [Y/N]:"i$
	x3=0:if i$="Y":x3=1

v.sub2
	print "\n\nEnter possible SUB-Answers now at 55 columns - Type";
	print " 'DONE' when completed.\n"
	width=55:y2=0

v.sub2a
	print "Sub-Answer #"y2+1" >";:input @3 i$
	if i$="" goto v.sub2a
	if (i$="DONE") | (i$="done") goto v.sub3
	y2++:i$=right$("00"+str$(y2),2)+".  "+i$
	print #1,i$:goto v.sub2a

v.sub3
	i$="voting/a"+str$(z1):delete i$:i$=i$+"."+str$(y1)
	delete i$:create i$:open #2,i$:print #2,y2,3,x3,0
	print #2,"\n":close #1:open #1,"voting/scratch"
	copy #1,#2:close:width=a:return

v.sub3a
	i$="voting/a"+str$(z1)+"."+str$(x1)
	open #2,i$:a=mark(1):close #2
	if a goto v.sysop:else delete i$:goto v.sub3a
	return

vo.resu
	a$="Voting Results":b=0:b$="All":c=0:c$="Voting Librarian"
	x=msg(a):b5=bb:bb=zx:gosub idinf
	if (kl>0) & (kl<=msg(0)) delete #msg(kb):crunch
	zx=msg(0)+1:print #msg(zx),a$"\n"b,b$"\n"c,c$
	copy #9,#7:msg(zx)=mn:mn++:update:tm++
	open #2,"voting/quick":position #2,128,bb
	print #2,msg(msg(0)):close #2:bb=b5
	print "\n\nVoting results have been posted."
	x=0:return

vo.resu1
	x=x+1:b$="voting/v"+str$(x2)+"."+str$(x)
	i$="voting/a"+str$(x2)+"."+str$(x)
	open #2,i$:b=mark(2):open #1,b$:a=mark(1)
	if (~a) | (~b) close:delete b$:delete i$:goto vo.resu1
	close:return

idinf
	flag(36)=0:flag(37)=1:flag(38)=0
	if bb=0:bf$="":bl=0:return
	me=0:bl=bb:open #1,"b:data2"
	mark(1)=1120:input #1,ab
	if bb>ab close #1:bf$="":bl=0:return
	position #1,128,bb+8
	input #1,bn$|bf$|b3,b4|bs,bs$|mb,kl,kb
	if left$(bn$,1)="%":flag(36)=1:flag(37)=1:bn$=mid$(bn$,2)
	if left$(bn$,1)="$":flag(36)=1:flag(37)=0:bn$=mid$(bn$,2)
	if left$(bn$,1)="#":flag(36)=0:flag(37)=0:bn$=mid$(bn$,2)
	b1=1:if b3:b1=flag(b3)
	b2=1:if b4:b2=flag(b4)
	close #1:if bf$="":bl=0:return
	if (b1) ready bf$:nn=nb
	return

add.o
	print "\nEnter new option at 55 columns"
	a=width:width=55
	input @3 "\n:"b$
	print "\nIt reads:"
	print b$
	width=a
	input @0 "\nCorrect [Yes/No] "i$
	if i$="N" return
	if b$="" goto add.o
	close #2
	open #2,a$+"."+str$(x):input #2,y,x1,x4,u
	y++:close #2:open #2,a$+"."+str$(x)
	print #2,y,x1,x4,u:b$=right$("00"+str$(y),2)+".  "+b$
	append #2:print #2,b$:close #2
	f$="voting/add.vote":create f$:open #2,f$
	append #2:print #2,a2$" - "b$
	d=y:pop:a=0:goto vote3.1

show.vo
	print "x2="x2
	close:p2=0:a$="voting/a"+str$(x2)
	open #1,a$:position #1,32,c+7
	fill ram(1),32,0:read #1,ram(1),32
	b2=byte(0)+byte(1)*256:b2 += (b2=0)
	open #2,a$+"."+str$(c)
	input #2,p1,p3:copy (p3-1)#2,#9:clear #9:y4=p1
	for p2=1 to p1:p1=byte(p2*2)+byte(p2*2+1)*256
	b1$=right$("...."+str$((p1*100)/b2)+"%",4):y3=len(b1$):y3=4-y3
	input #2,b$:y2=len(b$):b$=right$(b$,y2-5):y2=len(b$)
	y2=55+y3-y2
	print #s,"  "b$chr$(0x2E,y2);
	print #s,right$("...."+str$((p1*100)/b2)+"%",4)" ["right$("000"+str$(p1),3)"]"
	next:return

v.remove
	if ~(un=vl) | exec return
	print "\nRemove Voting Topic"
	print "-------------------"
	input @0 "\nDelete [Yes/No]: "i$
	if i$="Y":x=0:goto vo.resu1
	return

force		{Check to see if the user has voted on any active topics}
	on nocar goto link.term
	open #1,"voting/v.catalog":input #1,x3,b:close #1
	for x2 = 1 to x3
		t4=0:t2=0:t1=0
		a$="voting/v"+str$(x):s=0:edit clear:b=0
		if ~flag(1):x2=x3:goto force1
		open #1,a$:mark(1)=(un/512)*64:fill ram(1),64,0
		read #1,ram(1),64:z=flag:flag=ram(1):a=flag(un % 512)
		flag=z:close:if a goto force1
		gosub voting
force1
	next
	goto link.main

; system links

link.main
	chain "program/main.seg","fromsys"

link.term
	chain "program/main.seg","term1"

; get time remaining before logoff

time
	yy=(clock-clock online)/60:zz=clock:x$=right$("00"+str$(yy),3)
	if clock online>clock:x$="!!!"
	if yy=0:x$="---"
	if ~zz:x$="***"
	if exec:x$=":::"
	return

; handle an error

error
	print "\nOne moment please, returning you to the Main Level."
	clear gosub:close:create "system/sys.errors"
	open #1,"b:sys.errors":append #1
	print #1,"Error #"err" occured at "time$" on "date$" in voting.seg"
	close:chain "a:main.seg","fromsys"


; Variable Lists


; vl = User number of Voting Librarian

; pr$ = prompt for messages from segment
; f$  = file name of various file
