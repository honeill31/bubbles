
-- VARIABLES FOR BUBBLES --

local world
local circles = {} -- Table to store all circles
local spawnTimer = 0 -- Timer for spawning new circles
local spawnInterval = 0.3 -- Spawn a circle every second
local circleRadius = 50 -- Size of the circle
local circleLifespan = 5 -- Lifespan of a circle in seconds
local bubbleImage -- To store the bubble image


-- LOVE LOAD --

-- fOR LODING ASSETS INTO THE GAME

function love.load()
    -- Initialize the physics world
    world = love.physics.newWorld(0, 500, true) -- Gravity of 500 in the Y direction

    -- Load the bubble image
    bubbleImage = love.graphics.newImage("bubble.png")
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
        lifespan = circleLifespan, -- Initialize the circle's lifespan
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

        -- Decrease lifespan
        circle.lifespan = circle.lifespan - dt
        if circle.lifespan <= 0 then
            -- Destroy the circle and remove it if lifespan is zero
            circle.body:destroy()
            table.remove(circles, i)
            goto continue -- Skip the rest of the loop for this circle
        end

        local circleX, circleY = circle.body:getPosition()

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
            -- Change color based on collision
            if circle.colliding then
                love.graphics.setColor(0, 1, 0) -- Green when colliding
            else
                love.graphics.setColor(1, 0, 0) -- Red otherwise
            end

            -- Draw the circle
            love.graphics.circle("fill", x, y, circleRadius, 25)
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
