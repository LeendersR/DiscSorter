;===============================================================================
;  machine_interface.asm
;===============================================================================

@CODE
                    BRA     setup

;  Returns whether the sensor currently detects a white disc
;  Result is stored in R0
isDiscWhite :       PUSH    R1                             ;  save registers
                    LOAD    R1    REFLECTIONLAMP           ;
                    BRS     setOutputOn                    ;  turn on the reflection lamp (color detector)
                    LOAD    R1    REFLECTIONLAMPDELAY      ;  lighting delay
                    BRS     delay                          ;  wait for the delay
                    LOAD    R1    REFLECTIONSENSOR         ;
                    BRS     isInputOn                      ;  read reflection sensor (color detector), result is put in R0
                    LOAD    R1    REFLECTIONLAMP           ;
                    BRS     setOutputOff                   ;  turn off the reflection lamp (color detector)
                    PULL    R1                             ;  cleanup the registers used
                    RTS                                    ;  return to caller

;  Returns whether a disc exists or not (under the stack)
;  Result is stored in R0
isDiscAvailable :   PUSH    R1                             ;  save registers
                    LOAD    R1    STACKLAMP                ;
                    BRS     setOutputOn                    ;  turn on the stack lamp
                    LOAD    R1    INTERRUPTLAMPDELAY       ;  lighting delay
                    BRS     delay                          ;  wait for the delay
                    LOAD    R1    STACKSENSOR              ;
                    BRS     isInputOn                      ;  read beam sensor, result is put in R0
                    CMP     R0    FALSE                    ;  if the port is off
                    BEQ     ida_on                         ;    means there is a disc
ida_off :           LOAD    R0    FALSE                    ;  else there is not
                    BRA     ida_return                     ;    and finish up
ida_on :            LOAD    R0    TRUE                     ;  return TRUE
ida_return :        LOAD    R1    STACKLAMP                ;
                    BRS     setOutputOff                   ;  turn off the stack lamp
                    PULL    R1                             ;  cleanup the registers used
                    RTS                                    ;  return to caller

;  Pushes disc from stack to belt.
moveOneDiscToBelt : PUSH    R0                             ;
                    PUSH    R1                             ;  save registers
                    PUSH    R2                             ;
                    PUSH    R3                             ;
                    PUSH    R4                             ;
modtb_start :       LOAD    R1    STACKLAMP
                    BRS     setOutputOn
                    LOAD    R0    STACKSENSOR              ;  forcing port = stack sensor
                    LOAD    R1    PUSHERMOTORDRIVER        ;  motor towards the left side
                    LOAD    R2    PUSHDISKDUTY             ;  duty cycle
                    LOAD    R3    PUSHDISKTIMEOUT          ;  (cycles) timeout
                    LOAD    R4    PUSHERBUTTON             ;  check on pusher sensor
                    BRS     pwmOn                          ;  run the pwm
                    CMP     R0    TRUE                     ;  if result is true
                    BEQ     modtb_return                   ;    goto return
                    CMP     R0    UNKNOWN                  ;  if result is unknown
                    BEQ     modtb_start                    ;    goto start again
                    BRS     doAbort                        ;  else (in case it is FALSE) means the timeout expired => reset to prevent damage
modtb_return :      LOAD    R1    STACKLAMP                ;  turn off lamp
                    BRS     setOutputOff                   ;  -//-
                    PULL    R4                             ;
                    PULL    R3                             ;
                    PULL    R2                             ;
                    PULL    R1                             ;  clean up registers used
                    PULL    R0                             ;
                    RTS                                    ;  return

;  Moves the belt motor to the left until the edge sensor is off or for ~2 seconds.
dropDiscToTheLeft : PUSH    R0                             ;
                    PUSH    R1                             ;  save registers
                    PUSH    R2                             ;
                    PUSH    R3                             ;
                    PUSH    R4                             ;
                    LOAD    R1    LEFTLAMP                 ;
                    BRS     setOutputOn                    ;  turn on the lamp of the left edge sensor
                    LOAD    R0    0                        ;  no forcing sensor
                    LOAD    R1    BELTMOTORLEFTDRIVER      ;  motor towards the left side
                    LOAD    R2    DROPDISKDUTY             ;  duty cycle
                    LOAD    R3    DROPDISKTIMEOUT          ;  (cycles) timeout
                    LOAD    R4    LEFTEDGESENSOR           ;  check on left sensor
                    BRS     pwmOn                          ;  run the pwm
                    CMP     R0    FALSE                    ;  if pwm timed out
                    BEQ     ddLeft_return                  ;    just exit
                    BRS     incWhiteDiscs                  ;  else one more white was thrown
ddLeft_return :     LOAD    R1    BELTMOTORLEFTDRIVER      ;  turn off motor
                    BRS     setOutputOff                   ;  -//-
                    LOAD    R1    LEFTLAMP                 ;  turn off lamp
                    BRS     setOutputOff                   ; -//-
                    PULL    R4                             ;
                    PULL    R3                             ;
                    PULL    R2                             ;
                    PULL    R1                             ;  clean up registers used
                    PULL    R0                             ;
                    RTS                                    ;  return
;  Moves the belt motor to the right until the edge sensor is off or for ~2 seconds.
dropDiscToTheRight :PUSH    R0                             ;  save registers
                    PUSH    R1                             ;
                    PUSH    R2                             ;
                    PUSH    R3                             ;
                    PUSH    R4                             ;
                    LOAD    R1    RIGHTLAMP                ;
                    BRS     setOutputOn                    ;  turn on the lamp of the right edge sensor
                    LOAD    R0    0                        ;  no forcing sensor
                    LOAD    R1    BELTMOTORRIGHTDRIVER     ;  motor towards the right side
                    LOAD    R2    DROPDISKDUTY             ;  duty cycle
                    LOAD    R3    DROPDISKTIMEOUT          ;  (cycles) timeout
                    LOAD    R4    RIGHTEDGESENSOR          ;  check on right sensor
                    BRS     pwmOn                          ;  run the pwm
                    CMP     R0    FALSE                    ;  if pwm timed out
                    BEQ     ddRight_return                 ;    just exit
                    BRS     incBlackDiscs                  ;  else one more Black was thrown
ddRight_return :    LOAD    R1    BELTMOTORRIGHTDRIVER     ;  turn off motor
                    BRS     setOutputOff                   ;  -//-
                    LOAD    R1    RIGHTLAMP                ;  turn off lamp
                    BRS     setOutputOff                   ; -//-
                    PULL    R4                             ;
                    PULL    R3                             ;
                    PULL    R2                             ;
                    PULL    R1                             ;  clean up registers used
                    PULL    R0                             ;
                    RTS                                    ;  return

;  Resets all mechanisms to initial positions
reset_mechanisms :  PUSH    R0                             ;
                    PUSH    R1                             ;  save registers
                    PUSH    R2                             ;
                    PUSH    R3                             ;
                    PUSH    R4                             ;
rstMech_start :     LOAD    R1    PUSHERBUTTON             ;  check if button is pressed
                    BRS     isInputOn                      ;  -//-
                    CMP     R0    FALSE                    ;  push off button => FALSE = pressed
                    BEQ     rstMech_return                 ;  if it is pressed nothing needs to be done
                    LOAD    R1    STACKLAMP                ;  turn on stack lamp
                    BRS     setOutputOn                    ;  -//-
                    LOAD    R1    INTERRUPTLAMPDELAY       ;  lighting delay
                    BRS     delay                          ;  wait for the delay
rstMech_chkStack :  LOAD    R1    STACKSENSOR              ;  check sensor
                    BRS     isInputOn                      ;  -//-
                    CMP     R0    FALSE                    ;  if stack sensor is off
                    BEQ     rstMech_return                 ;  do not reset mechanism, just exit
                    LOAD    R0    0                        ;  do not use a forcing port
                    LOAD    R1    PUSHERMOTORDRIVER        ;  motor towards the left side
                    LOAD    R2    RESETPUSHERDUTY          ;  duty cycle
                    LOAD    R3    RESETPUSHERTIMEOUT       ;  (cycles) timeout
                    LOAD    R4    PUSHERBUTTON             ;  check on pusher sensor
                    BRS     pwmOn                          ;  run the pwm
                    CMP     R0    TRUE                     ;  if result is true
                    BEQ     rstMech_return                 ;    goto return
                    BRS     doAbort                        ;  else (in case it is FALSE) means the timeout expired => reset to prevent damage
rstMech_return :    LOAD    R1    STACKLAMP
                    BRS     setOutputOff
                    PULL    R4                             ;
                    PULL    R3                             ;
                    PULL    R2                             ;
                    PULL    R1                             ;  clean up registers used
                    PULL    R0                             ;
                    RTS                                    ;  return
@END
