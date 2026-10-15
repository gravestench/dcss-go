local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local catalog = require("policy.catalog")
local hit_points = require("policy.population.hit_points")
local summons = require("policy.magic.effects.summons.common")

-- Source: mon-death.cc:_make_simulacra, before the ordinary death rule
-- destroys the marked monster. A zero degree means no abjuration timer.
local system = {}

function system.update(ctx)
    for _, entity in ipairs(ctx:query({ component.SUMMON_MARK })) do
        local mark = ctx:get(entity, component.SUMMON_MARK)

        if ctx:aut() >= mark.expires_aut then
            ctx:remove(entity, component.SUMMON_MARK)
        else
            local health = ctx:get(entity, component.HEALTH)

            if health and health.current <= 0 then
                local origin = ctx:get(entity, component.POSITION)
                local actor = ctx:get(entity, component.ACTOR)
                local base = catalog.get("monsters", actor.kind_id)
                local hd = math.max(1, base.hd)
                local count = 1 + summons.roll(ctx,
                    1 + math.floor((mark.power + summons.roll(ctx, 20)) / 20))

                for _ = 1, count do
                    local hp = hit_points.roll(ctx, 30 * hd)
                    local creature = summons.spawn(ctx, mark.owner,
                        spells.SPELL_SIMULACRUM, monsters.MONS_SIMULACRUM, 0, 999, {
                            anchor = origin,
                            hp = hp,
                            hd = hd,
                        })

                    if creature then
                        ctx:add(creature, "magic.summon_simulacrum", {
                            base_kind_id = actor.kind_id,
                        })
                    end
                end

                ctx:remove(entity, component.SUMMON_MARK)
                ctx:emit("spell", "A freezing mist starts to gather...")
            end
        end
    end
end

register.system({
    id = "magic.summon.simulacrum",
    scope = "active",
    query = {},
    after = { "magic.summon.expiry" },
    before = { "actor.death" },
    update = system.update,
})

return system
