local spells = require("ids.spells")
local component = require("constants.component")
local blink = require("policy.combat.dispersal")
local common = require("policy.magic.effects.translocation.common")
local registry = require("policy.magic.effects.registry")
local teleport = require("policy.magic.effects.zaps.teleport_other")
local statuses = require("policy.magic.effects.statuses.player")

local disjunction = {}

-- Source: spl-transloc.cc:disjunction_spell. The source repeats a trial for
-- every aut of the player's action, with a distance-weighted blink chance.
function disjunction.pulse(ctx, player, aut)
    local state = ctx:get(player, component.PLAYER_STATUS)

    if not state or state.disjunction_aut <= 0 or aut <= 0 then
        return
    end

    local center = ctx:get(player, component.POSITION)

    for _ = 1, aut do
        local monsters = {}

        for _, monster in ipairs(common.monsters(ctx, center.level_id)) do
            if common.distance(center, monster.position) <= 7 and
                ctx:visible(center.level_id, center.x, center.y, 7,
                    monster.position.x, monster.position.y) then
                monsters[#monsters + 1] = monster
            end
        end

        for index = #monsters, 2, -1 do
            local other = ctx:random("spell", index) + 1
            monsters[index], monsters[other] = monsters[other], monsters[index]
        end

        for _, monster in ipairs(monsters) do
            local position = ctx:get(monster.entity, component.POSITION)

            if position and not teleport.no_tele(monster.actor,
                monster.definition, ctx, monster.entity) then
                local distance = common.distance(center, position)
                local decay = math.max(1, (distance - 1) * (distance + 1))
                local chance = math.floor(0.8 ^ (1 / decay) * 1000)

                if ctx:random("spell", 1000) >= chance then
                    blink.blink(ctx, player, monster.entity,
                        monster.definition)
                end
            end
        end
    end
end

function disjunction.resolve(ctx, player, _, _, power)
    local state = statuses.ensure(ctx, player)

    local random_turns = 35 + ctx:random("spell", 11) +
        ctx:random("spell", math.max(1, math.floor(power / 12)))
    local current = math.floor(state.disjunction_aut / 10)
    local turns = math.min(90 + math.floor(power / 12),
        math.max(current + random_turns, 30 + random_turns))
    state.disjunction_aut = turns * 10

    if ctx:has(player, component.PLAYER_STATUS) then
        ctx:set(player, component.PLAYER_STATUS, state)
    else
        ctx:add(player, component.PLAYER_STATUS, state)
    end
    ctx:emit("spell", "Space warps around you.")
end

registry.add(spells.SPELL_DISJUNCTION, {
    resolve = disjunction.resolve,
})

return disjunction
