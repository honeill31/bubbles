local score = 0
function increase_score()
    score = score + 1
end

function click_to_increase()
    if love.keyboard.isDown("d") then 
        increase_score()
    end
end