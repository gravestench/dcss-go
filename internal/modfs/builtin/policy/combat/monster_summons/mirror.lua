-- Monster mirror spells copy live ECS state beside their source. The spell
-- files choose when and whom; this owner creates one independently saved body.
-- Source: mon-cast.cc:cast_phantom_mirror and mon-clone.cc:clone_mons.
local actors = require("policy.combat.monster_area.actors")
local catalog = require("policy.catalog")
local clone_inventory = require("policy.combat.clone_inventory")
local component = require("constants.component")
local flags = require("constants.monster_flags")
local monster_stats = require("policy.combat.monster_stats")
local monsters = require("ids.monsters")
local net = require("policy.combat.net")
local spells = require("ids.spells")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local targets = require("policy.ai.targets")
local trap_held = require("policy.traps.held")

local mirror = {}
local SIGHT_RADIUS = 7
local tentacles = {
    [monsters.MONS_KRAKEN_TENTACLE] = true,
    [monsters.MONS_KRAKEN_TENTACLE_SEGMENT] = true,
    [monsters.MONS_ELDRITCH_TENTACLE] = true,
    [monsters.MONS_ELDRITCH_TENTACLE_SEGMENT] = true,
    [monsters.MONS_MNOLEG_TENTACLE] = true,
    [monsters.MONS_MNOLEG_TENTACLE_SEGMENT] = true,
    [monsters.MONS_STARSPAWN_TENTACLE] = true,
    [monsters.MONS_STARSPAWN_TENTACLE_SEGMENT] = true,
}

-- Statuses tied to the body can continue on the copied body. Restraints,
-- external marks, AI references, and world lifecycle tags cannot: copying
-- those would create a second owner of the source's outside relationships.
local bodily_status = {
    component.MONSTER_ALLEGIANCE,
    component.MONSTER_BOONS,
    component.MONSTER_CONFUSION,
    component.MONSTER_DRAINED,
    component.MONSTER_ENCHANT,
    component.MONSTER_ENFEEBLE,
    component.MONSTER_LOWERED_WILL,
    component.MONSTER_REPULSION,
    component.MONSTER_STASIS,
    component.MONSTER_TROGS_HAND,
    component.MONSTER_WATERLOGGED,
    component.PROJECTILE_POISON,
    component.PROJECTILE_SLOW,
    component.WRETCHED,
}

-- A catalogue flag is a species trait, so this test also works for a new
-- monster definition added by a mod without changing the spell owner.
local function has_flag(definition, wanted)
    for _, value in ipairs(definition.flags or {}) do
        if value == wanted then
            return true
        end
    end

    return false
end

-- Source Phantom Mirror takes an ordinary allied monster that can move and
-- is not already a spell copy. Mara's self-clone deliberately uses a separate
-- rule because its unique caster is eligible only for fake summoning.
function mirror.eligible_ally(ctx, caster, target)
    if target == caster or ctx:has(target, component.PLAYER) or
        ctx:has(target, component.SUMMON) or
        not targets.aligned(ctx, caster, target) then
        return false
    end

    local actor = ctx:get(target, component.ACTOR)

    if not actor then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)

    return not has_flag(definition, flags.STATIONARY) and
        not has_flag(definition, flags.CONJURED) and
        not has_flag(definition, flags.UNIQUE)
end

-- Summon Illusion clones its enemy, unlike Phantom Mirror's allied source.
-- One live copy per source is identified by the original ECS handle, not
-- merely by monster kind: two orcs may each have their own illusion.
function mirror.eligible_illusion(ctx, source)
    if ctx:has(source, component.PLAYER) or
        ctx:has(source, component.SUMMON_MIRROR) or
        ctx:has(source, component.PLAYER_ILLUSION) then
        return false
    end

    local actor = ctx:get(source, component.ACTOR)
    local health = ctx:get(source, component.HEALTH)

    if not actor or not health or health.current <= 0 or
        tentacles[actor.kind_id] then
        return false
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if has_flag(definition, flags.CONJURED) then
        return false
    end

    for _, entity in ipairs(ctx:query({ component.SUMMON_MIRROR })) do
        local state = ctx:get(entity, component.SUMMON)
        local copy = ctx:get(entity, component.SUMMON_MIRROR)
        local life = ctx:get(entity, component.HEALTH)

        if state and state.source_id == spells.SPELL_SUMMON_ILLUSION and
            copy.origin_entity_id == tostring(ctx:id(source)) and
            life and life.current > 0 then
            return false
        end
    end

    return true
end

-- Only live actors in unobstructed sight can be selected. Stable ECS query
-- order keeps a fixed seed independent of Lua table or file load order.
function mirror.allies(ctx, caster)
    local found = {}

    for _, target in ipairs(actors.los(ctx, caster,
        SIGHT_RADIUS)) do
        if mirror.eligible_ally(ctx, caster, target) then
            found[#found + 1] = target
        end
    end

    return found
end

-- Source count_summons counts only this caster's still aligned copies.
-- A changed allegiance can therefore free a slot for a new fake Mara.
function mirror.fake_count(ctx, caster)
    local count = 0

    for _, entity in ipairs(ctx:query({ component.SUMMON })) do
        local state = ctx:get(entity, component.SUMMON)

        if state.owner == caster and
            state.source_id == spells.SPELL_FAKE_MARA_SUMMON and
            targets.aligned(ctx, caster, entity) then
            count = count + 1
        end
    end

    return count
end

-- Copy only the actor's bodily timers. The clone's summon, target memory,
-- location, and outside bonds are all created afresh by their own owners.
local function copy_body(ctx, source, twin)
    local actor = ctx:get(source, component.ACTOR)
    local copied = ctx:get(twin, component.ACTOR)

    copied.speed = actor.speed
    ctx:set(twin, component.ACTOR, copied)

    for _, key in ipairs(bodily_status) do
        local state = ctx:get(source, key)

        if state then
            ctx:add(twin, key, state)
        end
    end

    clone_inventory.copy(ctx, source, twin)
end

-- Source cast_phantom_mirror frees the original from direct constriction
-- and trapping nets once the copy exists. The copy never inherits these
-- outside bindings, whose other endpoint belongs to the original body.
local function untangle_original(ctx, source)
    net.release(ctx, source)
    trap_held.release(ctx, source)

    for _, key in ipairs({
        component.PLAYER_CONSTRICTION,
        component.GRASPING_ROOTS,
        component.MONSTER_VILE_CLUTCH,
    }) do
        if ctx:has(source, key) then
            ctx:remove(source, key)
        end
    end
end

-- A coin flip swaps the source and copy in one grid operation. Both occupied
-- cells remain valid, and the source's existing target handles still name it.
local function maybe_swap(ctx, source, twin)
    if ctx:random(streams.MONSTER_SPELL, 2) ~= 0 then
        return
    end

    local original = ctx:get(source, component.POSITION)
    local copied = ctx:get(twin, component.POSITION)

    ctx:move_actors({
        {
            actor = source,
            level_id = original.level_id,
            x = copied.x,
            y = copied.y,
        },
        {
            actor = twin,
            level_id = copied.level_id,
            x = original.x,
            y = original.y,
        },
    })
end

-- The shared summon owner finds an adjacent cell and assigns finite source
-- lifetime. Only after placement succeeds do we copy current HP and items;
-- a blocked cast never creates duplicate equipment or rolls a swap.
function mirror.spawn(ctx, caster, source, spell_id, hp_percent, cap,
    options)
    options = options or {}
    local actor = ctx:get(source, component.ACTOR)
    local health = ctx:get(source, component.HEALTH)
    local position = ctx:get(source, component.POSITION)

    if not actor or not health or health.current <= 0 or not position then
        return nil
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local hd = monster_stats.base_hit_dice(ctx, source, definition)
    local current = math.max(1,
        math.floor(health.current * hp_percent / 100))
    local maximum = math.max(1,
        math.floor(health.max * hp_percent / 100))
    local twin = summons.spawn(ctx, caster, spell_id, actor.kind_id,
        options.duration or 5, cap, {
            anchor = position,
            attitude = targets.attitude(ctx, caster),
            hd = hd,
            hp = current,
        })

    if not twin then
        return nil
    end

    ctx:set(twin, component.HEALTH, {
        current = current,
        max = maximum,
    })
    ctx:add(twin, component.SUMMON_MIRROR, {
        origin_kind_id = actor.kind_id,
        origin_entity_id = tostring(ctx:id(source)),
        hp_percent = hp_percent,
    })

    copy_body(ctx, source, twin)

    if options.discard_charm then
        local allegiance = ctx:get(twin,
            component.MONSTER_ALLEGIANCE)

        if allegiance then
            allegiance.charm_aut = 0
            ctx:set(twin, component.MONSTER_ALLEGIANCE,
                allegiance)
        end
    end

    if options.untangle ~= false then
        untangle_original(ctx, source)
    end

    if options.swap ~= false then
        maybe_swap(ctx, source, twin)
    end

    return twin
end

return mirror
