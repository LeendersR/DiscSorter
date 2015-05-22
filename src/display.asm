;===============================================================================
;  display.asm
;===============================================================================

@DATA
;  ================================= CONSTANTS =================================
    DSPDIG                      EQU   9     ;  relative position of the 7-segment display's digit selector
    DSPSEG                      EQU   8     ;  relative position of the 7-segment display's segments

;  ================================= VARIABLES =================================
    digitCounter                DW    0     ;  digit to be displayed counter (0 and 1 is for white, 2 and 3 for black)

@INCLUDE "hex7Seg.asm"

@CODE
                    BRA     setup

updateDisplay :     PUSH    R1                             ;  save contents of register R1
                    PUSH    R0                             ;  save contents of register R0
                    PUSH    R2                             ;  save contents of register R2

digitswitch :       LOAD    R2    [GB+digitCounter]        ;  load digitCounter into R2
                    CMP     R2    0                        ;  compare digitCounter with 0
                    BEQ     whitedigit1                    ;  if 0 branch to whitedigit1
                    CMP     R2    1                        ;  compare digitCounter with 1
                    BEQ     whitedigit2                    ;  if 1 branch to whitedigit2
                    CMP     R2    2                        ;  compare digitCounter with 2
                    BEQ     blackdigit1                    ;  if 2 branch to blackdigit1
                    CMP     R2    3                        ;  compare digitCounter with 3
                    BEQ     blackdigit2                    ;  if 3 branch to blackdigit2

whitedigit1 :       LOAD    R1    [GB+whiteCounter]        ;  load white disk count
                    MOD     R1    10                       ;  get in R1 the value of the first white digit
                    BRS     hex7Seg                        ;  branch to hex7Seg to fill in DSPDIG with a digit pattern
                    STOR    R0    [R5+DSPSEG]              ;  store digit pattern in the DSPSEG register
                    LOAD    R0    %010000                  ;  R0 := the bit pattern identifying first digit from the right
                    STOR    R0    [R5+DSPDIG]              ;  display the digit
                    BRA     updateDisplay_ret              ;  update digitCounter

whitedigit2 :       LOAD    R1    [GB+whiteCounter]        ;  load the white disk count
                    DIV     R1    10                       ;  get in R1 the value of the second white digit
                    BRS     hex7Seg                        ;  branch to hex7Seg to fill in DSPDIG with a digit pattern
                    STOR    R0    [R5+DSPSEG]              ;  store digit pattern in the DSPSEG register
                    LOAD    R0    %100000                  ;  R0 := the bit pattern identifying second digit from the right
                    STOR    R0    [R5+DSPDIG]              ;  display the digit
                    BRA     updateDisplay_ret              ;  update digitCounter

blackdigit1 :       LOAD    R1    [GB+blackCounter]        ;  load the black disk count
                    MOD     R1    10                       ;  get in R1 the value of the first black digit
                    BRS     hex7Seg                        ;  branch to hex7Seg to fill in DSPDIG with a digit pattern
                    STOR    R0    [R5+DSPSEG]              ;  store digit pattern in the DSPSEG register
                    LOAD    R0    %000001                  ;  R0 := the bitpattern identifying Digit 1 from the right
                    STOR    R0    [R5+DSPDIG]              ;  display the digit
                    BRA     updateDisplay_ret              ;  update digitCounter

blackdigit2 :       LOAD    R1    [GB+blackCounter]        ;  load the black disk count
                    DIV     R1    10                       ;  get in R1 the value of the second black digit
                    BRS     hex7Seg
                    STOR    R0    [R5+DSPSEG]              ;  store digit pattern in the DSPSEG register
                    LOAD    R0    %000010                  ;  R0 := the bitpattern identifying Digit 1 from the right
                    STOR    R0    [R5+DSPDIG]              ;  display the digit

updateDisplay_ret : CMP     R2    3                        ;  compare digitCounter with 3
                    BEQ     updateDisplay_zero             ;  make digitCouinter 0 again (we only have digits 0,1,2,3)

                    ADD     R2    1                        ;  increase the digitCounter
                    STOR    R2    [GB+digitCounter]        ;  store the new digitCounter in memory
                    BRA     updateDisplay_ret_f            ;  exit the method

updateDisplay_zero :LOAD    R2    0                        ;  reset R2 to 0 (we only have digits 0,1,2,3)
                    STOR    R2    [GB+digitCounter]        ;  store new digitCounter in memory

updateDisplay_ret_f:PULL    R2                             ;  restore contents of register R2
                    PULL    R0                             ;  restore contents of register R0
                    PULL    R1                             ;  restore contents of register R1
                    RTS                                    ;  return to calling method
@END
