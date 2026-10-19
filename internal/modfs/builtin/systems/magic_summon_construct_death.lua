local spells = require("ids.spells")
local component = require("constants.component")
local blast = require("policy.magic.effects.summons.blast")
local lightning = require("policy.magic.effects.summons.ball_lightning")
local summons = require("policy.magic.effects.summons.common")

-- Theory of operation: Charged constructs explode before expiry removes their component and actor.
-- Source: mon-explode.cc. A struck, charged prism gives a weaker radius-one
-- blast; a ball lightning also explodes on ordinary death or timeout.
local system = {}

-- Prism and ball-lightning death effects run before summon expiry and actor deletion.
function system.update(ctx, active)
    for _, entity in ipairs(ctx:query({
        component.SUMMON,
        component.SUMMON_CONSTRUCT,
        component.HEALTH,
    })) do
        local summon = ctx:get(entity, component.SUMMON)
        local state = ctx:get(entity, component.SUMMON_CONSTRUCT)
        local health = ctx:get(entity, component.HEALTH)
        local timed_out = active == ctx:player() and
            summon.expires_aut > 0 and ctx:aut() >= summon.expires_aut
        local finished = (summon.source_id == spells.SPELL_FULMINANT_PRISM and
            state.charge >= 3) or
            ((summon.source_id == spells.SPELL_FOXFIRE or
                summon.source_id == spells.SPELL_MARSHLIGHT) and
                state.charge >= 1) or
            (summon.source_id == spells.SPELL_CONJURE_BALL_LIGHTNING and
                state.charge >= 1)

        if health.current <= 0 or timed_out or
            (active == ctx:player() and finished) then
            if summon.source_id == spells.SPELL_CONJURE_BALL_LIGHTNING then
                lightning.explode(ctx, entity)
            elseif summon.source_id == spells.SPELL_FULMINANT_PRISM and
                state.charge == 1 then
                local hd = math.max(1, math.floor(state.power / 10))
                local sides = 6 + math.floor(hd * 7 / 4)

                blast.area(ctx, entity, 1, 2, sides)
                state.charge = 2
                ctx:set(entity, component.SUMMON_CONSTRUCT, state)
            end

            if (timed_out or finished) and entity ~= active then
                summons.expire(ctx, entity)
            end
        end
    end
end

register.system({
    id = "magic.summon.construct_death",
    scope = "active",
    query = {},
    after = { "status.constriction" },
    before = { "magic.summon.expiry", "actor.death" },
    update = system.update,
})

return system
