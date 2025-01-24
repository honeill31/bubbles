local world
local circles = {} -- Table to store all circles
local spawnTimer = 0 -- Timer for spawning new circles
local spawnInterval = .3 -- Spawn a circle every second
local circleRadius = 50 -- size of the circle

function love.load()
    -- Initialize the physics world
    world = love.physics.newWorld(0, 500, true) -- Gravity of 500 in the Y direction
end

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
        canPop = love.math.random() < 0.5 -- 50% chance to make the circle "pop-able"
    })
end

function love.update(dt)
    -- Update the physics world
    world:update(dt)

    -- Handle spawning new circles
    spawnTimer = spawnTimer + dt
    if spawnTimer >= spawnInterval then
        spawnTimer = 0
        spawnCircle(love.math.random(500, 1000), -circleRadius) -- Spawn at random X position above the screen
    end

    -- Check hover states for all circles
    local mouseX, mouseY = love.mouse.getPosition()
    for _, circle in ipairs(circles) do
        local x, y = circle.body:getPosition()
        local dx, dy = mouseX - x, mouseY - y
        circle.hovered = (dx * dx + dy * dy) <= (circleRadius * circleRadius)

        -- Handle dragging
        if circle.dragging then
            circle.body:setPosition(mouseX, mouseY)
            circle.body:setLinearVelocity(0, 0) -- Stop all other motion while dragging
        end
    end
end

function love.mousepressed(x, y, button, istouch, presses)
    if button == 1 then
        for i = #circles, 1, -1 do -- Iterate backward to safely remove items
            local circle = circles[i]
            if circle.hovered then
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

function love.draw()
    -- Draw each circle
    for _, circle in ipairs(circles) do
        local x, y = circle.body:getPosition()

        -- Change color based on behavior
        if circle.dragging then
            love.graphics.setColor(0, 0, 1) -- Blue when dragging
        elseif circle.hovered then
            if circle.canPop then
                love.graphics.setColor(1, 1, 0) -- Yellow when pop-able and hovered
            else
                love.graphics.setColor(0, 1, 0) -- Green when draggable and hovered
            end
        else
            if circle.canPop then
                love.graphics.setColor(1, 0.5, 0) -- Orange for pop-able
            else
                love.graphics.setColor(1, 0, 0) -- Red for draggable
            end
        end

        love.graphics.circle("fill", x, y, circleRadius, 25)
    end

    love.graphics.setColor(1, 1, 1) -- Reset color
end
