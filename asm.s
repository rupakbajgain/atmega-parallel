#define __SFR_OFFSET 0
#include <avr/interrupt.h>

;Max threads using 64bytes stack <32;
;So let out max be 24
#define MAX_THREADS 24
#define TASK_INDEX RAMEND
#define ENERGY TASK_INDEX-1
#define TPRIORITY_BASE ENERGY-1
#define SP_BACKUP_BASE (TPRIORITY_BASE-MAX_THREADS)
#define STACK_START SP_BACKUP_BASE-2*MAX_THREADS
;for optimization - let the code be dirty
;Every code used commeneted may be required later but not now
;sbc &adc commands are commented as they are not required for fix address//computation
;No need to load hi8 two times as they don't change
;fix jmp with rjmp
.extern init

.section .text
.global setStackBase
setStackBase:
;24=pointer to function
;22=i
;20=stack
;18=par
;16=priority
	;make sure r1=0
	ldi r30,lo8(TPRIORITY_BASE)
	ldi r31,hi8(TPRIORITY_BASE)
	sub r30,r22
	;sbc r31,r1
	st z,r16
	ldi r30,lo8(SP_BACKUP_BASE)
	;ldi r31,hi8(SP_BACKUP_BASE)   ;z=SP_BACKUP_BASE
	lsl r22               ;22(i) is 2*i now
	sub r30,r22
	sbc r31,r1                    ;z==CURRENT_SP_BACKUP
	movw r26,r20           ;save 21:20 to 27:26
	sbiw r26,35                   ;z=StackAddr-35
	st z,r26
	st -z,r27
	;;
	movw r30,r26           ; 31:30=27:26
	;set sreg to 0,simulator complains
	std z+1,r1
   ;set r1=0 before calling C
	std z+3,r1
	;r25:r24 is parameter  in our r19:r18
	std z+27,r19
	std z+26,r18
	movw r30,r20
	;;;;Pointer here
	st z,r24                       ;z=func()
	st -z,r25
ret


.section .text
.global TIMER0_OVF_vect
TIMER0_OVF_vect:
;is context switch required???
	push r31
	push r30
	clr r30
	lds r31,ENERGY
	cp r31,r30
	breq 2f
	dec r31
	sts ENERGY,r31
	pop r31
	pop r30
	reti
	2:
   push r29
   push r28
   push r27
   push r26
   push r25
   push r24
   push r23
   push r22
   push r21
   push r20
   push r19
   push r18
   push r17
   push r16
   push r15
   push r14
   push r13
   push r12
   push r11
   push r10
   push r9
   push r8
   push r7
   push r6
   push r5
   push r4
   push r3
   push r2
   push r1
   push r0
   in r17,SREG
   push r17
;Context switch next
	lds r24,TASK_INDEX
	clr r1
	ldi r30,lo8(SP_BACKUP_BASE)
	ldi r31,hi8(SP_BACKUP_BASE)
	lsl r24
	sub r30,r24
	sbc r31,r1
	in r17,SPL
	st z,r17
	in r17,SPH
	st -z,r17
	lsr r24
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Scheduling
0:
dec r24
brmi 1f
rjmp 2f
1:
ldi r24,(MAX_THREADS-1)
2:
ldi r30,lo8(TPRIORITY_BASE)
ldi r31,hi8(TPRIORITY_BASE)
sub r30,r24
ld r16,z   ;energy read here
cp r16,r1
breq 0b
sts ENERGY,r16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   sts TASK_INDEX,r24
   ldi r30,lo8(SP_BACKUP_BASE)
	ldi r31,hi8(SP_BACKUP_BASE)
	lsl r24
	sub r30,r24                ;r24 is not used downward
	sbc r31,r1
	ld r17,z
	out SPL,r17
	ld r17,-z
	out SPH,r17
;Context switched
	pop r17
	cbr r17,7               ;cli first
	out SREG,r17
   pop r0
   pop r1
   pop r2
   pop r3
   pop r4
   pop r5
   pop r6
   pop r7
   pop r8
   pop r9
   pop r10
   pop r11
   pop r12
   pop r13
   pop r14
   pop r15
   pop r16
   pop r17
   pop r18
   pop r19
   pop r20
   pop r21
   pop r22
   pop r23
   pop r24
   pop r25
   pop r26
   pop r27
   pop r28
   pop r29
   pop r30
   pop r31
reti

.section .text
.global main
main:
ldi r24,2  ;initilizing timer0
out TCCR0,r24
ldi r20,(1<<TOIE0)
out TIMSK,r20 ;timer initialization complete
;Set stack for main thread
ldi r20,hi8(STACK_START)
out SPH,r20
ldi r20,lo8(STACK_START)
out SPL,r20
;initialization here
clr r1
ldi r30,lo8(TPRIORITY_BASE+1)
ldi r31,hi8(TPRIORITY_BASE+1)
ldi r16,(MAX_THREADS+1)    ;setting all priority to 0
1:
st -z,r1
dec r16
brne 1b
sts TASK_INDEX,r1
call init
sei           ;enable interrupt
1: rjmp 1b
.end





