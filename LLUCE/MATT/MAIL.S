; [::::::::::::::::::::]
; [ ProTALK v2.1       ]
; [ Mail Segment       ]
; [ (c) 1988 Parik Rao ]
; [::::::::::::::::::::]
; [ Network Mods       ]
; [ By Matthew Montano ]
; [::::::::::::::::::::]

 public read
 public mail
 public net7

 on nocar goto link.term

read
 wr=0
 on nocar goto link.term
 gosub read0:goto link.back

read0
 on nocar goto link.term
 open #1,"g:mail."+str$(un):a=mark(1):Close
 if a print \\"[Error]:No mail waiting!":return
 ready "g:mail."+str$(un)
 print:print
read1
 setint(1)
 for x=1 to msg(0):input #msg(x),t,t$,t1$\t2$,t3$,t1,t4$
 print "#"right$("00"+str$(x),2)"  --  From  :"left$(t1$+chr$(32,20),20)" ";
 print "   Subj :"left$(t$+chr$(32,20),20)
 next
 setint("")
read2
 print \\"[Input]:Start at which message [<cr>=quit][->";:input @3 i$
 if i$="" gosub purge:return
 z=val(i$):if (z<1) or (z>msg(0)) print \\"[Error]:Does not exist!":goto read2
 z=z-1:if z<0:z=0
read3
 z=z+1
 if z>msg(0) goto purge
 input #msg(z),t,t$,t1$\t2$,t3$,t1,t4$
 setint(1)
 print \chr$(95,79)\
 a$="Awaiting Reply"
 a=instr("!",t4$):b=instr("@",t4$):if aorb a$="Networked"
 print "[:.From....:] "t1$
 if instr("!",t4$) or instr("@",t4$) print "[:.From....:] "t4$:a$="Networked"
 print "[:.Subject.:] "t$
 print "[:.Letter..:] "z" of "msg(0)
 print "[:.Date....:] "t2$"  "t3$
 print "[:.Status..:] ";
 if t1=1:a$="Certified"
 if t1=2:a$="Already Read"
 if t1=3:a$="Post Office"
 print a$
 print chr$(95,36)"Message"chr$(95,36)\\
 copy #6
 print chr$(95,79)
 setint("")
 if t1=2 goto read4
 if t1<>1 goto read3b
 if not info(5) goto read3a
 print \"[Input]:Send Certificate? ";:gosub getkey
 if i$="N" print "No!":t1=0:else print "Yes!"
read3a
 if t1=1 gosub certify
read3b
 input #msg(z),t,t$,t1$\t2$,t3$,t1,t4$:edit(0):copy #6,#8
 t1=2:g=msg(z)
 kill #msg(z):update
 print #msg(z),t,t$,t1$\t2$,t3$,t1,t4$:copy #8,#6:msg(z)=g:update
read4
 if i$="+" goto read3
 print \\"[Mail Level]:Command? ";
read5
 gosub getkey
 if i$=chr$(13) or i$="N" or i$="+" print "Next":goto read3
 if i$="D" print "Dump Mail":i$="+":goto read3
 if i$="A" print "Auto-Reply":wr=1:sb$=t$:gosub reply:goto read4
 if i$="Q" print "Quit":gosub purge:return
 if i$="K" print "Kill":gosub kill:goto read4
 if i$="F" print "Forward":gosub forward:goto read4
 if i$="R" print "Reread":z=z-1:goto read3
 if i$="?" print "Menu":f$="b:mail.mnu2":gosub show.file:goto read4
 goto read5

reply
 a=instr("!",t1$):b=instr("@",t1$):if a or b goto net3
reply1
 if t=0 print \\"[Error]:Unknown User!":return
 y=un:fr$=a3$
 print \\"[:.From....:] "a3$;:if not info(5) print:goto reply2
 print chr$(8,(len(a3$)));:input @3 i$:if i$<>"":fr$=i$:y=0
reply2
 if t$:if left$(t$,3)<>"Re:":sb$="Re:"+t$
 print "[:.Subject.:] "sb$;chr$(8,(len(sb$)));:input @3 i$
 if i$<>"":sb$=i$
 print "[:.Date....:] "date$"  "time$\
 close:ready "      ":f$="g:mail."+str$(t):open #1,f$:a=mark(1):close
 if a gosub msg
 st=0
 print \"[Input]:Do you wish to send via certified mail? ";:gosub getkey
 if i$<>"Y" print "No!!":else print "Yes!":st=1
 print \"[Input]:Do you wish to Xmodem your message? ";:gosub getkey
 if i$<>"Y" print "No!!":goto reply2a:else gosub up.xmdm
 goto reply3
reply2a
 edit(0)
reply2b
 Gosub editor
reply3
 if not edit(2) return
 print \"[Wait]:Saving Message...";
 t4$="":ready f$
 print ".";
 c=msg(0)+1:print #msg(c),y,sb$,fr$\date$,time$,st,t4$
 copy #8,#6
 print ".";
 update:open #1,"g:mail."+str$(un):a=mark(1):close
 if not a ready "g:mail."+Str$(un)
 print ".Done!":return

purge
 print \\"[Input]:Delete all your mail? ";:gosub getkey
 if i$<>"Y" print "No!!":return
 print "Yes!!":ready "   ":close
 f$="g:mail."+str$(un):kill f$:return

kill
 print \\"[Input]:Delete THIS letter? ";:gosub getkey
 if i$<>"Y" print "No!!":return
 print "Yes!!":kill #msg(z):crunch:update:print \\"[Note]:Message Deleted."
 return

forward
 input @3 \\"[Input]:To who (user #) :"i$
 a=val(i$):if (a<1) or (a>nu) print \\"[Error]:Invalid User!!":return
 f$="g:mail."+str$(a):open #1,f$:b=mark(1):close
 if b gosub msg
 ready "g:mail."+str$(un)
 input #msg(z),y,y$,y1$\y2$,y3$,st,t4$:edit(0):copy #6,#8
 t=a:fr$=a3$:y=un:sb$="Forwarded"
 print \"[Wait]:Saving Message...";
 ready f$
 print ".";
 c=msg(0)+1:print #msg(c),y,sb$,fr$\date$,time$,st,t4$
 print #6,"<-> A Forwarded Letter <->"
 print #6,\"[:..Originally From..:] "y1$"  @"y4$
 print #6,"[:..Subject..........:] "y$
 print #6,"[:..Date & Time......:] "y2$"  "y3$\\
 copy #8,#6
 print ".";
 update
 ready "g:mail."+str$(un) 
 print ".done!"
 return

link.back
 ae=0:link "a:main.seg","fromsys"

link.term
 link "a:main.seg","term1"

msg
 kill f$:create f$:open #1,f$:ed=edit(5):fill ed,255,0:poke ed,4:poke ed+1,4
 write #1,ed,2:fill ed,255,0:for xz=1 to 4:write #1,ed,255:next:write #1,ed,10
 close #1:return

mail
 wr=0
 on nocar goto link.term
 print \\"[Mail Level]:Command? ";
mail2
 gosub getkey
 if i$="?" print "Menu":f$="b:mail.mnu":gosub show.file:goto mail
 if i$="P" print "Purge Mail":gosub purge:goto mail
 if i$="R" print "Read Mail":a=0:ready "   ":close:gosub read0:goto mail
 if i$="S" print "Send Mail":gosub send:goto mail
 if i$="Q" print "Quit":goto link.back
 if i$="N" print "Net Stations":gosub stats:goto mail
 if i$="B" print "Bulk Mailing":gosub bulk:close:goto mail
 if i$="E" print "Edit OutGoing Mail":gosub edit:goto mail
 if i$="L" print "List Users with mail":Gosub u.list:goto mail
 goto mail2

show.file
 setint(1):copy f$:setint(""):return

editor
 print sc$'
 ____________________________________________________________________________
|                                                                            |
| Enter Message Now                                               .S to Save |
|____________________________________________________________________________|'
 aa=clock(2):clock(2)=0:edit(1):clock(2)=aa:return

getkey
 s1=y:s2=q:y=0
get2
 q=key(0):if (q>96) and (q<123):q=q-32
 if q<>0:i$=chr$(q):y=s1:q=s2:return
 y=y+1
 if y=1500 print chr$(7,10);:goto get2
 if y=3000 print \"Timeout.  Bye...":goto link.term
 goto get2

u.list
 y=0:if not info(5) goto u.list1
 print \\"[Input]: Dump to printer? ";:gosub getkey
 if i$="Y" print "Yes!":y=5:else print "No!"
u.list1
 print #y,'
 ____________________________________________________
|     |                      |                       |
| ### | Name                 | Last On               |
|_____|______________________|_______________________|
|     |                      |                       |'
 setint(""):setint(1)
;MODIFY THIS________________________________________________________________
 close:open #2,"b:users":for x=1 to nu
 open #1,"g:mail."+str$(x):a=mark(1):Close #1
 if a goto u.list2
 if key(1):x=nu:goto u.list2
 position #2,512,x:input #2,d3$,d4$,d5$
 if d3$="" goto u.list2
 position #2,512,x,150:input #2,f1$,f2$,f3$\f4$,f5$,f6$\f7$,f8$,f9$
 print #y,"| "right$("000"+str$(x),3)" | "left$(d3$+chr$(32,20),20)" | ";
 print #y,f8$"  "f9$" |"
u.list2
 next:close
 setint("")
 print #y,"|_____|______________________|_______________________|"
 return

send
 on nocar goto link.term
 input @3 \\"[Input]:Enter User Number, Name, <N>et, or <cr> to Quit :"i$
 if i$="N" or i$="n" goto nets
 if i$="" return
 a=val(i$):if not a gosub send2
 if (a<1) or (a>nu) return
 move ram,64 to ram2
;MODIFY THIS!____________________________________________________________
 open #1,"b:users":position #1,128,a
 input #1,d1$,d2$\d3$\d4$,d5$:position #1,128,a,70:read #1,ram,58
 if d3$="" close:move ram2,58 to ram:return
 print \\"[Input]:Send mail to "d3$" ("a") , last on _"when$"_  :";
 close:move ram2,58 to ram
 gosub getkey
 if i$<>"Y" print "No!!":return
 print "Yes!!"
 t1$="":t4$=ne$:t=a:sb$="":goto reply

send2
;MODIFY THIS______________________________________________________________
 open #1,"b:users"
 setint(1):a=0
 for x=1 to nu
 if key(1):x=nu:setint(""):goto send3
 position #1,128,x:input #1,d1$,d2$\d3$\d4$,d5$
 if d3$=i$:a=x:x=nu:close:setint("")
send3
 next
 if a>0 return
 close
 setint("")
 print \\"[Error]:User not found."\
 pop:return

edit
 print \\"[Input]:Enter Users Name/User # whose mail you have already sent"
 print "        and wish to edit  :";:input @3 i$
 if i$="" return
 a=val(i$):close:ready "   ":rz=a
 open #1,"g:mail."+str$(a):z=mark(1):close
 if z print \\"[Error]:User has no mail!!":return
 ready "g:mail."+str$(a)
 for x=1 to msg(0)
 edit(0)
 input #msg(x),t,t$,t1$\t2$,t3$,t1,t4$
 if (t<>un) and (not info(5)) next:close:ready "   ":return
 print \\"Subject :"t$
 print "From    :"t1$
 print "Date    :"t2$"  "t3$\\
 print "Edit This one? ";:gosub getkey
 if i$<>"Y" print "No!":next:return
 else print "Yes!":w=a:a=x:x=msg(0):next:close
 print \\"Subject               :"t$;chr$(8,(len(t$)));:input @3 i$
 if i$<>"":t$=i$
 print   "From                  :"t1$;:if info(5) print chr$(8,(len(t1$)));
 if info(5) input @3 i$:if i$<>"":t1$=i$:else print
 print
 copy #6,#8
 t=un
 gosub editor
 if not edit(2) gosub edit2
 print \\"[Wait]:Saving Message...";
 a=rz
 kill #msg(a):update
 print ".";
 print #msg(a),t,t$,t1$\date$,time$,st,t4$
 copy #8,#6
 print ".";
 update
 print ".Done!"
 return

edit2
 if w=1 pop:return
 print \\"[Error]:You have aborted the process.  Do you wish to DELETE"
 print "        the entire message? ";:gosub getkey
 if i$<>"Y" print "No!":pop:return
 print "Yes!"\\"[Wait]:Deleting Message...";
 kill #msg(a):print ".";
 crunch:print ".";:update
 u=msg(0):if not u ready "   ":close:kill "g:mail."+str$(w)
 print ".done!":pop:return

stats
 close
 print \\"Listing of paths file                                    "
 print "---------------------------------------------------------"\
 z=0:open #1,"g:paths":setint(1) 
stat2
 copy #1
stat3
 setint("")
 close
 print \\"Press a key to continue...";:input @3 i$
 return

up.xmdm
 print \\"Xmodem: (P)roDOS, (S)tandard, (D)os 3.3  :";:gosub getkey:z=0
 if i$="P" print "ProDOS":z=1
 if i$="D" print "Dos 3.3":z=2
 if i$="S" print "Standard":z=3
 if not z return
 z=z*(z<>3):print \"Ready to Receive..."
 f1$="h:u":use "b:x.up",z,f1$
 close:edit(0):copy f1$,#8
 if not edit(2) print \\"[Note]:Message aborted!":return
 print \\"[Wait]:Checking Message..."edit(2)" bytes...";:z=0
up2
 open #1,f1$
up3
 if eof(1) goto up4
 z=z+1:input #1,i$
 if left$(i$,2)=".X" edit(0):close:goto die
 if not (z mod 5) print ".";
 goto up3
up4
 print ".done!"\\
 close
 kill f1$:edit(1)
 return

die
 create "b:hack":open #1,"b:hack":append #1
 print #1,\\"-Hack Attempt-"
 print #1,"Name         ->"a3$"   ("un")"
 print #1,"Reason       ->   <.X> bug-attempts..."
 close
 return

bulk
 if flag(37) and (not info(5)) print \"[Error]:Bulk Prohibited.":return
 f=0:f1=3
 if flag(5):f1=10
 if flag(10):f1=20
 if flag(19):f1=50
 if flag(33):f1=0
 if flag(34):f1=0
 kill "h:temp":create "h:temp":open #1,"h:temp"
bulk1
 input @2 \"[Input]:Send Bulk Mail To (User Number/Name/<cr>=Quit) :"i$
 if (i$="") and (f=0) return
 if i$="" goto bulk3
 a=val(i$):b=len(i$):if (b<3) and (not a) goto bulk1
 if a goto bulk2
 open #2,"b:users":for x=1 to nu:position #2,128,x:input #2,d1$,d2$\d3$\d4$,d5$
 if d3$=i$:a=x:x=nu:next:close #2:goto bulk2
 next
 close #2
 goto bulk1
bulk2
 open #2,"b:users":position #2,128,a:input #2,d1$,d2$\d3$\d4$\d5$:close #2
 print \"Send to        :"d3$"          ? ";:gosub getkey
 if i$<>"Y" print "No":goto bulk1
 print "Yes!"
 f=f+1
 if f1<>0:f1=f1-1:if f1=0 print \"[Error]:Bulk Mail Limit Exceeded!":flag(37)=1:return
 print #1,a
 goto bulk1
bulk3
 close
 fr$=a3$
 print \"[:..From....:] "fr$;
 if info(5) print chr$(8,(len(fr$)));:input @3 i$:if i$<>"":fr$=i$
 if fr$=a3$:y=un:else y=0
 input @3 "[:..Subject.:] "sb$
 if sb$="":sb$="Nothing Particular"
 print "[:..Date....:] "date$"  "time$
 print \"[Bulk]:Are you SURE you wish to continue? ";:gosub getkey
 if i$<>"Y" print "No!":return
 print "Yes!"\
 edit(0):gosub editor:print \\"[Wait]:Bulk Mailing...";
 kill "h:temp1":create "h:temp1":open #1,"h:temp1":copy #8,#1:close:edit(0)
 mk=0:for xz=1 to f
 open #1,"h:temp":mark(1)=mk:input #1,a:mk=mark(1):close #1
 f$="g:mail."+str$(a):open #1,f$:b=mark(1):close #1
 if b gosub msg
 open #1,"h:temp1":edit(0):copy #1,#8:close #1
 ready f$
 c=msg(0)+1:print #msg(c),y,sb$,fr$\date$,time$,0,t4$
 copy #8,#6:update:ready "   "
 print ".";
 next
 close
 print ".Done!!"\\
 return

certify
 f$="g:mail."+str$(t):open #1,f$:rt=mark(1):close
 if rt gosub msg
 print \"[Wait]:Sending Certification...";
 st=3:sb$="Certified Mail Reciept":fr$="The Post Office":y=un:edit(0)
 print ".";
 print #8,\"Your message to "a3$" ("un"), has been recieved on "date$"  "time$\
 print ".";
 ready f$
 print ".";
 c=msg(0)+1:print #msg(c),y,sb$,fr$\date$,time$,st,t4$
 copy #8,#6
 print ".";
 update
 ready "g:mail."+Str$(un)
 print ".Done!"
 return

nets
net1
net2
net3
net4
 input @3 \"[Input]:Enter Network Address of User :"i$
 if i$="" return
 if len(i$)<3 return
 ti$=i$:a9$=a3$:i$=a9$:gosub lcase:a9$=i$
net4.01
 a=instr(" ",a9$)
 if a:a9$=left$(a9$,(a-1))+"."+mid$(a9$,a+1):goto net4.01
 y=un:fr$=a9$
 print \\"[:.From....:] "sn$"!"a9$;:if not info(5) print:goto net4.1
 print chr$(8,(len(sn$+"!"+a9$)));:input @3 i$:if i$<>"":fr$=i$:y=0
 fr$=fr$+" "+date$+" "+time$:ft$=a9$+"@"+sn$+" ("+a3$+")"
net4.1
 print "[:.Subject.:] ";:input @3 sb$
 if sb$="" return
 print "[:.Date....:] "date$"  "time$\
 f$="g:mail.net":open #1,f$:a=mark(1):close:if a gosub msg
 print \"[Input]:Do you wish to Xmodem your message? ";:gosub getkey
 if i$<>"Y" print "No!!":goto net5
 gosub up.xmdm
 goto net6
net5
 edit(0)
net6
 Gosub editor
 if not edit(2) return
 print \\"[Input]:Is everything correct? ";:gosub getkey
 if i$<>"Y" print "No!":return
 print "Yes!"
 print \"[Wait]:Saving Message...";
 ready f$
 print ".";
 dt$=date$+" "+time$:pp$="out"
 c=msg(0)+1:print #msg(c),fr$,ti$,sb$\dt$,pp$,ft$
 copy #8,#6
 print ".";
 update:close:open #1,"g:mail."+str$(un):a=mark(1):close
 if not a ready "g:mail."+Str$(un)
 print ".Done!"
 print \"[System]: Please wait, parsing.":print \"Linking..."
 e$="g:mail.net"
 link "a:parse"
net7
 use "b:xdos","d g:mail.net"
 return

lcase
 a$="":for l=1 to len(i$)
 y=asc(mid$(i$,l,1)):if (y>65) and (y<90):y=y+32
 a$=a$+chr$(y):next
 i$=a$
 return
