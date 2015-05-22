;===============================================================================
;  utils.asm
;===============================================================================

@CODE
                    BRA     setup

;  Puts the machine in abort state, this routine must be called (BRS)
doAbort :           PULL    R1                             ;  ip
                    LOAD    R2    [GB+recoveryAddress]     ;  load the initial IP address
                    PUSH    R2                             ;  new ip
                    RTS                                    ;  return to abort section directly

;  Increments the white discs counter by 1
incWhiteDiscs :     PUSH    R0                             ;  save the register to the stack
                    LOAD    R0    [GB+whiteCounter]        ;  read the white discs counter
                    CMP     R0    99                       ;  if whiteCounter < 99
                    BLT     incWhiteDiscs_inc              ;    inc the value
                    LOAD    R0    0                        ;  else, zero it
                    BRA     incWhiteDiscs_ret              ;    and return
incWhiteDiscs_inc : ADD     R0    1                        ;  increase the counter
incWhiteDiscs_ret : STOR    R0    [GB+whiteCounter]        ;  save the counter
                    PULL    R0                             ;  cleanup used registers
                    RTS                                    ;  return

;  Increments the black discs counter by 1
incBlackDiscs :     PUSH    R0                             ;  save the register to the stack
                    LOAD    R0    [GB+blackCounter]        ;  read the white discs counter
                    CMP     R0    99                       ;  if blackCounter < 99
                    BLT     incBlackDiscs_inc              ;    inc the value
                    LOAD    R0    0                        ;  else, zero it
                    BRA     incBlackDiscs_ret              ;    and return
incBlackDiscs_inc : ADD     R0    1                        ;  increase the counter
incBlackDiscs_ret : STOR    R0    [GB+blackCounter]        ;  save the counter
                    PULL    R0                             ;  cleanup used registers
                    RTS                                    ;  return

;  Param in R1, steps of 5.5 ms each
delay:              PUSH    R1                             ;  save register
                    STOR    R1    [GB+customTimer]         ;  customTimer = delay parameter
delay_check :       CMP     R1    0                        ;  if custom timer value is zero
                    BEQ     delay_return                   ;    goto end
                    LOAD    R1    [GB+customTimer]         ;  else, reload the custom timer value
                    BRA     delay_check                    ;  and reloop
delay_return :      PULL    R1                             ;  cleanup registers
                    RTS                                    ;  return
@END
