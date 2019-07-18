; **********************
;    GBBS "Pro" V:1.4
;  By L & L Productions
;     Copyright 1987
; **********************

; maintenance segment rev a - 1/14/88

	public userlist

	cls:kill "system/sys.maintenance"
	f$="system/idl.node"+str$(node):create f$
	z=0:for x=1 to nn:f$="system/idl.node"+str$(x)
	if ~exist(f$):z=1
	next x:if ~z goto start

;	print node"\n"z"\n"x
;	get i$
	goto start

	x$=inverse$+"DO NOT INTERRUPT"+normal$
	print @(40-len(x$)/2),10 x$
	x$="This node is idle until all maintenance for the night"
	print @(40-len(x$)/2),20 x$
	x$="has been completed"
	print @(40-len(x$)/2),21 x$

	f$="system/sys.maintenance"
wait
	if exist(f$):for x=1 to 1000*node:next x:goto finish
	for x=1 to 5000*node:next x:goto wait

start
; gosub boards
	if mid$(ct$,4,2)="01" gosub purge
	create "system/sys.maintenance"

finish
	cls:ct=1:ct$=da$:gosub data.write
	for x=1 to nn:f$="system/idl.node"+str$(x):kill f$:next x
; poke 2053,77
	chain "program/logon.seg2","start1"

filebkup
	print "       Now making data file backups"
	kill "system2/sys.data.bk":kill "system2/sys.data1.bk"
	kill "system2/sys.users.bk"
	f$="system/sys.data":f2$="system2/sys.data.bk":gosub copy
	f$="system/sys.data1":f2$="system2/sys.data1.bk":gosub copy
	f$="system/sys.users":f2$="system2/sys.users.bk":gosub copy
	print "Done with file backups"
	return

boards
	print "\nDaily message maintenance now executing"
	open #1,"system/sys.data2":mark(1)=1120:input #1,ab
	print "Working on Board #";:for x=1 to ab:print x;
	position #1,128,x+8:input #1,bn$|bf$|b3,b4|bs,bs$|mb,kl,kb
	ready bf$
brd.1
	if msg(0)>mb kill #msg(kb):crunch:goto brd.1
	print chr$(8,len(str$(x)));:next x
	return

;	purge users from system...once a month

purge
	return

;	print a list of systems users

userlist
	gosub time
	print "\n["x$"][User List] Option (?=Help): ";
user1
	get i$
user2
	clear gosub:push userlist
	y=32
	if i$="1" print "Name":a=1:f$="system/srt.name":goto user3
	if i$="2" print "User":a=2:f$="system/srt.num":goto user3
	if i$="3" print "Pass":a=3:f$="system/srt.pw":y=64:goto user3
	if i$="4" print "Phone":a=4:f$="system/srt.ph":y=64:goto user3
	if i$="5" print "Date":a=5:f$="system/srt.date":y=64:goto user3
	if i$="6" print "Security":a=6:f$="system/srt.sec":y=64:goto user3
	if i$="7" print "Exit":pop:chain "program/system.seg"
	if i$="?" or i$="/" print "Menu":goto usermenu
	if i$="\n" or i$=" " goto user1
	a1++:print "\n"pr$"\""i$"\" is not a command":if a1<3 return

usermenu
	print cls'
1)  Print list sorted by name
2)  Print list sorted by user number
3)  Print list sorted by password
4)  Print list sorted by phone number
5)  Print list sorted by last date on
6)  Print list sorted by security level
7)  Return to main menu':return

user3
	print "\nShow passwords? (Y/"inverse$"[N]"normal$"): ";:get i$
	if i$="Y" print "Yes":pa=1:else print "No":pa=0
	print "\nOutput to printer? (Y/"inverse$"[N]"normal$"): ";:get i$
	if i$="Y" print "Yes":s=6:nl=58:else print "No":s=0:nl=15
	move ram,58 to ram2:on nocar goto user9
	z=1:print cls"\n":open #2,f$:if mark(2)=0 goto user5
	close:print "Reading data..."
	open #1,"system/users":kill f$:create f$:open #2,f$
	for l=1 to nu:position #1,192,l:input #1,d1$|d2$|d3$,d4$
	position #1,192,l,132:read #1,ram,60:t$="":if d1$="" goto user4
	t$=d2$+" "+d1$
	if a=2:t$=right$("    "+str$(l),4)
	if a=3:t$=mid$(" "+pa$+"       ",2,8)+t$
	if a=4:i$=right$(chr$(32,12)+ph$,12)
	if a=4:t$=left$(i$,3)+"-"+mid$(i$,5,3)+"-"+right$(i$,4)+t$
	if a=5:t$=right$(when$,2)+"/"+left$(when$,5)+t$
	if a=6:i$="":for x=1 to 34:i$=i$+str$(flag(x)):next x:t$=i$+t$
	position #2,y,z:print #2,t$"\n"l:z++
user4
	next l
user5
	close:z=1:print "Sorting...";:overlay "rndsort.128",f$,y,z
	print "Printing...":z=1:open #2,f$:open #1,"system/users":ln=1:r=0
user6
	position #2,y,z:input #2,t$|l:if t$="" goto user8
	position #1,192,l:input #1,d1$|d2$|d3$,d4$
	position #1,128,l,132:read #1,ram,60
	setint(1):if ln<>1 goto user7
	if r & (s=0) print "Press any key to continue..:";:get i$
	if r print #s,sc$;
	print #s,"\n**   LLUCE Userlist  -  Version 1.0  -  List Sorted By: ";
	if a=1 print #s,"User Name     ";
	if a=2 print #s,"User Number   ";
	if a=3 print #s,"Password      ";
	if a=4 print #s,"Phone Number  ";
	if a=5 print #s,"Last Date on  ";
	if a=6 print #s,"Security level";
	r=1:print #s,'   **
[Name]                     [Phone]    [User] [Pass]    [Sec]    [Last]  [Time]
[Alias]                    [Number]   [Numb] [Word]    [Lvl]    [Call] [Limit]'
	print #s,""
user7
	print #s,left$(d3$+chr$(32,25),25);ph$;right$("     "+str$(l),6)"-";
	if pa print #s,pa$;:else print #s,"********";
	print #s,"  ";:for x=1 to 8:print #s,flag(x);:next x
	print #s,"  "when$;right$("    "+str$(nibble(5)*10),4)
	z++:ln=ln+1:if ln>nl:ln=1
	if (mm=2) & (key=0x1B):mm=0
	if key flag=0 goto user6
user8
	close:setint("")
	if s=0 print "\n"pr$"Press any key to continue..:";:get i$
	print #s,sc$;:move ram2,58 to ram:chain "program/system.seg"
user9
	move ram2,58 to ram:close:setint("")
	chain "program/main.seg","term1"

;	read data file

data.read
	open #1,"system/sys.data"
	input #1,c1,ct,ct$,da$,wm$
	input #1,nu,mn,tm,nn|lu$
	close:return

;	write data file

data.write
	open #1,"system/sys.data"
	print #1,c1,ct,ct$,da$,wm$
	print #1,nu,mn,tm,nn"\n"lu$
	close:return

;	copy a file to another

copy
time
	return
