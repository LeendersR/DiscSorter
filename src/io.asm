;===============================================================================
;  io.asm
;===============================================================================

@CODE
                    BRA     setup
;  Returns whether the given input is on.
;  R0 is the result of the function, while R1 is the input parameter

;  Note: the input should be the value of the binary representation of the input bit.
;  Example: for input 4, the input value should be 8.
isInputOn :         LOAD    R0    [R5+INPUT]               ;  read the input register
                    AND     R0    R1                       ;  calc (inputReg = inputReg & inputParam)
                    CMP     R0    R1                       ;  if ((inputReg & inputParam) == inputParam)  (calc exactly above)
                    BEQ     isInputOn_true                 ;    return true
                    LOAD    R0    FALSE                    ;  else
                    RTS                                    ;    return false
isInputOn_true :    LOAD    R0    TRUE                     ;  "return true"
                    RTS                                    ;  -//-

;  Sets the given output to on.
;  R1 i the output parameter
;
;  Note: the input should be the value of the binary representation of the input bit.
;  Example: for input 4, the input value should be 8.
setOutputOff :      PUSH    R0                             ;  save original value of R0
                    PUSH    R1                             ;  save original value of R1
                    LOAD    R0    255
                    SUB     R0    R1                       ;  outputParam = 255 - outputParam
                    LOAD    R1    R0                       ;  get the outputParam back to its place
                    LOAD    R0    [GB+outputs]             ;  retrieve the output register cache
                    AND     R0    R1                       ;  OutputCache = (OutputCache & (255 - outputParam)) (calc is above)
                    STOR    R0    [R5+OUTPUT]              ;  set the actual ports
                    STOR    R0    [GB+outputs]             ;  save the output register cache
                    PULL    R1                             ;  cleanup used registers
                    PULL    R0                             ;  -//-
                    RTS                                    ;  return to caller

;  Sets the given output to off.
;  R1 i the output parameter
;
;  Note: the input should be the value of the binary representation of the input bit.
;  Example: for input 4, the input value should be 8.
setOutputOn :       PUSH    R0                             ;  save original value of R0
                    LOAD    R0    [GB+outputs]             ;  retrieve the output register cache
                    OR      R0    R1                       ;  OutputCache = (OutputCache | outputParam)
                    STOR    R0    [R5+OUTPUT]              ;  set the actual ports
                    STOR    R0    [GB+outputs]             ;  save the output register cache
                    PULL    R0                             ;  -//-
                    RTS                                    ;  return to caller

@END
