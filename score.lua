
function increase_score(sc)
    return sc + 1
end

function can_increase_score(circleX)

    left_rectangle = {
        width = 300,
        height = 300,
        x = 10,
        y = 400
    }

    right_rectangle = 
    {
        width = 300,
        height = 300,
        x = 1290,
        y = 400
    }

    if (circleX < left_rectangle.x or circleX > right_rectangle.x) then
        return true
    end

    return false
end