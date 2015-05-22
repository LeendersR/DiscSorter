;===============================================================================
;  hex7Seg.asm
;===============================================================================

@CODE
                    BRA     setup

;  Routine hex7Seg maps a number in the range [0..15] to its hexadecimal
;  representation pattern for the 7-segment display.
;  R1 : contains the number to show, (0x0A for dash)
;  R0 : contains the resulting pattern
hex7Seg     :       BRS     hex7Seg_bgn                    ;  push address(tbl) onto stack and proceed at "bgn"
hex7Seg_tbl :       CONS    %01111110                      ;  7-segment pattern for '0'
                    CONS    %00110000                      ;  7-segment pattern for '1'
                    CONS    %01101101                      ;  7-segment pattern for '2'
                    CONS    %01111001                      ;  7-segment pattern for '3'
                    CONS    %00110011                      ;  7-segment pattern for '4'
                    CONS    %01011011                      ;  7-segment pattern for '5'
                    CONS    %01011111                      ;  7-segment pattern for '6'
                    CONS    %01110000                      ;  7-segment pattern for '7'
                    CONS    %01111111                      ;  7-segment pattern for '8'
                    CONS    %01111011                      ;  7-segment pattern for '9'
                    CONS    %00000001                      ;  7-segment pattern for '-'
hex7Seg_bgn:        AND     R1    %01111                   ;  set R0 = R0 MOD 16 , just to be sure...
                    LOAD    R0    [SP++]                   ;  set R1 = address(tbl) (retrieve from stack)
                    LOAD    R0    [R0+R1]                  ;  set R1 = tbl[R0]
                    RTS                                    ;  return to caller
@END
