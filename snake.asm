;	set game state memory location
.equ    HEAD_X,         0x1000  ; Snake head's position on x
.equ    HEAD_Y,         0x1004  ; Snake head's position on y
.equ    TAIL_X,         0x1008  ; Snake tail's position on x
.equ    TAIL_Y,         0x100C  ; Snake tail's position on Y
.equ    SCORE,          0x1010  ; Score address
.equ    GSA,            0x1014  ; Game state array address

.equ    CP_VALID,       0x1200  ; Whether the checkpoint is valid.
.equ    CP_HEAD_X,      0x1204  ; Snake head's X coordinate. (Checkpoint)
.equ    CP_HEAD_Y,      0x1208  ; Snake head's Y coordinate. (Checkpoint)
.equ    CP_TAIL_X,      0x120C  ; Snake tail's X coordinate. (Checkpoint)
.equ    CP_TAIL_Y,      0x1210  ; Snake tail's Y coordinate. (Checkpoint)
.equ    CP_SCORE,       0x1214  ; Score. (Checkpoint)
.equ    CP_GSA,         0x1218  ; GSA. (Checkpoint)

.equ    LEDS,           0x2000  ; LED address
.equ    SEVEN_SEGS,     0x1198  ; 7-segment display addresses
.equ    RANDOM_NUM,     0x2010  ; Random number generator address
.equ    BUTTONS,        0x2030  ; Buttons addresses

; button state
.equ    BUTTON_NONE,    0
.equ    BUTTON_LEFT,    1
.equ    BUTTON_UP,      2
.equ    BUTTON_DOWN,    3
.equ    BUTTON_RIGHT,   4
.equ    BUTTON_CHECKPOINT,    5

; array state
.equ    DIR_LEFT,       1       ; leftward direction
.equ    DIR_UP,         2       ; upward direction
.equ    DIR_DOWN,       3       ; downward direction
.equ    DIR_RIGHT,      4       ; rightward direction
.equ    FOOD,           5       ; food

; constants
.equ    NB_ROWS,        8       ; number of rows
.equ    NB_COLS,        12      ; number of columns
.equ    NB_CELLS,       96      ; number of cells in GSA
.equ    RET_ATE_FOOD,   1       ; return value for hit_test when food was eaten
.equ    RET_COLLISION,  2       ; return value for hit_test when a collision was detected
.equ    ARG_HUNGRY,     0       ; a0 argument for move_snake when food wasn't eaten
.equ    ARG_FED,        1       ; a0 argument for move_snake when food was eaten

; initialize stack pointer
addi    sp, zero, LEDS

; BEGIN: main
main:
    stw		    zero,		CP_VALID(zero)

    replay:
        call		init_game

    continue_playing:
        call		wait
        call		get_input
        addi		t0,		    zero,		5
        beq		    v0,		    t0,		    check_checkpoint
        call		hit_test
        addi		t0,		    zero,		1
        beq		    v0,		    t0,		    eat_food
        bne		    v0,		    zero,		replay
        add		    a0,		    zero,		zero
        call		move_snake
        jmpi		buckle_up
        
    eat_food:
        ldw		    t0,		    SCORE(zero)
        addi		t0,		    t0,		    1
        stw		    t0,		    SCORE(zero)
        call		display_score
        addi		a0,		    zero,		1
        call		move_snake
        call		create_food
        call		save_checkpoint
        beq		    v0,		    zero,		buckle_up
        call		blink_score
        
    buckle_up:
        call		clear_leds
        call		draw_array
        jmpi		continue_playing

    check_checkpoint:
        call		restore_checkpoint
        beq		    v0,		    zero,		continue_playing
        call		blink_score
        jmpi		buckle_up   
; END: main


; BEGIN: clear_leds
clear_leds:
    stw		    zero,		LEDS(zero)
    stw		    zero,		LEDS+4(zero)
    stw		    zero,		LEDS+8(zero)
    ret
; END: clear_leds


; BEGIN: set_pixel
set_pixel:
    addi		t0,		zero,		4
    addi		t1,		zero,	    8
    addi		t2,		zero,		1
    addi		t4,		zero,	   LEDS
    blt		    a0,		t0,		set_LEDS
    sub		    a0,		a0,		    t0
    add		    t4,		t4,		    t0
    blt		    a0,		t0,     set_LEDS
    sub		    a0,		a0,		    t0
    add		    t4,		t4,		    t0
 
    set_LEDS:
        slli		a0,		a0,		    3
        add		    a1,		a1,		    a0
        sll		    t2,		t2,		    a1
        ldw		    t3,		0(t4)
        or		    t3,		t3,		    t2
        stw		    t3,		0(t4)
        ret     
; END: set_pixel


; BEGIN: display_score
display_score:
    ldw		    t7,		digit_map(zero)
    stw		    t7,     SEVEN_SEGS(zero)
    stw		    t7,	    SEVEN_SEGS+4(zero)
    ldw		    t0,		SCORE(zero)
    addi		t1,		zero,		    9
    add		    t2,		zero,		    zero
    blt		    t1,		t0,		        for_display
    stw		    t7,	    SEVEN_SEGS+8(zero)
    slli		t6,		t0,		        2
    ldw		    t6,		digit_map(t6)
    stw		    t6,		SEVEN_SEGS+12(zero)
    ret
    
    for_display:
        addi		t0,		t0,		        -10
        addi		t2,		t2,		        1
        blt		    t1,		t0,		        for_display
        slli		t6,		t0,		        2
        ldw		    t6,		digit_map(t6)
        stw		    t6,		SEVEN_SEGS+12(zero)
        slli		t5,		t2,		        2
        ldw		    t5,		digit_map(t5)
        stw		    t5,		SEVEN_SEGS+8(zero)
        ret
; END: display_score


; BEGIN: init_game
init_game:
    addi		sp,		    sp,		    -4
    stw		    ra,		    0(sp)
    call		clear_leds
    add 		t6,		    zero,		zero
    addi        t7,		    zero,		NB_CELLS ; 96

    init_GSA_loop:
        beq		    t6,		    t7,		    back_to_init
        slli		t3,		    t6,		    2
        stw		    zero,	    GSA(t3)
        addi		t6,		    t6,		    1
        jmpi		init_GSA_loop

    back_to_init:
        stw		    zero,		HEAD_X(zero)
        stw         zero,       HEAD_Y(zero)
        stw         zero,       TAIL_X(zero)
        stw         zero,       TAIL_Y(zero)
        addi        t0,         zero,       DIR_RIGHT ; 4 
	    stw         t0,         GSA(zero)
        stw         zero,       SCORE(zero)
        ldw		    t4,		    digit_map(zero)
        stw         t4,         SEVEN_SEGS(zero)
        stw         t4,         SEVEN_SEGS+4(zero)
        stw         t4,         SEVEN_SEGS+8(zero)
        stw         t4,         SEVEN_SEGS+12(zero)
        call		create_food
        call		draw_array
        call		display_score
        ldw		    ra,		    0(sp)
        addi		sp,		    sp,		    4
        ret
; END: init_game


; BEGIN: create_food
create_food:
    addi		t0,		zero,		NB_CELLS ; 96
    addi		t7,		zero,		FOOD
    
    check_food_position:
        ldw		    t1,		RANDOM_NUM(zero)
        andi		t1,		t1,		    255
        bge		    t1,		t0,		    check_food_position
        slli		t1,		t1,		    2 
        ldw		    t2,		GSA(t1)
        bne		    t2,		zero,		check_food_position
        stw		    t7,		GSA(t1)
        ret
; END: create_food


; BEGIN: hit_test
hit_test:
    addi		sp,		sp,		    -4
    stw		    ra,		0(sp)
    add		    v0,		zero,	    zero
    addi		t6,		zero,		5
    ldw		    t0,		HEAD_X(zero)
    ldw		    t1,		HEAD_Y(zero)
    call		load_next_hit_direction
    addi	    t7,		zero,		1
    beq		    t3,		t7,		    left_hit_test
    addi		t7,		t7,		    1
    beq		    t3,		t7,		    up_hit_test
    addi		t7,		t7,		    1
    beq		    t3,		t7,		    down_hit_test
    addi		t0,		t0,		    1
    call		load_next_hit_direction
    jmpi		check_next_hit
    
    left_hit_test:
        addi		t0,		t0,		    -1
        call		load_next_hit_direction
        jmpi		check_next_hit
                
    up_hit_test:
        addi		t1,		t1,		    -1
        call		load_next_hit_direction
        jmpi		check_next_hit

    down_hit_test:
        addi		t1,		t1,		    1
        call		load_next_hit_direction
        jmpi		check_next_hit
    
    load_next_hit_direction:
        slli		t2,		t0,		    3
        add		    t2,		t2,		    t1
        slli		t2,		t2,		    2
        ldw		    t3,		GSA(t2)
        ret

    check_next_hit:
        ldw		    ra,		0(sp)
        addi		sp,		sp,		    4
        beq		    t3,		t6,		    hit_food
        beq		    t3,		zero,		hit_nothing_or_led_screen_boundary

    hit_end_game:
        addi		v0,		zero,		2
        ret

    hit_food:
        addi		v0,		v0,		    1
        stw		    zero,	GSA(t2)
        ret

    hit_nothing_or_led_screen_boundary:
        addi		t2,		zero,		-1
        addi		t4,		zero,		NB_ROWS ; 8
        addi		t5,		zero,		NB_COLS ; 12
        beq		    t0,		t5,		    hit_end_game
        beq		    t1,		t4,		    hit_end_game
        beq		    t0,		t2,		    hit_end_game
        beq		    t1,		t2,		    hit_end_game
        ret
; END: hit_test


; BEGIN: get_input
get_input:
    addi		sp,		sp,		    -4
    stw		    ra,		0(sp)
    add		    v0,		zero,		zero
    ldw		    t2,		HEAD_X(zero)
    ldw		    t3,		HEAD_Y(zero)
    ldw		    t0,		BUTTONS+4(zero)
    stw		    zero,	BUTTONS+4(zero) 
    slli		t2,		t2,		    3
    add		    t2,		t2,		    t3
    slli		t2,		t2,		    2 
    ldw		    t3,		GSA(t2) ; direction of head
    andi		t1,		t0,		    16
    bne		    t1,		zero,		button_checkpoint_get_input
    andi		t1,		t0,		    1
    bne		    t1,		zero,		button_left_get_input
    andi		t1,		t0,		    2
    bne		    t1,		zero,		button_up_get_input
    andi		t1,		t0,		    4
    bne		    t1,		zero,		button_down_get_input
    andi		t1,		t0,		    8
    bne		    t1,		zero,		button_right_get_input
    addi		sp,		sp,		    4
    ret

    button_left_get_input:
        addi		v0,		zero,		1
        call		check_left_right
        stw		    v0,		GSA(t2)
        jmpi		end_get_input

    button_up_get_input:
        addi		v0,		zero,		    2
        call		check_up_down
        stw		    v0,		GSA(t2)
        jmpi		end_get_input
        
    button_down_get_input:
        addi		v0,		zero,		    3
        call		check_up_down
        stw		    v0,		GSA(t2)
        jmpi		end_get_input
    
    button_right_get_input:
        addi		v0,		zero,		    4
        call		check_left_right
        stw		    v0,		GSA(t2)
        jmpi		end_get_input

    check_left_right:
        addi		t4,		zero,       BUTTON_RIGHT
        addi		t5,		zero,	    BUTTON_LEFT
        beq		    t3,		t4,	        end_get_input
        beq		    t3,		t5,	        end_get_input
        ret
    
    check_up_down:
        addi		t4,		zero,       BUTTON_UP
        addi		t5,		zero,	    BUTTON_DOWN
        beq		    t3,		t4,	        end_get_input
        beq		    t3,		t5,	        end_get_input
        ret 

    end_get_input:
        ldw		    ra,		0(sp)
        addi		sp,		sp,		    4
        ret

    button_checkpoint_get_input:
        addi		v0,		zero,		5
        addi		sp,		sp,		    4
        ret
; END: get_input


; BEGIN: draw_array
draw_array:
    addi		s0,		zero,		NB_ROWS ; 8
    addi		s1,		zero,		NB_COLS ; 12
    add		    a0,		zero,		zero
    add		    a1,		zero,		zero

    for_x:
        blt		    a0,		s1,		    for_y
        ret

    for_y:
        slli		t2,		a0,		    3
        add		    t2,		t2,		    a1
        slli		t2,		t2,		    2
        ldw		    t3,		GSA(t2)
        bne		    t3,		zero,		draw_pixel

    return_for_y:
        addi		a1,		a1,		    1
        blt		    a1,		s0,		    for_y
        add		    a1,		zero,		zero
        addi		a0,		a0,		    1
        jmpi		for_x
    
    draw_pixel:
        addi		sp,		sp,		    -12
        stw		    ra,		0(sp)
        stw		    a0,		4(sp)
        stw		    a1,		8(sp)
        call		set_pixel
        ldw		    a1,		8(sp)
        ldw		    a0,		4(sp)
        ldw		    ra,		0(sp)
        addi		sp,		sp,		    12  
        jmpi		return_for_y
; END: draw_array


; BEGIN: move_snake
move_snake:
    add		    t6,		zero,		zero
    addi		sp,		sp,		    -4
    stw		    ra,		0(sp)
    ldw		    t0,		HEAD_X(zero)
    ldw		    t1,		HEAD_Y(zero)
    addi		t4,		zero,		HEAD_X
    addi		t5,		zero,		HEAD_Y
    jmpi		load_direction

    left_move_snake:
        addi		t0,		t0,		    -1
        stw		    t0,		0(t4)
        jmpi		store_direction
        
    up_move_snake:
        addi		t1,		t1,		    -1
        stw		    t1,		0(t5)
        jmpi		store_direction

    down_move_snake:
        addi		t1,		t1,		    1
        stw		    t1,		0(t5)

    store_direction:
        bne		    t6,		zero,		end_move_snake 
        slli		t2,		t0,		    3
        add		    t2,		t2,		    t1 
        slli		t2,		t2,		    2 
        stw		    t3,		GSA(t2)
        beq		    t6,		zero,		check_tail
    
    end_move_snake:
        ldw		    ra,		0(sp)
        addi		sp,		sp,		    4
        ret
    
    check_tail:
        beq		    a0,		zero,		erase_tail
        jmpi		end_move_snake

    erase_tail:
        addi		t6,		t6,		    1
        ldw		    t0,		TAIL_X(zero)
        ldw		    t1,		TAIL_Y(zero)
        addi		t4,		zero,		TAIL_X
        addi		t5,		zero,		TAIL_Y
    
    load_direction:
        slli		t2,		t0,		    3
        add		    t2,		t2,		    t1
        slli		t2,		t2,		    2 
        ldw		    t3,		GSA(t2)
        bne		    t6,		zero,		erase_last_position

    back_to_load_direction:
        addi	    t7,		zero,		1
        beq		    t3,		t7,		    left_move_snake
        addi		t7,		t7,		    1
        beq		    t3,		t7,		    up_move_snake
        addi		t7,		t7,		    1
        beq		    t3,		t7,		    down_move_snake
        addi		t0,		t0,		    1
        stw		    t0,		0(t4)
        jmpi		store_direction		 

    erase_last_position:
        stw		    zero,		GSA(t2)
        jmpi		back_to_load_direction
; END: move_snake


; BEGIN: save_checkpoint
save_checkpoint:
    ldw		    t0,		SCORE(zero)
    addi		t7,		zero,		10

    for_save_loop:
        blt		    t0,		zero,		do_not_save
        beq		    t0,		zero,		save
        sub 		t0,		t0,		    t7
        jmpi		for_save_loop
    
    do_not_save:
        add 		v0,		zero,		zero
        ret
    
    save:
        ldw		    t6,		HEAD_X(zero)
        stw		    t6,		CP_HEAD_X(zero)
        ldw		    t6,		HEAD_Y(zero)
        stw		    t6,		CP_HEAD_Y(zero)
        ldw		    t6,		TAIL_X(zero)
        stw		    t6,		CP_TAIL_X(zero)
        ldw		    t6,		TAIL_Y(zero)
        stw		    t6,		CP_TAIL_Y(zero)
        ldw		    t6,		SCORE(zero)
        stw		    t6,		CP_SCORE(zero)
        add		    t0,		zero,		zero
        addi		t7,		zero,		NB_CELLS ; 96

        save_GSA_loop:
            beq		    t0,		t7,		    end_save
            slli		t3,		t0,		    2
            ldw		    t1,		GSA(t3)
            stw		    t1,		CP_GSA(t3)
            addi		t0,		t0,		    1
            jmpi		save_GSA_loop
        
    end_save:
        addi		v0,		zero,		1
        stw		    v0,		CP_VALID(zero)
        ret
; END: save_checkpoint


; BEGIN: restore_checkpoint
restore_checkpoint:
    ldw		    t0,		CP_VALID(zero)
    beq		    t0,		zero,		do_not_restore
    ldw		    t6,		CP_HEAD_X(zero)
    stw		    t6,		HEAD_X(zero)
    ldw		    t6,		CP_HEAD_Y(zero)
    stw		    t6,		HEAD_Y(zero)
    ldw		    t6,		CP_TAIL_X(zero)
    stw		    t6,		TAIL_X(zero)
    ldw		    t6,		CP_TAIL_Y(zero)
    stw		    t6,		TAIL_Y(zero)
    ldw		    t6,		CP_SCORE(zero)
    stw		    t6,		SCORE(zero)
    add		    t6,		zero,		zero
    addi        t7,		zero,		NB_CELLS ; 96

    restore_GSA_loop:
        beq		    t6,		t7,		    end_restore
        slli		t3,		t6,		    2
        ldw		    t1,		CP_GSA(t3)
        stw		    t1,		GSA(t3)
        addi		t6,		t6,		    1
        jmpi		restore_GSA_loop

    do_not_restore:
        add		    v0,		zero,		zero
        ret
    
    end_restore:
        addi		v0,		zero,		1
        ret
; END: restore_checkpoint


; BEGIN: blink_score
blink_score:
    addi		sp,		sp,		    -4
    stw		    ra,		0(sp) 
    stw		    zero,		SEVEN_SEGS(zero)
    stw		    zero,		SEVEN_SEGS+4(zero)
    stw		    zero,		SEVEN_SEGS+8(zero)
    stw		    zero,		SEVEN_SEGS+12(zero)
    call		wait
    call		display_score
    call		wait
    stw		    zero,		SEVEN_SEGS(zero)
    stw		    zero,		SEVEN_SEGS+4(zero)
    stw		    zero,		SEVEN_SEGS+8(zero)
    stw		    zero,		SEVEN_SEGS+12(zero)
    call		wait
    call		display_score
    ldw		    ra,		    0(sp)
    addi		sp,		    sp,		    4
    ret
; END: blink_score


; BEGIN: wait
wait:
    addi		t0,		zero,		6000
	slli        t0,     t0,         9
	addi        t1,     zero,       1 

	loop_wait:
        beq         t0,     zero,       end_loop_wait 
        sub         t0,     t0,         t1 
        jmpi        loop_wait 

	end_loop_wait:
	    ret
;END: wait

digit_map:
    .word 0xFC ; 0
    .word 0x60 ; 1
    .word 0xDA ; 2
    .word 0xF2 ; 3
    .word 0x66 ; 4
    .word 0xB6 ; 5
    .word 0xBE ; 6
    .word 0xE0 ; 7
    .word 0xFE ; 8
    .word 0xF6 ; 9