-- Theory of operation: a surviving heavy hit from a monster can make a
-- five-star Jiyva worshipper eject friendly slimes. The hit's final HP
-- loss decides the count, and each body is an ordinary saved ECS summon.
-- Reading worship at hit time lets penance or renunciation end the effect.
local attitudes = require("constants.attitude")
local categories = require("constants.catalog")
local causes = require("constants.damage_causes")
local channels = require("constants.message_channels")
local component = require("constants.component")
local ejectable = require("constants.jiyva_ejectable_monsters")
local gods = require("constants.gods")
local order = require("constants.damage_reaction_order")
local reactions = require("policy.combat.player_damage_reactions")
local defenses = require("policy.religion.jiyva.defenses")
local streams = require("constants.rng_streams")

local retaliation = {}

-- The source chooses one species before testing whether the hit is large
-- enough. Keep that draw even for a subthreshold hit so replay stays stable.
local function choose_species(ctx)
    local index = ctx:random(streams.RELIGION, #ejectable.ids) + 1

    return ejectable.ids[index]
end

-- C++ integer division truncates each fraction of maximum HP. The
-- strongest tier ejects two to five bodies, the middle tier two or three.
local function requested_count(ctx, damage, maximum_hp)
    if damage >= math.floor(maximum_hp * 3 / 4) then
        return ctx:random(streams.RELIGION, 4) + 2
    end

    if damage >= math.floor(maximum_hp / 2) then
        return ctx:random(streams.RELIGION, 2) + 2
    end

    if damage >= math.floor(maximum_hp / 4) then
        return 1
    end

    return 0
end

-- The common health owner calls this only after positive, nonlethal HP
-- loss. A monster source is essential: source ouch.cc ignores terrain,
-- self-harm, and other damage without a monster damager.
function retaliation.on_damage(ctx, player, damage, cause, attacker)
    if not defenses.active(ctx, player, 5) or not attacker or
        attacker == player or not ctx:has(attacker, component.ACTOR) then
        return 0
    end

    local health = ctx:get(player, component.HEALTH)

    if not health or health.max <= 0 then
        error("Jiyva slime ejection requires player health")
    end

    local species = choose_species(ctx)
    local count = requested_count(ctx, damage, health.max)

    if count == 0 then
        return 0
    end

    -- Load the shared summon owner at use time to avoid a module cycle
    -- while the player-health owner installs this damage reaction.
    local summons = require("policy.magic.effects.summons.common")
    local created = 0
    local attacker_health = ctx:get(attacker, component.HEALTH)
    local foe_alive = attacker_health and attacker_health.current > 0

    for _ = 1, count do
        local entity = summons.spawn(ctx, player, gods.JIYVA,
            species, 2, nil, {
                attitude = attitudes.FRIENDLY,
                source_category = categories.GODS,
                stream = streams.RELIGION,
                silent_failure = true,
            })

        if entity then
            created = created + 1

            -- The source starts each ejected slime with the living
            -- damager as its foe. This saved target component already
            -- guides summons through the ordinary enemy decision path.
            if foe_alive then
                ctx:add(entity, component.SUMMON_HAUNTING, {
                    target = attacker,
                })
            end
        end
    end

    if created > 0 then
        local impact = cause == causes.HIT and "blow" or "blast"
        local arrival = created > 1 and
            "a flood of jellies pours out from you" or
            "a jelly pops out"

        ctx:emit(channels.COMBAT,
            "You shudder from the " .. impact .. " and " .. arrival .. "!")
    end

    return created
end

-- The source orders slime ejection after deterioration but before the
-- demonic guardian. Register once, independent of mod file load order.
function retaliation.register()
    reactions.add("religion.jiyva.slime_ejection",
        order.JIYVA_SLIME_EJECTION, retaliation.on_damage)
end

return retaliation
