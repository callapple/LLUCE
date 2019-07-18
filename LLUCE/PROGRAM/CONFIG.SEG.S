
; Rev 06/18/88 - 18:11 AW

	ready " ":on nocar goto terminate
start
	print sc$'
1)  Edit bulletin boards
2)  Print a sorted user list
3)  Purge Users
4)  Edit access information
5)  Quit':gosub showtime
	print iv$"[Config]"no$" Which? (1-6)";
	l1$=cr$+es$+"12345":gosub getone:a=val(i$):if i$=cr$ or i$=es$:a=6
	if a=5 print "Quit":l1$="a:main.seg":l2$="fromsys":goto link
	push start:if a=1 print "Edit boards":goto maintbrd
	if a=2 print "User list":goto userlist
	if a=3 print "Not finished":gosub get:return
	if a=4 print "Edit access":goto edaccess

maintbrd
	print sc$'1)  Add a new bulletin board
2)  Delete a bulletin board
3)  Edit an existing board
4)  Swap two bulletin boards
5)  List all bulletin boards
6)  Create board storage file
7)  Return to Config menu':gosub showtime
	print iv$"[BBS edit]"no$" Which? (1-7)";:l1$=cr$+es$+"1234567":gosub getone
	a=val(i$):if i$=cr$ or i$=es$ or (a=7) return
	push maintbrd:if a=1 print "Add":goto add.brd
	if a=2 print "Delete":goto del.brd
	if a=3 print "Edit":goto edit.brd
	if a=4 print "Swap":goto sw.brd
	if a=5 print "List":goto lst.brd
	if a=6 print "Create":goto stocre

add.brd
	print \"Add a board?";:yn=1:es=1:gosub getyn:if i$="N" return
	nb=1:open #1,"b:data2":mark(1)=1120:input #1,ab:close
	bb=ab+1:bn$="New Board":bf$="F:B"+str$(bb)
	b3=1:b4=1:bs=0:bs$="":mb=128:kl=0:kb=0:goto ed.brd1

edit.brd
	open #1,"b:data2":mark(1)=1120:input #1,ab
	nb=0:print \"System has boards from 1-"ab
ed.brd0
	print \"  Edit #";:ix=2:gosub input2:if i$="" close:return
	bb=val(i$):if (bb<1) or (bb>ab) print \iv$"Invalid Board"no$:goto ed.brd0
	position #1,128,bb+8:input #1,bn$\bf$\b3,b4\bs,bs$\mb,kl,kb:close
ed.brd1
	print \"1)  Name: "bn$"  [#"bb"]"
	print "2)  File: "bf$
	print \"3)  Access: "left$(str$(b3)+" "),2)"  4)  Write: "b4
	print \"5)  Aux Sysop Numb: "bs
	print "6)  Aux Sysop Name: ";
	if bs$="" print "[ No Aux Sysop ]":else print bs$
	print \"7)  Max #  of bulletins: "mb
	print "8)  Auto kill threshold: ";
	if kl print kl:else print "No auto kill"
	print "9)  Bulletin #  to Kill: "kb
	print \"10)  Abort Without Saving"
	print "11)  Save Changes And Quit"
	print \"Edit? [1-11]";:ix=2:gosub input:a=val(i$):if (i$="") or a=10 return
	if a=1 print \"Name";:ix=3:gosub input:if i$<>"":bn$=i$
	if a=2 print \"File";:ix=3:gosub input:if i$<>"":bf$=i$
	if a=3 print \"Access";:ix=3:gosub input:if i$<>"":b3=val(i$)
	if a=4 print \"Write";:ix=3:gosub input:if i$<>"":b4=val(i$)
	if a=5 print \"Aux Sysop #";:ix=4:gosub input2
	if (a=5) and (i$<>""):bs=val(i$):gosub ed.brd3
	if a=6 print \'
Aux sysop Name -> 'bs$;chr$(8,len(bs$));:ix=4:gosub input2:if i$<>"":bs$=i$
	if a=7 print \"Max # of Bulletins";:ix=4:gosub input:if i$<>"":mb=val(i$)
	if a=8 print \"Auto kill threshold";:ix=4:gosub input:kl=val(i$)
	if a=9 print \"Bulletin # to Kill";:ix=4:gosub input:if i$<>"":kb=val(i$)
	if a=11 goto ed.brd2
	goto ed.brd1

ed.brd2
	print \"Updating..";:open #1,"b:data2":mark(1)=1120:input #1,ab
	i$=bn$+cr$+bf$+cr$+str$(b3)+","+str$(b4)+cr$+str$(bs)+","+bs$+cr$
	i$=i$+str$(mb)+","+str$(kl)+","+str$(kb)
	if len(i$)<127:i$=i$+cr$:if len(i$)<127:i$=i$+chr$(32,127-len(i$))
	position #1,128,bb+8:print #1,i$:if nb=1:mark(1)=1120:print #1,ab+1
	close:print ".board #"bb" updated":if nb=1 goto stocre1
	return

ed.brd3
	open #1,"b:users":position #1,128,bs:input #1,a$,b$\c$:close #1
	if a$<>"":bs$=c$:return
	print \iv$"That user does not exist!"no$
	if bs$="" or (bs=0):bs=0:bs$=""
	return

del.brd
	open #1,"b:data2":mark(1)=1120:input #1,ab
	nb=0:print \"System has boards from 1-"ab
del.brd0
	print \"Delete #";:ix=2:gosub input2:if i$="" close:return
	bb=val(i$):if (bb<1) or (bb>ab) print \iv$"Invalid Board"no$:goto del.brd0
	position #1,128,bb+8:input #1,bn$\bf$
	print \"Delete "bn$"?";:yn=1:es=1:gosub getyn:if i$="N" close:return
	kill bf$:ab=ab-1:mark(1)=1120:print #1,ab:if bb=(ab+1) close:return
	for l=bb to ab-1:position #1,128,l+9:input #1,bn$\bf$\b3,b4\bs,bs$\mb,kl,kb
	i$=bn$+cr$+bf$+cr$+str$(b3)+","+str$(b4)+cr$+str$(bs)+","+bs$+cr$
	i$=i$+ctr$(mb)+","+str$(kl)+","+str$(kb)
	if len(i$)<127:i$=i$+cr$:if len(i$)<127:i$=i$+chr$(32,127-len(i$))
	position #1,128,l+8:print #1,i$:next:close:return

sw.brd
	open #1,"b:data2":mark(1)=1120:input #1,ab
	nb=0:print \"System has boards from 1-"ab
sw.brd0
	print \"Swap #";:ix=2:gosub input2:if i$="" close:return
	b1=val(i$):if (b1<1) or (b1>ab) print \iv$"Invalid Board"no$:goto sw.brd0
sw.brd1
	print "With #";:ix=2:gosub input2:if i$="" goto sw.brd0
	b2=val(i$):if (b2<1) or (b2>ab) print \iv$"Invalid Board"no$:goto sw.brd1
	position #1,128,b1+8:input #1,bn$:print "Swap board: "bn$
	position #1,128,b2+8:input #1,bn$:print "With board: "bn$
	print \"Correct?";:yn=1:es=1:gosub getyn:if i$="N" close:return
	position #1,128,b1+8:input #1,bn$\bf$\b3,b4\bs,bs$\mb,kl,kb
	edit clear:print #8,bn$\bf$\b3,b4\bs,bs$\mb,kl,kb
	position #1,128,b2+8:input #1,bn$\Bf$\b3,b4\bs,bs$\mb,kl,kb
	i$=bn$+cr$+bf$+cr$+str$(b3)+","+str$(b4)+cr$+str$(bs)+","+bs$+cr$
	i$=i$+ctr$(mb)+","+str$(kl)+","+str$(kb)
	if len(i$)<127:i$=i$+cr$:if len(i$)<127:i$=i$+chr$(32,127-len(i$))
	position #1,128,b1+8:print #1,i$
	input #8,bn$\bf$\b3,b4\bs,bs$\mb,kl,kb:edit clear
	i$=bn$+cr$+bf$+cr$+str$(b3)+","+str$(b4)+cr$+str$(bs)+","+bs$+cr$
	i$=i$+ctr$(mb)+","+str$(kl)+","+str$(kb)
	if len(i$)<127:i$=i$+cr$:if len(i$)<127):i$=i$+chr$(32,127-len(i$))
	position #1,128,b2+8:print #1,i$
	close:return

lst.brd
	print sc$:open #1,"b:data2":mark(1)=1120:input #1,ab
	for l=1 to ab:position #1,128,l+8:input #1,bn$,bf$
	print right$(" "+str$(l),2)". "left$(bn$+chr$(32,32),32)bf$
	next:close:print \"Press any key to continue";:gosub get:return

stocre
	print sc$:open #1,"b:data2":mark(1)=1120:input #1,ab
stocre0
	print \"Create storage file for board #";:ix=2:gosub input2
	if i$="" close:return
	bb=val(i$):if (bb<1) or (bb>ab) print \iv$"Invalid Board"no$:goto stocre0
	position #1,128,bb+8:input #1,bn$\bf$\b3,b4\bs,bs$\mb,kl,kb:close
stocre1
	print \"Directory Capacity [Default=128]";:ix=2:gosub input:a$=i$
	if a$="":a$="128"
	print \"Storage Capacity  [Default=128k]";:ix=2:gosub input:b$=i$
	if b$="":b$="128"
	y=val(a$):z=val(b$):print sc$"Name: "bn$:print \"File: "bf$
	print \"Max Bulletins: "y:print \"Max Storage: "z
	print \"Is the above correct?";:yn=1:es=1:gosub getyn:if i$="N" return
	y=(y/128)*128:z=(z/128)*128:l=(y/32)+(z/128)
	fill ram2,64,0:poke ram2,z/128:poke ram2+1,y/32:create bf$:open #1,bf$
	write #1,ram2,8:fill ram2,64,0:for x=1 to l:write #1,ram2,64
	write #1,ram2,64:next:close:x=6:use "e:xtyp",bf$,x:return

userlist
	print sc$'
1)  Print list sorted by name
2)  Print list sorted by user number
3)  Print list sorted by password
4)  Print list sorted by phone number
5)  Print list sorted by last date on
6)  Print list sorted by security level
7)  Return to main menu':gosub showtime
	print iv$"[User list]"no$" Which? (1-7)";:l1$=cr$+es$+"1234567"
	gosub getone:a=val(i$):if i$=cr$ or i$=es$ or (a=7) return
	y=32:if a=1 print "Name":f$="b:srt.name"
	if a=2 print "User":f$="b:srt.num"
	if a=3 print "Pass":f$="b:srt.pw":y=64
	if a=4 print "Phone":f$="b:srt.ph":y=64
	if a=5 print "Date":f$="b:srt.date":y=64
	if a=6 print "Security":f$="b:srt.sec":y=64
	print \"Show passwords?";:yn=1:es=1:gosub getyn:pa=(i$="Y"):if es return
	i$="":print \"To printer?";:yn=1:es=1:gosub getyn:s=5:nl=58:if es return
	if i$="N":s=0:nl=15
	move ram,58 to ram2:on nocar goto pterm
	z=1:print sc$\:open #2,f$:if mark(2)=0 goto sortit
	close:print "Reading data...":open #1,"b:users":kill f$:create f$:open #2,f$
	for l=1 to nu:position #1,128,l:input #1,d1$,d2$\d3$\d4$,d5$
	position #1,128,l,70:read #1,ram,58:t$="":if d1$="" goto next
	t$=d2$+" "+d1$
	if a=2:t$=right$("    "+str$(l),4)
	if a=3:t$=mid$(" "+pa$+"       ",2,8)+t$
	if a=4:i$=right$(chr$(32,12)+ph$,12)
	if a=4:t$=left$(i$,3)+"-"+mid$(i$,5,3)+"-"+right$(i$,4)+t$
	if a=5:t$=right$(when$,2)+"/"+left$(when$,5)+t$
	if a=6:i$="":for x=1 to 34:i$=i$+str$(flag(x)):next:t$=i$+t$
	position #2,y,z:print #2,t$\l:z=z+1
next
	next
sortit
	close:z=1:print "Sorting...";:use "e:rndsort.128",f$,y,z
	print "Printing...":z=1:open #2,f$:open #1,"b:users":ln=1:r=0
ploop
	position #2,y,z:input #2,t$\l:if t$="" goto pend
	position #1,128,l:input #1,d1$,d2$\d3$\d4$,d5$
	position #1,128,l,70:read #1,ram,58
	setint(1):if mm=2 addint(es$)
	if ln<>1 goto skp.hdr
	if r and (s=0) print "Press any key to continue";:gosub get
	if r print #s,sc$;
	print #s,'
**  GBBS "Pro" Userlist  -  Version 1.3  -  List Sorted By: ';
	if a=1 print #s,"User Name     ";
	if a=2 print #s,"User Number   ";
	if a=3 print #s,"Password      ";
	if a=4 print #s,"Phone Number  ";
	if a=5 print #s,"Last Date on  ";
	if a=6 print #s,"Security level";
	r=1:print #s,'  **
[Name]                     [Phone]    [User] [Pass]    [Sec]    [Last]  [Time]
[Alias]                    [Number]   [Numb] [Word]    [Lvl]    [Call] [Limit]'
	print #s,""
skp.hdr
	print #s,left$(d3$+chr$(32,25),25);ph$;right$("     "+str$(l),6)"-";
	if pa print #s,pa$;:else print #s,"********";
	print #s,"  ";:for x=1 to 8:print #s,flag(x);:next
	print #s,"  "when$;right$("    "+str$(nibble(5)*10),4)
	z=z+1:ln=ln+1:if ln>nl:ln=1
	if (mm=2) and (key=27):mm=0
	if key flag=0 goto ploop
pend
	close:setint(""):if s=0 print \"Press any key to continue";:gosub get
	print #s,sc$;:move ram2,58 to ram:return

pterm
	move ram2,58 to ram:close:setint("")
terminate
	l1$="a:main.seg":l2$="term1"
link
	open #1,"b:trace":append #1:print #1,l1$,l2$:link l1$,l2$

edaccess
	gosub showtime:print iv$"[Access]"no$" "iv$"[Q]"no$"uit, V)iew, E)dit";
	l1$=cr$+es$+"QVE":gosub getone
	if i$="Q" or i$=cr$ or i$=es$ print "Quit":return
	push edaccess:if i$="E" print "Edit":goto accessed
	print "View"\:open #1,"b:data2":for l=0 to 16
	position #1,32,l:input #1,a$:position #1,32,l+17:input #1,b$
	print right$(sp$+str$(l),2)". "left$(a$+chr$(32,32),32)"  ";
	print right$(sp$+str$(l+17),2)". "b$:next
	position #1,32,34:input #1,a$:print chr$(32,38)"34. "a$:close:return

accessed
	print \"Edit flag #";:ix=2:gosub input2:if i$="" return
	l=val(i$):if (l<0) or (l>34) print \iv$"Invalid flag"no$;g$:goto accessed
	open #1,"b:data2":position #1,32,l:input #1,a$
acc.1
	print right$(" "+str$(l),2)". "a$
	print " ";:ix=3:gosub input:if len(i$)>31 print '
Entry too long.. Try again..'\:goto acc.1
	if i$<>"" goto setflag
	print \"Zero this flag?";:yn=1:es=1:gosub getyn:if i$="N" return:else i$=""
setflag
	if len(i$)<31:i$=i$+cr$:if len(i$)<31:i$=i$+chr$(32,31-len(i$))
	position #1,32,l:print #1,i$:close:goto accessed

showtime
	ty=clock online:tx=clock-ty:tx$=""
	if ty>3599:tx$=right$("0"+str$(ty/3600),2)+":":ty=(ty mod 3600)
	tx$=tx$+right$("0"+str$(ty/60),2)+":"+right$("0"+str$(ty mod 60),2)
	if exec or (clock=0) goto d.time
	tx$=tx$+"-"
	if tx>3599:tx$=tx$+right$("0"+str$(tx/3600),2)+":":tx=(tx mod 3600)
	tx$=tx$+right$("0"+str$(tx/60),2)+":"+right$("0"+str$(tx mod 60),2)
d.time
	print:if td print "["tx$"] ";
	return

getyn
	print " (";:l1$="YN":if yn=2 print iv$"[Y]"no$;:l1$=l1$+cr$:else print "y";
	print "/";:if yn=1 print iv$"[N]"no$;:l1$=l1$+cr$:else print "n";
	print ")";:if es>0:l1$=l1$+es$
	gosub getone:l1$=i$:if (i$=es$) and (es>0):i$=mid$("NY",es,1)
	if (i$=cr$) and (yn>0):i$=mid$("NY",yn,1)
	es=0:yn=0:if l1$=es$:es=1:print "Esc":return
	if i$="Y" print "Yes":else print "No"
	return

getone
	print ": ";
getonex
	gosub get.mac:cx=cx+1:if (mm=1) and (i$=g$) gosub savemac
	if instr(i$,l1$) goto get2
	goto getonex

get
	print ": ";:gosub get.mac:cx=cx+1
get2
	if mm=1 print #10,i$;:if mark(10)>126 goto savemac
	return

input
	print " -> ";
input2
	free:if mm<>2 goto input2a
	if key=27 get i$:mm=0:goto input2a
	input #10,i$:print i$:goto input3
input2a
	if ix=-1 input i$
	if ix=0 input @0 i$
	if ix=1 input @1 i$
	if ix=2 input @2 i$
	if ix=3 input @3 i$
	if ix=4 input @4 i$
input3
	cx=cx+len(i$)+1:ix=-1:if mm<>1 return
	if mark(10)+len(i$)<127 print #10,i$:else goto macsv
	if mark(10)<127:return
macsv
	print g$;
savemac
	open #2,"b:macros":position #2,128,un:write #2,-18816,128:close #2
	mm=0:print g$;:return

get.mac
	free:if mm<>2 get i$:return
	if key=27 get i$:mm=0:goto get.mac
	mm=peek(mark(10)-18816):if mm=0 goto get.mac
	mark(10)=mark(10)+1:i$=chr$(mm):mm=2:if mark(10)>126:mm=0
	return
