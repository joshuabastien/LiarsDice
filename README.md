# Liar's Dice

## Overview

A simple **Liar's Dice** game built in Lua with LOVE2D. Play against a computer opponent by betting on the number of dice showing a certain face value. Win rounds by making accurate bets or successfully calling the computer's bluffs.

## Lua Technical Details

- **Game Logic**: Dice rolls are stored in `playerDice` and `computerDice`. Bets are tracked with variables like `playerBetFace` and `computerBetCount`. AI decisions are handled by `computerCallBluff()` and `placeBet()` functions.

- **Graphics/Audio**: Background and text are rendered with `love.graphics`, while music tracks are managed with `love.audio.newSource()` and shuffled for continuous play.

- **State Management**: The game uses a `gameState` variable to control flow between `"roll"`, `"bet"`, `"raise"`, `"call"`, and `"end"` phases.

- **Input Handling**: Player inputs are processed in `love.keypressed()` and vary according to the current `gameState`.

### Input Handling

- **Key Presses**: The `love.keypressed()` function handles player input, with actions varying depending on the current `gameState`.

## Setup

1. Install [LOVE2D](https://love2d.org/).
2. Clone this repository.
3. Run the game with LOVE2D:

   ```bash
   love .
