local spells = require("ids.spells")
local gods = require("constants.gods")
local jiyva_slimes = require("constants.jiyva_ejectable_monsters")
local monsters = require("ids.monsters")
local items = require("ids.items")
local component = require("constants.component")
local catalog = require("policy.catalog")
local categories = require("constants.catalog")
local attitudes = require("constants.attitude")
local traps = require("ids.traps")
local net = require("policy.combat.net")
local poison = require("policy.combat.monster_poison")
local slow = require("policy.combat.monster_slow")
local sticky_flame = require("policy.magic.effects.zaps.sticky_flame")
local brands = require("constants.weapon_brands")
local plants = require("policy.save.monster_plants")
local living_spells = require("policy.combat.monster_summons.living_spells")
local resistance_ids = require("constants.resistance_ids")
local holiness = require("constants.monster_holiness")
local wizlab = require("constants.wizlab")
local trog_roster = require("policy.religion.trog.brothers_roster")
local makhleb_roster = require("policy.religion.makhleb.roster")
local spiders = require("policy.combat.monster_summons.spiders")
local attack_flavours = require("constants.attack_flavours")

local constructs = require("constants.monster_construct_components")
local monster_profile = require("policy.combat.monster_profile")
local roster = require("policy.population.roster")
local slime_lifecycle = require("policy.monsters.slime_lifecycle")

local summons = {}

local valid_attitudes = {
    [attitudes.HOSTILE] = true,
    [attitudes.FRIENDLY] = true,
    [attitudes.NEUTRAL] = true,
    [attitudes.GOOD_NEUTRAL] = true,
    [attitudes.FELLOW_SLIME] = true,
}

-- Native wound summons name the monster that made the bite. Bind that
-- profile to the saved owner, including its retained original class after
-- polymorph, so a player or unrelated monster cannot claim the child.
local function valid_spider_origin(ctx, state, kind_id)
    if state.source_category ~= categories.MONSTERS or
        not spiders.contains(kind_id) then
        return false
    end

    local owner = ctx:get(state.owner, component.ACTOR)
    local polymorph = ctx:get(state.owner, component.MONSTER_POLYMORPH)

    if not owner or ctx:has(state.owner, component.PLAYER) or
        (owner.kind_id ~= state.source_id and
            (not polymorph or
                polymorph.original_kind_id ~= state.source_id)) then
        return false
    end

    local source = catalog.get(categories.MONSTERS, state.source_id)

    for _, attack in ipairs(source.attacks or {}) do
        if attack.flavour_id == attack_flavours.SPIDER then
            return true
        end
    end

    return false
end

-- Validate the complete saved ghost snapshot before AI or combat reads it.
-- The source player can move or change gear after creation, so no field is
-- reconstructed from that player's present state during restore.
local function validate_player_illusion(ctx, entity, actor, state, stats)
    local profile = ctx:get(entity, component.PLAYER_ILLUSION)
    local illusion_source = state.source_id ==
        spells.SPELL_SUMMON_ILLUSION

    local ghost_actor = actor.kind_id == monsters.MONS_PLAYER_ILLUSION

    if not profile and not ghost_actor then
        return
    end

    local health = ctx:get(entity, component.HEALTH)

    if not profile or not illusion_source or
        state.source_category ~= categories.SPELLS or
        not ghost_actor or
        not stats or stats.hd < 1 or stats.hd > 27 or
        not health or health.max < 1 or health.max > 400 or
        profile.species_id == "" or
        profile.job_id == "" or profile.ac < 0 or
        profile.ev < 0 or profile.ev > 60 or
        profile.damage < 0 or profile.damage > 50 then
        error("summon " .. ctx:id(entity) ..
            " has invalid player illusion profile")
    end

    if profile.necromancy_skill < 0 or
        profile.necromancy_skill > 27 then
        error("summon " .. ctx:id(entity) ..
            " has invalid player illusion profile")
    end

    catalog.get("species", profile.species_id)
    catalog.get("jobs", profile.job_id)

    local valid_brand = false

    for _, id in pairs(brands) do
        valid_brand = valid_brand or id == profile.brand_id
    end

    if not valid_brand then
        error("player illusion has invalid ghost weapon brand")
    end

    if profile.holiness_id ~= holiness.NATURAL and
        profile.holiness_id ~= holiness.UNDEAD and
        profile.holiness_id ~= holiness.NONLIVING and
        profile.holiness_id ~= holiness.DEMONIC then
        error("player illusion has invalid holiness")
    end

    local allowed_resistances = {}

    for _, id in pairs(resistance_ids) do
        allowed_resistances[id] = true
    end

    for id, level in pairs(profile.resistances) do
        if not allowed_resistances[id] or level < -3 or level > 3 then
            error("player illusion has invalid resistance")
        end
    end

    if #profile.spell_ids ~= #profile.frequencies then
        error("player illusion has mismatched spell slots")
    end

    local frequency = #profile.spell_ids > 0 and
        math.floor((stats.hd + 50) / #profile.spell_ids) or 0
    local seen = {}

    for index, id in ipairs(profile.spell_ids) do
        if seen[id] or profile.frequencies[index] ~= frequency then
            error("player illusion has invalid ghost spell weights")
        end

        seen[id] = true
        catalog.get("spells", id)
    end

    local copies = 0

    for _, other in ipairs(ctx:query({ component.PLAYER_ILLUSION })) do
        local candidate = ctx:get(other, component.PLAYER_ILLUSION)

        if candidate.name == profile.name then
            copies = copies + 1
        end
    end

    if copies > 1 then
        error("duplicate player illusion of " .. profile.name)
    end
end

-- Summoned creatures belong to their caster, not the scenario's starting
-- population. Their ownership and expiry survive a save and restore.
-- Example: summons.validate(ctx, entity, actor, position, ai, state, now) checks summoning expiry.
function summons.validate(ctx, entity, actor, position, ai, state, current_aut)
    -- Divine punishment creatures are hostile, player-anchored god gifts.
    -- Most are permanent; their origin is still a registered god rather
    -- than a fabricated spell or a member of the starting population.
    local owner_player = state.owner == ctx:player() and
        ctx:has(state.owner, component.PLAYER)
    local wrath_god_source = state.source_category == categories.GODS and
        owner_player and state.attitude == attitudes.HOSTILE
    local yred_gift_source = state.source_category == categories.GODS and
        state.source_id == gods.YREDELEMNUL and owner_player and
        state.attitude == attitudes.FRIENDLY and
        state.expires_aut == 0
    local trog_gift_source = state.source_category == categories.GODS and
        state.source_id == gods.TROG and owner_player and
        state.attitude == attitudes.FRIENDLY and
        state.expires_aut == 0
    local makhleb_servant_source =
        state.source_category == categories.GODS and
        state.source_id == gods.MAKHLEB and owner_player and
        (state.attitude == attitudes.FRIENDLY or
            state.attitude == attitudes.HOSTILE) and
        state.expires_aut > current_aut
    local permanent_spell = state.source_category == categories.SPELLS and
        (state.source_id == spells.SPELL_SIMULACRUM or
            state.source_id == spells.SPELL_DEATH_CHANNEL or
            state.source_id == spells.SPELL_ANIMATE_DEAD or
            state.source_id == spells.SPELL_BIND_SOULS or
            state.source_id == spells.SPELL_NECROTISE or
            state.source_id == spells.SPELL_CREATE_TENTACLES or
            state.source_id == spells.SPELL_MALIGN_GATEWAY and
                (ctx:has(entity, constructs.PORTAL) or
                    ctx:has(entity, component.SUMMON_SEGMENT)))
    local trap_source = state.source_category == categories.TRAPS and
        state.source_id == traps.TRAP_ZOT
    local permanent = (permanent_spell or trap_source or
        wrath_god_source or yred_gift_source or trog_gift_source) and
        state.expires_aut == 0

    local owner_actor = ctx:get(state.owner, component.ACTOR)
    local owner_avatar = ctx:has(state.owner,
        component.RELIGION_AVATAR_SOURCE) and
        state.source_category == categories.SPELLS and
        state.attitude == attitudes.HOSTILE

    if (not owner_actor and not owner_player and
        not owner_avatar) or
        not valid_attitudes[state.attitude] or
        state.source_id == "" or
        (not permanent and state.expires_aut <= current_aut) or
        state.heads < 0 then
        error("summon " .. ctx:id(entity) .. " has invalid ownership or expiry")
    end

    local spectral = ctx:get(entity, component.SPECTRAL_WEAPON)
    local item_source = state.source_category == categories.ITEMS and
        actor.kind_id == monsters.MONS_SPECTRAL_WEAPON and spectral
    local scroll_source = state.source_category == categories.ITEMS and
        (state.source_id == items.SCR_SUMMONING or
            state.source_id == items.SCR_BUTTERFLIES)
    local jiyva_source = state.source_category == categories.GODS and
        state.source_id == gods.JIYVA
    local xom_source = state.source_category == categories.GODS and
        state.source_id == gods.XOM
    local lugonu_source = state.source_category == categories.GODS and
        state.source_id == gods.LUGONU
    local wizlab_source = state.source_category == categories.VAULTS and
        (state.source_id == wizlab.WUCAD_MAP_ID or
            state.source_id == wizlab.BORGNJOR_MAP_ID)
    local native_spider_source = valid_spider_origin(ctx, state,
        actor.kind_id)

    if state.source_category ~= categories.SPELLS and
        state.source_category ~= categories.MUTATIONS and
        not trap_source and
        not item_source and not scroll_source and
        not jiyva_source and not xom_source and
        not lugonu_source and
        not wrath_god_source and
        not yred_gift_source and
        not trog_gift_source and
        not makhleb_servant_source and
        not wizlab_source and
        not native_spider_source then
        error("summon " .. ctx:id(entity) .. " has invalid origin category")
    end

    if wizlab_source then
        local event = ctx:get(entity,
            component.WORLD_WIZLAB_EVENT_ACTOR)
        local expected_kind = state.source_id ==
            wizlab.WUCAD_MAP_ID and
            wizlab.EVENT_ACTOR_WUCAD or
            wizlab.EVENT_ACTOR_BORGNJOR

        if not event or event.kind ~= expected_kind or
            event.vault_id ~= state.source_id or
            event.level_id ~= position.level_id or
            state.owner ~= ctx:player() or
            state.attitude ~= attitudes.HOSTILE then
            error("summon " .. ctx:id(entity) ..
                " has invalid Wizard Lab origin")
        end
    end

    if jiyva_source and
        (not jiyva_slimes.allowed[actor.kind_id] or
            state.attitude ~= attitudes.FRIENDLY or
            state.owner ~= ctx:player()) then
        error("summon " .. ctx:id(entity) .. " has invalid Jiyva origin")
    end

    if xom_source and
        (actor.kind_id ~= monsters.MONS_BUTTERFLY or
            state.attitude ~= attitudes.FRIENDLY or
            state.owner ~= ctx:player()) then
        error("summon " .. ctx:id(entity) .. " has invalid Xom origin")
    end

    -- Brothers in Arms uses the monster's Berserk action clock as its
    -- abjuration clock. No independent world-time deadline can drift.
    if trog_gift_source then
        local allegiance = ctx:get(entity, component.MONSTER_ALLEGIANCE)

        if not trog_roster.allowed[actor.kind_id] or
            not allegiance or allegiance.frenzy_aut <= 0 then
            error("summon " .. ctx:id(entity) ..
                " has invalid Trog gift")
        end
    end

    -- Finite player-invoked servants may be friendly or a paid hostile
    -- failure. Permanent hostile wrath uses its existing zero clock.
    if makhleb_servant_source and
        not makhleb_roster.contains(actor.kind_id, "lesser") and
        not makhleb_roster.contains(actor.kind_id, "greater") then
        error("summon " .. ctx:id(entity) ..
            " has invalid Makhleb servant")
    end

    catalog.get(state.source_category, state.source_id)

    local blob = ctx:get(entity, component.SLIME_BLOB)

    local split_slime = ctx:has(entity, component.SLIME_BIRTH) or
        blob and blob.reshaped_max > 0

    if blob and (state.source_id ~= spells.SPELL_PLANEREND or
        actor.kind_id ~= monsters.MONS_SLIME_CREATURE or
        blob.size ~= 5 and not split_slime) then
        error("summon " .. ctx:id(entity) ..
            " has invalid Planerend slime size")
    end

    if actor.kind_id == monsters.MONS_SLIME_CREATURE then
        slime_lifecycle.validate(ctx, entity,
            ctx:get(entity, component.HEALTH),
            roster.profile(actor.kind_id), current_aut)
    end

    local haunting = ctx:get(entity, component.SUMMON_HAUNTING)

    if haunting and
        (not (state.source_id == spells.SPELL_HAUNT or
            jiyva_source or xom_source) or
        not ctx:has(haunting.target, component.ACTOR)) then
        error("summon " .. ctx:id(entity) ..
            " has invalid Haunt target or origin")
    end

    -- A living spell must keep both its source identity and the custom
    -- one-shot slot. The tome may die or change before this save is loaded.
    local living = ctx:get(entity, component.SUMMON_LIVING_SPELL)
    local living_source = state.source_id ==
        spells.SPELL_CONJURE_LIVING_SPELLS
    local living_actor = actor.kind_id == monsters.MONS_LIVING_SPELL
    local stats = ctx:get(entity, component.SUMMON_STATS)
    validate_player_illusion(ctx, entity, actor, state, stats)

    if living_source or living_actor or living then
        if not living_source or not living_actor or not living or
            not living_spells.valid_spell(living.spell_id) or
            not stats or stats.hd < 1 then
            error("summon " .. ctx:id(entity) ..
                " has invalid living spell state")
        end
    end

    -- Mirror copies keep the source monster's body but have their own
    -- summon owner and finite lifetime. The original need not remain alive.
    local mirror = ctx:get(entity, component.SUMMON_MIRROR)
    local polymorph = ctx:get(entity, component.MONSTER_POLYMORPH)
    local original_kind = polymorph and polymorph.original_kind_id or
        actor.kind_id
    local phantom = state.source_id == spells.SPELL_PHANTOM_MIRROR
    local fake_mara = state.source_id == spells.SPELL_FAKE_MARA_SUMMON
    local monster_illusion = state.source_id ==
        spells.SPELL_SUMMON_ILLUSION and
        actor.kind_id ~= monsters.MONS_PLAYER_ILLUSION

    if mirror or phantom or fake_mara or monster_illusion then
        local expected_percent = fake_mara and 50 or 100

        if not mirror or
            not (phantom or fake_mara or monster_illusion) or
            state.source_category ~= categories.SPELLS or
            mirror.origin_kind_id ~= original_kind or
            mirror.origin_entity_id == "" or
            mirror.hp_percent ~= expected_percent or
            not stats or stats.hd < 1 then
            error("summon " .. ctx:id(entity) ..
                " has invalid mirror state")
        end
    end

    -- A spectral weapon remains bonded to an equipped item carried by its owner; stray copies fail restore.
    if spectral then
        local source = ctx:get(spectral.source_weapon, component.ITEM)
        local carrier = ctx:get(spectral.source_weapon,
            component.CARRIED_BY)
        local equipped = ctx:get(spectral.source_weapon,
            component.EQUIPPED)
        local energy = ctx:get(entity, component.MONSTER_ENERGY)

        if not item_source or not source or not carrier or not equipped or
            source.kind_id ~= state.source_id or
            source.ego ~= brands.SPECTRAL or
            carrier.holder ~= state.owner or
            equipped.slot ~= "weapon" or
            not energy or energy.points ~= 0 or
            spectral.triggered_aut > current_aut then
            error("summon " .. ctx:id(entity) .. " has invalid spectral bond")
        end
    end

    local wander = ai.behavior == "wander" and
        ai.memory_until_aut == 0 and
        ((ai.target_x == 0 and ai.target_y == 0) or
            ctx:walkable(position.level_id, ai.target_x, ai.target_y))
    local seek = ai.behavior == "seek" and
        ctx:walkable(position.level_id, ai.target_x, ai.target_y) and
        ai.memory_until_aut >= 0 and
        ai.memory_until_aut <= current_aut + 550

    if not wander and not seek then
        error("summon " .. ctx:id(entity) .. " has invalid saved AI role")
    end

    local segment = ctx:get(entity, component.SUMMON_SEGMENT)

    if segment and state.source_id == spells.SPELL_CREATE_TENTACLES then
        local link = ctx:get(segment.head, constructs.TENTACLE)
        local head = ctx:get(segment.head, component.SUMMON)
        local head_actor = ctx:get(segment.head, component.ACTOR)
        local expected = head_actor and
            head_actor.kind_id == monsters.MONS_KRAKEN_TENTACLE and
            monsters.MONS_KRAKEN_TENTACLE_SEGMENT or
            monsters.MONS_STARSPAWN_TENTACLE_SEGMENT

        if not link or link.parent ~= segment.gateway or
            not head or head.owner ~= state.owner or
            actor.kind_id ~= expected or segment.index < 1 or
            segment.index > 11 or state.expires_aut ~= 0 then
            error("summon has an invalid attached tentacle link")
        end
    elseif segment then
        local head = ctx:get(segment.head, component.SUMMON)
        local marker = ctx:get(segment.gateway, component.SUMMON_GATEWAY)
        local portal = ctx:get(segment.gateway, constructs.PORTAL)
        local head_actor = ctx:get(segment.head, component.ACTOR)
        local attached_portal = portal and segment.gateway == segment.head
        local matching_marker = marker and
            marker.tentacle_id == ctx:id(segment.head) and
            marker.source_id == state.source_id and
            marker.source_category == state.source_category

        if (state.source_id ~= spells.SPELL_MALIGN_GATEWAY and
            not trap_source) or
            actor.kind_id ~= monsters.MONS_ELDRITCH_TENTACLE_SEGMENT or
            not head or head.source_id ~= state.source_id or
            head.source_category ~= state.source_category or
            head.owner ~= state.owner or
            not attached_portal and not matching_marker or
            not head_actor or head_actor.kind_id ~= monsters.MONS_ELDRITCH_TENTACLE or
            state.expires_aut ~= head.expires_aut or
            segment.index < 1 or segment.index > 4 then
            error("summon " .. ctx:id(entity) .. " has an invalid tentacle link")
        end
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if yred_gift_source then
        local undead = false

        for _, kind in ipairs(definition.holiness or {}) do
            undead = undead or kind == holiness.UNDEAD
        end

        if not undead or ctx:has(entity,
            component.MONSTER_BOUND_SOUL) or
            ctx:has(entity, component.SUMMON_SEGMENT) then
            error("summon " .. ctx:id(entity) ..
                " has invalid Yredelemnul gift")
        end
    end

    definition = monster_profile.definition(ctx, entity, definition)

    if not slow.validate(ctx, entity, definition, actor) then
        error("summon " .. ctx:id(entity) .. " has invalid speed")
    end

    plants.validate(ctx, entity, actor, state, position)

    net.validate(ctx, entity, position)
    poison.validate(ctx, entity)
    sticky_flame.validate(ctx, entity)
end

return summons
