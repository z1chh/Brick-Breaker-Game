; Name         : HU, Zi Chen
; McGill ID    : 260931572
; Final Project: Brick Breaker Game

; Cheats:
;            Uncomment the following lines to activate the cheat
;            Line  416: Laser that goes through bricks (no collisions)
;            Line  481: Ball that goes through bricks (no collisions)
;            Line 1179: Click on 3 for a free laser (without checking for the 50 points rule - points still go towards next power-up)
;                       Activating laser (via 2 or 3) cancels any laser that already exists
;            Line 1183: Click on 4 for a free long paddle power-up (without checking for the 50 points rule - points still go towards next power-up)
;                       Activate long paddle (via 1 or 4) resets the 500 iterations-timer back to 0


.286
.model small
.stack 100h
.data
        studentID       db "260931572$"                                         ; Change the content of the string to your studentID (do not remove the $ at the end)

        ball_x          dw 160	                                                ; Default value: 160
        ball_y          dw 144	                                                ; Default value: 144

        ball_x_vel      dw 0	                                                ; Default value: 0
        ball_y_vel      dw -1                                                   ; Default value: -1

        paddle_x        dw 144                                                  ; Default value: 144
        paddle_length   dw 32                                                   ; Default value: 32

        score_diff      dw 0                                                    ; The score difference to use a power-up

        paddle_time   dw 0                                                      ; The iterations of the power-up (long paddle)

        laser_power_up  dw 0                                                    ; Bool to indicate if the laser power-up is active
        laser_x         dw 0                                                    ; x-coordinate for the laser
        laser_y         dw 0                                                    ; y-coordinate for the laser

.code

; get the functions from the util_br.obj file (needs to be linked)
EXTRN setupGame:PROC, drawBricks:PROC, checkBrickCollision:PROC, sleep:PROC, decreaseLives:PROC, getScore:PROC, clearPaddleZone:PROC



; draw a single pixel specific to Mode 13h (320x200 with 1 byte per color)
drawPixel:
        color   EQU ss:[bp+4]
        x1      EQU ss:[bp+6]
        y1      EQU ss:[bp+8]

        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx
        push    es

        ; set ES as segment of graphics frame buffer
        mov     ax, 0A000h
        mov     es, ax


        ; BX = ( y1 * 320 ) + x1
        mov     bx, x1
        mov     cx, 320
        xor     dx, dx
        mov     ax, y1
        mul     cx
        add     bx, ax

        ; DX = color
        mov     dx, color

        ; plot the pixel in the graphics frame buffer
        mov     BYTE PTR es:[bx], dl

        pop     es
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret     6



; retrieves the color of the pixel at the given coordinates
getPixel:
        x1      EQU ss:[bp+4]
        y1      EQU ss:[bp+6]

        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx
        push    es

        ; set ES as segment of graphics frame buffer
        mov     ax, 0A000h
        mov     es, ax

        ; BX = ( y1 * 320 ) + x1
        mov     bx, x1
        mov     cx, 320
        xor     dx, dx
        mov     ax, y1
        mul     cx
        add     bx, ax

        ; retrieve the pixel from the graphics frame buffer
        mov     al, BYTE PTR es:[bx]
        xor     ah, ah

        pop     es
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret     4



; draw the laser at its new position and update global variables
drawLaser:
        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx
        push    es

        ; Erase the laser at the current position
        mov     ax, laser_x
        mov     bx, laser_y
        push    bx                                                              ; y = laser_y
        push    ax                                                              ; x = laser_x
        push    00h                                                             ; color = 00 - Black
        call    drawPixel

        ; Update the laser position
        mov     ax, laser_y
        sub     ax, 1
        mov     laser_y, ax
        

        ; Draw the laser at its new position
        mov     ax, laser_x
        mov     bx, laser_y
        push    bx                                                              ; y = laser_y
        push    ax                                                              ; x = laser_x
        push    04h                                                             ; color = 04 - Red
        call    drawPixel

        ; End of function
        pop     es
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret



; draw the ball at its new position and update global variables
drawBall:
        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx
        push    es

        ; Erase the ball at the current position
        mov     ax, ball_x
        mov     bx, ball_y
        push    bx                                                              ; y = ball_y
        push    ax                                                              ; x = ball_x
        push    00h                                                             ; color = 00 - Black
        call    drawPixel

        ; Update the ball position
        mov     ax, ball_x
        mov     bx, ball_y
        mov     cx, ball_x_vel
        mov     dx, ball_y_vel
        add     ax, cx                                                          ; Increment x by x-velocity
        add     bx, dx                                                          ; Increment y by y-velocity
        mov     ball_x, ax
        mov     ball_y, bx
        

        ; Draw the ball at its new position
        mov     ax, ball_x
        mov     bx, ball_y
        push    bx                                                              ; y = ball_y
        push    ax                                                              ; x = ball_x
        push    0Fh                                                             ; color = 0F - White
        call    drawPixel

        ; End of function
        pop     es
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret



; Checks if there is a collision with the walls
checkWallCollision:
        ; Initialize variables
        x_coord EQU ss:[bp+4]
        y_coord EQU ss:[bp+6]

        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx
        push    es

        ; Check y-coordinate
        mov     ax, x_coord
        mov     bx, y_coord
        cmp     bx, 32
        jz      top_limit                                                       ; y-coordinate == 32
        jg      side_wall_check                                                 ; y-coordinate >= 33
        jmp     no_wall

; Check if ball is next to the top wall, but not at the corner
top_limit:
        cmp     ax, 16
        jz      corner                                                          ; (16, 32)  -> corner
        cmp     ax, 303
        jz      corner                                                          ; (16, 303) -> corner
        jl      top_wall_check                                                  ; x-coordinate <= 302
        jmp     no_wall

top_wall_check:
        cmp     ax, 16
        jg      top_wall                                                        ; 16 < x < 303 and y = 32 -> top wall
        jmp     no_wall

; Check if ball is next to the left or right wall, but not at the corner
side_wall_check:
        cmp     ax, 16
        jz      side_wall                                                       ; x = 16 and y >= 33  -> right wall
        cmp     ax, 303
        jz      side_wall                                                       ; x = 303 and y >= 33 -> left wall
        jmp     no_wall                                                         ; Otherwise, not a wall nor corner

; Ball is is next to a corner
corner:
        xor     ax, ax
        mov     ax, 3
        jmp     endCheckWallCollision

; Ball is next to the top wall
top_wall:
        xor     ax, ax
        mov     ax, 2
        jmp     endCheckWallCollision

; Ball is next to left or right wall
side_wall:
        xor     ax, ax
        mov     ax, 1
        jmp     endCheckWallCollision

; Nothing
no_wall:
        xor     ax, ax
        mov     ax, 0
        jmp     endCheckWallCollision

endCheckWallCollision:
        ; End of function
        pop     es
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret     4



; Checks if there is a collision with the paddle
checkPaddleCollision:
        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx
        push    es
        
        ; Check y-coordinate of the ball
        mov     ax, ball_y
        cmp     ax, 183
        je      above_paddle_level

        ; Otherwise, not directly above paddle level.
        jmp     not_above_paddle

above_paddle_level:
        ; Get color of pixel under the ball
        mov     ax, ball_x
        mov     bx, ball_y
        add     bx, 1

        push    bx
        push    ax
        call    getPixel

        ; Compare the color
        cmp     ax, 00h
        je      not_above_paddle
        cmp     ax, 2Ch
        je      left_section
        cmp     ax, 2Dh
        je      middle_section
        cmp     ax, 2Eh
        je      right_section
        jmp     not_above_paddle                                                ; Technically unreachable code

not_above_paddle:
        mov     ax, 0
        jmp     endCheckPaddleCollision

left_section:
        mov     ax, 1
        jmp     endCheckPaddleCollision

middle_section:
        mov     ax, 2
        jmp     endCheckPaddleCollision

right_section:
        mov     ax, 3
        jmp     endCheckPaddleCollision

endCheckPaddleCollision:
        ; End of function
        pop     es
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret



; Handle collisions of the laser
handleLaserCollisions:
        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx
        push    es

        ; Call checkWallCollision(x, y)
        mov     bx, laser_y
        mov     ax, laser_x
        push    bx
        push    ax
        call    checkWallCollision

        ; Handle the collision, if there is one
        cmp     ax, 1
        jz      remove_laser
        cmp     ax, 2
        jz      remove_laser
        cmp     ax, 3
        jz      remove_laser

        ; Check for brick collisions
        push    -1                                                              ; laser always has y-velocity of -1
        push    0                                                               ; laser always has x-velocity of 0
        push    laser_y
        push    laser_x
        call    checkBrickCollision

        ; Handle the collision, if there is one
        ;mov    ax, 0                                                           ; Cheat gang gang
        cmp     ax, 1
        jz      remove_laser
        cmp     ax, 2
        jz      remove_laser
        cmp     ax, 3
        jz      remove_laser
        jmp    endHandleLaserCollisions                                         ; No collision

remove_laser:
        mov     laser_power_up, 0                                               ; Set power-up as off (0)
        mov     ax, laser_x
        mov     bx, laser_y
	push    bx	                                                        ; y = laser_y
	push    ax	                                                        ; x = laser_x
	push    00h	                                                        ; color = 00 - Black
	call    drawPixel                                                       ; Erase the laser at the current position

endHandleLaserCollisions:
        ; End of function
        pop     es
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret



; Handle collisions by updating ball velocity
handleCollisions:
        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx
        push    es

        ; Call checkWallCollision(x, y)
        mov     bx, ball_y
        mov     ax, ball_x
        push    bx
        push    ax
        call    checkWallCollision                                              ; Check for any wall collision

        ; Handle the collision, if there is one
        cmp     ax, 1
        jz      invert_x                                                        ; Invert ball_x_vel
        cmp     ax, 2
        jz      invert_y                                                        ; Invert ball_y_vel
        cmp     ax, 3
        jz      invert_all                                                      ; Invert ball_x_vel and ball_y_vel

        ; Check for brick collisions
        push    ball_y_vel
        push    ball_x_vel
        push    ball_y
        push    ball_x
        call    checkBrickCollision

        ; Handle the collision, if there is one
        ;mov    ax, 0                                                           ; Cheat gang gang
        cmp     ax, 1
        jz      invert_x                                                        ; Invert ball_x_vel
        cmp     ax, 2
        jz      invert_y                                                        ; Invert ball_y_vel
        cmp     ax, 3
        jz      invert_all                                                      ; Invert ball_x_vel and ball_y_vel
        jmp    check_paddle_collision                                           ; Check for paddle collision

; To invert x: 0 - x = (-x)
invert_x:
        mov     ax, ball_x_vel
        xor     bx, bx
        sub     bx, ax
        mov     ball_x_vel, bx                                                  ; Invert velocity of x
        jmp     endHandleCollisions

invert_y:
        mov     ax, ball_y_vel
        xor     bx, bx
        sub     bx, ax
        mov     ball_y_vel, bx                                                  ; Invert velocity of y
        jmp     endHandleCollisions

invert_all:
        mov     ax, ball_x_vel
        xor     bx, bx
        sub     bx, ax
        mov     ball_x_vel, bx                                                  ; Invert velocity of x

        mov     ax, ball_y_vel
        xor     bx, bx
        sub     bx, ax
        mov     ball_y_vel, bx                                                  ; Invert velocity of y
        jmp     endHandleCollisions

check_paddle_collision:
        call    checkPaddleCollision

        ; Handle the collision, if there is one
        cmp     ax, 1
        jz      left_coll                                                       ; Invert ball_x_vel
        cmp     ax, 2
        jz      middle_coll                                                     ; Invert ball_y_vel
        cmp     ax, 3
        jz      right_coll                                                      ; Invert ball_x_vel and ball_y_vel
        jmp    endHandleCollisions                                              ; No collisions, nothing to update

left_coll:
        mov     ball_x_vel, -1
        mov     ball_y_vel, -1
        jmp     endHandleCollisions

middle_coll:
        mov     ball_x_vel, 0
        mov     ball_y_vel, -1
        jmp     endHandleCollisions

right_coll:
        mov     ball_x_vel, 1
        mov     ball_y_vel, -1
        jmp     endHandleCollisions

endHandleCollisions:
        ; End of function
        pop     es
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret



; Resets the ball to default position and velocity. Returns the number of lives.
resetAfterBallLoss:
        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx
        push    es

        ; Reset ball position
        mov     ball_x, 160
        mov     ball_y, 144

        ; Reset ball velocity
        mov     ball_x_vel, 0
        mov     ball_y_vel, -1

        ; Draw ball at reset location
        push    144
        push    160
        push    0Fh
        call drawPixel

        ; Reset the paddle (x-coordinate and length)
        mov     paddle_x, 144
        mov     paddle_length, 32

        ; Draw paddle at reset location
        call    drawPaddle

        ; Remove the laser if it was there
        mov     ax, laser_power_up
        cmp     ax, 1
        je      remove_laser_for_reset
        jmp     no_laser

remove_laser_for_reset:
        mov     laser_power_up, 0                                               ; Set power-up as off (0)
        mov     ax, laser_x
        mov     bx, laser_y
	push    bx	                                                        ; y = laser_y
	push    ax	                                                        ; x = laser_x
	push    00h	                                                        ; color = 00 - Black
	call    drawPixel                                                       ; Erase the laser at the current position

no_laser:
        ; Call decreaseLives
        call decreaseLives

        ; End of function
        pop     es
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret



; draws a horizontal line on y, from x1 (included) to x2 (excluded).
drawLine_h:
        ; Initialize variables
        color   EQU ss:[bp+4]
        x1      EQU ss:[bp+6]
        y       EQU ss:[bp+8]
        x2      EQU ss:[bp+10]

        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx

        ; Set variables before loop
        mov     bx, x1                                                          ; bx contains x1
        mov     cx, x2
        sub     cx, bx                                                          ; cx contains x2 - x1 (nb of iterations)
        mov     dx, y                                                           ; dx contains y

        mov     ax, cx                                                          ; x1 = x2, we dont draw anything.
        jz      hEnd

hLineLoop:
        push    bx
        push    cx
        push    dx

        push    dx
        push    bx
        push    color
        call    drawPixel                                                       ; draw pixel

        pop     dx
        pop     cx
        pop     bx

        add     bx, 1                                                           ; we want to draw to the right
        sub     cx, 1                                                           ; decrease counter
        mov     ax, cx
        jnz     hLineLoop                                                       ; check if counter reached 0

hEnd:
        ; End of function
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret     8



; draws a vertical line on x, from y1 (included) to y2 (excluded).
drawLine_v:
        ; Initialize variables
        color   EQU ss:[bp+4]
        x       EQU ss:[bp+6]
        y1      EQU ss:[bp+8]
        y2      EQU ss:[bp+10]

        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx

        ; Set variables before loop
        mov     bx, y1                                                          ; bx contains y1
        mov     cx, y2
        sub     cx, bx                                                          ; cx contains y2 - y1 (nb of iterations)
        mov     dx, x                                                           ; dx contains x

        mov     ax, cx                                                          ; y1 = y2, we dont draw anything.
        jz      vEnd

vLineLoop:
        push    bx
        push    cx
        push    dx

        push    bx
        push    dx
        push    color
        call    drawPixel                                                       ; draw pixel

        pop     dx
        pop     cx
        pop     bx

        add     bx, 1                                                           ; we want to draw below
        sub     cx, 1                                                           ; decrease counter
        mov     ax, cx
        jnz     vLineLoop                                                       ; check if counter reached 0

vEnd:
        ; End of function
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret     8



; Draws a rectangle
countourRectangle:
        ; Initialize variables
        x1      EQU ss:[bp+4]
        x2      EQU ss:[bp+6]
        y1      EQU ss:[bp+8]
        y2      EQU ss:[bp+10]
        color   EQU ss:[bp+12]

        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx

        ; Draw horizontal lines
        push    x2
        push    y1
        push    x1
        push    color
        call    drawLine_h
        
        mov     ax, x2
        add     ax, 1
        push    ax
        push    y2
        push    x1
        push    color
        call    drawLine_h

        ; Draw vertical lines
        push    y2
        push    y1
        push    x1
        push    color
        call    drawLine_v

        push    y2
        push    y1
        push    x2
        push    color
        call    drawLine_v

        ; End of function
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret     10



; Fills the rectangle of edge_color with the fill_color
simple_fill:
        ; Initialize variables
        x               EQU ss:[bp+4]
        y               EQU ss:[bp+6]
        fill_color      EQU ss:[bp+8]
        edge_color      EQU ss:[bp+10]

        initialX        EQU ss:[bp+4]
        initialY        EQU ss:[bp+6]

        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx

        mov     bx, x
        mov     cx, y

sweepDown:
        push    bx
        push    cx
        push    cx
        push    bx
        call    getPixel                                                        ; get the color of the current pixel
        pop     cx
        pop     bx
        mov     dx, edge_color
        cmp     ax, dx
        jz      doneSweepDown

downRightLoop:
        push    bx
        push    cx
        push    cx
        push    bx
        call    getPixel                                                        ; get the color of the current pixel
        pop     cx
        pop     bx
        mov     dx, edge_color
        cmp     ax, dx
        jz      doneDownRight                                                   ; done right side

        ; otherwise, we color the current pixel
        push    bx
        push    cx
        push    cx
        push    bx
        push    fill_color
        call    drawPixel
        pop     cx
        pop     bx

        ; increment x for next loop
        inc     bx
        jmp     downRightLoop

doneDownRight:
        xor     ax, ax
        mov     ax, initialX
        sub     ax, 1
        mov     bx, ax	; set x to initialX - 1
        jmp     downLeftLoop

downLeftLoop:
        push    bx
        push    cx
        push    cx
        push    bx
        call    getPixel                                                        ; get the color of the current pixel
        pop     cx
        pop     bx
        mov     dx, edge_color
        cmp     ax, dx
        jz      doneDownLeft                                                    ; done left side

        ; otherwise, we color the current pixel
        push    bx
        push    cx
        push    cx
        push    bx
        push    fill_color
        call    drawPixel
        pop     cx
        pop     bx

        ; decrement x for next loop
        dec     bx
        jmp     downLeftLoop

doneDownLeft:
        xor     ax, ax
        mov     ax, initialX
        mov     bx, ax                                                          ; set x to initialX
        inc     cx
        jmp     sweepDown

doneSweepDown:
        ; End of function
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret     8



; Draws a rectangle (contour and fill)
drawRectangle:
        ; Initialize variables
        x1      EQU ss:[bp+4]
        x2      EQU ss:[bp+6]
        y1      EQU ss:[bp+8]
        y2      EQU ss:[bp+10]
        color   EQU ss:[bp+12]

        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx

        ; Draw the contour of the rectangle
        push    color
        push    y2
        push    y1
        push    x2
        push    x1
        call    countourRectangle

        ; Fill the rectangle
        mov     bx, x1
        add     bx, 1
        mov     cx, y1
        add     cx, 1
        push    color
        push    color
        push    cx
        push    bx
        call simple_fill

        ; End of function
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret     10



; Draws the paddle
drawPaddle:
        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx

        ; Clear the paddle zone
        call    clearPaddleZone

        ; Compute the length of the side rectangles
        mov     ax, paddle_length
        sub     ax, 4
        mov     bl, 2
        div     bl
        xor     ah, ah

        ; Draw the first rectangle of the paddle
        mov     bx, paddle_x
        add     bx, ax
        sub     bx, 1
        push    ax                                                              ; Save (paddle_length - 4) / 2
        push    bx                                                              ; Save ending of first rectangle

        push    2Ch
        push    187
        push    184
        push    bx
        push    paddle_x
        call    drawRectangle

        pop     bx                                                              ; Pop back bx
        pop     ax                                                              ; Pop back ax

        ; Draw the second rectangle of the paddle
        add     bx, 1
        mov     cx, bx
        add     cx, 3
        push    ax                                                              ; Save (paddle_length - 4) / 2
        push    cx                                                              ; Save ending of second rectangle

        push    2Dh
        push    187
        push    184
        push    cx
        push    bx
        call    drawRectangle

        pop     cx                                                              ; Pop back cx
        pop     ax                                                              ; Pop back ax

        ; Draw the third rectangle of the paddle
        add     cx, 1
        mov     bx, cx
        add     bx, ax
        sub     bx, 1
        push    2Eh
        push    187
        push    184
        push    bx
        push    cx
        call    drawRectangle

        ; End of function
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret



; Activates and initializes the laser power-up
activateLaser:
        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx

        ; Remove laser if already there (cuz theres a cheat) - if you don't cheat you can technically safely delete this section
        mov     laser_power_up, 0                                               ; Set power-up as off (0)
        mov     ax, laser_x
        mov     bx, laser_y
	push    bx	                                                        ; y = laser_y
	push    ax	                                                        ; x = laser_x
	push    00h	                                                        ; color = 00 - Black
	call    drawPixel                                                       ; Erase the laser at the current position

        ; Activate power-up
        mov     laser_power_up, 1
        mov     ax, paddle_length
        mov     bl, 2
        div     bl
        xor     ah, ah
        add     ax, paddle_x
        mov     laser_x, ax

spawn_laser:
        mov     laser_y, 183

        ; End of function
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret



; Cheat function to spawn a laser without points restriction
cheater:
        ; Subroutine
        push    bp
        mov     bp, sp

        push    bx
        push    cx
        push    dx

        ; CHEATER CHEATER CHEATER CHEATER CHEATER CHEATER CHEATER CHEATER CHEATER CHEATER CHEATER CHEATER CHEATER CHEATER CHEATER CHEATER 
        call    activateLaser

        ; End of function
        pop     dx
        pop     cx
        pop     bx

        pop     bp

        ret


; Start of main
start:
        mov     ax, @data
        mov     ds, ax

        push    OFFSET studentID                                                ; do not change this, change the string in the data section only
        push    ds
        call    setupGame                                                       ; change video mode, draw walls & write score, studentID and lives

        ; Draw the bricks
        call    drawBricks

main_loop:
        ; Sleep so animations are not too fast
        call    sleep

        ; Increment main loop iteration
        mov     ax, paddle_time
        add     ax, 1
        mov     paddle_time, ax

        ; Check for power-up reset
        mov     ax, paddle_time
        cmp     ax, 500
        jge     power_down
        jmp     after_paddle_reset

power_down:
        ; Reset paddle length
        mov     paddle_length, 32
        jmp     after_paddle_reset

after_paddle_reset:
        ; Check if there is a laser
        mov     ax, laser_power_up
        cmp     ax, 1
        je      move_laser
        jmp     after_powers

move_laser:
        
        call    drawLaser                                                       ; Move the laser and check for collisions
        call    handleLaserCollisions
        jmp     after_powers

after_powers:
        call    drawPaddle                                                      ; Move ball while handling collisions
        call    drawBall
        call    handleCollisions

        mov     ax, ball_y                                                      ; Check if ball is lost (below paddle)
        cmp     ax, 199
        jg      reset_ball
        jmp     keypressCheck

reset_ball:
        call    resetAfterBallLoss                                              ; Reset the ball and check if player is dead
        cmp     ax, 0
        jg      keyboardInput
        jmp     keypressThenExit

keypressThenExit:
        mov     ah, 00h                                                         ; wait for keyboard input
        int     16h                                                             
        jmp     exit                                                            ; exit after keyboard input

keypressCheck:
        mov     ah, 01h ; check if keyboard is being pressed
        int     16h ; zero flag (zf) is set to 1 if no key pressed
        jz      main_loop ; if zero flag set to 1 (no key pressed), loop back

keyboardInput:
        ; else get the keyboard input
        mov     ah, 00h
        int     16h

        ; A: move the paddle left by 8 pixels
        cmp     al, 61h
        je      move_paddle_left
        cmp     al, 41h
        je      move_paddle_left

        ; D: move the paddle right by 8 pixels
        cmp     al, 64h
        je      move_paddle_right
        cmp     al, 44h
        je      move_paddle_right

        ; 3: free laser power-up
        cmp     al, 33h
        ;je      you_are_a_cheater

        ; 4: infinite long-paddle
        cmp     al, 34h
        ;je      wow_you_are_a_cheater
        jmp     wow_good_job_for_not_cheating

wow_good_job_for_not_cheating:
        ; 1: long paddle power-up
        cmp     al, 31h
        je      long_paddle

        ; 2: laser power-up
        cmp     al, 32h
        je      laser
        jmp     check_for_exit

you_are_a_cheater:
        call    cheater
        jmp     main_loop

wow_you_are_a_cheater:
        mov     paddle_time, 0                                                ; Set power-up timer to 0
        mov     paddle_length, 64
        jmp     main_loop 

check_for_exit:
        ; Escape: exit the program
        cmp     al, 1bh
        je      exit
        jmp     main_loop                                                       ; Otherwise, go back to main loop

move_paddle_left:
        mov     ax, paddle_x
        sub     ax, 8
        cmp     ax, 0
        jl      set_paddle_to_min
        mov     paddle_x, ax                                                    ; Decrement paddle_x by 8
        jmp     main_loop

set_paddle_to_min:
        mov     paddle_x, 0                                                     ; Set paddle_x to 0
        jmp     main_loop

move_paddle_right:
        mov     ax, paddle_x
        add     ax, 8
        mov     bx, 320
        sub     bx, paddle_length
        cmp     ax, bx
        jg      set_paddle_to_max
        mov     paddle_x, ax                                                    ; Increment paddle_x by 8
        jmp     main_loop

set_paddle_to_max:
        mov     paddle_x, bx                                                    ; Set paddle_x to (320 - paddle_length)
        jmp     main_loop

long_paddle:
        call    getScore
        mov     bx, score_diff
        sub     ax, bx
        cmp     ax, 50                                                          ; Check if player has enough points
        jge     activate_long_paddle                                            ; If yes, activate power-up
        jmp     main_loop                                                       ; If not, ignore input

activate_long_paddle:
        call    getScore
        mov     score_diff, ax                                                  ; Update current score
        mov     paddle_time, 0                                                  ; Set power-up timer to 0
        mov     paddle_length, 64                                               ; Activate power-up
        jmp     main_loop

laser:
        call    getScore
        mov     bx, score_diff
        sub     ax, bx
        cmp     ax, 50                                                          ; Check if player has enough points
        jge     activate_laser                                                  ; If yes, activate power-up
        jmp     main_loop                                                       ; If not, ignore input

activate_laser:
        call    getScore
        mov     score_diff, ax                                                  ; Update current score
        call    activateLaser                                                   ; Activate power-up
        jmp     main_loop

exit:
        mov     ax, 4f02h                                                       ; change video mode back to text
        mov     bx, 3
        int     10h

        mov     ax, 4c00h                                                       ; exit
        int     21h

END start

