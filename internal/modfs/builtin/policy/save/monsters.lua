local catalog = require("policy.catalog")
local roster = require("policy.population.roster")
local entities = require("policy.save.entities")
local inventory = require("policy.save.monster_inventory")
local links = require("policy.save.links")
local net = require("policy.combat.net")
local poison = require("policy.combat.monster_poison")
local slow = require("policy.combat.monster_slow")
local sticky_flame = require("policy.magic.effects.zaps.sticky_flame")
local summons = require("policy.save.summons")
local summon_branches = require("policy.combat.monster_summons.branches")
local abyss = require("policy.world.abyss")
local component = require("constants.component")
local doom_howl = require("policy.combat.monster_doom_howl.ids")
local monsters = require("ids.monsters")
local tactical = require("constants.monster_tactical")
local band_members = require("policy.population.band_members")
local branches = require("ids.branches")
local ai_validation = require("policy.ai.validation")

-- Banished monsters have different location requirements from level residents.
local function validate_banishment(ctx, entity, position)
    local origin = ctx:get(entity, component.BANISHMENT)

    if not origin then
        return
    end

    if position.level_id ~= abyss.level_id or
        origin.origin_level_id <= 0 or
        origin.origin_level_id == abyss.level_id or
        not ctx:walkable(origin.origin_level_id,
            origin.origin_x, origin.origin_y) then
        error("monster " .. ctx:id(entity) ..
            " has invalid banishment origin")
    end
end

-- Authored stationary monsters omit speed; their saved actor speed is zero.
-- Moving monsters can have a valid temporary slow recorded by its component.
local function valid_speed(ctx, entity, definition, actor)
    if (definition.speed or 0) == 0 then
        return actor.speed == 0 and
            not ctx:has(entity, component.PROJECTILE_SLOW)
    end

    return slow.validate(ctx, entity, definition, actor)
end

-- Roster monsters must match the scenario's allowed profile and starting bounds.
local function validate_roster_monster(ctx, entity, actor, health, position,
    ai, state)
    local polymorph = ctx:get(entity, "magic.monster_polymorph")
    local clone = ctx:get(entity, component.CHAOS_CLONE)
    local roster_id = clone and clone.roster_kind_id or
        polymorph and polymorph.original_kind_id or actor.kind_id

    if clone and (clone.roster_kind_id == "" or
        clone.created_aut > state.current_aut) then
        error("monster " .. ctx:id(entity) .. " has invalid chaos clone")
    end

    local banishment = ctx:get(entity, component.BANISHMENT)
    local level_id = banishment and banishment.origin_level_id or
        position.level_id

    if not state.fixed and not clone then
        local count = (state.live_by_level[level_id] or 0) + 1

        if count > (state.budgets[level_id] or 0) then
            error("Dungeon:" .. level_id .. " has too many live monsters")
        end

        state.live_by_level[level_id] = count
    end

    -- A chaos duplicate can copy an authored vault actor, whose kind is not
    -- part of the ordinary scenario roster. The clone component records its
    -- source kind; the catalog/profile checks below still validate it.
    local allowed = state.allowed_by_level[level_id] or state.allowed

    if not clone and not allowed[roster_id] then
        error("unsupported melee attacker " .. roster_id ..
            " on level " .. tostring(level_id))
    end

    local definition = catalog.get("monsters", actor.kind_id)
    local profile = roster.profile(roster_id)

    if state.fixed and state.seen[roster_id] and not clone then
        error("duplicate fixed animal " .. roster_id)
    end

    if not clone then
        state.seen[roster_id] = true
    end

    if polymorph and (roster_id == actor.kind_id or
        health.max <= 0 or health.current > health.max) then
        error("invalid polymorphed monster " .. ctx:id(entity))
    end

    if not polymorph and not clone and
        (health.max < profile.minimum or health.max > profile.maximum) then
        error("impossible fixed monster maximum HP " .. health.max)
    end

    if not valid_speed(ctx, entity, definition, actor) then
        error("fixed monster " .. actor.kind_id ..
            " has wrong speed " .. actor.speed)
    end

    ai_validation.validate(ctx, entity, ai, position, definition,
        state.current_aut)
    net.validate(ctx, entity, position)
    poison.validate(ctx, entity)
    sticky_flame.validate(ctx, entity)
end

local module = {}

-- A caster's spell-specific choices survive reload, so reject impossible
-- branch names and attempt counts before its next AI decision uses them.
local function validate_summon_cast_state(ctx, entity)
    local invitation = ctx:get(entity, component.MONSTER_INVITATION)
    local brothers = ctx:get(entity, component.MONSTER_BROTHERS)
    local recall = ctx:get(entity, component.MONSTER_RECALL)

    if invitation and
        not summon_branches.valid_invitation(invitation.branch_id) then
        error("monster " .. ctx:id(entity) ..
            " has invalid Invitation branch")
    end

    if brothers and (brothers.count < 0 or brothers.count > 2) then
        error("monster " .. ctx:id(entity) ..
            " has invalid Brothers in Arms count")
    end

    -- A chant and its cooldown are distinct phases; impossible timers
    -- would otherwise resume a spell at the wrong action after loading.
    if recall and (not recall.foe or
        recall.chant_aut < 0 or recall.chant_aut > 30 or
        recall.breath_aut < 0 or recall.breath_aut > 120 or
        (recall.chant_aut > 0 and recall.breath_aut > 0)) then
        error("monster " .. ctx:id(entity) ..
            " has invalid Word of Recall state")
    end
end

-- Vault actors are validated against authored origin overrides instead of roster limits.
local function validate_vault_monster(ctx, entity, actor, health, position,
    ai, current_aut)
    local definition = catalog.get("monsters", actor.kind_id)
    local overrides = ctx:get(entity, component.VAULT_ACTOR_OVERRIDES)
    local profile_id = overrides and overrides.base_id ~= "" and
        overrides.base_id or actor.kind_id
    local profile = roster.profile(profile_id)
    local fixed_hp = overrides and overrides.fixed_hp or 0
    local blob = ctx:get(entity, component.SLIME_BLOB)
    local blob_size = blob and blob.size or 1
    local invalid_health = fixed_hp > 0 and
        health.max ~= fixed_hp * blob_size or
        fixed_hp == 0 and
        (health.max < profile.minimum * blob_size or
            health.max > profile.maximum * blob_size)

    if invalid_health then
        error("vault monster " .. ctx:id(entity) .. " has impossible HP")
    end

    if not valid_speed(ctx, entity, definition, actor) then
        error("vault monster " .. actor.kind_id .. " has wrong speed")
    end

    ai_validation.validate(ctx, entity, ai, position, definition,
        current_aut)
    net.validate(ctx, entity, position)
    poison.validate(ctx, entity)
    sticky_flame.validate(ctx, entity)
end

-- Doom Howl arrivals are permanent creatures created during play. Their
-- explicit saved origin admits them outside the fixed starting roster,
-- while the ordinary monster profile and AI invariants still apply.
local function validate_doom_arrival(ctx, entity, actor, health, position,
    ai, current_aut)
    local origin = ctx:get(entity, doom_howl.ARRIVAL)

    if not doom_howl.beast(actor.kind_id) or
        origin.created_aut < 0 or origin.created_aut > current_aut then
        error("monster " .. ctx:id(entity) ..
            " has invalid Doom Howl arrival origin")
    end

    validate_vault_monster(ctx, entity, actor, health, position,
        ai, current_aut)
end

-- Monster save validation separates roster, vault, and banished actors because their origins differ.
-- Example: module.run(ctx, input) rejects a banished monster left on an ordinary floor.
function module.run(ctx, input)
    entities.validate(ctx)
    inventory.validate(ctx)
    links.validate(ctx)

    -- Every marker needs a live monster owner, including authored monsters
    -- whose vault origin takes precedence later in the save dispatch.
    for _, entity in ipairs(ctx:query({ tactical.KIRKE_BAND })) do
        local band = ctx:get(entity, tactical.KIRKE_BAND)
        local actor = ctx:get(entity, component.ACTOR)
        local form = ctx:get(entity, component.MONSTER_POLYMORPH)

        if not band.band_member or not actor or
            (actor.kind_id ~= monsters.MONS_HOG and
                (not form or form.original_kind_id ~= monsters.MONS_HOG)) or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) then
            error("entity " .. ctx:id(entity) ..
                " has orphan Kirke band origin")
        end
    end

    for _, entity in ipairs(ctx:query({ tactical.KIRKE_FREED })) do
        local freed = ctx:get(entity, tactical.KIRKE_FREED)
        local actor = ctx:get(entity, component.ACTOR)
        local form = ctx:get(entity, component.MONSTER_POLYMORPH)
        local changed_again = form and
            form.original_kind_id == freed.original_kind_id

        if not freed.freed or not actor or freed.kind_id == "" or
            freed.original_kind_id == "" or
            (freed.kind_id ~= actor.kind_id and not changed_again) or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) then
            error("entity " .. ctx:id(entity) ..
                " has orphan Kirke freedom origin")
        end
    end

    -- These two source exceptions create actors outside the ambient roster.
    -- Their saved origin markers must identify the matching unique body.
    for _, entity in ipairs(ctx:query({ component.UNIQUE_REVIVAL })) do
        local state = ctx:get(entity, component.UNIQUE_REVIVAL)
        local actor = ctx:get(entity, component.ACTOR)
        local form = ctx:get(entity, component.MONSTER_POLYMORPH)

        if not actor or state.revives < 1 or state.revives > 2 or
            (actor.kind_id ~= monsters.MONS_NATASHA and
                (not form or form.original_kind_id ~= monsters.MONS_NATASHA)) or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) then
            error("entity " .. ctx:id(entity) ..
                " has invalid Natasha revival origin")
        end
    end

    for _, entity in ipairs(ctx:query({ component.UNIQUE_REPLACEMENT })) do
        local state = ctx:get(entity, component.UNIQUE_REPLACEMENT)
        local actor = ctx:get(entity, component.ACTOR)

        if not actor or state.kind_id ~= monsters.MONS_BORIS or
            actor.kind_id ~= monsters.MONS_BORIS or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) then
            error("entity " .. ctx:id(entity) ..
                " has invalid Boris replacement origin")
        end
    end

    -- Bennu's second body is outside the level's original population
    -- budget. Only an actual saved Bennu with one rebirth may claim this
    -- exception; a forged marker cannot introduce another monster kind.
    for _, entity in ipairs(ctx:query({ component.BENNU_REVIVAL })) do
        local state = ctx:get(entity, component.BENNU_REVIVAL)
        local actor = ctx:get(entity, component.ACTOR)

        if not actor or actor.kind_id ~= monsters.MONS_BENNU or
            state.revives ~= 1 or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) then
            error("entity " .. ctx:id(entity) ..
                " has invalid Bennu revival origin")
        end
    end

    -- The delayed Pikel action removes these marked lemures. Its origin
    -- must not be forged onto a different live monster in a save file.
    for _, entity in ipairs(ctx:query({ component.PIKEL_BAND })) do
        local marker = ctx:get(entity, component.PIKEL_BAND)
        local actor = ctx:get(entity, component.ACTOR)
        local form = ctx:get(entity, component.MONSTER_POLYMORPH)
        local source_kind = form and form.original_kind_id or
            actor and actor.kind_id

        if not marker.band_member or
            source_kind ~= monsters.MONS_LEMURE or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) then
            error("entity " .. ctx:id(entity) ..
                " has invalid Pikel band origin")
        end
    end

    -- A band member can outlive its leader and lose the live follower
    -- link. Its durable origin still identifies a legitimate catalog
    -- member so restore does not misclassify it as an ambient spawn.
    for _, entity in ipairs(ctx:query({ component.BAND_ORIGIN })) do
        local origin = ctx:get(entity, component.BAND_ORIGIN)
        local actor = ctx:get(entity, component.ACTOR)
        local form = ctx:get(entity, component.MONSTER_POLYMORPH)
        local source_kind = form and form.original_kind_id or
            actor and actor.kind_id
        local leader = catalog.get("monsters", origin.leader_kind_id)

        if not actor or origin.member_kind_id ~= source_kind or
            not band_members.allowed(leader.band, source_kind) or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) then
            error("entity " .. ctx:id(entity) ..
                " has invalid band origin")
        end
    end

    -- The borrowed body may change repeatedly, but the one permanent owner
    -- must still identify a real source monster and its first lineage.
    for _, entity in ipairs(ctx:query({
        component.MONSTER_SHAPESHIFTER,
    })) do
        local shape = ctx:get(entity, component.MONSTER_SHAPESHIFTER)
        local actor = ctx:get(entity, component.ACTOR)
        local health = ctx:get(entity, component.HEALTH)
        local form = ctx:get(entity, component.MONSTER_POLYMORPH)
        local ordinary = shape.variant_id == monsters.MONS_SHAPESHIFTER
        local glowing = shape.variant_id ==
            monsters.MONS_GLOWING_SHAPESHIFTER
        local source = register.get("monsters", shape.original_kind_id)

        if not actor or not health or health.current <= 0 or
            not ctx:has(entity, component.POSITION) or
            not ctx:has(entity, component.AI) or
            not (ordinary or glowing) or
            shape.original_kind_id == "" or
            not source or source.status ~= "defined" or
            not form or form.original_kind_id ~= shape.original_kind_id then
            error("entity " .. ctx:id(entity) ..
                " has invalid shapeshifter identity")
        end
    end

    -- A saved chant must belong to a real monster. The active recall
    -- system queries this component directly, including non-AI owners.
    for _, owner in ipairs(ctx:query({ component.MONSTER_RECALL })) do
        if owner == ctx:player() or
            not ctx:has(owner, component.AI) or
            not ctx:has(owner, component.ACTOR) or
            not ctx:has(owner, component.POSITION) then
            error("invalid Word of Recall owner " .. ctx:id(owner))
        end
    end

    local allowed = roster.allowed(input.scenario_id, branches.BRANCH_DUNGEON)
    local fixed = input.scenario_id ~= "fixed-dungeon-population-v1" and
        input.scenario_id ~= "generated-dungeon-basic-v1"
    local seen = {}
    local budgets = {}
    local live_by_level = {}
    local allowed_by_level = {}

    if not fixed then
        for _, level in ipairs(input.levels) do
            budgets[level.id] = level.initial_actors

            if input.scenario_id == "generated-dungeon-basic-v1" and
                level.branch_id ~= branches.BRANCH_ABYSS then
                allowed_by_level[level.id] = roster.allowed(
                    input.scenario_id, level.branch_id)
            end
        end
    end

    if input.scenario_id == "generated-dungeon-basic-v1" then
        allowed.MONS_GOBLIN = true
        allowed.MONS_KOBOLD = true
    end

    local roster_state = {
        allowed = allowed,
        allowed_by_level = allowed_by_level,
        fixed = fixed,
        seen = seen,
        budgets = budgets,
        live_by_level = live_by_level,
        current_aut = input.current_aut,
    }

    -- A custom ghost profile may not be detached from its live actor. The
    -- ordinary AI loop below only visits complete monsters, so catch orphan
    -- profile entities before they could bypass summon validation.
    for _, entity in ipairs(ctx:query({ component.PLAYER_ILLUSION })) do
        if not ctx:has(entity, component.ACTOR) or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) or
            not ctx:has(entity, component.SUMMON) then
            error("orphan player illusion profile " .. ctx:id(entity))
        end
    end

    for _, entity in ipairs(ctx:query({ "core.ai" })) do
        local actor = ctx:get(entity, "core.actor")
        local health = ctx:get(entity, "core.health")
        local position = ctx:get(entity, "core.position")
        local energy = ctx:get(entity, "core.monster_energy")
        local ai = ctx:get(entity, "core.ai")
        local rolling = ctx:get(entity, component.MONSTER_ROLLING)

        if not actor or not health or not position or not energy then
            error("invalid monster entity " .. ctx:id(entity))
        end

        if energy.points < 0 or (input.player_alive and energy.points >= 80) then
            error("monster " .. ctx:id(entity) .. " has invalid action energy")
        end

        if health.current <= 0 then
            error("saved monster " .. ctx:id(entity) .. " has no remaining HP")
        end

        if rolling and (rolling.remaining_aut < 1 or
            rolling.remaining_aut > 150) then
            error("monster " .. ctx:id(entity) ..
                " has invalid rolling duration")
        end

        validate_banishment(ctx, entity, position)
        validate_summon_cast_state(ctx, entity)

        local summon = ctx:get(entity, "magic.summon")

        if ctx:has(entity, component.SUMMON_MIRROR) and not summon then
            error("mirror copy " .. ctx:id(entity) ..
                " has no summon owner")
        end

        if ctx:has(entity, component.PLAYER_ILLUSION) and not summon then
            error("player illusion " .. ctx:id(entity) ..
                " has no summon owner")
        end

        -- Summons follow owner/expiry rules; authored vault actors and roster actors have different origin checks.
        if summon then
            summons.validate(ctx, entity, actor, position, ai,
                summon, input.current_aut)
        elseif ctx:get(entity, doom_howl.ARRIVAL) then
            validate_doom_arrival(ctx, entity, actor, health,
                position, ai, input.current_aut)
        elseif ctx:get(entity, component.VAULT_ORIGIN) then
            validate_vault_monster(ctx, entity, actor, health,
                position, ai, input.current_aut)
        -- Kirke's extra band and released actors have explicit origins, not
        -- roster slots. The marker loop above checks their ownership; the
        -- ordinary monster profile still checks HP, speed, and AI here.
        elseif ctx:get(entity, component.UNIQUE_REVIVAL) or
            ctx:get(entity, component.UNIQUE_REPLACEMENT) or
            ctx:get(entity, component.BENNU_REVIVAL) or
            ctx:get(entity, component.BAND_ORIGIN) or
            ctx:get(entity, tactical.KIRKE_BAND) or
            ctx:get(entity, tactical.KIRKE_FREED) then
            validate_vault_monster(ctx, entity, actor, health,
                position, ai, input.current_aut)
        else
            validate_roster_monster(ctx, entity, actor, health,
                position, ai, roster_state)
        end
    end

    return {}
end

register.policy({
    id = "save.validate_monsters",
    run = module.run,
})

return module
