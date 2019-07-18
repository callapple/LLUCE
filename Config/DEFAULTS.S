            LST   OFF
            TR
            TR    ADR
*-------------------------------
* Date: 12/1/89
*-------------------------------
* system defaults
*-------------------------------

            REL
            DSK   REL/DEFAULTS

TopBox      EXT
print       EXT
cls         EXT
get_cr      EXT
start       EXT

                              ; change system defaults
do_dflts    ENT
            JSR   TopBox
            JSR   print
            DB    1,2,27
            ASC   '- Edit System Defaults -'
            DB    1,4,5
            ASC   'Please refer to Appendix D of your user'
            ASC   ' manual for more information.'00
            JSR   cls

            JSR   print
            DB    1,10,10
            ASC   'code for editing the system defaults'
            ASC   ' will go here.'00

            JSR   get_cr
            JMP   start

