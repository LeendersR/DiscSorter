;===============================================================================
;  main.asm
;===============================================================================

@DATA

;  ================================= CONSTANTS =================================
    IOAREA                      EQU   -16   ;  address of the I/O-Area, modulo 2^18
    INPUT                       EQU   7     ;  position of the input buttons (relative to IOAREA)
    OUTPUT                      EQU   11    ;  relative position of the power outputs
    TIMER                       EQU   13    ;  address of the TIMER
    TRUE                        EQU   1     ;  const for true
    FALSE                       EQU   0     ;  const for false
    UNKNOWN                     EQU   3     ;  const for unknown state
    ABORTDISPLAYVALUE           EQU   0     ;  the value that is saved in the counters during abort state

;  ==== INPUTS
    REFLECTIONSENSOR            EQU   1     ;  input 0
    STACKSENSOR                 EQU   2     ;  input 1
    RIGHTEDGESENSOR             EQU   4     ;  input 2
    LEFTEDGESENSOR              EQU   8     ;  input 3
    PUSHERBUTTON                EQU   16    ;  input 4
    ABORTBUTTON                 EQU   64    ;  input 6
    STARTSTOPBUTTON             EQU   128   ;  input 7

;  ==== OUTPUTS
    REFLECTIONLAMP              EQU   1     ;  output 0
    STACKLAMP                   EQU   2     ;  output 1
    RIGHTLAMP                   EQU   4     ;  output 2
    LEFTLAMP                    EQU   8     ;  output 3
    BELTMOTORRIGHTDRIVER        EQU   16    ;  output 4
    BELTMOTORLEFTDRIVER         EQU   32    ;  output 5
    PUSHERMOTORDRIVER           EQU   64    ;  output 6

;  ==== DELAYS
    MS                          EQU   6        ;  ~6ms (5.5ms) per step
    REFLECTIONLAMPDELAY         EQU   500 / MS ; 500ms
    INTERRUPTLAMPDELAY          EQU   500 / MS ; 500ms

;  ==== TIMEOUTS
    DROPDISKTIMEOUT             EQU   200  ;  belt move right/left timeout
    PUSHDISKTIMEOUT             EQU   200  ;  pusher timeout
    RESETPUSHERTIMEOUT          EQU   200  ;  pusher resetting timeout

;  ==== SPEEDS / DUTY CYCLES
    DROPDISKDUTY                EQU   45    ;  x/50 duty cycle when moving the belt
    PUSHDISKDUTY                EQU   45    ;  x/50 duty cycle when pushing the disc
    RESETPUSHERDUTY             EQU   30    ;  x/50 duty cycle when resetting the pusher

;  ================================= VARIABLES =================================
    running                     DW    0     ;  machine running boolean
    whiteCounter                DW    0     ;  white discs counter
    blackCounter                DW    0     ;  black discs counter
    outputs                     DW    0     ;  outputs register cache
    entryPoint                  DW    0     ;  the entry point of the program
    recoveryAddress             DW    0     ;  the IP of the recovery section, filled in runtine, to avoid CODE segment address hardcoding
    abortState                  DW    0     ;  this is set to 1 by the "recovery" section in case the cpu boots from abort
    customTimer                 DW    0     ;  a custom countdown timer (MAX INT to ZERO), the steps are equal to 5.5 ms interval
    pendingStop                 DW    0     ;  this is TRUE in the case that stop was pressed

@INCLUDE "io.asm"
@INCLUDE "display.asm"
@INCLUDE "utils.asm"
@INCLUDE "pwm.asm"
@INCLUDE "machine_interface.asm"
@INCLUDE "isr.asm"

@CODE
                    BRA     setup                         ;  goto setup()

abortRecovery :     LOAD    R0    TRUE                    ;
                    STOR    R0    [GB+abortState]         ;  set abortState to true
                    BRA     setup_fromAbort               ;  skip original init

                    ;  Base Register (= GB = R6) is initialised automagically
                    ;  R5 initially contains the entry point of the program
setup :             STOR    R5    [GB+entryPoint]         ;  save the entry point (used also for the timer isr)
                    ADD     R5    abortRecovery           ;  add the relative address of the recovery section
                    STOR    R5    [GB+recoveryAddress]    ;  store the absolute address of the recovery section
                    LOAD    R5    IOAREA                  ;  initialise the IO base register
                    BRS     install_isr                   ;  install ISR and enable interrupt (timer overflow)
setup_fromAbort :   LOAD    R0    0                       ;  R0 = 0
                    STOR    R0    [GB+outputs]            ;  reset outputs variable
                    STOR    R0    [R5+OUTPUT]             ;  all outputs = 0
                    STOR    R0    [GB+whiteCounter]       ;  reset the white discs counter
                    STOR    R0    [GB+blackCounter]       ;  reset the white discs counter
                    STOR    R0    [GB+running]            ;  set machine state to stopped
                    LOAD    R0    [GB+abortState]         ;  load abortState var
                    CMP     R0    FALSE                   ;  if (!abortState)
                    BEQ     setup_final                   ;    goto final part of setup section
                                                          ;  else (wait for start/stop button)
setup_abortStop :   ;  if the machine is "stopped", this checks the "start button" forever
                    LOAD    R0    [GB+running]            ;  get the running state
                    CMP     R0    FALSE                   ;  if (!running)
                    BEQ     setup_abortStop               ;    keep waiting
                    LOAD    R0    FALSE                   ;
                    STOR    R0    [GB+running]            ;  cancel the running state (it is not actually running - it is an "abort cancelation"
                    STOR    R0    [GB+abortState]         ;  cancel the abort state
                    STOR    R0    [GB+pendingStop]        ;  clear pending stop flag
setup_final :       BRS     reset_mechanisms              ;  bring all mechanisms to initial position

main :              ;  if the machine is "stopped", this checks the "start button" forever
                    LOAD    R4    [GB+pendingStop]        ;  get the value of pendingStop
                    CMP     R4    FALSE                   ;  if there is not a pendingStop
                    BEQ     main_checkRunning             ;    continue as usually
                    LOAD    R4    FALSE                   ;  else, force values to zero
                    STOR    R4    [GB+pendingStop]        ;    -//-
                    STOR    R4    [GB+running]            ;    -//-
main_checkRunning : LOAD    R4    [GB+running]            ;  get the running state
                    CMP     R4    FALSE                   ;  if (!running)
                    BEQ     main_return                   ;    skip the code

                    BRS     isDiscAvailable               ;
                    CMP     R0    FALSE                   ;  if there is no disc left
                    BEQ     main_noDisc                   ;    goto main_noDisc

main_discFound :    BRS     moveOneDiscToBelt             ;  push a disc to the belt
                    BRS     isDiscWhite                   ;  scan if the placed disc is white
                    CMP     R0    FALSE                   ;  if it is not white
                    BEQ     main_blackDisc                ;    goto black disc procedure
main_whiteDisc :    BRS     dropDiscToTheLeft             ;  else drop disc to the left
                    BRA     main_discFoundEnd
main_blackDisc :    BRS     dropDiscToTheRight            ;  it is a black disc, so drop disc to the right
main_discFoundEnd : BRA     main_return                   ;  finished the "disc found" cycle
main_noDisc:        LOAD    R4    FALSE                   ;  set running = 0
                    STOR    R4    [GB+running]

main_return :       BRA     main                          ;  it is a main (infinite while) loop
@END
