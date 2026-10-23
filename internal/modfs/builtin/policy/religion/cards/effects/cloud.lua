-- Cloud surrounds each visible threatening enemy with black smoke. Its
-- purpose is battlefield sight denial, so occupied adjacent cells are
-- allowed; terrain and the shared cloud owner decide legal placement.
local clouds = require("ids.clouds")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local nearby = require("policy.religion.cards.effects.nearby")
local placement = require("policy.clouds.placement")
local roll = require("policy.combat.roll")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")
local terrain = require("constants.terrain")

local cloud = {}

cloud.uses_tier = true

-- The source skips nonthreatening bodies as well as allies. A hostile
-- projectile is excluded earlier by the shared nearby scan.
local function threatening(candidate)
    for _, flag in ipairs(candidate.definition.flags or {}) do
        if flag == flags.NO_THREAT then
            return false
        end
    end

    return true
end

-- Each eligible adjacent floor cell receives an independent duration roll.
-- The cloud owner stores that source lifetime in aut for save and expiry.
function cloud.apply(ctx, player, request)
    local tier = request.tier

    if type(tier) ~= "number" or tier % 1 ~= 0 or
        tier < 0 or tier > 2 then
        error("Cloud requires a source power tier")
    end

    local seen = false

    for _, candidate in ipairs(nearby.monsters(ctx, player)) do
        if targets.enemy(ctx, player, candidate.entity) and
            threatening(candidate) then
            local position = candidate.position

            for dy = -1, 1 do
                for dx = -1, 1 do
                    if dx ~= 0 or dy ~= 0 then
                        local x = position.x + dx
                        local y = position.y + dy

                        if ctx:cell(position.level_id, x, y) ==
                            terrain.DNGN_FLOOR and
                            not placement.at(ctx, position.level_id,
                                x, y) then
                            local turns = 5 + roll.average_two(ctx,
                                streams.CARDS, tier * 6)
                            local created = placement.place(ctx,
                                clouds.CLOUD_BLACK_SMOKE, player,
                                position.level_id, x, y, turns * 10)

                            seen = seen or created ~= nil
                        end
                    end
                end
            end
        end
    end

    if seen then
        ctx:emit("religion", "Clouds appear around you!")
    else
        ctx:emit("religion", "Nothing happens.")
    end
end

return cloud
