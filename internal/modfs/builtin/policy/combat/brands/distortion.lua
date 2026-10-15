local dispersal = require("policy.combat.dispersal")
local roll = require("policy.combat.roll")
local player_health = require("policy.combat.player_health")
local abyss = require("policy.world.abyss")

local distortion = {}

local function warp_damage(ctx, hit, small)
    local amount
    local message

    if small then
        amount = 1 + roll.average_two(ctx, "melee", 7)
        message = "Space warps around you!"
    else
        amount = 3 + roll.average_two(ctx, "melee", 24)
        message = "Space warps horribly around you!"
    end

    hit.health = player_health.damage(ctx, hit.defender, amount,
        false, hit.attacker)
    ctx:emit("combat", message)
end

local function blink(ctx, hit)
    local position = ctx:get(hit.defender, "core.position")
    local destination = dispersal.nearby_space(ctx, position)

    if not destination then
        return
    end

    ctx:move_actor(hit.defender, position.level_id, destination.x, destination.y)
    ctx:emit("combat", "You blink away!")
end

function distortion.apply(ctx, hit)
    -- attack.cc:471-529: 35 small, 25 large, 5 banish, 20 blink,
    -- and 15 no effect. The player-moving exclusion belongs to a
    -- simultaneous movement attack; these scheduled monster attacks
    -- occur after movement has completed.
    local choice = roll.melee(ctx, 100)

    if choice < 35 then
        warp_damage(ctx, hit, true)
    elseif choice < 60 then
        warp_damage(ctx, hit, false)
    elseif choice < 65 then
        abyss.banish(ctx, hit.defender)
    elseif choice < 85 then
        blink(ctx, hit)
    end
end

return distortion
