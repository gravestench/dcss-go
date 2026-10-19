-- Mara's illusion is a monster with a snapshot of the player's ghost-like
-- combat body. The player can change after this cast without changing it.
-- Source: mon-clone.cc:mons_summon_illusion_from and ghost.cc:init_player_ghost.
local catalog = require("policy.catalog")
local component = require("constants.component")
local equipment = require("policy.combat.equipment")
local failure = require("policy.magic.failure")
local fighter = require("policy.combat.fighter")
local formulas = require("policy.character.formulas")
local magic_damage = require("policy.magic.damage")
local monster_effects = require("policy.combat.monster_spells")
local mutation_levels = require("policy.mutations.levels")
local mutations = require("ids.mutations")
local object_classes = require("ids.object_classes")
local player_resistance = require("policy.combat.player_resistance")
local records = require("policy.character.spell_records")
local resistance_ids = require("constants.resistance_ids")
local senses = require("policy.character.senses")
local spell_ids = require("ids.spells")
local staves = require("policy.inventory.staves")
local streams = require("constants.rng_streams")
local summons = require("policy.magic.effects.summons.common")
local targets = require("policy.ai.targets")
local weapon_brands = require("constants.weapon_brands")
local monsters = require("ids.monsters")
local holiness = require("constants.monster_holiness")
local player_holiness = require("policy.character.holiness")
local ammunition = require("ids.ammunition")
local species_ids = require("ids.species")
local zap_ids = require("policy.magic.effects.zaps.ids")

local illusion = {}
local MAX_HP = 400
local MAX_EV = 60
local MAX_DAMAGE = 50
local DURATION = 6

local staff_brands = {
    fire = weapon_brands.FLAMING,
    ice = weapon_brands.FREEZING,
    poison = weapon_brands.VENOM,
    necromancy = weapon_brands.PAIN,
    air = weapon_brands.ELECTROCUTION,
    earth = weapon_brands.VORPAL,
}

local forbidden_brands = {
    [weapon_brands.HOLY_WRATH] = true,
    [weapon_brands.CHAOS] = true,
    [weapon_brands.REAPING] = true,
    [weapon_brands.PENETRATION] = true,
    [weapon_brands.SPECTRAL] = true,
}

local spell_translation = {
    [spell_ids.SPELL_DRAGON_CALL] = spell_ids.SPELL_SUMMON_DRAGON,
    [spell_ids.SPELL_SWIFTNESS] = spell_ids.SPELL_SPRINT,
}

-- Stable known-slot order is the same order in which the player memorized
-- spells. This comparator is separate from the capture loop for readability.
local function known_before(first, second)
    return first.known_slot < second.known_slot
end

-- Ghost creation unwinds transformations in the source. This read-only
-- context view masks a temporary form while preserving every other live
-- player component and the normal equipment/attribute policies.
local function untransformed(ctx, player)
    local view = setmetatable({}, { __index = ctx })

    -- Ignore only the player's temporary form for derived ghost values.
    function view:get(entity, key)
        if entity == player and key == component.PLAYER_FORM then
            return nil
        end

        return ctx:get(entity, key)
    end

    -- Keep presence checks consistent with the masked component read.
    function view:has(entity, key)
        if entity == player and key == component.PLAYER_FORM then
            return false
        end

        return ctx:has(entity, key)
    end

    return view
end

-- Source ghost damage ignores enchantment and uses the weapon's base damage,
-- its governing skill, Fighting, and the player's current Strength. Launchers
-- use Fighting for the first skill term even though they bash in melee.
local function melee_profile(ctx, player, level)
    local worn = equipment.worn(ctx, player, { weapon = true })
    local weapon = worn.weapon
    local damage = 4
    local brand = weapon_brands.NORMAL

    if weapon then
        local definition = weapon.definition
        local profile = staves.weapon(definition)

        if profile then
            damage = profile.damage

            local launcher = profile.ammo_id ~= nil and
                profile.ammo_id ~= ammunition.NONE
            local skill = launcher and
                "SK_FIGHTING" or profile.skill_id

            damage = math.floor(damage *
                (25 + fighter.skill_level(ctx, skill)) / 25)
        end

        if definition.class == object_classes.OBJ_WEAPONS then
            brand = weapon.ego ~= "" and weapon.ego or
                weapon_brands.NORMAL
        elseif definition.class == object_classes.OBJ_STAVES then
            brand = staff_brands[definition.staff.school] or
                weapon_brands.NORMAL
        end

        if forbidden_brands[brand] then
            brand = weapon_brands.NORMAL
        end
    else
        if mutation_levels.base(ctx, player, mutations.MUT_CLAWS) > 0 then
            damage = damage + level
        end

        damage = damage + fighter.skill_level(ctx,
            "SK_UNARMED_COMBAT")
    end

    damage = math.floor(damage *
        (30 + fighter.skill_level(ctx, "SK_FIGHTING")) / 30)

    local attributes = require("policy.character.attributes")

    damage = damage + math.floor(attributes.current(ctx, player).strength / 4)

    return math.min(MAX_DAMAGE, damage), brand
end

-- The player and monster damage owners share IDs. Store a numeric map so
-- later attacks use the snapshot even if the source player's rings change.
local function resistances(ctx, player)
    local levels = {}

    for _, id in ipairs({
        resistance_ids.FIRE,
        resistance_ids.COLD,
        resistance_ids.ELECTRICITY,
        resistance_ids.ACID,
        resistance_ids.STEAM,
        resistance_ids.NEGATIVE_ENERGY,
    }) do
        levels[id] = magic_damage.player_resistance(ctx, player, id)
    end

    levels[resistance_ids.POISON] =
        player_resistance.poison(ctx, player)
    levels[resistance_ids.PETRIFY] =
        player_resistance.petrification(ctx, player) and 3 or 0
    levels[resistance_ids.MIASMA] =
        player_holiness.natural(ctx, player) and 0 or 3

    return levels
end

-- Only a known spell with a monster resolver can enter the custom AI book.
-- Missing resolver files become eligible automatically when that spell's
-- Lua domain is ported; there is no content-ID switch in the engine.
local function executable(spell_id)
    local available, effect = pcall(monster_effects.effect, spell_id)

    return available and type(effect) == "table" and
        type(effect.plan) == "function" and
        type(effect.resolve) == "function"
end

-- Source ghosts forget spells stochastically according to displayed failure.
-- The selected list and normalized frequencies are saved on the illusion,
-- never regenerated during AI turns or restore.
local function spells(ctx, player, level)
    local known = {}

    for _, entry in ipairs(records.list(ctx, player)) do
        if entry.state.known_slot > 0 then
            known[#known + 1] = entry.state
        end
    end

    table.sort(known, known_before)

    local selected = {}

    for _, record in ipairs(known) do
        local spell = catalog.get("spells", record.spell_id)
        local ghost_id = spell_translation[record.spell_id] or
            record.spell_id
        local no_ghost = false

        for _, flag in ipairs(spell.flags or {}) do
            if flag == "no_ghost" then
                no_ghost = true
            end
        end

        if not no_ghost and executable(ghost_id) then
            local chance = math.max(0, 50 -
                failure.profile(ctx, player, spell).percent)

            if ctx:random(streams.MONSTER_SPELL, 2500) <
                chance * chance then
                selected[#selected + 1] = ghost_id
            end
        end
    end

    local frequencies = {}

    if #selected > 0 then
        local frequency = math.floor((level + 50) / #selected)

        for index = 1, #selected do
            frequencies[index] = frequency
        end
    end

    return selected, frequencies
end

-- Capture all ghost values before placing an actor. If the adjacent grid is
-- blocked, none of the player-derived data becomes an orphaned component.
function illusion.capture(ctx, player)
    local view = untransformed(ctx, player)
    local choice = view:get(player, component.PLAYER)
    local progress = view:get(player, component.PROGRESSION)
    local skills = view:get(player, component.SKILLS)
    local species = catalog.get("species", choice.species_id)
    local defense = fighter.defense(view)
    local damage, brand = melee_profile(view, player, progress.level)
    local spell_list, frequencies = spells(view, player, progress.level)
    local natural = player_holiness.natural(view, player)
    local holiness_id = natural and holiness.NATURAL or holiness.UNDEAD
    local petrification = view:get(player,
        component.PLAYER_PETRIFICATION)

    if choice.species_id == species_ids.SP_GARGOYLE or
        choice.species_id == species_ids.SP_DJINNI or
        petrification and petrification.petrified_aut > 0 then
        holiness_id = holiness.NONLIVING
    end

    return {
        name = choice.name,
        species_id = choice.species_id,
        job_id = choice.job_id,
        ac = defense.ac,
        ev = math.min(MAX_EV, defense.ev),
        damage = damage,
        necromancy_skill = fighter.skill_level(view,
            "SK_NECROMANCY"),
        brand_id = brand,
        holiness_id = holiness_id,
        see_invisible = senses.see_invisible(view, player),
        resistances = resistances(view, player),
        spell_ids = spell_list,
        frequencies = frequencies,
        hp = math.min(MAX_HP, formulas.max_hp(view, player,
            progress.level, species, skills.entries)),
        hd = progress.level,
    }
end

-- An active illusion of this named player prevents repeated summons. The
-- source checks by name because its monster body has a separate entity ID.
function illusion.exists(ctx, name)
    for _, entity in ipairs(ctx:query({
        component.PLAYER_ILLUSION,
        component.HEALTH,
    })) do
        local profile = ctx:get(entity, component.PLAYER_ILLUSION)
        local health = ctx:get(entity, component.HEALTH)

        if profile.name == name and health.current > 0 then
            return true
        end
    end

    return false
end

-- The source transfers only durations internal to the body. A trapping net,
-- sticky flame, or external hex remains on the original player and is not
-- fabricated on the new monster.
local function copy_statuses(ctx, player, actor)
    local durations = ctx:get(player, component.DURATIONS)

    if durations and (durations.haste_aut > 0 or
        durations.might_aut > 0) then
        ctx:add(actor, component.MONSTER_BOONS, {
            haste_aut = durations.haste_aut,
            might_aut = durations.might_aut,
        })
    end

    local invisible = ctx:get(player,
        component.POTION_INVISIBILITY)

    if invisible and invisible.remaining_aut > 0 then
        ctx:add(actor, component.MONSTER_ENCHANT, {
            invisible_aut = invisible.remaining_aut,
        })
    end

    local paralysis = ctx:get(player, component.PLAYER_PARALYSIS)

    if paralysis and paralysis.remaining_aut > 0 then
        ctx:add(actor, component.PARALYSIS, {
            remaining_aut = paralysis.remaining_aut,
        })
    end

    local confusion = ctx:get(player,
        zap_ids.component.PLAYER_CONFUSION)

    if confusion and confusion.remaining_aut > 0 then
        ctx:add(actor, component.MONSTER_CONFUSION, {
            remaining_aut = confusion.remaining_aut,
        })
    end

    local rage = ctx:get(player, component.RAGE)

    if rage and rage.remaining_aut > 0 then
        ctx:add(actor, component.MONSTER_ALLEGIANCE, {
            frenzy_aut = rage.remaining_aut,
            berserk_hp = true,
        })
    end

    local slow = ctx:get(player, component.PLAYER_SLOW)

    if slow and slow.remaining_aut > 0 then
        local body = ctx:get(actor, component.ACTOR)

        body.speed = math.floor(body.speed * 2 / 3)
        ctx:set(actor, component.ACTOR, body)
        ctx:add(actor, component.PROJECTILE_SLOW, {
            base_speed = 10,
            remaining_aut = slow.remaining_aut,
        })
    end
end

-- The generic summon owner places the body beside Mara and owns lifetime,
-- allegiance, energy, and expiry. The ghost snapshot owns its combat rules.
function illusion.spawn(ctx, caster, player)
    local profile = illusion.capture(ctx, player)
    local actor = summons.spawn(ctx, caster,
        spell_ids.SPELL_SUMMON_ILLUSION,
        monsters.MONS_PLAYER_ILLUSION, DURATION, nil, {
            hp = profile.hp,
            hd = profile.hd,
            attitude = targets.attitude(ctx, caster),
        })

    if not actor then
        return nil
    end

    profile.hp = nil
    profile.hd = nil
    ctx:add(actor, component.PLAYER_ILLUSION, profile)
    copy_statuses(ctx, player, actor)

    return actor
end

return illusion
