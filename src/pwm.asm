;===============================================================================
;  pwm.asm
;===============================================================================

@DATA
    pwmCheckingPort             DW    0     ;  the port that is to be checked
    pwmForcingPort              DW    0     ;  the port that forcefully sets the result to 3
    pwmForceBit                 DW    0     ;  the var for the force bit
    pwmUseCheckingPort          DW    0     ;  the var for checking if the checking port had at least one transition

@CODE
                    BRA     setup                     ;  goto setup()

;  Pulses a particular port using PWM. It is assumed that the timer will not overflow in the time a cycle of this routine runs.
;  R1 is the port to pulse, R2 is the percentage, R3 is the timeout (measured in iteration-counts), R4 is the port to check to interrupt execution (or zero)
;  R0 is a port that needs to get 0->1 at least once during the routine (if this port is zero, it is not taken into account)
;  R0 returrns the result:
;     FALSE if routine finished with timeout,
;     TRUE if the routine was interrupted by the port transition (1->0),
;     UNKNOWN if the forcing port was declared and did not change from 0->1
pwmOn :             STOR    R0    [GB+pwmForcingPort]     ;  forcingPort
                    STOR    R4    [GB+pwmCheckingPort]    ;  checkingPort
                    LOAD    R0    FALSE                   ;  make UseCheckingPort = 0
                    STOR    R0    [GB+pwmUseCheckingPort] ;  -//-
                    LOAD    R0    FALSE                   ;  make force bit = 0
                    STOR    R0    [GB+pwmForceBit]        ;  -//-
                    PUSH    R3                            ;  save the registers
pwmOn_while :       LOAD    R0    FALSE                   ;  in case iterationCounter == 0, the result should be FALSE
                    CMP     R3    FALSE                   ;  if (iterationCounter == 0)
                    BEQ     pwmOn_return                  ;    exit the routine
                    PUSH    R3                            ;  keep R3 (counter) in stack, to re-use R3 inside routine
pwmOn_checkPort1 :  LOAD    R0    [GB+pwmForcingPort]     ;  load forcing port from memory
                    CMP     R0    0                       ;  check if the port == 0
                    BEQ     pwmOn_checkPort2              ;    continue to the next port checking
                    PUSH    R1                            ;  save R1
                    LOAD    R1    R0                      ;  move the port to R1 to pass it as parameter
                    BRS     isInputOn                     ;  check if the port is on
                    CMP     R0    TRUE                    ;  if it is
                    BEQ     pwmOn_forceTrue               ;    set force bit
                    PULL    R1                            ;  cleanup saved register
                    BRA     pwmOn_checkPort2              ;  continue
pwmOn_forceTrue :   LOAD    R0    TRUE                    ;  load true value
                    STOR    R0    [GB+pwmForceBit]        ;  store to the variable
                    PULL    R1                            ;  cleanup saved register
pwmOn_checkPort2 :  LOAD    R4    [GB+pwmCheckingPort]    ;  load the checking port
                    CMP     R4    0                       ;  check if the port == 0
                    BEQ     pwmOn_portChecked             ;  that means that the port checking is to be skipped
                    PUSH    R1                            ;  save R1
                    LOAD    R1    R4                      ;  move the port to R1 to pass it as parameter
                    BRS     isInputOn                     ;  check if the port is on
                    CMP     R0    TRUE                    ;  if it is
                    BEQ     pwmOn_portOn                  ;    continue the cycle
pwmOn_portOff :     LOAD    R4    [GB+pwmUseCheckingPort] ;  load UseCheckingPort
                    CMP     R4    FALSE                   ;  if we should not check the port yet then
                    BEQ     pwmOn_portOn                  ;    go directly to portOn
                    PULL    R1                            ;  else: clean up stack before return
                    PULL    R3                            ;        stack cleanup continued (saved @pwm_while)
                    LOAD    R0    TRUE                    ;        result = true
                    BRA     pwmOn_return                  ;        now return
pwmOn_portOn :      LOAD    R4    [GB+pwmUseCheckingPort] ;  load UseCheckingPort
                    CMP     R4    TRUE                    ;  if we are checking the port normally, then
                    BEQ     pwmOn_portOn_f                ;    go directly to portOn_f
                                                          ;  R0 should still contain the result from previous isInputOn(CheckingPort)
                    STOR    R0    [GB+pwmUseCheckingPort] ;  if the port is on then we now can start using it's state
pwmOn_portOn_f :    PULL    R1                            ;  retrieve R1's original value
pwmOn_portChecked : LOAD    R0    [R5+TIMER]              ;  R0 = TimerValue
                    LOAD    R4    R0                      ;  R4 = TimerValue
                    SUB     R4    R2                      ;  R0 = TimerValue - Percentage
pwmOn_pulseOn :     CLRI    8                             ;  disable interrupt
                    BRS     setOutputOn                   ;  turn port on
pwmOn_pulseOn_1 :   CMP     R0    R4                      ;  if R0 <= R4
                    BLE     pwmOn_pulseOff                ;    do pulse off
                    LOAD    R0    [R5+TIMER]              ;  else get the latest timer value
                    BRA     pwmOn_pulseOn_1               ;  and reloop
pwmOn_pulseOff :    BRS     setOutputOff                  ;  turn port off
                    SUB     R4    50                      ;
                    ADD     R4    R2                      ;  R4 = prevTimerValue - (100 - n)
pwmOn_pulseOff_1 :  CMP     R0    R4                      ;  if R0 <= R4
                    BLE     pwmOn_reloop                  ;  then it is the end of this cycle - reloop
                    LOAD    R0    [R5+TIMER]              ;  else reload the timer value
                    BRA     pwmOn_pulseOff_1              ;  and reloop
pwmOn_reloop :      SETI    8                             ;  re-enable the timer interrupt
                    ;  force interrupt
                    LOAD    R0    0                       ;  R0 = 0
                    SUB     R0    [R5+TIMER]              ;  R0 = -TIMER
                    STOR    R0    [R5+TIMER]              ;  TIMER = TIMER+R0
                    PULL    R3                            ;  restore R3 from the stack (counter was saved there @pwmOn_while)
                    SUB     R3    1                       ;  iterationCounter--;
                    BRA     pwmOn_while                   ;  go back to top of loop
pwmOn_return :      BRS     setOutputOff                  ;  turn port off
                    LOAD    R4    [GB+pwmForcingPort]     ;  load checkingPort
                    CMP     R4    0                       ;  if checkingPort == 0
                    BEQ     pwmOn_return_f                ;    goto final part
                    LOAD    R4    [GB+pwmForceBit]        ;  load force bit
                    CMP     R4    TRUE                    ;  if (force bit == 1)
                    BEQ     pwmOn_return_f                ;    go to the final part
                    LOAD    R0    UNKNOWN                 ;  else force return value = unknown
pwmOn_return_f :    LOAD    R4    [GB+pwmCheckingPort]    ;  checkingPort
                    PULL    R3                            ;  cleanup the used registers
                    RTS                                   ;  return to caller
@END
