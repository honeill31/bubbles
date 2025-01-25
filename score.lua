
function increase_score(sc)
    return sc + 1
end

function can_increase_score(circleX)

    if (circleX < left_rectangle.x or circleX > right_rectangle.x) then
        return true
    end

    return false
end