local spells = require("ids.spells")
local component = require("constants.component")
local golem = require("policy.magic.effects.summons.guardian_golem")

-- Source: monster::hurt splits half of incoming damage, rounded down,
-- to the living aligned guardian. Observe at the last pre-death phase so
-- normal attacks and constriction both pass through the persistent bond.
local system = {}

function system.update(ctx, active)
    local active_summon = ctx:get(active, component.SUMMON)

    if active_summon and
        active_summon.spell_id == spells.SPELL_SUMMON_GUARDIAN_GOLEM then
        golem.bond(ctx, active)
    end

    for _, ally in ipairs(ctx:query({
        component.SUMMON_BOND,
        component.SUMMON,
        component.HEALTH,
    })) do
        local bond = ctx:get(ally, component.SUMMON_BOND)
        local guardian = bond.guardian
        local protector = ctx:get(guardian, component.SUMMON)
        local protector_health = ctx:get(guardian, component.HEALTH)
        local health = ctx:get(ally, component.HEALTH)

        if not protector or not protector_health or
            protector.spell_id ~= spells.SPELL_SUMMON_GUARDIAN_GOLEM or
            protector.owner ~= ctx:get(ally, component.SUMMON).owner or
            protector_health.current <= 0 then
            ctx:remove(ally, component.SUMMON_BOND)
        else
            local loss = math.max(0, bond.observed_hp - health.current)
            local split = math.floor(loss / 2)

            if split > 0 then
                health.current = math.min(health.max,
                    health.current + split)
                protector_health.current = math.max(0,
                    protector_health.current - split)
                ctx:set(ally, component.HEALTH, health)
                ctx:set(guardian, component.HEALTH, protector_health)
            end

            bond.observed_hp = health.current
            ctx:set(ally, component.SUMMON_BOND, bond)
        end
    end
end

register.system({
    id = "magic.summon.bond",
    scope = "active",
    query = {},
    after = { "attack.combat", "status.constriction" },
    before = { "magic.summon.construct_death", "actor.death" },
    update = system.update,
})

return system
