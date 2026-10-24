local catalog = require("policy.catalog")
local monster_flags = require("constants.monster_flags")
local item_use = require("constants.monster_item_use")
local books = require("ids.monster_spellbooks")
local spell_weights = require("data.monster_spell_xp")
local component = require("constants.component")
local constructs = require("constants.monster_construct_components")
local origin_policy = require("policy.population.origin")
local item_ids = require("ids.items")
local streams = require("constants.rng_streams")
local draconian_base = require("policy.monsters.draconian_base")

local death = {}

-- Source monster flags gate XP and corpse handling without assuming every definition has flags.
local function has_flag(definition, wanted)
    for _, flag in ipairs(definition.flags or {}) do
        if flag == wanted then
            return true
        end
    end

    return false
end

-- Monster XP combines health and HD with spell, speed, attack, and equipment difficulty.
-- Example: death.experience(no_xp_monster, max_hp, legacy) returns 0 for NO_EXP_GAIN.
function death.experience(definition, max_hp, legacy)
    if has_flag(definition, monster_flags.NO_EXP_GAIN) then
        return 0
    end

    local max_melee = 0

    for _, attack in ipairs(definition.attacks or {}) do
        max_melee = max_melee + attack.damage
    end

    local xp = math.floor((16 + max_hp) * definition.hd * definition.hd / 10)
    local difficulty = 0

    local spellcaster = definition.spellbook_id ~= books.MST_NO_SPELLS

    if spellcaster and definition.spellbook_id ~= books.MST_GHOST then
        local book = catalog.get("monster_spellbooks",
            definition.spellbook_id)

        for _, slot in ipairs(book.slots) do
            difficulty = difficulty + (spell_weights[slot.spell_id] or 0)
        end
    end

    if has_flag(definition, monster_flags.FAST_REGEN) then
        difficulty = difficulty + 15
    end

    if definition.speed >= 10 and max_melee > 30 then
        difficulty = difficulty + (definition.speed == 10 and
            math.floor(max_melee / 2) or max_melee)
    end

    local equipment_user = definition.item_use_id ~= item_use.NOTHING and
        definition.item_use_id ~= item_use.OPEN_DOORS

    if equipment_user then
        difficulty = difficulty + 30
    end

    xp = math.floor(xp * (100 + math.min(100, difficulty)) / 100)

    if definition.speed > 0 then
        xp = math.floor(xp * definition.speed / 10)
    end

    if definition.speed < 10 and not spellcaster and not equipment_user then
        xp = math.floor(xp / 2)
    end

    if definition.xp_modifier > 0 then
        xp = math.floor(xp * definition.xp_modifier / 10)
    end

    if xp > 100 then
        xp = 100 + math.floor((xp - 100) * 3 / 4)
    end

    if xp > 750 then
        xp = 750 + math.floor((xp - 750) / (legacy and 3 or 6))
    end

    return math.max(1, xp)
end

-- Death releases carried entities at the monster's last position before a corpse may occupy that tile.
function death.drop_inventory(ctx, monster, position)
    local dropped = {}
    local dissolving_weapon = ctx:has(monster,
        constructs.DANCING_WEAPON)

    for _, item in ipairs(ctx:query({ "core.carried_by" })) do
        local carrier = ctx:get(item, "core.carried_by")

        if carrier.holder == monster then
            if not ctx:has(item, "core.item") or ctx:has(item, "core.position") then
                error("monster " .. ctx:id(monster) .. " has invalid carried item " .. ctx:id(item))
            end

            -- Source MF_HARD_RESET destroys a dancing weapon and its
            -- temporary item together. In particular, a card randart
            -- must never become permanent loot when its dancer dies.
            if dissolving_weapon then
                ctx:destroy(item)
            else
                local equipped = ctx:get(item, component.EQUIPPED)

                dropped[#dropped + 1] = {
                    entity = item,
                    slot = equipped and equipped.slot or nil,
                }

                ctx:remove(item, "core.equipped")
                ctx:remove(item, "core.carried_by")
                ctx:add(item, "core.position", position)
            end
        end
    end

    return dropped
end

-- A changed body leaves its first recorded species' corpse. Polymorph and
-- shapeshifter status both write ORIGINAL_TYPE_KEY only when it is absent,
-- so the first transformation wins. Callers without an actor use definition.
local function corpse_class(ctx, monster, definition)
    local original_id = definition.id
    local species_id

    if monster then
        local shape = ctx:get(monster, component.MONSTER_SHAPESHIFTER)
        local form = ctx:get(monster, component.MONSTER_POLYMORPH)
        local base = ctx:get(monster, component.MONSTER_DRACONIAN_BASE)

        if shape then
            original_id = shape.corpse_kind_id ~= "" and
                shape.corpse_kind_id or shape.variant_id
        elseif form then
            original_id = form.corpse_kind_id ~= "" and
                form.corpse_kind_id or form.original_kind_id
        elseif base and draconian_base.is_job(definition.id) then
            species_id = base.base_id
        end
    end

    local original = catalog.get("monsters", original_id)
    local species = catalog.get("monsters",
        species_id or original.species_id or original_id)

    return original, species
end

-- The species gates corpse existence; original class stays available to
-- later resurrection and presentation rules through the typed host store.
function death.corpse(ctx, definition, position, source_origin, monster)
    local original, species = corpse_class(ctx, monster, definition)
    local shape = monster and ctx:get(monster,
        component.MONSTER_SHAPESHIFTER)
    local form = monster and ctx:get(monster, component.MONSTER_POLYMORPH)
    local source_id = shape and shape.original_kind_id or
        form and form.original_kind_id or definition.id

    -- Kiku's wretches always leave the real corpse that their invocation
    -- raised them to provide. Ordinary monsters still use the source coin flip.
    local wretch = monster and
        ctx:has(monster, component.RELIGION_KIKU_WRETCH)

    if not species.leaves_corpse or
        (not wretch and ctx:random(streams.CORPSE, 2) == 1) then
        return
    end

    catalog.get("items", item_ids.CORPSE_BODY)
    local corpse = ctx:create()
    ctx:add(corpse, "core.item", {
        kind_id = item_ids.CORPSE_BODY,
        quantity = 1,
    })
    ctx:add(corpse, "core.corpse", {
        monster_id = species.id,
        original_monster_id = original.id,
        death_kind_id = definition.id,
        source_monster_id = source_id,
        freshness = 110,
        appearance = ctx:random(streams.CORPSE, 255) + 1,
    })
    ctx:add(corpse, "core.position", position)

    if source_origin then
        ctx:add(corpse, component.VAULT_ORIGIN,
            origin_policy.for_entity(source_origin, item_ids.CORPSE_BODY,
                origin_policy.CORPSE_OCCURRENCE))
    end

    return corpse
end

return death
