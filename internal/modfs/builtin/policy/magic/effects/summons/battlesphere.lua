local spells = require("ids.spells")
local monsters = require("ids.monsters")
local component = require("constants.component")
local catalog = require("policy.catalog")
local blast = require("policy.magic.effects.summons.blast")
local roll = require("policy.combat.roll")
local registry = require("policy.magic.effects.registry")
local summons = require("policy.magic.effects.summons.common")
local streams = require("constants.rng_streams")
local senses = require("policy.character.senses")
local trajectory = require("policy.combat.trajectory")
local targets = require("policy.ai.targets")

local sphere = {}

-- Player and monster casts share actor state but consume different saved RNG
-- streams. The owner, rather than the target, determines the stream.
local function stream_for(ctx, owner)
    return owner == ctx:player() and streams.SPELL or
        streams.MONSTER_SPELL
end

-- The owner may have one active sphere; recasting recharges that entity.
local function active(ctx, owner)
    for _, entity in ipairs(ctx:query({
        component.SUMMON,
        component.SUMMON_BATTLESPHERE,
    })) do
        local state = ctx:get(entity, component.SUMMON)

        if state.owner == owner then
            return entity
        end
    end

    return nil
end

-- Roll the sphere's nominal life in aut, then cap it so repeated casts cannot extend it without bound.
local function duration(ctx, owner, power)
    local stream = stream_for(ctx, owner)
    local rolled = 7 + 1 + roll.draw(ctx, stream,
        math.max(1, power)) +
        1 + roll.draw(ctx, stream, math.max(1, power))

    return math.min(rolled * 10, 500)
end

-- Keep charge rolls tied to spell power while leaving at least four shots at low power.
local function charge(ctx, owner, power)
    return 4 + math.floor(roll.draw(ctx,
        stream_for(ctx, owner), power + 10) / 10)
end

-- Source aim_battlesphere chooses one visible unaligned actor at random.
-- Keep owner and sphere sight in the test before choosing a shot.
local function target(ctx, owner, entity, origin)
    local choices = {}
    local owner_position = ctx:get(owner, component.POSITION)

    if not owner_position or
        owner_position.level_id ~= origin.level_id then
        return nil
    end

    for _, hostile in ipairs(ctx:query({ component.ACTOR, component.POSITION, component.HEALTH })) do
        if targets.enemy(ctx, entity, hostile) then
            local position = ctx:get(hostile, component.POSITION)
            local health = ctx:get(hostile, component.HEALTH)
            local range = math.max(math.abs(position.x - origin.x),
                math.abs(position.y - origin.y))

            if position.level_id == origin.level_id and
                health.current > 0 and range <= 7 and
                ctx:visible(origin.level_id, origin.x, origin.y,
                    7, position.x, position.y) and
                ctx:visible(origin.level_id,
                    owner_position.x, owner_position.y, 7,
                    position.x, position.y) and
                ctx:projectile_clear(origin.level_id, origin.x, origin.y,
                    position.x, position.y) then
                choices[#choices + 1] = hostile
            end
        end
    end

    if #choices == 0 then
        return nil
    end

    local index = roll.draw(ctx, stream_for(ctx, owner),
        #choices) + 1

    return choices[index]
end

-- Example: sphere.fire(ctx, player) after a player spell spends one charge
-- only if its traced ray still contacts the selected hostile.
function sphere.fire(ctx, owner)
    local entity = active(ctx, owner)

    if not entity then
        return
    end

    local state = ctx:get(entity, component.SUMMON_BATTLESPHERE)

    if state.charge <= 0 then
        return
    end

    local owner_health = ctx:get(owner, component.HEALTH)

    if not owner_health or owner_health.current <= 0 then
        return
    end

    local origin = ctx:get(entity, component.POSITION)
    local hostile = target(ctx, owner, entity, origin)

    if not hostile then
        return
    end

    local destination = ctx:get(hostile, component.POSITION)
    local impact = trajectory.trace(ctx, origin.level_id,
        origin.x, origin.y, destination.x, destination.y, 7)
    local contact = impact.contacts[1]

    if not contact or contact.actor ~= hostile then
        return
    end

    local stats = ctx:get(entity, component.SUMMON_STATS)
    local hd = stats and stats.hd or
        1 + math.floor(state.power / 11)
    local sides = 5 + hd
    local stream = stream_for(ctx, owner)
    local damage = 2 + roll.draw(ctx, stream, sides) +
        roll.draw(ctx, stream, sides)

    blast.hit(ctx, hostile, damage, nil, entity, stream)

    state.charge = state.charge - 1
    ctx:set(entity, component.SUMMON_BATTLESPHERE, state)
    if owner == ctx:player() then
        local definition = catalog.get("monsters",
            ctx:get(hostile, component.ACTOR).kind_id)

        ctx:emit("combat", "Your battlesphere fires at the " ..
            definition.name .. ".")
    elseif senses.player_sees_actor(ctx, entity) then
        ctx:emit("combat", "The battlesphere fires!")
    end

    if state.charge == 0 then
        summons.expire(ctx, entity)
    end
end

-- Source: spl-summoning.cc:cast_battlesphere and
-- battlesphere_damage (2d(5 + HD)).
-- Recast caps both charge and remaining lifetime, preventing indefinite
-- accumulation while preserving an existing sphere's ECS identity.
function sphere.spawn(ctx, owner, power)
    local existing = active(ctx, owner)

    if existing then
        if owner ~= ctx:player() then
            return existing
        end

        local state = ctx:get(existing, component.SUMMON_BATTLESPHERE)
        local summon = ctx:get(existing, component.SUMMON)
        local remaining = math.max(0, summon.expires_aut - ctx:aut())

        state.charge = math.min(20, state.charge +
            charge(ctx, owner, power))
        summon.expires_aut = ctx:aut() + math.min(500,
            remaining + duration(ctx, owner, power))
        ctx:set(existing, component.SUMMON_BATTLESPHERE, state)
        ctx:set(existing, component.SUMMON, summon)
        ctx:emit("spell", "You imbue your battlesphere with additional charge.")

        return existing
    end

    local hd = 1 + roll.random_divide(ctx, power, 11,
        stream_for(ctx, owner))
    local creature = summons.spawn(ctx, owner,
        spells.SPELL_BATTLESPHERE, monsters.MONS_BATTLESPHERE, 0, 1, {
            expires_aut = ctx:aut() + duration(ctx, owner, power),
            hd = hd,
        })

    if creature then
        ctx:add(creature, component.SUMMON_BATTLESPHERE, {
            power = power,
            charge = charge(ctx, owner, power),
        })

        if owner == ctx:player() then
            ctx:emit("spell", "You conjure a globe of magical energy.")
        elseif senses.player_sees_actor(ctx, owner) then
            ctx:emit("spell",
                "The caster conjures a globe of magical energy!")
        end
    end

    return creature
end

-- Preserve the player spell registration through the shared owner-neutral
-- creation path. Recast charges the same actor instead of replacing it.
function sphere.resolve(ctx, player, _, _, power)
    sphere.spawn(ctx, player, power)
end

registry.add(spells.SPELL_BATTLESPHERE, {
    resolve = sphere.resolve,
})

return sphere
