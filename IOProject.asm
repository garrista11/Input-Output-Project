TITLE Project 6     (Proj6_garrista.asm)

; Author: Taylor Garrison
; Last Modified: 04/6/2022
; Description: This file allows the user to enter 10 numbers as strings and will then convert each number into an integer. Using the conversions, it will calculate the sum
; and average of the entered numbers. It will then output the numbers entered converted back into strings to the display, as well as the string versions of the sum and average.
; Can handle positive and negative numbers, as long as they fit inside of a 32-bit register. Will ask the user to try again if they enter a string that contains an invalid character
; (something other than a number) or if they enter a number that was too big (or too small). 

INCLUDE Irvine32.inc



; -----------------------------------------------------------------------------
; Name: mGetString
;
; Displays a prompt to the output and recieves a string as input.
;
; Preconditions: None.
;
; Receives:
; prompt		= byte string address
; entered_str	= empty string address
; str_len		= address for memory variable to hold length of input
; max_str_len	= max string length address
; 
; Returns: 
; entered_str = inputted byte string
; str_len	  = length of inputted string
; -----------------------------------------------------------------------------
mGetString	MACRO	prompt, entered_str, str_len,  max_str_len
  PUSHAD
  MOV		EDX, prompt
  CALL		WriteString
  MOV		EDX, entered_str
  MOV		ECX, max_str_len
  CALL		ReadString
  MOV		[str_len], EAX
  POPAD
ENDM

; -----------------------------------------------------------------------------
; Name: mDisplayString
;
; Displays a string to output.
;
; Preconditions: None
;
; Receives:
; str_display	= byte array address
;
;Returns: None
; -----------------------------------------------------------------------------
mDisplayString MACRO str_display
  PUSH		EDX
  MOV		EDX, str_display
  CALL		WriteString
  POP		EDX
ENDM

MAXSIZE	=	10								; determines how many numbers the user can enter
MAX_POS =	2147483647
MAX_NEG =	2147483648
.data
intro_1		BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low level I/O procedures", 13, 10, 0
intro_2		BYTE	"Written by: Taylor Garrison", 13, 10, 0
instr_1		BYTE	"Please provide 10 signed decimal integers.", 13, 10, 0
instr_2		BYTE	"Each number needs to be small enough to fit inside a 32 bit register. After you have finished inputting", 13, 10, 0
instr_3		BYTE	"the raw numbers I will display a list of the integers, their sum, and their average value.", 13, 10, 0
usr_prompt	BYTE	"Please enter a signed integer: ", 0
error_msg	BYTE	"ERROR: You did not enter a signed number or your number was too big.", 13, 10, 0
error_prmpt	BYTE	"Please try again: ", 0
list_descr	BYTE	"You entered the following numbers: ", 13, 10, 0
sum_descr	BYTE	"The sum of these numbers is: ", 0
avg_descr	BYTE	"The truncated average is: " ,0
goodbye_msg	BYTE	"Thanks for playing!", 13, 10, 0
usr_buffer	BYTE	20	DUP(0)
buffer_size	DWORD	SIZEOF usr_buffer - 1
usr_len		DWORD	?						; to be calculated
user_num	SDWORD	?						; to be calculated
sum_num		SDWORD	?						; to be calculated
avg_num		SDWORD	?						; to be calculated
cnvrt_buff	BYTE	33	DUP(0)
numArray	SDWORD	MAXSIZE DUP(?)			; to be calculated




.code
main PROC

  mDisplayString	OFFSET intro_1
  mDisplayString	OFFSET intro_2
  CALL				CrLf
  mDisplayString	OFFSET instr_1
  mDisplayString	OFFSET instr_2
  mDisplayString	OFFSET instr_3

; Set up the loop for getting inputs
  MOV				ECX, MAXSIZE
  MOV				EDI, OFFSET numArray

_mainLoop:

  PUSH				OFFSET error_prmpt	
  PUSH				OFFSET error_msg	
  PUSH				OFFSET user_num		
  PUSH				OFFSET usr_len		
  PUSH				buffer_size			
  PUSH				OFFSET usr_buffer	
  PUSH				OFFSET usr_prompt	
  CALL				ReadVal

  MOV				EAX, user_num		  ; Add the converted number to the array
  CLD
  STOSD
  LOOP				_mainLoop
  
  mDisplayString	OFFSET list_descr		

; Set up loop for displaying numbers to screen
  MOV				ECX, MAXSIZE
  MOV				ESI, OFFSET	numArray

_printLoop:
  MOV				EAX, [ESI]				; Get the current number from the array
  MOV				user_num, EAX
  PUSH				OFFSET cnvrt_buff	
  PUSH				user_num			
  CALL				WriteVal
  ADD				ESI, 4
  CMP				ECX, 1
  JE				_skipComma

  _writeCommaAndSpace:
  MOV				AL, ','
  CALL				WriteChar
  MOV				AL, ' '
  CALL				WriteChar

  _skipComma:
  LOOP				_printLoop
  CALL				CrLf

  mDisplayString	OFFSET	sum_descr

; Calculate the sum
  PUSH				OFFSET sum_num		
  PUSH				OFFSET numArray		
  CALL				calSum

; Display the sum
  PUSH				OFFSET cnvrt_buff	
  PUSH				sum_num				
  CALL				WriteVal
  CALL				CrLf

  mDisplayString	OFFSET	avg_descr

; Calculate the average
  PUSH				OFFSET avg_num		
  PUSH				sum_num				
  CALL				calAverage

; Display the average
  PUSH				OFFSET cnvrt_buff	
  PUSH				avg_num				
  CALL				WriteVal
  CALL				CrLf

  CALL				CrLf
  mDisplayString	OFFSET goodbye_msg


Invoke ExitProcess,0	; exit to operating system
main ENDP

; --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Name: ReadVal
;
; Uses mGetString to receive a string from the user and attempts to convert that string into an SDWORD. If the string isn't able to be converted, ReadVal
; will re-prompt the user to enter another string. Can receive positive and negative values as long as they fit into a 32-bit register.
;
; Preconditions: Usr_prompt is a byte array, usr_buffer is an empty byte array, buffer_size is a DWORD containing a value that is one less than the size of usr_buffer,usr_len is a DWORD,
; user_num is a SDWORD, error_msg is a byte array, and error_prompt is a byte array.
;
; Postconditions: None.
;
; Receives:
; [EBP+8]	= address of usr_prompt (BYTE array)
; [EBP+12]	= address of usr_buffer (BYTE array)
; [EBP+16]	= value of buffer_size (DWORD)
; [EBP+20]	= adress of usr_len (DWORD)
; [EBP+24]	= address of user_num (SDWORD)
; [EBP+28]	= address of error_msg (BYTE array)
; [EBP+32]	= address of error_prompt (BYTE array)
;
; Returns: User_num contains the value entered by the user converted into an SDWORD and user_len contains the length of the string they entered.
; --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

ReadVal PROC
  PUSH			EBP
  MOV			EBP, ESP
  PUSHAD

  JMP			_receiveNumber

_overflowError:
  DEC			ECX
  CMP			ECX, 0
  JLE			_showDiffPrompt
_removeItemsFromStack_2:
  POP			EAX
  LOOP	_removeItemsFromStack_2
  JMP	_showDiffPrompt

_errorPrompt:

  MOV			ECX, EDX
  CMP			ECX, 0
  JE	_showDiffPrompt
  _removeItemsFromStack:
  POP			EAX
  LOOP	_removeItemsFromStack

_showDiffPrompt:
  mDisplayString [EBP+28]
  mGetString	 [EBP+32], [EBP+12], [EBP+20], [EBP+16]
  jmp			 _setupLoop



; Get user input in the form of a string
_receiveNumber:
  mGetString	[EBP+8], [EBP+12], [EBP+20], [EBP+16]


; Set up the loop for changing to integer
_setupLoop:
  MOV		ECX, [EBP+20]	; counter for the loop
  MOV		ESI, [EBP+12]	; string address that we will take digits from
  MOV		EDX, 0			; this will store a counter for the next loop

_getLoop:
	CLD					; clear the direction flag
	LODSB				; now the first digit is in AL and ESI is pointed to the next digit in the string
	MOVZX	EAX, AL		; now the byte is stored in a 32 bit register

;Check for + or - at the beginning of the string
	CMP		EAX, 43
	JE		_plusSign

	CMP		EAX, 45
	JE		_minusSign

; Check to see if input was valid
	CMP		EAX, 48
	JL		_errorPrompt

	CMP		EAX, 57
	JG		_errorPrompt
	_validNum:
	SUB		EAX, 48		; now the character is the integer it represents

	PUSH	EAX			; save the byte on the stack
	INC		EDX
	LOOP	_getLoop
	JMP		_nextStep

_plusSign:
  CMP		ECX, [EBP+20]
  JNE		_errorPrompt
  JMP		_validNum

_minusSign:
   CMP		ECX, [EBP+20]
   JNE		_errorPrompt
   JMP		_validNum

; Set up the loop that will change each byte into the right size integer

_nextStep:
  MOV		ECX, EDX

  MOV		EBX, 1
  MOV		EDI, [EBP+24]
  MOV		EAX, 0
  MOV		[EDI], EAX		; make sure that user_num is set to 0 before we start adding to it
   
_convertLoop:
    POP		EAX
	CMP		EAX, -5
	JE		_convertLoopEnd
	CMP		EAX, -3
	JE		_negativeNumber
	MUL		EBX
	JO		_overflowError
	ADD		[EDI], EAX
	JO		_overflowError
	MOV		EAX, MAX_POS
	CMP		[EDI], EAX
	JG		_overflowError
	MOV		EAX, EBX
	MOV		EBX, 10
	MUL		EBX
	MOV		EBX, EAX
	JMP		_convertLoopEnd
_negativeNumber:
	MOV		EAX, MAX_NEG
	MOV		EBX, [EDI]
	CMP		EBX, EAX
	JA		_overflowError
	MOV		EAX, [EDI]
	MOV		EBX, -1
	IMUL	EBX
	JC		_overflowError
	MOV		[EDI], EAX
_convertLoopEnd:
	LOOP	_convertLoop

  POPAD
  POP	EBP
  RET	28
  
ReadVal	ENDP

; --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Name: WriteVal
;
; Takes an integer and converts it into a BYTE array of ASCII values that can be outputted to the display. 
;
; Preconditions: There must be a number to convert and and cnvrt_buffer must be a byte array that can hold 33 bytes.
;
; Postconditions: None
;
; Receives:
; [EBP+8]	= value to be converted
; [EBP+12]	= address of byte array
;
; Returns: Value converted from number into string stored in cnvrt_buffer. 
; --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

WriteVal PROC
  PUSH		EBP
  MOV		EBP, ESP
  PUSHAD

  MOV		ESI, [EBP+12]
; Check to see if the value is negative

  MOV		ESI, [EBP+8]
  CMP		ESI, 0
  JG		_startProcess
  MOV		EAX, [EBP+8]
  MOV		EBX, -1
  IMUL		EBX
  MOV		ESI, 1					; Used as a check for negative numbers
  JMP	_skipStart

; Move the value we want into EAX
_startProcess:
  MOV		ESI, 0					; Since this means that the number wasn't negative
  MOV		EAX, [EBP+8]

; Move the address of the string we want to write into into EDI
_skipStart:
  MOV		EDI, [EBP+12]

; Loop to push each value onto the stack
  MOV		ECX, 0
_getLoop:
  MOV		EDX, 0
  MOV		EBX, 10
  DIV		EBX
  PUSH		EDX
  INC		ECX
  CMP		EAX, 0
  JNE		_getLoop

  MOV		EBX, 32

_negativeCheck:
  CMP		ESI, 0
  JE		_convertLoop
  MOV		EAX, 45
  CLD
  STOSB
  DEC		EBX

_convertLoop:
  POP		EDX
  MOV		EAX, EDX
  ADD		EAX, 48
  CLD
  STOSB
  DEC		EBX
  LOOP	_convertLoop

  MOV		ECX, EBX
_fillLoop:
  MOV		EAX, 0
  CLD
  STOSB
  LOOP	_fillLoop

  mDisplayString [EBP+12]

  POPAD
  POP		EBP
  RET		8
WriteVal ENDP

; --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Name: calSum
;
; Calculates the sum of integers stored in a SDWORD array.
;
; Preconditions: The array must be filled with SDWORD's and there must be a SDWORD where the sum can be stored.
;
; Postconditions: None.
;
; Receives:
; [EBP+8]	= address of SDWORD array
; [EBP+12]	= address of SDWORD
;
; Returns: Changes the value in [EBP+12] to reflect the sum of the SDWORD's in the array.
; --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

calSum PROC
  PUSH		EBP
  MOV		EBP, ESP
  PUSHAD
  ; Set up the loop
  MOV		ECX, MAXSIZE
  MOV		ESI, [EBP+8]
  MOV		EDI, [EBP+12]

_addLoop:
  CLD
  LODSD
  ADD		[EDI], EAX
  LOOP	_addLoop

  POPAD
  POP		EBP
  RET		8
calSum ENDP

; --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
; Name: calAverage
;
; Calculates the average of the entered numbers using the sum obtained in calSum.
;
; Preconditions: The sum of the numbers must have already been calculated and there must be a place to store the average number.
;
; Postconditions: None.
;
; Receives:
; [EBP+8]	= value of the sum of numbers
; [EBP+12]	= address of SDWORD where the average will be stored
;
; Returns: The calculated average will be returned in memory corresponding to [EBP+12]. 
; --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

calAverage PROC
  PUSH	EBP
  MOV	EBP, ESP
  PUSHAD

  MOV	EAX, [EBP+8]
  MOV	EDX, 0
  MOV	EBX, MAXSIZE
  CDQ
  IDIV	EBX

  MOV	EDI, [EBP+12]
  MOV	[EDI], EAX

  POPAD
  POP	EBP
  RET	8

calAverage ENDP
END main
