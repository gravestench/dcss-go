-- Player and monster Mephitic Cloud share the same source blast cells and
-- duration rule. The caller supplies the caster and RNG stream so cloud
-- attribution and replay stay attached to the actual spell source.
local cloud = require("policy.clouds.placement")
local clouds = require("ids.clouds")
local explosion = require("policy.combat.explosion")

local burst = {}
local CHANCE_BOUND = 225
local CHANCE_BASE = 125
local POWER_CAP = 100
local AUT_PER_TURN = 10

-- Always place the center when possible; each neighboring blast cell has
-- source probability (125 + capped power) / 225 and its own duration.
function burst.place(ctx, caster, level_id, x, y, power, stream)
    local capped = math.min(power, POWER_CAP)
    local placed = 0

    for _, cell in ipairs(explosion.cells(ctx, level_id, x, y, 1)) do
        if cell.x == x and cell.y == y or
            ctx:random(stream, CHANCE_BOUND) < CHANCE_BASE + capped then
            local sides = 3 + math.floor(capped / 20)
            local turns = 2 + ctx:random(stream, sides) +
                ctx:random(stream, sides)
            local entity = cloud.place(ctx, clouds.CLOUD_MEPHITIC,
                caster, level_id, cell.x, cell.y,
                turns * AUT_PER_TURN)

            if entity then
                placed = placed + 1
            end
        end
    end

    return placed
end

return burst
