
-- Includes
require "score"
require "colour"

-- VARIABLES FOR BUBBLES --

local world
local circles = {} -- Table to store all circles
local spawnTimer = 0 -- Timer for spawning new circles
local spawnInterval = 0.3 -- Spawn a circle every second
local circleRadius = 50 -- Size of the circle
local basketImage -- basket image
local score = 0 -- To store the score
local gravity = 100

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
    height = H()
}

right_rectangle = {
    x = W()-128,
    y = 0,
    width = 128,
    height = H()
}

-- Track the active colours for the left and right rectangles
local left_colour = left_rectangle_colour
local right_colour = right_rectangle_colour


-- LOVE LOAD --

-- fOR LODING ASSETS INTO THE GAME

function love.load()
    -- Initialize the physics world
    world = love.physics.newWorld(0, gravity, true) -- Gravity of 500 in the Y direction
    love.graphics.setColor(255,255,255)
    font = love.graphics.newFont(32)

    -- Load the images
    bubbleImage = love.graphics.newImage("bubble.png")
    ballImage = love.graphics.newImage("ball.png")
    basketImage = love.graphics.newImage("basket.png")
    



-- load the sounds

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
        if (col < 0.33) then
            bubble_colour = ball_1
        elseif (col > 0.33 and col < 0.66) then
            bubble_colour = ball_2
        elseif (col > 0.66) then
            bubble_colour = ball_3
        end 
    end

    if (can_pop == false) then 
        local right = love.math.random() < 0.5
        if (right) then 
            bubble_colour = left_rectangle_colour
        else
            bubble_colour = right_rectangle_colour
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
        canPop = can_pop
    })
end



-- LOVE UPDATE --

function love.update(dt)
    -- Update the physics world
    world:update(dt)

    -- Handle spawning new circles
    spawnTimer = spawnTimer + dt
    if spawnTimer >= spawnInterval then
        spawnTimer = 0
        spawnCircle(love.math.random(left_rectangle.x + circleRadius, W()-left_rectangle.x - circleRadius), -circleRadius) -- Spawn at random X position above the screen
    end

    -- Check for collisions and bubble-ball interactions
    local toRemove = {} -- Keep track of bubbles to remove

    for i = #circles, 1, -1 do -- Iterate backward to allow safe removal
        local circle = circles[i]
        local circleX, circleY = circle.body:getPosition()

        -- Destroy circle if it goes below the bottom of the window
        _, height, _ = love.window.getMode()
        if (circleY > height) then
            if can_increase_score(circleX) then
                score = increase_score(score)
            end
            table.insert(toRemove, i)
            goto continue
        end

        -- Check for collisions between pop-able bubbles and held balls
        if circle.canPop then -- Only for pop-able bubbles
            for _, otherCircle in ipairs(circles) do
                if not otherCircle.canPop and otherCircle.dragging then -- Check if a ball is being held
                    local otherX, otherY = otherCircle.body:getPosition()

                    -- Calculate the distance between the bubble and the held ball
                    local dx = circleX - otherX
                    local dy = circleY - otherY
                    local distance = math.sqrt(dx * dx + dy * dy)

                    -- If the distance is less than the sum of their radii, pop the bubble
                    if distance <= circleRadius * 2 then
                        -- Play a random pop sound
                        local randomSound = bubblePopSounds[love.math.random(#bubblePopSounds)]
                        randomSound:play()

                        -- Mark the pop-able bubble for removal
                        table.insert(toRemove, i)
                        break -- No need to check further; the bubble will pop
                    end
                end
            end
        end

        ::continue::
    end

    -- Remove all marked circles
    for _, i in ipairs(toRemove) do
        circles[i].body:destroy()
        table.remove(circles, i)
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
            --We need to also check the score
            if can_increase_score(circleX) then 
                score = increase_score(score)
            end
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

-- MOUSE PRESS --

function love.mousepressed(x, y, button, istouch, presses)
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
                    table.remove(circles, i)
                    return -- Stop processing further since a circle was popped
                else
                    -- If not pop-able, start dragging
                    circle.dragging = true
                    circle.body:setType("kinematic") -- Temporarily disable physics
                    break
                end
            end
        end
    end
end


function love.mousereleased(x, y, button, istouch, presses)
    if button == 1 then
        for _, circle in ipairs(circles) do
            if circle.dragging then
                circle.dragging = false
                circle.body:setType("dynamic") -- Re-enable physics
            end
        end
    end
end



-- GRAPHICS SETTINGS 

function love.draw()

    -- Draw the score in the top left corner
    local score_string = string.format("Score: %d", score)
    love.graphics.setFont(font)
    love.graphics.print(score_string, 10, 10)


    -- Draw the rectangles using the color values
    love.graphics.setColor(get_colour(left_rectangle_colour.red), get_colour(left_rectangle_colour.green), get_colour(left_rectangle_colour.blue), get_colour(left_rectangle_colour.alpha))
    love.graphics.rectangle("fill", left_rectangle.x, left_rectangle.y, left_rectangle.width, left_rectangle.height)
    love.graphics.setColor(get_colour(right_rectangle_colour.red), get_colour(right_rectangle_colour.green), get_colour(right_rectangle_colour.blue), get_colour(right_rectangle_colour.alpha))
    love.graphics.rectangle("fill", right_rectangle.x, right_rectangle.y, right_rectangle.width, right_rectangle.height)


    -- Draw each circle
    for _, circle in ipairs(circles) do
        local x, y = circle.body:getPosition()

        love.graphics.setColor(get_colour(circle.colour.red), get_colour(circle.colour.green), get_colour(circle.colour.blue), get_colour(circle.colour.alpha))
        love.graphics.circle("fill", x, y, circleRadius)

    end
end

