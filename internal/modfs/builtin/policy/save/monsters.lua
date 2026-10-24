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
local avatar = require("policy.religion.wrath.avatar")
local summon_branches = require("policy.combat.monster_summons.branches")
local abyss = require("policy.world.abyss")
local abyss_constants = require("constants.abyss")
local component = require("constants.component")
local doom_howl = require("policy.combat.monster_doom_howl.ids")
local monsters = require("ids.monsters")
local tactical = require("constants.monster_tactical")
local band_members = require("policy.population.band_members")
local branches = require("ids.branches")
local ai_validation = require("policy.ai.validation")
local monster_profile = require("policy.combat.monster_profile")
local monster_spells = require("policy.combat.monster_spells")
local pan_traits = require("constants.pan_lord_traits")
local pan_colours = require("constants.pan_lord_colours")
local ugly_thing = require("policy.monsters.ugly_thing")
local slime_lifecycle = require("policy.monsters.slime_lifecycle")
local slime_blob = require("policy.monsters.slime_blob")
local fedhas = require("policy.religion.gods.fedhas")
local beogh = require("policy.religion.gods.beogh")
local jiyva = require("policy.religion.gods.jiyva")
local jiyva_growth = require("policy.religion.jiyva.growth")
local gods = require("constants.gods")
local vault_effects = require("constants.vault_effects")

-- A merge may consume an authored slime whose fixed HP differs from the
-- survivor's. Saved vault records retain that source maximum after death;
-- taking the largest possible source value bounds any merged blob without
-- trusting the new body's own reshaped HP marker as proof.
local function authored_slime_maximum(input)
    local by_level = {}
    local global_maximum = 0

    for _, level in ipairs(input.vault_levels or {}) do
        for _, record in ipairs(level.vault_records or {}) do
            local arguments = record.arguments or {}

            if record.kind == vault_effects.MONSTER and
                arguments.kind_id == monsters.MONS_SLIME_CREATURE and
                not record.pending and not arguments.no_spawn then
                local hp = arguments.hp or 0

                by_level[level.id] = math.max(by_level[level.id] or 0, hp)
                global_maximum = math.max(global_maximum, hp)
            end
        end
    end

    return by_level, global_maximum
end

-- Runtime combinations take place on one floor. Use that floor's authored
-- HP cap; transit through the Abyss may carry bodies from different floors.
local function slime_bound_for(ctx, entity, position, state)
    local origin = ctx:get(entity, component.VAULT_ORIGIN)
    local banishment = ctx:get(entity, component.BANISHMENT)
    local duel = ctx:get(entity, component.MONSTER_ARENA_DUEL)
    local visit = duel and duel.current and
        ctx:get(ctx:player(), component.PLAYER_ARENA_VISIT)
    local level_id = origin and origin.level_id or
        banishment and banishment.origin_level_id or
        visit and visit.origin_level_id or position.level_id

    if level_id == abyss.level_id then
        return state.slime_hp_global
    end

    return state.slime_hp_by_level[level_id] or 0
end

-- Banished monsters have different location requirements from level residents.
local function validate_banishment(ctx, entity, position)
    local origin = ctx:get(entity, component.BANISHMENT)

    if not origin then
        return
    end

    if (position.level_id ~= abyss.level_id and
        position.level_id ~= abyss_constants.TRANSIT_LEVEL_ID) or
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
    local arena_mark = ctx:get(entity, component.MONSTER_ARENA_DUEL)

    -- Duel moves the same roster actor to a temporary branch. Its source
    -- roster slot and allowed species still belong to the outside floor.
    if arena_mark and arena_mark.current then
        local visit = ctx:get(ctx:player(), component.PLAYER_ARENA_VISIT)

        if not visit or position.level_id ~= visit.level_id then
            error("Arena challenger has no matching player visit")
        end

        level_id = visit.origin_level_id
    end
    if level_id == abyss_constants.TRANSIT_LEVEL_ID then
        level_id = abyss.level_id
    end
    local fixed = state.fixed and level_id ~= abyss.level_id
    local growth = ctx:get(entity, component.JIYVA_GROWTH)
    local slime_birth = ctx:get(entity, component.SLIME_BIRTH)
    local born_from_split = growth and growth.born_from_split or
        slime_birth ~= nil

    if not fixed and not clone and not born_from_split then
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

    if not clone and not born_from_split and not allowed[roster_id] then
        error("unsupported melee attacker " .. roster_id ..
            " on level " .. tostring(level_id))
    end

    local definition = catalog.get("monsters", actor.kind_id)
    -- A polymorph rolls the live body's HP afresh. If that body later feeds,
    -- its Jiyva birth HP belongs to the new species, not its roster origin.
    -- Ambient corpse-form templates use a selected source body just as
    -- authored undead do. Validate rolled HP against that saved base
    -- instead of the template row, whose average HP is intentionally zero.
    local overrides = ctx:get(entity, component.VAULT_ACTOR_OVERRIDES)
    local profile_id = overrides and overrides.base_id ~= "" and
        overrides.base_id or roster_id
    local live_slime = actor.kind_id == monsters.MONS_SLIME_CREATURE
    local live_profile_id = (growth or live_slime and polymorph) and
        actor.kind_id or profile_id
    local profile = roster.profile(live_profile_id)

    if fixed and state.seen[roster_id] and not clone and
        not born_from_split then
        error("duplicate fixed animal " .. roster_id)
    end

    if not clone and not born_from_split then
        state.seen[roster_id] = true
    end

    -- A durable shifter can borrow its original species again. Its form
    -- marker still carries lineage, and the shifter validator below checks
    -- the permanent variant against that same origin.
    if polymorph and (roster_id == actor.kind_id and
        not ctx:has(entity, component.MONSTER_SHAPESHIFTER) or
        health.max <= 0 or health.current > health.max) then
        error("invalid polymorphed monster " .. ctx:id(entity))
    end

    local slime_fixed_hp = polymorph and 0 or
        overrides and overrides.fixed_hp

    slime_lifecycle.validate(ctx, entity, health, profile,
        state.current_aut, slime_fixed_hp,
        slime_bound_for(ctx, entity, position, state))

    if growth then
        local size = slime_blob.size(ctx, entity)

        jiyva_growth.validate(ctx, entity, health, {
            minimum = profile.minimum * size,
            maximum = profile.maximum * size,
        }, 0, slime_bound_for(ctx, entity, position, state))
    elseif not polymorph and not clone and
        actor.kind_id ~= monsters.MONS_SLIME_CREATURE and
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

-- Source ghost demons own their rolled profile. Compare the saved actor to
-- that profile and to the source bounds; a catalog HP/speed check would reject
-- legitimate lords and an unvalidated component could forge an impossible one.
local function validate_pan_lord(ctx, entity, actor, health, definition, overrides)
    local lord = ctx:get(entity, component.PANDEMONIUM_LORD)

    if not lord then
        return false
    end

    local lowest_hp = lord.spellcaster and 103 or 154
    local highest_hp = lord.spellcaster and 250 or 375
    local lowest_hd = lord.spellcaster and 12 or 17
    local highest_hd = lord.spellcaster and 30 or 35
    local lowest_speed = lord.spellcaster and 10 or 13
    local highest_speed = lord.spellcaster and 18 or 19
    local lowest_damage = lord.spellcaster and 22 or 32
    local highest_damage = lord.spellcaster and 60 or 70

    if type(lord.name) ~= "string" or
        not lord.name:match("^[A-Z][A-Za-z ]+$") or
        lord.name:find("  ", 1, true) or
        lord.name:sub(-1) == " " or
        #lord.name < 4 or #lord.name > 450 or
        not pan_colours.VALID[lord.colour_id] then
        error("Pan lord " .. ctx:id(entity) ..
            " has invalid generated appearance")
    end

    if actor.kind_id ~= monsters.MONS_PANDEMONIUM_LORD or
        lord.hp < lowest_hp or lord.hp > highest_hp or
        lord.hd < lowest_hd or lord.hd > highest_hd or
        lord.speed < lowest_speed or lord.speed > highest_speed or
        lord.damage < lowest_damage or lord.damage > highest_damage or
        lord.ac < 0 or lord.ev < 0 or
        #lord.spell_ids ~= #lord.frequencies or
        #lord.spell_ids > 5 or
        (not overrides or overrides.fixed_hp == 0) and
        health.max ~= lord.hp then
        error("Pan lord " .. ctx:id(entity) ..
            " has an invalid generated profile")
    end

    local resistance_bounds = {
        [pan_traits.fire] = { minimum = -1, maximum = 3 },
        [pan_traits.cold] = { minimum = -1, maximum = 3 },
        [pan_traits.electricity] = { minimum = 0, maximum = 3 },
    }
    local resistance_count = 0

    for id, level in pairs(lord.resistances) do
        local bounds = resistance_bounds[id]

        if not bounds or level < bounds.minimum or
            level > bounds.maximum then
            error("Pan lord " .. ctx:id(entity) ..
                " has invalid generated resistance")
        end

        resistance_count = resistance_count + 1
    end

    if resistance_count ~= 3 or
        not pan_traits.valid_attack_types[lord.attack_type_id] or
        not pan_traits.valid_flavours[lord.flavour_id] or
        not pan_traits.valid_brands[lord.brand_id] or
        not pan_traits.valid_rings[lord.ring_id] then
        error("Pan lord " .. ctx:id(entity) ..
            " has invalid generated melee or cloud ring")
    end

    local total = 0

    for index, id in ipairs(lord.spell_ids) do
        local frequency = lord.frequencies[index]
        local ok, effect = pcall(monster_spells.effect, id)

        if not ok or not effect or
            type(effect.plan) ~= "function" or
            type(effect.resolve) ~= "function" or
            frequency < 1 or frequency > 100 then
            error("Pan lord " .. ctx:id(entity) ..
                " has an invalid generated spell")
        end

        total = total + frequency
    end

    if total > 200 or not valid_speed(ctx, entity,
        monster_profile.definition(ctx, entity, definition), actor) then
        error("Pan lord " .. ctx:id(entity) ..
            " has invalid speed or spell frequency")
    end

    return true
end

-- Vault actors are validated against authored origin overrides instead of roster limits.
local function validate_vault_monster(ctx, entity, actor, health, position,
    ai, current_aut, slime_hp_bound)
    local definition = catalog.get("monsters", actor.kind_id)
    local overrides = ctx:get(entity, component.VAULT_ACTOR_OVERRIDES)
    local profile_id = overrides and overrides.base_id ~= "" and
        overrides.base_id or actor.kind_id
    local polymorph = ctx:get(entity, component.MONSTER_POLYMORPH)
    local growth_profile_id = polymorph and actor.kind_id or profile_id
    local profile = roster.profile(polymorph and
        actor.kind_id == monsters.MONS_SLIME_CREATURE and
        actor.kind_id or profile_id)
    local growth_profile = roster.profile(growth_profile_id)
    local fixed_hp = overrides and overrides.fixed_hp or 0
    local blob = ctx:get(entity, component.SLIME_BLOB)
    local blob_size = blob and blob.size or 1
    local reshaped = blob and blob.reshaped_max > 0
    local generated = ctx:get(entity, component.PANDEMONIUM_LORD)
    local invalid_health = not reshaped and not polymorph and
        fixed_hp > 0 and
        health.max ~= fixed_hp * blob_size or
        not reshaped and (fixed_hp == 0 or polymorph) and
        not generated and
        (health.max < profile.minimum * blob_size or
            health.max > profile.maximum * blob_size)

    slime_lifecycle.validate(ctx, entity, health, profile,
        current_aut, polymorph and 0 or fixed_hp, slime_hp_bound)

    if generated then
        validate_pan_lord(ctx, entity, actor, health, definition, overrides)
        definition = monster_profile.definition(ctx, entity, definition)
    end

    if ctx:has(entity, component.JIYVA_GROWTH) then
        -- Authored large slime creatures multiply their rolled or fixed HP
        -- by the saved blob size before the first meal records birth_max.
        local growth_size = polymorph and 1 or blob_size

        local growth_fixed_hp = polymorph and 0 or
            fixed_hp * growth_size

        jiyva_growth.validate(ctx, entity, health, {
            minimum = growth_profile.minimum * growth_size,
            maximum = growth_profile.maximum * growth_size,
        }, growth_fixed_hp, slime_hp_bound)
    elseif invalid_health then
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
    ai, current_aut, slime_hp_bound)
    local origin = ctx:get(entity, doom_howl.ARRIVAL)

    if not doom_howl.beast(actor.kind_id) or
        origin.created_aut < 0 or origin.created_aut > current_aut then
        error("monster " .. ctx:id(entity) ..
            " has invalid Doom Howl arrival origin")
    end

    validate_vault_monster(ctx, entity, actor, health, position,
        ai, current_aut, slime_hp_bound)
end

-- Monster save validation separates roster, vault, and banished actors because their origins differ.
-- Example: module.run(ctx, input) rejects a banished monster left on an ordinary floor.
function module.run(ctx, input)
    avatar.validate(ctx)
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

    for _, level in ipairs(input.levels) do
        if not fixed or level.branch_id == branches.BRANCH_ABYSS then
            budgets[level.id] = level.initial_actors

            if level.branch_id == branches.BRANCH_ABYSS then
                allowed_by_level[level.id] = roster.allowed(
                    "generated-dungeon-basic-v1", level.branch_id)
            elseif input.scenario_id == "generated-dungeon-basic-v1" then
                allowed_by_level[level.id] = roster.allowed(
                    input.scenario_id, level.branch_id)
            end
        end
    end

    if input.scenario_id == "generated-dungeon-basic-v1" then
        allowed.MONS_GOBLIN = true
        allowed.MONS_KOBOLD = true
    end

    local slime_hp_by_level, slime_hp_global =
        authored_slime_maximum(input)
    local roster_state = {
        allowed = allowed,
        allowed_by_level = allowed_by_level,
        fixed = fixed,
        seen = seen,
        budgets = budgets,
        live_by_level = live_by_level,
        current_aut = input.current_aut,
        slime_hp_by_level = slime_hp_by_level,
        slime_hp_global = slime_hp_global,
    }

    -- Plant allegiance is independent of the roster's origin, so validate
    -- every saved tag before the monster-only loop can skip an orphan.
    for _, entity in ipairs(ctx:query({ component.FEDHAS_PLANT })) do
        fedhas.validate(ctx, entity)
    end

    for _, entity in ipairs(ctx:query({ component.BEOGH_ORC })) do
        beogh.validate(ctx, entity)
    end

    for _, entity in ipairs(ctx:query({ component.BEOGH_RESURRECTED })) do
        local origin = ctx:get(entity, component.BEOGH_RESURRECTED)
        local actor = ctx:get(entity, component.ACTOR)
        local definition = actor and catalog.get("monsters",
            actor.kind_id)
        local allegiance = ctx:get(entity, component.BEOGH_ORC)

        if not definition or
            definition.genus_id ~= monsters.MONS_ORC or
            not allegiance or not allegiance.gift or
            origin.created_aut < 0 or
            origin.created_aut > input.current_aut or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) then
            error("invalid Beogh resurrection origin " ..
                ctx:id(entity))
        end
    end

    for _, entity in ipairs(ctx:query({ component.JIYVA_SLIME })) do
        jiyva.validate(ctx, entity)
    end

    -- Ignis's marker is a permanent monster enchantment. Reject orphaned
    -- or player-attached records before the ordinary AI loop could skip
    -- them and silently grant movement or attack effects to the wrong role.
    for _, entity in ipairs(ctx:query({
        component.IGNIS_FIRE_CHAMPION,
    })) do
        local marker = ctx:get(entity,
            component.IGNIS_FIRE_CHAMPION)

        if not marker.active or
            ctx:has(entity, component.PLAYER) or
            not ctx:has(entity, component.ACTOR) or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) then
            error("invalid Ignis fire champion " .. ctx:id(entity))
        end
    end

    -- The fed/split marker must belong to a complete monster, even when a
    -- malformed save omits AI and would miss the monster loop below.
    for _, entity in ipairs(ctx:query({ component.JIYVA_GROWTH })) do
        if not ctx:has(entity, component.ACTOR) or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) then
            error("orphan Jiyva growth " .. ctx:id(entity))
        end
    end

    -- A forged birth marker must not vanish from validation merely because
    -- its alleged body is missing the AI component used by the main loop.
    for _, entity in ipairs(ctx:query({ component.SLIME_BIRTH })) do
        if not ctx:has(entity, component.ACTOR) or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) then
            error("orphan slime birth " .. ctx:id(entity))
        end
    end

    -- Blob size without a complete actor would otherwise evade the main
    -- roster loop while still appearing in the dynamic component save.
    for _, entity in ipairs(ctx:query({ component.SLIME_BLOB })) do
        if not ctx:has(entity, component.ACTOR) or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) then
            error("orphan slime blob " .. ctx:id(entity))
        end
    end

    -- A spawned jelly is outside the original population count, but its
    -- saved origin must still prove species, creation time, and ownership.
    for _, entity in ipairs(ctx:query({ component.JIYVA_SPAWN })) do
        local origin = ctx:get(entity, component.JIYVA_SPAWN)
        local actor = ctx:get(entity, component.ACTOR)
        local overrides = ctx:get(entity, component.VAULT_ACTOR_OVERRIDES)

        if not actor or actor.kind_id ~= monsters.MONS_JELLY or
            not overrides or overrides.god_id ~= gods.JIYVA or
            overrides.fixed_hp ~= 0 or
            origin.created_aut < 1 or
            origin.created_aut > input.current_aut or
            not ctx:has(entity, component.JIYVA_SLIME) or
            not ctx:has(entity, component.AI) or
            not ctx:has(entity, component.HEALTH) or
            not ctx:has(entity, component.POSITION) then
            error("invalid Jiyva jelly origin " .. ctx:id(entity))
        end
    end

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

        ugly_thing.validate(ctx, entity,
            catalog.get("monsters", actor.kind_id))

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
                position, ai, input.current_aut,
                slime_bound_for(ctx, entity, position, roster_state))
        elseif ctx:get(entity, component.BEOGH_RESURRECTED) or
            ctx:get(entity, component.JIYVA_SPAWN) or
            ctx:get(entity, component.PANDEMONIUM_LORD) or
            ctx:get(entity, component.VAULT_ORIGIN) or
            ctx:get(entity, component.WORLD_VAULT_SPAWN) or
            ctx:get(entity, component.WORLD_WIZLAB_EVENT_ACTOR) then
            validate_vault_monster(ctx, entity, actor, health,
                position, ai, input.current_aut,
                slime_bound_for(ctx, entity, position, roster_state))
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
                position, ai, input.current_aut,
                slime_bound_for(ctx, entity, position, roster_state))
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
