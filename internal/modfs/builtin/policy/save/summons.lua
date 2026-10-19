local spells = require("ids.spells")
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

local summons = {}

local valid_attitudes = {
    [attitudes.HOSTILE] = true,
    [attitudes.FRIENDLY] = true,
    [attitudes.NEUTRAL] = true,
    [attitudes.GOOD_NEUTRAL] = true,
    [attitudes.FELLOW_SLIME] = true,
}

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
    local permanent_spell = state.source_category == categories.SPELLS and
        (state.source_id == spells.SPELL_SIMULACRUM or
            state.source_id == spells.SPELL_DEATH_CHANNEL or
            state.source_id == spells.SPELL_ANIMATE_DEAD or
            state.source_id == spells.SPELL_NECROTISE)
    local trap_source = state.source_category == categories.TRAPS and
        state.source_id == traps.TRAP_ZOT
    local permanent = (permanent_spell or trap_source) and
        state.expires_aut == 0

    local owner_actor = ctx:get(state.owner, component.ACTOR)

    if not owner_actor or not valid_attitudes[state.attitude] or
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

    if state.source_category ~= categories.SPELLS and
        state.source_category ~= categories.MUTATIONS and
        not trap_source and
        not item_source and not scroll_source then
        error("summon " .. ctx:id(entity) .. " has invalid origin category")
    end

    catalog.get(state.source_category, state.source_id)

    local blob = ctx:get(entity, component.SUMMON_BLOB)

    if blob and (state.source_id ~= spells.SPELL_PLANEREND or
        actor.kind_id ~= monsters.MONS_SLIME_CREATURE or
        blob.size ~= 5) then
        error("summon " .. ctx:id(entity) ..
            " has invalid Planerend slime size")
    end

    local haunting = ctx:get(entity, component.SUMMON_HAUNTING)

    if haunting and (state.source_id ~= spells.SPELL_HAUNT or
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

    if segment then
        local head = ctx:get(segment.head, component.SUMMON)
        local marker = ctx:get(segment.gateway, component.SUMMON_GATEWAY)
        local head_actor = ctx:get(segment.head, component.ACTOR)

        if (state.source_id ~= spells.SPELL_MALIGN_GATEWAY and
            not trap_source) or
            actor.kind_id ~= monsters.MONS_ELDRITCH_TENTACLE_SEGMENT or
            not head or head.source_id ~= state.source_id or
            head.source_category ~= state.source_category or
            head.owner ~= state.owner or
            not marker or marker.tentacle_id ~= ctx:id(segment.head) or
            marker.source_id ~= state.source_id or
            marker.source_category ~= state.source_category or
            not head_actor or head_actor.kind_id ~= monsters.MONS_ELDRITCH_TENTACLE or
            state.expires_aut ~= head.expires_aut or
            segment.index < 1 or segment.index > 4 then
            error("summon " .. ctx:id(entity) .. " has an invalid tentacle link")
        end
    end

    local definition = catalog.get("monsters", actor.kind_id)

    if not slow.validate(ctx, entity, definition, actor) then
        error("summon " .. ctx:id(entity) .. " has invalid speed")
    end

    plants.validate(ctx, entity, actor, state, position)

    net.validate(ctx, entity, position)
    poison.validate(ctx, entity)
    sticky_flame.validate(ctx, entity)
end

return summons
