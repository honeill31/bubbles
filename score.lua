
function increase_score(sc)
    return sc + 1
end

function add_score(sc, to_add)
    return sc + to_add
end

function in_left_rect(circleX, rad, width)
    return (circleX < left_rectangle.x + left_rectangle.width + rad)
end


function in_right_rect(circleX, rad, width)
    return (circleX > width - right_rectangle.width - rad)
end

function is_same_colour(circle, rect)
    return circle.colour == rect.colour
end