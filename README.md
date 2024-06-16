# Snake Game in Assembly

## Introduction
This project involves writing a simplified single-player version of the Snake game in assembly language. The game runs on a Nios II processor and is demonstrated on a Gecko4EPFL board. The purpose of this project is to understand computer architecture concepts by implementing a fun and interactive game.

## Requirements
- Nios II Processor
- nios2sim Simulator
- Gecko4EPFL board
- Quartus and VHDL files
- Assembly code file (`snake.asm`)

## About the Game
The Snake game consists of a snake that moves around the screen to eat food while avoiding obstacles. The player's goal is to maximize their score by consuming food. The snake grows longer with each food item consumed. The game ends if the snake hits an obstacle or itself.

## Setup Instructions

### Prerequisites
Ensure you have the following tools installed:
- Quartus II software
- Nios II EDS
- nios2sim simulator

### Folder Structure
Your project directory should be structured as follows:

project_root/

├── Nios II (Snake Game)/├── quartus/

│ │ └── [Quartus project files]

│ └── vhdl/

│ └── [VHDL files]

│
├── demo.MOV

├── NiosII.jar

├── README.md

├── snake.asm

└── snake.pdf


### Steps to Run the Game
1. **Assemble the Code**: Use the Nios II EDS to assemble the `snake.asm` file.
   ```sh
   nios2-elf-as snake.asm -o snake.o
   nios2-elf-ld snake.o -o snake.elf
   nios2-elf-objcopy -O srec snake.elf snake.srec

2. **Simulate using nios2sim**:
- Open the nios2sim simulator.
- Load the assembled code (`snake.srec`) into the simulator.
- Test the game functionality.

3. **Load onto FPGA**:
- Open the Quartus project in the `quartus/` directory.
- Compile the project.
- Program the FPGA with the compiled code.
- Load the assembled code (`snake.srec`) into the FPGA using Nios II terminal.

4. **Running on Gecko4EPFL**:
- Connect the Gecko4EPFL board to your system.
- Load the assembled code and start the game on the board.

### NiosII.jar Simulator
This NiosII simulator has support for the 5th button. It has been compiled under Java 9. The button view is reindexed from 0--4. For backwards compatibility, the jar file was exported for Java 8, and we have tested it under Java 11 (openjdk) and Java 17 (openjdk).

## Detailed Description

### Memory Layout
The game state is stored in specific memory locations:
- `0x1000` to `0x100C`: Head and tail positions of the snake
- `0x1010`: Score
- `0x1014` to `0x1198`: Game State Array (GSA) for LED representation
- `0x1200` to `0x121C`: Checkpoint data
- `0x2000` to `0x2010`: LEDs
- `0x2030`: Buttons

### Procedures Implemented
The following procedures are implemented in the `snake.asm` file:
- `clear_leds`: Clears the LED display
- `set_pixel`: Lights up a specific LED pixel
- `get_input`: Captures button inputs for controlling the snake
- `move_snake`: Updates the snake's position based on the input
- `draw_array`: Draws the snake and food on the LED display
- `create_food`: Generates new food at a random location
- `hit_test`: Detects collisions with boundaries, food, or the snake itself
- `display_score`: Shows the score on the 7-segment display
- `init_game`: Initializes the game state
- `save_checkpoint`: Saves the current game state at checkpoints
- `restore_checkpoint`: Restores the game state from the last checkpoint

### Game Flow
1. **Initialization**:
- The game is initialized with the snake at the top-left corner and moving rightwards.
- Food is placed at a random location.

2. **Gameplay Loop**:
- The snake moves based on player input.
- Collisions are detected to determine game over or score increments.
- The game state is periodically saved at checkpoints.
- The score is displayed and updated.

3. **Game Over**:
- If the snake collides with itself or the boundary, the game restarts.
- The game can be reset to the last checkpoint using a specific button.

## Demonstration Video
A demonstration video showing the game running on the Gecko4EPFL board is included in this repository (`demo.MOV`). This video provides a quick overview of the gameplay and functionality.

## Testing
The game was tested using the nios2sim simulator. The simulator's consistent behavior with the Gecko4EPFL board ensures the reliability of the game. The simulator allows you to:
- Test the game logic
- Verify the LED display output
- Debug and validate procedures

## Acknowledgements
This project was developed as part of a computer architecture course at EPFL. Special thanks to the course instructors and teaching assistants for their support and guidance.
