local beam = require("policy.combat.monster_beams")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local habitat = require("policy.combat.monster_habitat")
local spells = require("ids.spells")

local blinkbolt = {
    bounceable = false,
}
local profile = catalog.get(categories.MONSTER_BEAMS,
    spells.SPELL_BLINKBOLT)

function blinkbolt.plan(ctx, caster, foe)
    return beam.plan(ctx, caster, foe, profile, blinkbolt)
end

-- beam.cc:bolt::finish_beam walks the recorded ray backward and blinks the
-- original caster to the first habitable, unoccupied cell.
function blinkbolt.after_endpoint(ctx, caster, _, _, endpoint)
    for index = #endpoint.path, 1, -1 do
        local cell = endpoint.path[index]

        if not ctx:actor_at(endpoint.level_id, cell.x, cell.y) and
            habitat.at(ctx, caster, endpoint.level_id,
                cell.x, cell.y) then
            ctx:move_actor(caster, endpoint.level_id, cell.x, cell.y)

            return
        end
    end
end

function blinkbolt.resolve(ctx, caster, foe, _, plan)
    return beam.resolve(ctx, caster, foe, profile, plan, blinkbolt)
end

return blinkbolt
