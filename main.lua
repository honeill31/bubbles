
require "score"
require "run"
local main_text

function draw_main_screen()
    love.graphics.print("Welcome to the bubbles game!", 400, 300)
    love.graphics.print("By Maggie and Holly", 400,400)
    love.graphics.circle("fill", 10, 10, 100, 25)
    love.graphics.rectangle("line", 200, 30, 120, 100)
    love.graphics.print(tostring(score), 100, 100)
end

function love.update(dt)
end

function love.draw()
    draw_main_screen()
end

love.run()
