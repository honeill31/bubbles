
-- Includes
require "score"
require "colour"
require "timer"

-- VARIABLES FOR BUBBLES --

local world
local circles = {} -- Table to store all circles
local spawnTimer = 0 -- Timer for spawning new circles
local circleRadius = 50 -- Size of the circle
local score = 0 -- To store the score



local loadingBar = {
    x = 128,                -- X position of the bar
    y = 0,                -- Y position of the bar
    width = 544,           -- Total width of the bar
    height = 20,           -- Height of the bar
    alpha = 0.8,            -- Opacity of the entire bar (50% transparent)
    color = {0.667, 0.667, 0.678, 1}, -- Bar fill color (default full opacity)
    backgroundColor = {0.5, 0.5, 0.5, 0.3} -- Background color of the bar

}

local current_round = 1
local current_stage = 1

-- current_stage = 1 - main menu
-- current_stage = 2 - game 
-- current_stage = 3 - score screen

local font = love.graphics.newFont(50)


local round_3_colours = {
    left_rect = s3_left_rectangle_colour,
    right_rect = s3_right_rectangle_colour,
    b_1 = s3_ball_1,
    b_2 = s3_ball_2,
    b_3 = s3_ball_3,
    spawn = 0.4,
    gravity = 100
}


local round_2_colours = {
    left_rect = s2_left_rectangle_colour,
    right_rect = s2_right_rectangle_colour,
    b_1 = s2_ball_1,
    b_2 = s2_ball_2,
    b_3 = s2_ball_3,
    spawn = 0.5,
    gravity = 70
}

local round_1_colours = {
    left_rect = left_rectangle_colour,
    right_rect = right_rectangle_colour,
    b_1 = ball_1,
    b_2 = ball_2,
    b_3 = ball_3,
    spawn = 0.7,
    gravity = 50
}

local round_control = {}
round_control[1] = round_1_colours
round_control[2] = round_2_colours
round_control[3] = round_3_colours

-- Timer
timer = 20.0
timer_begin = 20.0

W = function() return love.graphics.getWidth() end
H = function() return love.graphics.getHeight() end

function get_colour(a_colour)
    result = 0
    if a_colour == 0 then
        return result
    else
        return a_colour/255
    end
end


 -- Rectangles
left_rectangle = {
    x = 0,
    y = 0,
    width = 128,
    height = H(),
    colour = left_rectangle_colour
}

right_rectangle = {
    x = W()-128,
    y = 0,
    width = 128,
    height = H(),
    colour = right_rectangle_colour
}

-- Track the active colours for the left and right rectangles
local left_colour = left_rectangle_colour
local right_colour = right_rectangle_colour
local ball_1_colour = ball_1
local ball_2_colour = ball_2 
local ball_3_colour = ball_3

local world


-- LOVE LOAD --

-- fOR LODING ASSETS INTO THE GAME

function love.load()
    -- Initialize the physics world
    world = love.physics.newWorld(0, round_control[current_round].gravity, true) -- Gravity of 500 in the Y direction
    love.graphics.setBackgroundColor(get_colour(background_colour.red), get_colour(background_colour.green), get_colour(background_colour.blue), get_colour(background_colour.alpha))

    love.graphics.setFont(font)



-- load the sounds


-- Load "PickUp" sounds
pickUpSounds = {}
for i = 1, 4 do
    pickUpSounds[i] = love.audio.newSource(string.format("sounds/PickUp_%d.wav", i), "static")
end


-- load pop sounds
    bubblePopSounds = {}
    for i = 1, 10 do
        bubblePopSounds[i] = love.audio.newSource(string.format("sounds/pop%d.wav", i), "static")
    end

end


-- FUNCTIONS --
-- Function to create a new circle
local function spawnCircle(x, y)
    local body = love.physics.newBody(world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(circleRadius)
    local fixture = love.physics.newFixture(body, shape)
    fixture:setRestitution(0.8) -- Make the circle bouncy

    local can_pop = love.math.random() < 0.5 -- 50% chance to make the circle "pop-able"
    local bubble_colour = left_rectangle_colour

    if (can_pop) then
        local col = love.math.random()
        if (col <= 0.33) then
            bubble_colour = round_control[current_round].b_1
        elseif (col > 0.33 and col < 0.66) then
            bubble_colour = round_control[current_round].b_2
        elseif (col >= 0.66) then
            bubble_colour = round_control[current_round].b_3
        end 
    end

    if (can_pop == false) then 
        local right = love.math.random() < 0.5
        if (right) then 
            bubble_colour = round_control[current_round].left_rect
        else
            bubble_colour = round_control[current_round].right_rect
        end
    end

    

    -- Add the new circle to the circles table
    table.insert(circles, {
        body = body,
        shape = shape,
        fixture = fixture,
        colour = bubble_colour,
        hovered = false,
        dragging = false,
        colliding = false, -- Tracks if the circle is colliding with a rectangle
        canPop = can_pop,
        isScored = false
    })
end

function should_delete(circle)
    -- Is this circle the right colour for this round?
    local round_info = round_control[current_round]
    should = circle.colour ~= round_info.left_rect and 
    circle.colour ~= round_info.right_rect and
    circle.colour ~= round_info.b_1 and 
    circle.colour ~= round_info.b_2 and 
    circle.colour ~= round_info.b_3
    return should
end

-- LOVE UPDATE --

function love.update(dt)

-- Update the physics world
world:update(dt)

-- Calculate the current width of the loading bar
local timeLeftPercent = timer / timer_begin
loadingBar.currentWidth = loadingBar.width * timeLeftPercent

-- normalise score
if (score < 0) then 
    score = 0
end

    -- Update the left/right rectangle colours
    local rnd_idx = current_round
    if (rnd_idx > 3) then 
        rnd_idx = 3
    end 
    left_rectangle.colour = round_control[rnd_idx].left_rect
    right_rectangle.colour = round_control[rnd_idx].right_rect

    if (current_stage == 2) then 
        timer = timer - dt
        if (is_round_over(timer)) then 
            current_round = current_round + 1
            local grav = current_round
            if current_round > 3 then 
                grav = 3
            end
            world:setGravity(0, round_control[grav].gravity)
            if (current_round > 3) then 
                current_stage = 3
                return
                --love.event.quit()
            end
            timer = timer_begin
        end
    
        -- Handle spawning new circles
        spawnTimer = spawnTimer + dt
        if spawnTimer >= round_control[current_round].spawn then
            spawnTimer = 0
            local min_val = left_rectangle.width + circleRadius * 2
            local max_val = W() - right_rectangle.width - circleRadius * 2
            spawnCircle(love.math.random(min_val, max_val), 0) -- Spawn at random X position above the screen
        end
    
        -- Check for collisions and bubble-ball interactions
        local toRemove = {} -- Keep track of bubbles to remove
    
        for i = #circles, 1, -1 do -- Iterate backward to allow safe removal
            local circle = circles[i]
            local circleX, circleY = circle.body:getPosition()

            -- Try to score any circles
            score_circle(circle)
    
            -- Destroy circle if it goes below the bottom of the window, or if wrong colour
            _, height, _ = love.window.getMode()
            if (circleY > height) or (should_delete(circle)) then
                table.insert(toRemove, i)
                goto continue
            end
    
        -- Remove all marked circles
        for _, i in ipairs(toRemove) do
            if (circles[i] ~= nil) then
                circles[i].body:destroy()
                table.remove(circles, i)
            end
        end
    
    -- COLLISIONS --
    -- collisions for the rectangles -- 
    
        -- Collision detection function
        local function checkCircleRectCollision(circleX, circleY, circleRadius, rectX, rectY, rectWidth, rectHeight)
            -- Find the closest point on the rectangle to the circle's center
            local closestX = math.max(rectX, math.min(circleX, rectX + rectWidth))
            local closestY = math.max(rectY, math.min(circleY, rectY + rectHeight))
    
            -- Calculate the distance between the circle's center and this closest point
            local distanceX = circleX - closestX
            local distanceY = circleY - closestY
    
            -- If the distance is less than the circle's radius, there's a collision
            return (distanceX * distanceX + distanceY * distanceY) < (circleRadius * circleRadius)
        end
    
        -- Check for collisions between circles and rectangles
        for i = #circles, 1, -1 do -- Iterate backward to allow safe removal
            local circle = circles[i]
    
            local circleX, circleY = circle.body:getPosition()
    
            -- Destroy circle if it goes below the bottom of the window
            _, height, _ = love.window.getMode()
            if (circleY > height) then 
                circle.body:destroy()
                table.remove(circles, i)
                goto continue
            end
    
            -- Reset collision flag
            circle.colliding = false
    
            -- Collision checks for rectangles
            if checkCircleRectCollision(circleX, circleY, circleRadius, left_rectangle.x, left_rectangle.y, left_rectangle.width, left_rectangle.height) then
                circle.colliding = true -- Mark circle as colliding
            end
    
            if checkCircleRectCollision(circleX, circleY, circleRadius, right_rectangle.x, right_rectangle.y, right_rectangle.width, right_rectangle.height) then
                circle.colliding = true -- Mark circle as colliding
            end
    
        end
    
    -- COLLISIONS END
    
    -- DRAGGING MECHANIC --
    
            -- Handle dragging
            if circle.dragging then
                local mouseX, mouseY = love.mouse.getPosition()
                circle.body:setPosition(mouseX, mouseY) -- Move the circle to the mouse position
                circle.body:setLinearVelocity(0, 0) -- Stop other motion while dragging
            end
    
            ::continue::
        end
    end
end

-- MOUSE PRESS --

function love.mousepressed(x, y, button, istouch, presses)

    if (current_stage == 1) then 
        current_stage = 2
        font = love.graphics.newFont(32)
        love.graphics.setFont(font)
    end

    if (current_stage == 2) then 
        if button == 1 then
            for i = #circles, 1, -1 do -- Iterate backward to safely remove items
                local circle = circles[i]
                local circleX, circleY = circle.body:getPosition()
                local dx, dy = x - circleX, y - circleY
                local isHovered = (dx * dx + dy * dy) <= (circleRadius * circleRadius)
    
                if isHovered then
                    if circle.canPop then
                        -- Play a random pop sound
                        local randomSound = bubblePopSounds[love.math.random(#bubblePopSounds)]
                        randomSound:play()
    
                        -- If the circle can pop, remove it
                        circle.body:destroy() -- Destroy the physics body
                        score = score + 1
                        table.remove(circles, i)
                        return -- Stop processing further since a circle was popped
                    else
                      -- If not pop-able, start dragging
circle.dragging = true
circle.body:setType("kinematic") -- Temporarily disable physics

-- Play a random "PickUp" sound
local randomPickUpSound = pickUpSounds[love.math.random(#pickUpSounds)]
randomPickUpSound:play()
break
                    end
                end
            end
        end
    end
    if (current_stage == 3) then 
        -- Reset round variable
        current_stage = 2
        current_round = 1
        score = 0
        timer = timer_begin
    end
end


function score_circle(circle)
    local circleX, _ = circle.body:getPosition()
    if circle.isScored == false then
        if in_left_rect(circleX) then 
            if (is_same_colour(circle, left_rectangle)) then 
                score = score + 2
            else 
                score = score - 5
            end
            circle.isScored = true
        elseif in_right_rect(circleX) then 
            if (is_same_colour(circle, right_rectangle)) then 
                score = score + 2
                circle.isScored = true
            else 
                score = score - 5
            end
            circle.isScored = true
        end
    end
end

function love.mousereleased(x, y, button, istouch, presses)
    if (current_stage == 2) then 
        if button == 1 then
            for _, circle in ipairs(circles) do
                if circle.dragging then
                    circle.dragging = false
                    circle.body:setType("dynamic") -- Re-enable physics
                    score_circle(circle)
                end
            end
        end
    end
end



-- GRAPHICS SETTINGS 

function love.draw()

    if (current_stage == 1) then 
        love.graphics.setColor(get_colour(left_rectangle.colour.red), get_colour(left_rectangle.colour.green), get_colour(left_rectangle.colour.blue), get_colour(left_rectangle.colour.alpha))
        love.graphics.rectangle("fill", 0, 0, W()/2, H())
        love.graphics.setColor(get_colour(right_rectangle.colour.red), get_colour(right_rectangle.colour.green), get_colour(right_rectangle.colour.blue), get_colour(right_rectangle.colour.alpha))
        love.graphics.rectangle("fill", W()/2, 0, W()/2, H())

        local start_string = "start"
        local game_string  = "game"
        love.graphics.setColor(get_colour(right_rectangle.colour.red), get_colour(right_rectangle.colour.green), get_colour(right_rectangle.colour.blue), get_colour(right_rectangle.colour.alpha))
        love.graphics.print(start_string, W()/2-font:getWidth(start_string)- 5, H()/2)
        love.graphics.setColor(get_colour(left_rectangle.colour.red), get_colour(left_rectangle.colour.green), get_colour(left_rectangle.colour.blue), get_colour(left_rectangle.colour.alpha))
        love.graphics.print(game_string, W()/2 + 5, H()/2)

    end

    if (current_stage == 3) then
        -- Draw the left and right rectangle backgrounds
        love.graphics.setColor(get_colour(left_rectangle.colour.red), get_colour(left_rectangle.colour.green), get_colour(left_rectangle.colour.blue), get_colour(left_rectangle.colour.alpha))
        love.graphics.rectangle("fill", 0, 0, W() / 2, H())
        love.graphics.setColor(get_colour(right_rectangle.colour.red), get_colour(right_rectangle.colour.green), get_colour(right_rectangle.colour.blue), get_colour(right_rectangle.colour.alpha))
        love.graphics.rectangle("fill", W() / 2, 0, W() / 2, H())
    
        -- Draw the "score" text
        local score_string = "score"
        love.graphics.setColor(get_colour(right_rectangle.colour.red), get_colour(right_rectangle.colour.green), get_colour(right_rectangle.colour.blue), get_colour(right_rectangle.colour.alpha))
        love.graphics.print(score_string, W() / 2 - font:getWidth(score_string) - 5, H() / 2)
        love.graphics.setColor(get_colour(left_rectangle.colour.red), get_colour(left_rectangle.colour.green), get_colour(left_rectangle.colour.blue), get_colour(left_rectangle.colour.alpha))
        local num_string = tostring(score)
        love.graphics.print(num_string, W() / 2 + 5, H() / 2)
    
        -- Draw the restart text
        local restart_text_part1 = "click/tap" -- First part of the text
        local restart_text_part2 = "to restart" -- Second part of the text
        local col1 = round_control[3].b_1
        local col2 = round_control[3].b_2
    
        -- Measure widths of the parts to calculate their positions
        local part1_width = font:getWidth(restart_text_part1)
        local total_width = font:getWidth(restart_text_part1 .. " " .. restart_text_part2)
        local start_x = W() / 2 - total_width / 2 -- Centered start position
        local y = H() / 1.4 -- Y position for the text
    
        -- Draw the first part
        love.graphics.setColor(get_colour(right_rectangle.colour.red), get_colour(right_rectangle.colour.green), get_colour(right_rectangle.colour.blue), get_colour(right_rectangle.colour.alpha))
        love.graphics.print(restart_text_part1, start_x, y)
    
        -- Draw the second part, slightly offset to the right
        love.graphics.setColor(get_colour(left_rectangle.colour.red), get_colour(left_rectangle.colour.green), get_colour(left_rectangle.colour.blue), get_colour(left_rectangle.colour.alpha))
        love.graphics.print(restart_text_part2, start_x + part1_width + font:getWidth(" "), y)
    end
    

    if (current_stage == 2) then 
-- Draw the score in the center of the screen
local score_string = string.format("%d", score)
font = love.graphics.newFont(325)
love.graphics.setFont(font)

-- Get the screen dimensions
local screenWidth = love.graphics.getWidth()
local screenHeight = love.graphics.getHeight()

-- Measure the text dimensions
local textWidth = font:getWidth(score_string)
local textHeight = font:getHeight()

-- Calculate the centered position
local x = (screenWidth - textWidth) / 2
local y = (screenHeight - textHeight) / 2

-- Set color with custom RGB and opacity
love.graphics.setColor(219 / 255, 207 / 255, 206 / 255, .3) -- Full opacity

-- Draw the text at the centered position
love.graphics.print(score_string, x, y)

-- Reset the color to avoid affecting other drawings
love.graphics.setColor(1, 1, 1, 1) -- Back to full white
font = love.graphics.newFont(20)
love.graphics.setFont(font)




        -- Draw the rectangles using the color values
        love.graphics.setColor(get_colour(round_control[current_round].left_rect.red), get_colour(round_control[current_round].left_rect.green), get_colour(round_control[current_round].left_rect.blue), get_colour(round_control[current_round].left_rect.alpha))
        love.graphics.rectangle("fill", left_rectangle.x, left_rectangle.y, left_rectangle.width, left_rectangle.height)
        love.graphics.setColor(get_colour(round_control[current_round].right_rect.red), get_colour(round_control[current_round].right_rect.green), get_colour(round_control[current_round].right_rect.blue), get_colour(round_control[current_round].right_rect.alpha))
        love.graphics.rectangle("fill", right_rectangle.x, right_rectangle.y, right_rectangle.width, right_rectangle.height)


        -- Draw each circle
        for _, circle in ipairs(circles) do
            local x, y = circle.body:getPosition()
            love.graphics.setColor(get_colour(circle.colour.red), get_colour(circle.colour.green), get_colour(circle.colour.blue), get_colour(circle.colour.alpha))
            love.graphics.circle("fill", x, y, circleRadius)

        end
    end

    if current_stage == 2 then
       -- Draw the loading bar background
    love.graphics.setColor(
        loadingBar.backgroundColor[1], 
        loadingBar.backgroundColor[2], 
        loadingBar.backgroundColor[3], 
        loadingBar.backgroundColor[4] * loadingBar.alpha
    )
    love.graphics.rectangle("fill", loadingBar.x, loadingBar.y, loadingBar.width, loadingBar.height)

    -- Draw the loading bar fill (loading part)
    local loadingWidth = loadingBar.width * (timer / timer_begin) -- Calculate width based on timer
    love.graphics.setColor(
        loadingBar.color[1], 
        loadingBar.color[2], 
        loadingBar.color[3], 
        loadingBar.color[4] * loadingBar.alpha
    )
    love.graphics.rectangle("fill", loadingBar.x, loadingBar.y, loadingWidth, loadingBar.height)
    end
end

