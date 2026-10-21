-- Force an error after a Pan portal has moved the player and published its
-- history. A failed retirement must restore the whole command, not just the
-- newly generated grid.
local retirement = {}

function retirement.prune_stock(ctx, input)
    error("forced retirement failure")
end

register.policy({
    id = "world.prune_retired_stock",
    run = retirement.prune_stock,
})

return retirement
