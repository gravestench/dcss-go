-- Theory of operation: a real slime creature spends its monster action on
-- division when trapped near a foe, or combines with a compatible neighbor
-- when that neighbor is the only route closer to its target. Each surviving
-- body is an ECS actor; blob size changes name, melee damage, and HP bounds.
-- The source rule lives in mon-abil.cc. Jiyva's feeding jelly uses another
-- split policy because it has a different trigger and health calculation.
local behaviors = require("constants.ai_behaviors")
local catalog = require("policy.catalog")
local channels = require("constants.message_channels")
local component = require("constants.component")
local confusion = require("policy.magic.effects.statuses.confusing_touch")
local enchant = require("policy.combat.monster_enchant")
local factory = require("policy.population.factory")
local habitat = require("policy.combat.monster_habitat")
local invisibility = require("policy.potions.invisibility")
local jiyva_growth = require("policy.religion.jiyva.growth")
local monsters = require("ids.monsters")
local senses = require("policy.character.senses")
local slime_blob = require("policy.monsters.slime_blob")
local statuses = require("policy.magic.effects.statuses.player")
local streams = require("constants.rng_streams")
local targets = require("policy.ai.targets")

local lifecycle = {}
local MAX_BLOBS = 5

-- A child inherits bodily enchantments but not a web, net, or outside bond
-- attached to the old body. These are the same saved status owners used by
-- monster mirror copies, listed here for the slime rule's distinct lineage.
local bodily_status = {
    component.MONSTER_ALLEGIANCE,
    component.MONSTER_BOONS,
    component.MONSTER_DRAINED,
    component.MONSTER_ENCHANT,
    component.MONSTER_ENFEEBLE,
    component.MONSTER_LOWERED_WILL,
    component.MONSTER_MASS_ENCHANT,
    component.MONSTER_REPULSION,
    component.MONSTER_STASIS,
    component.MONSTER_TROGS_HAND,
    component.FLASH_FROZEN,
    component.STICKY_FLAME,
    component.PROJECTILE_POISON,
    component.PROJECTILE_SLOW,
    component.WRETCHED,
}

-- These ECS fields carry the source's mergeable enchant durations. Other
-- fields on the same records, such as poison attribution or berserk HP,
-- retain the surviving actor's owner rather than becoming arithmetic.
local timed_enchantments = {
    {
        key = component.MONSTER_ENCHANT,
        fields = { "blind_aut", "corrosion_aut", "invisible_aut" },
    },
    {
        key = component.MONSTER_ALLEGIANCE,
        fields = { "charm_aut", "frenzy_aut", "fatigue_aut" },
    },
    {
        key = component.MONSTER_MASS_ENCHANT,
        fields = { "fear_aut", "anguish_aut" },
    },
    {
        key = component.MONSTER_STASIS,
        fields = { "sleep_wary_aut", "petrifying_aut", "petrified_aut" },
    },
    {
        key = component.STICKY_FLAME,
        fields = { "remaining_aut", "max_aut" },
    },
    {
        key = component.FLASH_FROZEN,
        fields = { "remaining_aut" },
    },
    {
        key = component.PROJECTILE_POISON,
        fields = { "remaining_aut", "max_aut" },
    },
    {
        key = component.PROJECTILE_SLOW,
        fields = { "remaining_aut" },
    },
}

-- Crawl measures approach in eight-way grid steps, including diagonals.
local function distance(left, right)
    return math.max(math.abs(left.x - right.x),
        math.abs(left.y - right.y))
end

-- A shapeshifter's borrowed appearance is not an actual blob lineage.
-- Fear, confusion, and paralysis also suppress this natural special ability.
local function disabled(ctx, entity)
    return ctx:has(entity, component.MONSTER_SHAPESHIFTER) or
        ctx:has(entity, component.PARALYSIS) or
        confusion.active(ctx, entity) or
        statuses.fear_active(ctx, entity)
end

-- A free cell must support this live body's habitat; grid occupancy is
-- checked separately because terrain passability alone admits other actors.
local function free_site(ctx, entity, position, x, y)
    return habitat.at(ctx, entity, position.level_id, x, y) and
        not ctx:actor_at(position.level_id, x, y)
end

-- Prefer a live enemy in sight. A remembered coordinate remains a route
-- goal for merging, but split placement uses only a currently visible foe.
local function visible_foe(ctx, entity, position)
    if enchant.blinded(ctx, entity) or
        statuses.enfeeble_blinded(ctx, entity) then
        return nil
    end

    local foe = targets.nearest(ctx, entity, position, 7)

    if not foe and targets.enemy(ctx, entity, ctx:player()) and
        invisibility.visible_to(ctx, ctx:player(), entity) then
        foe = ctx:player()
    end

    local target = foe and ctx:get(foe, component.POSITION)

    if foe == ctx:player() and
        not invisibility.visible_to(ctx, foe, entity) then
        return nil
    end

    if target and target.level_id == position.level_id and
        ctx:visible(position.level_id, position.x, position.y, 7,
            target.x, target.y) then
        return target
    end

    return nil
end

-- Source fair-adjacent iteration must not let loop ordering bias the child
-- location. Reservoir sampling spends one draw per legal cell.
local function split_site(ctx, entity, position, foe, forced)
    local old_distance = foe and distance(position, foe) or 0

    if foe and old_distance > 1 and not forced then
        for dy = -1, 1 do
            for dx = -1, 1 do
                if dx ~= 0 or dy ~= 0 then
                    local x = position.x + dx
                    local y = position.y + dy

                    if distance({ x = x, y = y }, foe) < old_distance and
                        free_site(ctx, entity, position, x, y) then
                        return nil
                    end
                end
            end
        end
    end

    local count = 0
    local chosen

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = position.x + dx
                local y = position.y + dy
                local next_site = { x = x, y = y }

                if (forced or not foe or
                    distance(next_site, foe) <= old_distance) and
                    free_site(ctx, entity, position, x, y) then
                    count = count + 1

                    if ctx:random(streams.SLIME_CREATURE, count) == 0 then
                        chosen = next_site
                    end
                end
            end
        end
    end

    return chosen
end

-- Copy pursuit and bodily effects after spawn, which initializes the child's
-- ordinary actor, health, position, and energy with production schemas.
local function inherit(ctx, parent, child)
    local ai = ctx:get(parent, component.AI)

    if ai then
        ctx:set(child, component.AI, ai)
    end

    local source_actor = ctx:get(parent, component.ACTOR)
    local child_actor = ctx:get(child, component.ACTOR)

    child_actor.speed = source_actor.speed
    ctx:set(child, component.ACTOR, child_actor)

    for _, key in ipairs(bodily_status) do
        local state = ctx:get(parent, key)

        if state then
            ctx:add(child, key, state)
        end
    end

    for _, key in ipairs({
        component.SUMMON,
        component.JIYVA_SLIME,
        component.MONSTER_ARENA_DUEL,
    }) do
        local state = ctx:get(parent, key)

        if state then
            ctx:add(child, key, state)
        end
    end
end

-- Both HP totals are divided by original blob count, then truncated in the
-- source. Creating the child first ensures failed placement leaves the
-- original untouched.
local function split(ctx, parent, position, health, size, site)
    local child_size = math.floor(size / 2)
    local parent_size = size - child_size
    local actor = ctx:get(parent, component.ACTOR)
    local attitude = targets.real_attitude(ctx, parent)
    local source = ctx:get(parent, component.VAULT_ACTOR_OVERRIDES)
    local fixed_hp = source and source.fixed_hp or 0
    local child = factory.spawn(ctx, actor.kind_id, position.level_id,
        site.x, site.y, {
            attitude = attitude,
            hp = fixed_hp > 0 and fixed_hp or nil,
            blob_size = child_size,
        })

    inherit(ctx, parent, child)

    local child_health = {
        current = math.max(1, math.floor(health.current * child_size / size)),
        max = math.max(1, math.floor(health.max * child_size / size)),
    }
    local parent_health = {
        current = math.max(1, math.floor(health.current * parent_size / size)),
        max = math.max(1, math.floor(health.max * parent_size / size)),
    }

    ctx:set(parent, component.HEALTH, parent_health)
    ctx:set(child, component.HEALTH, child_health)
    ctx:set(parent, component.SLIME_BLOB, {
        size = parent_size,
        reshaped_max = parent_health.max,
    })
    local child_blob = {
        size = child_size,
        reshaped_max = child_health.max,
    }

    if ctx:has(child, component.SLIME_BLOB) then
        ctx:set(child, component.SLIME_BLOB, child_blob)
    else
        ctx:add(child, component.SLIME_BLOB, child_blob)
    end

    ctx:add(child, component.SLIME_BIRTH, {
        created_aut = ctx:aut(),
    })

    if ctx:has(parent, component.JIYVA_GROWTH) then
        jiyva_growth.split_blob(ctx, parent, child, size, child_size)
    end

    if senses.player_sees_actor(ctx, parent) then
        ctx:emit(channels.MONSTER, "The " ..
            slime_blob.name(ctx, parent, "slime creature") .. " splits.")
    end

    return child
end

-- Source attempts division before merging. Its coin flip is paid only when
-- the body is large and healthy enough to try; movement can still veto it.
local function try_split(ctx, entity, position, health, size)
    if size <= 1 or health.current < 4 or
        ctx:random(streams.SLIME_CREATURE, 2) ~= 0 then
        return false
    end

    local site = split_site(ctx, entity, position,
        visible_foe(ctx, entity, position))

    if not site then
        return false
    end

    return split(ctx, entity, position, health, size, site) ~= nil
end

-- A polymorph request may divide a merged body without spending its normal
-- action. Source _slime_split still draws its coin flip but ignores the
-- result when forced; it also skips the approach restriction. The common
-- split owner apportions HP and lineage.
function lifecycle.force_split(ctx, entity)
    local actor = ctx:get(entity, component.ACTOR)
    local health = ctx:get(entity, component.HEALTH)
    local position = ctx:get(entity, component.POSITION)

    if not actor or actor.kind_id ~= monsters.MONS_SLIME_CREATURE or
        not health or health.current < 4 or not position then
        return nil
    end

    local size = slime_blob.size(ctx, entity)

    if size <= 1 then
        return nil
    end

    -- The C++ condition evaluates coinflip() before !force_split. Keeping
    -- this draw preserves later placement and polymorph RNG order.
    ctx:random(streams.SLIME_CREATURE, 2)

    if disabled(ctx, entity) then
        return nil
    end

    local site = split_site(ctx, entity, position, nil, true)

    if not site then
        return nil
    end

    return split(ctx, entity, position, health, size, site)
end

-- Only actors with the same durable allegiance and summon classification
-- can share a body. Charm and hex must also match, as in the source.
local function compatible(ctx, entity, other, size)
    local actor = ctx:get(other, component.ACTOR)
    local health = ctx:get(other, component.HEALTH)

    if not actor or actor.kind_id ~= monsters.MONS_SLIME_CREATURE or
        not health or health.current <= 0 or disabled(ctx, other) or
        targets.real_attitude(ctx, entity) ~= targets.real_attitude(ctx, other) or
        ctx:has(entity, component.SUMMON) ~= ctx:has(other, component.SUMMON) or
        targets.attitude(ctx, entity) ~= targets.attitude(ctx, other) then
        return false
    end

    return size + slime_blob.size(ctx, other) <= MAX_BLOBS
end

-- Source merge_ench_durations averages each timer by the number of blobs
-- that carried it. A positive remainder stays at one tick so a short
-- enchantment does not disappear just because integer division truncates.
local function merge_enchantments(ctx, source, target, source_size,
    target_size)
    local total = source_size + target_size

    for _, entry in ipairs(timed_enchantments) do
        local from = ctx:get(source, entry.key)
        local into = ctx:get(target, entry.key)

        if from or into then
            local result = into or from

            for _, field in ipairs(entry.fields) do
                local source_aut = from and from[field] or 0
                local target_aut = into and into[field] or 0
                local weighted = math.floor((source_aut * source_size +
                    target_aut * target_size) / total)

                if source_aut > 0 or target_aut > 0 then
                    weighted = math.max(1, weighted)
                end

                result[field] = weighted
            end

            if into then
                ctx:set(target, entry.key, result)
            else
                ctx:add(target, entry.key, result)
            end
        end
    end
end

-- A split child can be the surviving ECS identity when it absorbs the
-- original body. Move the original roster/vault origin to that survivor;
-- otherwise save accounting would treat an extant original as an extra
-- birth and could lose an authored vault's source reference.
local function inherit_original_origin(ctx, source, target)
    if not ctx:has(target, component.SLIME_BIRTH) or
        ctx:has(source, component.SLIME_BIRTH) then
        return
    end

    ctx:remove(target, component.SLIME_BIRTH)

    local source_growth = ctx:get(source, component.JIYVA_GROWTH)
    local target_growth = ctx:get(target, component.JIYVA_GROWTH)

    if source_growth and target_growth and
        not source_growth.born_from_split then
        target_growth.born_from_split = false
        ctx:set(target, component.JIYVA_GROWTH, target_growth)
    end

    for _, key in ipairs({
        component.VAULT_ORIGIN,
        component.VAULT_ACTOR_OVERRIDES,
    }) do
        local state = ctx:get(source, key)

        if state then
            if ctx:has(target, key) then
                ctx:set(target, key, state)
            else
                ctx:add(target, key, state)
            end
        end
    end
end

-- Merge into the neighboring body, preserving its ECS identity and pooling
-- health. Removing the old actor directly deliberately skips death rewards.
local function merge(ctx, entity, other, position, size)
    local source_health = ctx:get(entity, component.HEALTH)
    local target_health = ctx:get(other, component.HEALTH)
    local target_size = slime_blob.size(ctx, other)
    local inherited_slow = ctx:has(entity, component.PROJECTILE_SLOW) and
        not ctx:has(other, component.PROJECTILE_SLOW)

    merge_enchantments(ctx, entity, other, size, target_size)

    -- The slow component stores baseline speed, but the actor also carries
    -- its slowed live speed. Transfer both when only the dismissed body had
    -- that enchantment or restore would see an impossible slow state.
    if inherited_slow then
        local source_actor = ctx:get(entity, component.ACTOR)
        local target_actor = ctx:get(other, component.ACTOR)

        target_actor.speed = source_actor.speed
        ctx:set(other, component.ACTOR, target_actor)
    end

    jiyva_growth.merge_blob(ctx, entity, other,
        source_health.max, target_health.max)
    inherit_original_origin(ctx, entity, other)

    target_health.current = target_health.current + source_health.current
    target_health.max = target_health.max + source_health.max
    ctx:set(other, component.HEALTH, target_health)

    local blob = ctx:get(other, component.SLIME_BLOB)

    local merged_blob = {
        size = size + target_size,
        reshaped_max = target_health.max,
    }

    if blob then
        ctx:set(other, component.SLIME_BLOB, merged_blob)
    else
        ctx:add(other, component.SLIME_BLOB, merged_blob)
    end

    local ai = ctx:get(entity, component.AI)

    if ai then
        ctx:set(other, component.AI, ai)
    end

    local duel = ctx:get(entity, component.MONSTER_ARENA_DUEL)

    if duel and duel.current then
        if ctx:has(other, component.MONSTER_ARENA_DUEL) then
            ctx:set(other, component.MONSTER_ARENA_DUEL, duel)
        else
            ctx:add(other, component.MONSTER_ARENA_DUEL, duel)
        end
    end

    local energy = ctx:get(other, component.MONSTER_ENERGY)

    if energy then
        local actor = ctx:get(other, component.ACTOR)
        local definition = catalog.get("monsters", actor.kind_id)

        energy.points = math.max(0, energy.points - definition.energy.move)
        ctx:set(other, component.MONSTER_ENERGY, energy)
    end

    if senses.player_sees_actor(ctx, other) or
        senses.player_sees_actor(ctx, entity) then
        ctx:emit(channels.MONSTER, "Two slime creatures merge to form a " ..
            slime_blob.name(ctx, other, "slime creature") .. ".")
    end

    ctx:remove_actor(entity, position.level_id)
    ctx:destroy(entity)

    return true
end

-- A slime merges only if an adjacent compatible body advances pursuit and
-- there is no ordinary free step that advances it just as well.
local function try_merge(ctx, entity, position, state, size)
    if not state or state.behavior == behaviors.SLEEP or
        state.behavior == behaviors.WANDER or
        (state.target_x == 0 and state.target_y == 0) then
        return false
    end

    local goal = { x = state.target_x, y = state.target_y }
    local old_distance = distance(position, goal)
    local selected

    for dy = -1, 1 do
        for dx = -1, 1 do
            if dx ~= 0 or dy ~= 0 then
                local x = position.x + dx
                local y = position.y + dy
                local site = { x = x, y = y }

                if distance(site, goal) < old_distance then
                    local other = ctx:actor_at(position.level_id, x, y)

                    if not other and
                        free_site(ctx, entity, position, x, y) then
                        return false
                    end

                    if not selected and other and
                        compatible(ctx, entity, other, size) then
                        selected = other
                    end
                end
            end
        end
    end

    return selected and merge(ctx, entity, selected, position, size) or false
end

-- A successful natural ability consumes this action before spell and route
-- selection. The monster system installs WAIT for the surviving parent.
function lifecycle.tick(ctx, entity)
    local actor = ctx:get(entity, component.ACTOR)
    local health = ctx:get(entity, component.HEALTH)
    local position = ctx:get(entity, component.POSITION)

    if not actor or actor.kind_id ~= monsters.MONS_SLIME_CREATURE or
        not health or health.current <= 0 or not position or
        disabled(ctx, entity) then
        return false
    end

    local size = slime_blob.size(ctx, entity)

    return try_split(ctx, entity, position, health, size) or
        try_merge(ctx, entity, position, ctx:get(entity, component.AI), size)
end

-- Save validation has to distinguish a source-born extra body from an
-- arbitrary extra roster monster. An old birth marker may remain after
-- polymorph because that actor is still outside the initial floor budget.
function lifecycle.validate(ctx, entity, health, profile, now,
    fixed_per_blob, authored_max)
    local actor = ctx:get(entity, component.ACTOR)
    local birth = ctx:get(entity, component.SLIME_BIRTH)
    local blob = ctx:get(entity, component.SLIME_BLOB)
    local form = ctx:get(entity, component.MONSTER_POLYMORPH)
    local is_slime = actor and
        actor.kind_id == monsters.MONS_SLIME_CREATURE
    local descended = is_slime or form and
        form.original_kind_id == monsters.MONS_SLIME_CREATURE

    if birth and (not descended or birth.created_aut < 0 or
        birth.created_aut > now) then
        error("invalid slime birth " .. ctx:id(entity))
    end

    if blob and (not is_slime or blob.size < 1 or
        blob.size > MAX_BLOBS or blob.reshaped_max < 0 or
        blob.reshaped_max > MAX_BLOBS * 10000) then
        error("invalid slime blob " .. ctx:id(entity))
    end

    if not is_slime or not health or not profile then
        return
    end

    local size = blob and blob.size or 1
    local reshaped = blob and blob.reshaped_max > 0
    local upper_per_blob = math.max(profile.maximum,
        fixed_per_blob or 0, authored_max or 0)
    local growth = ctx:has(entity, component.JIYVA_GROWTH)
    local upper_total = upper_per_blob * size

    if growth then
        local definition = catalog.get("monsters", actor.kind_id)
        local average = math.floor(definition.average_hp_10x / 10)

        upper_total = math.max(upper_total, average * 4 * size)
    end

    -- A later Jiyva meal can legitimately raise the rounded split maximum.
    -- The growth owner's own birth and ceiling checks cover that case.
    if reshaped and (blob.reshaped_max > upper_total or
        not growth and
        health.max ~= blob.reshaped_max) then
        error("invalid reshaped slime health " .. ctx:id(entity))
    end

    local fixed = fixed_per_blob and fixed_per_blob > 0
    local invalid_max = fixed and
        health.max ~= fixed_per_blob * size or
        not fixed and
        (health.max < profile.minimum * size or
            health.max > profile.maximum * size)

    if (not reshaped and not growth and
        invalid_max) or
        health.current < 1 or health.current > health.max then
        error("invalid slime health " .. ctx:id(entity))
    end
end

return lifecycle
