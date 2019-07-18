            LST   OFF
            TR
            TR    ADR
*-------------------------------
* Clock Driver Header Block
*-------------------------------
* Revised Date: 08/01/87
*-------------------------------
*
* driver load info
*
* $0800 = header block                  ;offset
* $0a00 = Thunder/Timemaster            ;2
* $0b00 = A.E. Serial Pro               ;3
* $0c00 = SMT No Slot clock             ;4
* $0d00 = //c System Clock              ;5
* $0e00 = Apple //gs Clock              ;6
* $0f00 = A.E. Ultra Clock              ;7
* $1000 = prodos compatible             ;8
* $1100 = Mountain Clock                ;9
* $1200 = Versacard                     ;a
* $1300 = no clock in system            ;b

            rel
            dsk   rel/clocks.hdr

            org   $800

clocks      hex   0201
            asc   'Thunderclock Compatable       '
            hex   0201
            asc   'A.E. Timemaster II H.O.       '
            hex   0301
            asc   'A.E. Serial Pro               '
            hex   8401
            asc   'SMT No Slot Clock             '
            hex   0501
            asc   'A.E. //c System Clock         '
            hex   8601
            asc   'Apple //GS built-in clock     '
            hex   8701
            asc   'A.E. Ultra Clock              '
            hex   8801
            asc   'ProDOS Compatible Clock       '
            hex   0901
            asc   'Mountain Hardware Clock       '
            hex   0a01
            asc   'Prometheus Versacard          '
            hex   8b01
            asc   'No Clock in System            '

            hex   0000
            ds    \

