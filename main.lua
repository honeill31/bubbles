
-- Includes
require "score"

-- VARIABLES FOR BUBBLES --

local world
local circles = {} -- Table to store all circles
local spawnTimer = 0 -- Timer for spawning new circles
local spawnInterval = 0.3 -- Spawn a circle every second
local circleRadius = 50 -- Size of the circle
local bubbleImage -- To store the bubble image
local bubbleBackgroundImage -- background image
local ballImage -- ball image
local basketImage -- basket image
local score = 0 -- To store the score


-- LOVE LOAD --

-- fOR LODING ASSETS INTO THE GAME

function love.load()
    -- Initialize the physics world
    world = love.physics.newWorld(0, 500, true) -- Gravity of 500 in the Y direction
    love.graphics.setColor(255,255,255)
    font = love.graphics.newFont(32)

    -- Load the images
    bubbleImage = love.graphics.newImage("bubble.png")
    ballImage = love.graphics.newImage("ball.png")
    basketImage = love.graphics.newImage("basket.png")
    bubbleBackgroundImage = love.graphics.newImage("noonbackground.png")
end


-- FUNCTIONS --
-- Function to create a new circle
local function spawnCircle(x, y)
    local body = love.physics.newBody(world, x, y, "dynamic")
    local shape = love.physics.newCircleShape(circleRadius)
    local fixture = love.physics.newFixture(body, shape)
    fixture:setRestitution(0.8) -- Make the circle bouncy

    -- Add the new circle to the circles table
    table.insert(circles, {
        body = body,
        shape = shape,
        fixture = fixture,
        hovered = false,
        dragging = false,
        colliding = false, -- Tracks if the circle is colliding with a rectangle
        canPop = love.math.random() < 0.5 -- 50% chance to make the circle "pop-able"
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
        spawnCircle(love.math.random(500, 1000), -circleRadius) -- Spawn at random X position above the screen
end

-- COLLISIONS --

-- collisions for the rectangles -- 
    -- Left rectangle dimensions
    local leftRectX = 10
    local leftRectY = 400
    local leftRectWidth = 300
    local leftRectHeight = 300

    -- Right rectangle dimensions
    local rightRectX = 1290
    local rightRectY = 400
    local rightRectWidth = 300
    local rightRectHeight = 300

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
        -- TODO: Get this value from the confv
        if (circleY > 600) then 
            circle.body:destroy()
            table.remove(circles, i)
            goto continue
        end

        -- Reset collision flag
        circle.colliding = false

        -- Collision checks for rectangles
        if checkCircleRectCollision(circleX, circleY, circleRadius, leftRectX, leftRectY, leftRectWidth, leftRectHeight) then
            circle.colliding = true -- Mark circle as colliding
        end

        if checkCircleRectCollision(circleX, circleY, circleRadius, rightRectX, rightRectY, rightRectWidth, rightRectHeight) then
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


 -- Draw the background image first
 love.graphics.setColor(1, 1, 1) -- Ensure default color for the image
 love.graphics.draw(
     bubbleBackgroundImage,
     0, 0,                          -- Draw at the top-left corner
     0,                             -- No rotation
     love.graphics.getWidth() / bubbleBackgroundImage:getWidth(),  -- Scale X to fit the window
     love.graphics.getHeight() / bubbleBackgroundImage:getHeight() -- Scale Y to fit the window
 )



    -- Draw the score in the top left corner
    local score_string = string.format("Score: %d", score)
    love.graphics.setFont(font)
    love.graphics.print(score_string, 10, 10)

    -- Draw each circle
    for _, circle in ipairs(circles) do
        local x, y = circle.body:getPosition()

        if circle.canPop then
            -- Draw the bubble image for pop-able circles
            love.graphics.setColor(1, 1, 1) -- Reset color for the image
            love.graphics.draw(
                bubbleImage,
                x - circleRadius,                 -- Align image to the circle's center
                y - circleRadius,                 -- Align image to the circle's center
                0,                                -- No rotation
                (circleRadius * 2) / bubbleImage:getWidth(),  -- Scale X
                (circleRadius * 2) / bubbleImage:getHeight() -- Scale Y
            )
        else
            -- Draw the ball image for non-pop-able circles
            love.graphics.setColor(1, 1, 1) -- Reset color for the image
            love.graphics.draw(
                ballImage,
                x - circleRadius,                 -- Align image to the circle's center
                y - circleRadius,                 -- Align image to the circle's center
                0,                                -- No rotation
                (circleRadius * 2) / ballImage:getWidth(),  -- Scale X
                (circleRadius * 2) / ballImage:getHeight() -- Scale Y
            )
        end
    end

    love.graphics.setColor(1, 1, 1) -- Reset color

    -- Draw left rectangle
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", 10, 400, 300, 300)

    -- Draw right rectangle
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", 1290, 400, 300, 300)
end

