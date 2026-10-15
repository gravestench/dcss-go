local abyss = require("policy.world.abyss")
local dispersal = require("policy.combat.dispersal")
local relocation = require("policy.world.monster_relocation")
local roll = require("policy.combat.roll")

local brand = {}

local function warp(ctx, hit, brands, small)
    local raw
    local message

    if small then
        raw = 1 + roll.average_two(ctx, "melee", 7)
        message = "Space warps around the " .. hit.definition.name .. "!"
    else
        raw = 3 + roll.average_two(ctx, "melee", 24)
        message = "Space warps horribly around the " ..
            hit.definition.name .. "!"
    end

    brands.damage(ctx, hit, raw)
    ctx:emit("combat", message)
end

function brand.apply(ctx, hit, brands)
    -- Source: attack.cc:471-529. The 5% banish and 20% blink outcomes
    -- are real actor transitions, not damage substitutions.
    local choice = roll.melee(ctx, 100)

    if choice < 35 then
        warp(ctx, hit, brands, true)
    elseif choice < 60 then
        warp(ctx, hit, brands, false)
    elseif choice < 65 then
        hit.banished = abyss.banish_monster(ctx, hit.defender,
            hit.definition)
    elseif choice < 85 then
        local position = ctx:get(hit.defender, "core.position")
        local destination = dispersal.nearby_space(ctx, position)

        if destination then
            relocation.move(ctx, hit.defender, position.level_id,
                destination.x, destination.y)
            ctx:emit("combat", "The " .. hit.definition.name .. " blinks away!")
            hit.moved = true
        end
    end
end

return brand
