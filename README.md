# Brick-Breaker-Game

## Game Rules
* Break all the bricks before you lose all your balls to win the game
* Use the paddle to prevent the ball from falling, which costs a life
* Press 'a' or 'A' to move the paddle to the left
* Press 'd' or 'D' to move the paddle to the right

## Power-Ups
Each brick that is broken awards points, and 50 points can be used to activate a power-up.

Point Distribution:
* Bricks in the bottom two rows: 2 points
* Bricks in the middle two rows: 3 points
* Bricks in the top two rows: 5 points

Power-Ups:
* Long Paddle (Press 1): doubles the size of your paddle (500 iterations of the main loop)
* Laser (Press 2): shoots out a pixel-sized red laser out of the middle of the paddle, towards the top of the screen (destroys at most one brick)

## Game Implementation
This .asm program interacts with the GPU to display the game, but also to interact (a ball collision is determined when it hits a non-black pixel - bricks are coloured and walls have fixed x- and y- coordinates on the screen).

### Ball
Global variables are used to keep track of the ball's x- and y-coordinates, as well as the x- and y-velocity.

The ball is represented by drawing a pixel at its current location. Its movement is represented by setting the pixel at its current location back to black (background color), and drawing the white pixel at a new location, according to its x- and y-velocities.

A collision with the wall is determined when the ball reaches a corner (since the video mode is set to 13h, the x- and y-coordinates can easily be computed). Depending on the wall that the ball hit, the x- and/or y-velocities will be inverted.

A collision with the paddle changes the direction depending on which section of the paddle the ball hit (see the [Paddle section down below](https://github.com/z1chh/Brick-Breaker-Game/edit/main/README.md#L38))).

Losing the ball resets the ball at the initial position (as well as the paddle), and the program waits for user input before continuing the game. A life will be decreased as well. A ball is lost if its y-coordinate is greater than 199 (bottom of the screen = higher y-coordinate).

### Paddle
Global variables are used to keep track of the paddle's x-coordinate (left-end of the paddle) (the y-coordinate does not change - hardcoded) and its length (default is 32, power-up 1 changes it temporarily to 64).

The drawPaddle method takes as input the x-coordinate of the paddle and its length. It then draws 3 rectangles and fills them with their own color.

Moving the paddle changes its x-coordinate by 8 pixels, while making sure that it doesn't get out of the screen (which technically means that the paddle would appear higher or lower in the screen, depending of if you moved too far to the left or right).
