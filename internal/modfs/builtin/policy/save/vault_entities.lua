local component = require("constants.component")
local effects = require("constants.vault_effects")
local origin_policy = require("policy.population.origin")
local item_ids = require("ids.items")
local monster_specs = require("policy.generation.vaults.specs.monster")
local slime_blob = require("policy.monsters.slime_blob")
local monsters = require("ids.monsters")
local vault_enchantments = require("policy.monsters.vault_enchantments")
local catalog = require("policy.catalog")

local vault_entities = {}

-- Index saved levels by ID before checking each vault entity's origin.
local function level_index(input)
    local levels = {}

    for _, level in ipairs(input.levels or {}) do
        levels[level.id] = level
    end

    return levels
end

-- A vault actor override must agree with the authored monster directive.
local function validate_actor_overrides(ctx, entity, record, arguments)
    local selected

    if arguments.selected_expression and arguments.selected_expression ~= "" then
        selected = monster_specs.parse(arguments.selected_expression, {
            path = arguments.path,
            vault_id = record.source_id,
            line = record.line,
            directive = record.directive,
            glyph = record.source,
        })[1][1]
    end

    local spells = (arguments.spells or "") ~= "" and
        { arguments.spells } or {}

    if selected and selected.spells then
        local allowed = false

        for _, book in ipairs(selected.spells) do
            allowed = allowed or book == arguments.spells
        end

        if not allowed then
            error("entity " .. ctx:id(entity) ..
                " has a spellbook absent from its source vault slot")
        end
    end

    -- A status can be dispelled after spawn, but restoration cannot invent
    -- one that the selected DES monster expression never granted.
    local permanent = ctx:get(entity,
        component.VAULT_PERMANENT_ENCHANTMENTS)

    if permanent then
        local allowed = {}

        for _, name in ipairs(selected and
            selected.permanent_enchantments or {}) do
            allowed[name] = true
        end

        for name, active in pairs(permanent.active) do
            if active and not allowed[name] then
                error("entity " .. ctx:id(entity) ..
                    " has forged permanent vault enchantment " .. name)
            end
        end
    end

    if selected then
        local source_names = selected.permanent_enchantments or {}

        vault_enchantments.validate(source_names)

        if (arguments.permanent_enchantments or "") ~=
            table.concat(source_names, "|") then
            error("entity " .. ctx:id(entity) ..
                " has forged permanent vault source tags")
        end
    end

    local expected = (arguments.base_id or "") ~= "" or
        (arguments.colour or "") ~= "" or
        (arguments.attitude or "") ~= "" or
        (arguments.god_id or "") ~= "" or #spells > 0
        or (arguments.hp or 0) > 0 or (arguments.hd or 0) > 0
        or (arguments.custom_name or "") ~= ""
        or (arguments.name_adjective or false)
        or (arguments.name_species or false)
        or (arguments.database_name or "") ~= ""
        or (arguments.tile or "") ~= ""
    local overrides = ctx:get(entity, component.VAULT_ACTOR_OVERRIDES)
    local expected_hd = arguments.hd or 0

    -- A generic skeleton or zombie has no catalog HD. Its source corpse
    -- base supplies the saved derived override used by live combat policy.
    if expected_hd == 0 and (arguments.base_id or "") ~= "" then
        local definition = catalog.get("monsters", arguments.kind_id)

        if not definition.hd then
            local base = catalog.get("monsters", arguments.base_id)

            expected_hd = base.hd or 0
        end
    end

    if not expected and not overrides then
        return
    end

    if not expected or not overrides or
        overrides.base_id ~= (arguments.base_id or "") or
        overrides.variant ~= (arguments.variant or "") or
        overrides.colour ~= (arguments.colour or "") or
        overrides.attitude ~= ((arguments.attitude or "") ~= "" and
            arguments.attitude or "hostile") or
        overrides.god_id ~= (arguments.god_id or "") or
        overrides.fixed_hp ~= (arguments.hp or 0) or
        overrides.hit_dice ~= expected_hd or
        overrides.custom_name ~= (arguments.custom_name or "") or
        overrides.name_adjective ~= (arguments.name_adjective or false) or
        overrides.name_species ~= (arguments.name_species or false) or
        overrides.database_name ~= (arguments.database_name or "") or
        overrides.tile ~= (arguments.tile or "") or
        #overrides.spells ~= #spells then
        error("entity " .. ctx:id(entity) .. " has forged vault actor overrides")
    end

    for index, spell in ipairs(spells) do
        if overrides.spells[index] ~= spell then
            error("entity " .. ctx:id(entity) .. " has forged vault spell override")
        end
    end
end

-- A corpse left by a vault actor may have aged without losing its authored origin.
local function decayed_authored_corpse(ctx, entity, record, arguments, item)
    if record.kind ~= effects.ITEM or
        arguments.kind_id ~= item_ids.CORPSE_BODY or
        item.kind_id ~= item_ids.CORPSE_SKELETON then
        return false
    end

    local corpse = ctx:get(entity, component.CORPSE)

    return corpse and corpse.monster_id == arguments.base_id
end

-- Authored entities retain the vault origin that produced them.
local function validate_origin(ctx, entity, origin, levels, seen)
    local level = levels[origin.level_id]
    local record = level and level.vault_records[origin.record_index]

    if not level or not record or origin.record_index < 1 or
        origin.occurrence < 1 or
        origin.vault_id ~= record.source_id or
        origin.spawn_x ~= record.x or origin.spawn_y ~= record.y then
        error("entity " .. ctx:id(entity) .. " has dangling vault origin")
    end

    local arguments = record.arguments or {}

    if record.pending or arguments.no_spawn or
        not arguments.kind_id or arguments.kind_id == "" then
        error("entity " .. ctx:id(entity) .. " has inactive vault origin")
    end

    local actor = ctx:get(entity, component.ACTOR)
    local item = ctx:get(entity, component.ITEM)
    local kind_id = actor and actor.kind_id or item and item.kind_id
    local form = actor and ctx:get(entity, component.MONSTER_POLYMORPH)
    local source_kind = form and form.original_kind_id or kind_id

    -- A vault shapeshifter adopts a borrowed body as soon as it spawns;
    -- later polymorph can do the same to any authored monster. The durable
    -- polymorph source, not the current body, must match the DES selection.
    if not kind_id or source_kind ~= origin.kind_id then
        error("entity " .. ctx:id(entity) .. " has forged vault kind ID " ..
            tostring(kind_id) .. " versus " .. tostring(origin.kind_id) ..
            " from " .. tostring(record.source_id) .. ":" ..
            tostring(origin.record_index))
    end

    -- Pickup trusts this marker to withhold a rune. Its presence must
    -- match the authored DES choice even for a moved or saved floor item.
    local mimic = ctx:get(entity, component.VAULT_ITEM_MIMIC)
    local expected_mimic = origin.occurrence == 1 and
        record.kind == effects.ITEM and arguments.mimic == true

    if expected_mimic ~= (mimic ~= nil) or
        (mimic and not mimic.active) then
        error("entity " .. ctx:id(entity) ..
            " has forged vault item mimic state")
    end

    -- One record can yield an actor, corpse, and gear, but their occurrence numbers must remain distinct.
    if origin.occurrence == 1 then
        if (source_kind ~= arguments.kind_id and not
            (item and decayed_authored_corpse(ctx, entity, record,
                arguments, item))) or
            (record.kind == effects.MONSTER and not actor) or
            (record.kind == effects.ITEM and not item) then
            error("entity " .. ctx:id(entity) .. " disagrees with vault selection")
        end

        if item and (item.kind_id == item_ids.CORPSE_BODY or
            item.kind_id == item_ids.CORPSE_SKELETON) then
            local corpse = ctx:get(entity, component.CORPSE)

            if not corpse or corpse.monster_id ~= arguments.base_id then
                error("entity " .. ctx:id(entity) .. " has forged vault corpse species")
            end
        end

        if actor then
            validate_actor_overrides(ctx, entity, record, arguments)

            -- The selected merged body count is part of the authored
            -- monster, so a restored actor must retain that ECS state.
            if actor.kind_id == monsters.MONS_SLIME_CREATURE and
                slime_blob.size(ctx, entity) ~=
                    (arguments.blob_size or 1) then
                error("entity " .. ctx:id(entity) ..
                    " has forged vault slime size")
            end
        end
    elseif origin.occurrence == origin_policy.CORPSE_OCCURRENCE then
        local corpse = ctx:get(entity, component.CORPSE)

        if record.kind ~= effects.MONSTER or not corpse or
            corpse.monster_id ~= arguments.kind_id or
            (item.kind_id ~= item_ids.CORPSE_BODY and
                item.kind_id ~= item_ids.CORPSE_SKELETON) then
            error("entity " .. ctx:id(entity) .. " has invalid vault corpse origin")
        end
    else
        local gear_key = "gear_" .. origin.occurrence .. "_kind_id"

        if record.kind ~= effects.MONSTER or not item or
            arguments[gear_key] ~= item.kind_id then
            error("entity " .. ctx:id(entity) .. " has invalid vault gear origin")
        end
    end

    local key = table.concat({
        origin.level_id,
        origin.vault_id,
        origin.record_index,
        origin.occurrence,
    }, ":")

    if seen[key] then
        error("duplicate live vault occurrence " .. key)
    end

    seen[key] = true

    if (record.kind == effects.MONSTER and actor and origin.occurrence == 1) or
        origin.occurrence == origin_policy.CORPSE_OCCURRENCE then
        local lifecycle_key = table.concat({
            origin.level_id,
            origin.vault_id,
            origin.record_index,
            "alive_or_corpse",
        }, ":")

        if seen[lifecycle_key] then
            error("vault monster and its corpse both remain live " .. lifecycle_key)
        end

        seen[lifecycle_key] = true
    end
end

-- Vault entity overrides retain their originating level and authored record.
-- Example: vault_entities.validate_vault_entities(ctx, input) checks a saved vault actor's origin.
function vault_entities.validate_vault_entities(ctx, input)
    local levels = level_index(input)
    local seen = {}

    for _, entity in ipairs(ctx:query({ component.VAULT_ORIGIN })) do
        local origin = ctx:get(entity, component.VAULT_ORIGIN)

        validate_origin(ctx, entity, origin, levels, seen)
    end

    -- A patrol may stop after charm, but an active patrol must still point
    -- to the cell and source flag that created this authored monster.
    for _, entity in ipairs(ctx:query({ component.MONSTER_PATROL })) do
        local anchor = ctx:get(entity, component.MONSTER_PATROL)
        local origin = ctx:get(entity, component.VAULT_ORIGIN)
        local position = ctx:get(entity, component.POSITION)
        local health = ctx:get(entity, component.HEALTH)
        local level = origin and levels[origin.level_id]
        local record = level and level.vault_records[origin.record_index]
        local arguments = record and record.arguments or {}

        if not ctx:has(entity, component.ACTOR) or
            not origin or origin.occurrence ~= 1 or
            not position or not health or health.current <= 0 or
            not record or not arguments.patrolling or
            anchor.level_id ~= origin.level_id or
            anchor.x ~= origin.spawn_x or
            anchor.y ~= origin.spawn_y or
            position.level_id ~= anchor.level_id then
            error("entity " .. ctx:id(entity) ..
                " has invalid authored patrol anchor")
        end
    end

    return {}
end

register.policy({
    id = "save.validate_vault_entities",
    run = vault_entities.validate_vault_entities,
})

return vault_entities
