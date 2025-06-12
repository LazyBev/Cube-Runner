local Collision = {}

function Collision.checkCollision(a, b)
    local dx = a.x - b.x
    local dy = a.y - b.y
    local distance = math.sqrt(dx * dx + dy * dy)
    return distance < (a.size + b.size/2)
end

return Collision 