;===============================================================================
;  isr.asm
;===============================================================================

@DATA
    isrTimerSteps               EQU   55    ;  timer period (in 0.1ms steps) for interrupt

    isrCounter                  DW    0     ;  this gets a value from 0 to (incl) 182, used to choose updating display or buttons check
    startBtnPressed             DW    0     ;  keeps the state of the button when previously checked. Used for checking button complete presses


@CODE
                    BRA     setup                          ;  goto setup()

;  This is the interrupt service for the timer overflow INT
;     the (multiplexing) display and buttons will be updated 185 times per second
;     in total 185 times / second => 1000 / 185 = 5.46 ms period
;     that means 5.46 * 10 = 54.6 = 55 timer steps

isr :               LOAD    R4    [GB+customTimer]         ;  load the custom timer
                    CMP     R4    0                        ;  if timer is zero, nothing is to be done
                    BEQ     isr_checkCounter               ;  skip to the rest of the isr
                    SUB     R4    1                        ;  else, subtract 1
                    STOR    R4    [GB+customTimer]         ;  and save the variable
isr_checkCounter :  LOAD    R4    [GB+isrCounter]          ;  load the counter
                                                           ;  in all other occasions
isr_display :       BRS     updateDisplay                  ;  update led display
                    ;BRA     isr_return                     ;  done
isr_btn_check :     LOAD    R1    STARTSTOPBUTTON          ;
                    BRS     isInputOn                      ;  check if start/stop button is pushed
                    LOAD    R1    [GB+startBtnPressed]     ;  load previous state
                    CMP     R0    R1                       ;  check current and previous state
                    BLT     isr_btn1Released               ;  if ((current == FALSE) && (previous == TRUE)), goto btn released
                    BGT     isr_btn1Pressed                ;  if ((current == TRUE) && (previous == FALSE)), goto btn pressed
                    BRA     isr_btn2                       ;    else return to caller immediatelly
isr_btn1Pressed :   LOAD    R0    TRUE                     ;  write down that the button is pressed
                    STOR    R0    [GB+startBtnPressed]     ;  -//-
                    BRA     isr_btn2                       ;  return
isr_btn1Released :  LOAD    R0    FALSE                    ;  write down that the button is released
                    STOR    R0    [GB+startBtnPressed]     ;  -//-
isr_state1Invert :  LOAD    R0    [GB+running]             ;  load the running state of the machine
                    CMP     R0    FALSE                    ;  if it is off
                    BEQ     isr_state1On                   ;  set it on
isr_state1Off :     LOAD    R0    FALSE                    ;  else, set it to off
                    LOAD    R1    TRUE                     ;  also, set the pendingStop var
                    STOR    R1    [GB+pendingStop]         ;  -//-
                    BRA     isr_state1Ret                  ;  goto "save and return"
isr_state1On :      LOAD    R0    TRUE                     ;  set state to on
isr_state1Ret :     STOR    R0    [GB+running]             ;  save the new state
isr_btn2 :          LOAD    R1    [GB+running]             ;  load running
                    CMP     R1    FALSE                    ;  if it is not running
                    BEQ     isr_return                     ;    exit
                    LOAD    R1    ABORTBUTTON              ;
                    BRS     isInputOn                      ;  check if abort button is pushed
                    CMP     R0    TRUE                     ;  if it is, then
                    BEQ     isr_abort                      ;    handle it
                    BRA     isr_return
isr_abort :         PULL    R0                             ;  psw
                    PULL    R1                             ;  ip
                    LOAD    R2    [GB+recoveryAddress]     ;  load the initial IP address
                    PUSH    R2                             ;  new ip
                    PUSH    R0                             ;  original psw
isr_return :        CMP     R4    182                      ;  if the counter == 182
                    BEQ     isr_rtn_ZeroCount              ;    needs to be zeroed
                    ADD     R4    1                        ;  else, add 1 to the counter
                    STOR    R4    [GB+isrCounter]          ;    and save the variable
                    BRA     isr_return_f                   ;    done!
isr_rtn_ZeroCount : LOAD    R4    0                        ;  make counter = 0
                    STOR    R4    [GB+isrCounter]          ;  save the variable
isr_return_f :      LOAD    R0    0                        ;
                    SUB     R0    [R5+TIMER]               ;  R0 := -TIMER
                    ADD     R0    isrTimerSteps            ;  add steps
                    STOR    R0    [R5+TIMER]               ;  TIMER := TIMER+R0
                    SETI    8                              ;  enable timer overflow interrupt
                    RTE

;  Installs the timer overflow interrupt handler
install_isr :       PUSH    R0
                    PUSH    R1
                    LOAD    R1    [GB+entryPoint]          ;  get the program entry point
                    ADD     R1    isr                      ;  add the relative address of the interrupt handler
                    LOAD    R0    0                        ;  use zero base for indirect addressing
                    STOR    R1    [R0+16]                  ;  set the isr address
                    STOR    R0    [GB+isrCounter]          ;  initialize the counter with 0
                    SETI    8                              ;  enable timer overflow interrupt
                    ;  make timer = 0
                    LOAD    R0    0                        ;
                    SUB     R0    [R5+TIMER]               ;  R0 := -TIMER
                    STOR    R0    [R5+TIMER]               ;  TIMER := TIMER+R0
                    PULL    R1                             ;  cleanup registers
                    PULL    R0                             ;  cleanup registers
                    RTS                                    ;  return to caller
@END
