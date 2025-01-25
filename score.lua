
function increase_score(sc)
    return sc + 1
end

function can_increase_score(circleX)
    width, _, _ = love.window.getMode()
    if (circleX < left_rectangle.x + left_rectangle.width or circleX > right_rectangle.x) then
        return true
    end

    return false
end