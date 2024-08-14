local playerDice = {}
local computerDice = {}
local playerBetFace = 0
local playerBetCount = 0
local computerBetFace = 0
local computerBetCount = 0
local round = 1
local playerWins = 0
local computerWins = 0
local message = "Roll the dice!"
local gameState = "roll"
local background
local bgWidth, bgHeight

local musicTracks = {}
local currentTrackIndex = 1

function love.load()
    -- Load the background image
    background = love.graphics.newImage("background.png")
    
    -- Get the dimensions of the background image
    bgWidth, bgHeight = background:getDimensions()
    
    -- Set the window size to match the background image dimensions
    love.window.setMode(bgWidth, bgHeight)
    
    love.window.setTitle("Liar's Dice")

    -- Load a large, bold font
    local boldFont = love.graphics.newFont("Kleader.ttf", 36)
    love.graphics.setFont(boldFont)
    
    math.randomseed(os.time())  -- Seed the random number generator

    -- Load music tracks
    musicTracks = {
    --    love.audio.newSource("ost1.mp3", "stream"),
        love.audio.newSource("ost2.mp3", "stream"),
        love.audio.newSource("ost3.mp3", "stream"),
        love.audio.newSource("ost4.mp3", "stream")
    }

      -- Set all tracks' volume to 50%
      for _, track in ipairs(musicTracks) do
        track:setVolume(0.2)  -- Set volume to 50%
    end

    -- Shuffle the tracks
    for i = #musicTracks, 2, -1 do
        local j = math.random(1, i)
        musicTracks[i], musicTracks[j] = musicTracks[j], musicTracks[i]
    end

    -- Play the first track
    love.audio.play(musicTracks[currentTrackIndex])
end

function love.update(dt)
    -- Check if the current track has finished playing
    if not musicTracks[currentTrackIndex]:isPlaying() then
        -- Move to the next track
        currentTrackIndex = currentTrackIndex + 1
        if currentTrackIndex > #musicTracks then
            currentTrackIndex = 1  -- Loop back to the first track
        end
        love.audio.play(musicTracks[currentTrackIndex])
    end
end

local function rollFiveDice()
    local dice = {}
    for i = 1, 5 do
        table.insert(dice, math.random(1, 6))
    end
    return dice
end

local function rollDice()
    playerDice = rollFiveDice()
    computerDice = rollFiveDice()
end

local function countTotalDice(face)
    local totalCount = 0
    for _, die in ipairs(playerDice) do
        if die == face then totalCount = totalCount + 1 end
    end
    for _, die in ipairs(computerDice) do
        if die == face then totalCount = totalCount + 1 end
    end
    return totalCount
end

local function callBluff(isPlayerCalling)
    local totalCount = countTotalDice(isPlayerCalling and computerBetFace or playerBetFace)
    
    -- Clear the message before updating it
    message = ""

    if isPlayerCalling then
        if totalCount >= computerBetCount then
            computerWins = computerWins + 1
            message = "You call and lose! The computer was right."
        else
            playerWins = playerWins + 1
            message = "You call and win! The computer bluffed."
        end
    else
        if totalCount >= playerBetCount then
            playerWins = playerWins + 1
            message = "Computer calls and loses! You were right."
        else
            computerWins = computerWins + 1
            message = "Computer calls and wins! You bluffed."
        end
    end
    
    gameState = "end"
end


local function computerCallBluff()
    local totalCount = countTotalDice(playerBetFace)
    
    if totalCount < playerBetCount then
        message = "Computer calls your bluff!"
        callBluff(false)  -- false indicates that the computer is calling the player's bluff
    else
        -- If the bet seems reasonable, the computer continues to place a bet
        computerBetFace = playerBetFace
        computerBetCount = playerBetCount + math.random(1, 2)
        message = "Your bet: " .. playerBetCount .. " " .. playerBetFace .. "'s\n" ..
                  "Computer bet: " .. computerBetCount .. " " .. computerBetFace .. "'s. Call (C) or Raise (R)?"
        gameState = "call"
    end
end

local function placeBet()
    -- Computer AI decides to either raise or call bluff
    if math.random() > 0.5 then  -- 50% chance to call bluff
        computerCallBluff()
    else
        -- If not calling bluff, place a normal bet
        local computerCount = countTotalDice(playerBetFace)

        -- Ensure the computer's bet is valid (i.e., higher than the player's bet)
        if computerCount >= playerBetCount then
            -- If the computer has enough of the current face, it can raise the count
            computerBetFace = playerBetFace
            computerBetCount = playerBetCount + math.random(1, 2)
        else
            -- If the computer cannot raise the count, it must raise the face value
            if playerBetFace < 6 then
                computerBetFace = playerBetFace + 1
                computerBetCount = math.max(1, math.random(1, 2))
            else
                -- In the rare case where the player's bet is maxed out (e.g., 6 6's), the computer must call bluff
                computerCallBluff()
                return
            end
        end

        message = "Your bet: " .. playerBetCount .. " " .. playerBetFace .. "'s\n" ..
                  "Computer bet: " .. computerBetCount .. " " .. computerBetFace .. "'s. Call (C) or Raise (R)?"
        gameState = "call"
    end
end


local function raiseBet()
    if playerBetFace < computerBetFace or (playerBetFace == computerBetFace and playerBetCount <= computerBetCount) then
        message = "Raise must be higher than the current bet!"
    else
        placeBet()
    end
end

local function resetGame()
    round = round + 1
    playerBetFace = 0
    playerBetCount = 0
    computerBetFace = 0
    computerBetCount = 0
    gameState = "roll"
    message = "Roll the dice!"
end

function love.keypressed(key)
    if gameState == "roll" then
        if key == "space" then
            rollDice()
            gameState = "bet"
            message = "Place your bet on a face value and count!"
        end
    elseif gameState == "bet" or gameState == "raise" then
        if key == "up" then
            playerBetCount = playerBetCount + 1
        elseif key == "down" then
            playerBetCount = math.max(1, playerBetCount - 1)
        elseif key == "right" then
            playerBetFace = math.min(6, playerBetFace + 1)
        elseif key == "left" then
            playerBetFace = math.max(1, playerBetFace - 1)
        elseif key == "return" then
            if playerBetFace > 0 and playerBetCount > 0 then
                if gameState == "bet" then
                    placeBet()
                elseif gameState == "raise" then
                    raiseBet()
                end
            else
                message = "You must choose a valid face value and count!"
            end
        end
    elseif gameState == "call" then
        if key == "c" then
            callBluff(true)
        elseif key == "r" then
            gameState = "raise"
            playerBetFace = computerBetFace  -- Start with the current bet face value
            playerBetCount = computerBetCount  -- Start with the current bet count
            message = "Raise the bet! Adjust it, then press ENTER."
        end
    elseif gameState == "end" then
        if key == "r" then
            resetGame()
        end
    end
end

function love.draw()
    local shadowOffset = 2  -- The amount by which the shadow is offset
    local shadowColor = {0, 0, 0, 0.5}  -- Dark color with some transparency for the shadow
    local deepRedColor = {0.6, 0, 0, 1}  -- Deep red color

    -- Get the height of the current font to adjust line spacing
    local fontHeight = love.graphics.getFont():getHeight()
    local lineSpacing = fontHeight  -- Adjust the multiplier as needed

    -- Define the Y positions for the lines of text using dynamic spacing
    local line1Y = 20
    local line2Y = line1Y + lineSpacing
    local line3Y = line2Y + lineSpacing
    local line4Y = line3Y + lineSpacing
    local line5Y = line4Y + lineSpacing
    local line6Y = line5Y + lineSpacing
    local line7Y = line6Y + lineSpacing

    -- Draw the background image
    love.graphics.draw(background, 0, 0)

    -- Overlay a semi-transparent rectangle to dim the background
    love.graphics.setColor(0, 0, 0, 0.5)  -- Black with 50% opacity
    love.graphics.rectangle("fill", 0, 0, bgWidth, bgHeight)

    -- Reset color to white for drawing text
    love.graphics.setColor(1, 1, 1, 1)
    -- Draw the round and score with shadow on the first line
    local roundMessage = "Round: " .. round .. " | You: " .. playerWins .. " | Computer: " .. computerWins
    love.graphics.setColor(shadowColor)
    love.graphics.printf(roundMessage, shadowOffset, line1Y + shadowOffset, bgWidth, "center")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(roundMessage, 0, line1Y, bgWidth, "center")

    -- Draw the message on the second line
    love.graphics.setColor(shadowColor)
    love.graphics.printf(message, shadowOffset, line2Y + shadowOffset, bgWidth, "center")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(message, 0, line2Y, bgWidth, "center")

    if gameState == "roll" then
        love.graphics.setColor(shadowColor)
        love.graphics.printf("Press SPACE to roll the dice.", shadowOffset, line4Y + shadowOffset, bgWidth, "center")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Press SPACE to roll the dice.", 0, line4Y, bgWidth, "center")
    elseif gameState == "bet" or gameState == "raise" then
        local betMessage = "Your bet: " .. playerBetCount .. " " .. playerBetFace .. "'s"
        love.graphics.setColor(shadowColor)
        love.graphics.printf(betMessage, shadowOffset, line3Y + shadowOffset, bgWidth, "center")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(betMessage, 0, line3Y, bgWidth, "center")
        
        local controlMessage = "Press UP/DOWN to adjust count, LEFT/RIGHT to adjust face value, ENTER to confirm."
        love.graphics.setColor(shadowColor)
        love.graphics.printf(controlMessage, shadowOffset, line4Y + shadowOffset, bgWidth, "center")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf(controlMessage, 0, line4Y, bgWidth, "center")
    elseif gameState == "call" then
        love.graphics.setColor(shadowColor)
        love.graphics.printf("Press 'C' to call bluff, 'R' to raise bet.", shadowOffset, line4Y + shadowOffset, bgWidth, "center")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Press 'C' to call bluff, 'R' to raise bet.", 0, line4Y, bgWidth, "center")
    elseif gameState == "end" then
        love.graphics.setColor(shadowColor)
        love.graphics.printf("Press 'R' to play again.", shadowOffset, line3Y + shadowOffset, bgWidth, "center")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Press 'R' to play again.", 0, line3Y, bgWidth, "center")
    end

    -- Display player's dice with shadow on the fifth line
    love.graphics.setColor(shadowColor)
    love.graphics.printf("Your dice: ", shadowOffset, line6Y + shadowOffset, bgWidth, "left")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("Your dice: ", 0, line6Y, bgWidth, "left")
    
    for i, die in ipairs(playerDice) do
        -- Draw the shadow for each die
        love.graphics.setColor(shadowColor)
        love.graphics.printf(tostring(die), line5Y + (i - 1) * 30 + shadowOffset, line6Y + shadowOffset, 30, "center")

        -- Draw the die in deep red
        love.graphics.setColor(deepRedColor)
        love.graphics.printf(tostring(die), line5Y + (i - 1) * 30, line6Y, 30, "center")

        -- Reset color to white after drawing the number
        love.graphics.setColor(1, 1, 1, 1)
    end

    -- Optionally, display computer's dice on the sixth line
    if gameState == "end" then
        love.graphics.setColor(shadowColor)
        love.graphics.printf("Computer's dice: ", shadowOffset, line7Y + shadowOffset, bgWidth, "left")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.printf("Computer's dice: ", 0, line7Y, bgWidth, "left")
        
        for i, die in ipairs(computerDice) do
            -- Draw the shadow for each die
            love.graphics.setColor(shadowColor)
            love.graphics.printf(tostring(die), line7Y + (i - 1) * 30 + shadowOffset, line7Y + shadowOffset, 30, "center")

            -- Draw the die in deep red
            love.graphics.setColor(deepRedColor)
            love.graphics.printf(tostring(die), line7Y + (i - 1) * 30, line7Y, 30, "center")

            -- Reset color to white after drawing the number
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end
