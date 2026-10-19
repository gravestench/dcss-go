local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")
local targets = require("policy.ai.targets")

local golem = {}

-- Example: A guardian bonds eligible nearby allied summons so their damage can be shared.
-- Source: mon-abil.cc:guardian_golem_bond. Only allied monsters in LOS
-- receive ENCH_INJURY_BOND; the player is not one of its protectees.
function golem.bond(ctx, guardian)
    local origin = ctx:get(guardian, component.POSITION)
    local guardian_state = ctx:get(guardian, component.SUMMON)

    if not origin or not guardian_state then
        return
    end

    for _, ally in ipairs(ctx:query({
        component.SUMMON,
        component.POSITION,
        component.HEALTH,
    })) do
        if ally ~= guardian and
            not ctx:has(ally, component.SUMMON_BOND) and
            not targets.enemy(ctx, guardian, ally) then
            local state = ctx:get(ally, component.SUMMON)
            local position = ctx:get(ally, component.POSITION)
            local health = ctx:get(ally, component.HEALTH)
            local distance = math.max(math.abs(origin.x - position.x),
                math.abs(origin.y - position.y))

            if state.owner == guardian_state.owner and
                position.level_id == origin.level_id and
                health.current > 0 and distance <= 7 and
                ctx:visible(origin.level_id, origin.x, origin.y,
                    7, position.x, position.y) then
                ctx:add(ally, component.SUMMON_BOND, {
                    guardian = guardian,
                    observed_hp = health.current,
                })
            end
        end
    end
end

-- Source: spl-summoning.cc:cast_summon_guardian_golem, HD
-- 4 + div_rand_round(pow, 16), immediate bond and degree-three abjuration.
function golem.resolve(ctx, player, _, _, power)
    local hd = 4 + math.floor(power / 16)
    local creature = summons.spawn(ctx, player,
        spells.SPELL_SUMMON_GUARDIAN_GOLEM, monsters.MONS_GUARDIAN_GOLEM, 3, 1, {
            hp = hd * 8,
        })

    if creature then
        golem.bond(ctx, creature)
        ctx:emit("spell", "A guardian golem appears, shielding your allies.")
    end
end

registry.add(spells.SPELL_SUMMON_GUARDIAN_GOLEM, {
    resolve = golem.resolve,
})

return golem
