local items = require("ids.items")
local catalog = require("policy.catalog")
local formulas = require("policy.character.formulas")
local experience_limit = require("policy.character.experience_limit")
local fighter = require("policy.combat.fighter")
local colors = require("policy.presentation.colors")
local clouds = require("policy.presentation.clouds")
local identification = require("policy.items.identification")
local evokers = require("policy.inventory.evokers")
local component = require("constants.component")
local god_names = require("policy.religion.names")
local monster_display = require("policy.combat.monster_support.display")
local targets = require("policy.ai.targets")

local view = {}

-- Resolve species/job names and XP progress from live character data so the
-- HUD cannot retain a stale label after a mod changes the catalogs.
-- Example: runtime.Policy("presentation.player", character_input).
function view.player(ctx, input)
    local name = input.name or ""
    local species = catalog.get("species", input.species_id)
    local job = catalog.get("jobs", input.job_id)
    local maximum = experience_limit.max_level(ctx, ctx:player())
    local percent = formulas.level_progress(input.total_xp, input.level,
        species.xp, maximum)

    if name == "" then
        name = "Adventurer"
    end

    return {
        player_name = name,
        species_name = species.name,
        character_name = species.name .. " " .. job.name,
        next_level_percent = percent,
    }
end

-- Vault colour overrides belong to the live monster entity; catalog glyph and name still come from its kind.
-- Example: runtime.Policy("presentation.entity", monster_input) uses the
-- monster catalog for identity and the entity component for its vault tint.
function view.entity(ctx, input)
    local role = input.role
    local kind_id = input.kind_id or ""
    local name = ""
    local glyph = string.byte("?")
    local color_id = ""
    local hostile = false

    if role == "player" then
        kind_id = "player"
        name = input.player_name or "Adventurer"
        glyph = string.byte("@")
    elseif role == "monster" then
        local monster = catalog.get("monsters", kind_id)
        name = monster.name
        glyph = monster.glyph
        color_id = monster.colour_id or ""

        if input.monster_entity_id then
            local actor = ctx:entity(input.monster_entity_id)
            local overrides = ctx:get(actor, component.VAULT_ACTOR_OVERRIDES)

            name = monster_display.name(ctx, actor)
            hostile = targets.enemy(ctx, actor, ctx:player())
            local generated = ctx:get(actor, component.PANDEMONIUM_LORD)
            local ugly = ctx:get(actor, component.UGLY_THING)

            if generated and generated.colour_id ~= "" then
                color_id = generated.colour_id
            end

            if ugly then
                color_id = ugly.colour_id
            end

            if overrides and overrides.colour ~= "" and not ugly then
                color_id = overrides.colour
            end
        end
    elseif role == "disturbance" then
        name = "disturbance in the air"
        glyph = string.byte("{")
    elseif role == "cloud" then
        local appearance = clouds.get(kind_id)

        name = appearance.name
        glyph = string.byte("#")
        color_id = appearance.color_id
    elseif role == "trap" then
        local trap = catalog.get("traps", kind_id)
        name = trap.name
        glyph = string.byte(trap.glyph)
        color_id = input.color_id or "LIGHTGREY"
    elseif role == "item" then
        local item = catalog.get("items", kind_id)
        local entity = ctx:entity(input.item_entity_id)
        name = identification.name(ctx, ctx:player(), entity)
        glyph = item.glyph

        if input.corpse_monster_id and input.corpse_monster_id ~= "" then
            local source = catalog.get("monsters", input.corpse_monster_id)
            name = source.name .. " " .. name
        end
    end

    return {
        kind_id = kind_id,
        role = role,
        name = name,
        glyph = glyph,
        color_id = color_id,
        animated_color = color_id == colors.random_effect_id,
        hostile = hostile,
    }
end

-- Inventory naming consults the player's identification state, so an unknown potion keeps its appearance label.
-- Example: view.inventory_item(ctx, item_input) returns the currently known
-- name and slot without revealing an unidentified item kind to the player.
function view.inventory_item(ctx, input)
    local item = catalog.get("items", input.kind_id)
    local entity = ctx:entity(input.item_entity_id)
    local name = identification.name(ctx, ctx:player(), entity)
    local rule = evokers.definition(input.kind_id)

    -- XP charge belongs to the player's subtype debt, not core.item.
    -- Derive the label each frame so a kill immediately updates every copy.
    if rule then
        name = string.format("%s (%d/%d)", name,
            evokers.charges(ctx, ctx:player(), input.kind_id),
            rule.max_charges)
    end

    return {
        kind_id = input.kind_id,
        name = name,
        class = item.class,
        quantity = input.quantity,
        slot = input.slot or "",
    }
end

-- Distinguish remembered terrain from currently seen terrain, and show
-- detected items in green even if their underlying cell is not visible.
function view.terrain_color(input)
    if input.detected_creature then
        return { fg = colors.light_red }
    end

    if input.detected_item then
        return { fg = colors.green }
    end

    if input.state ~= 2 then
        return { fg = colors.dark_grey }
    end

    -- A live vault callback can recolour a wall after triggering. Keep the
    -- source colour name on the level; this policy alone maps it to IRGB.
    local override = input.color_id and
        colors.source[input.color_id:upper()]

    if override then
        return { fg = override }
    end

    -- A blood mark is saved separately from the feature so divine effects
    -- can cleanse it without replacing terrain or a vault colour.
    if input.bloody then
        return { fg = colors.red }
    end

    if input.glyph == "<" or input.glyph == ">" then
        return { fg = colors.yellow }
    end

    return { fg = colors.light_grey }
end

-- Use DCSS's ASCII glyph for an item sensed but not directly seen; this
-- prevents the display from implying a known item identity.
function view.detected_item()
    -- Source: viewchar.cc, CSET_ASCII item_detected.
    return { glyph = string.byte("{") }
end

-- Source creature detection paints the monster base glyph in light red.
-- It is only a sensed genus: no exact actor identity or visibility leaks.
function view.detected_creature(_, input)
    local monster = catalog.get("monsters", input.kind_id)

    return { glyph = monster.glyph }
end

-- An altar's saved god ID supplies its identity; the source B glyph is
-- generic and cannot name a deity on its own. Worship is handled elsewhere.
function view.altar(_, input)
    local name = god_names[input.god_id]

    if not name then
        error("unknown altar god " .. tostring(input.god_id))
    end

    return {
        name = "an altar of " .. name,
        glyph = string.byte("_"),
    }
end

-- Give an explicit vault tint first priority, then fall back by role and
-- catalog type so unknown source colors never reach terminal ANSI output.
function view.entity_color(input)
    if input.color_id == colors.random_effect_id then
        local draw = input.ui_roll

        if type(draw) ~= "number" or draw % 1 ~= 0 or
            draw < 0 or draw >= #colors.nonblack_irgb then
            error("random element colour needs a bounded UI draw")
        end

        return { fg = colors.nonblack_irgb[draw + 1] }
    end

    local source = input.color_id and colors.source[input.color_id:upper()]

    if source then
        return { fg = source }
    end
    if input.role == "cloud" then
        return { fg = clouds.get(input.kind_id).color }
    end

    if input.role == "player" then
        return { fg = colors.white }
    end

    if input.role == "monster" then
        return { fg = colors.brown }
    end

    if input.role == "trap" then
        return { fg = input.color_id == "DARKGREY" and
            colors.dark_grey or colors.light_grey }
    end

    if input.role == "item" then
        if input.kind_id == items.CORPSE_BODY then
            return { fg = colors.brown }
        elseif input.kind_id == items.CORPSE_SKELETON then
            return { fg = colors.light_grey }
        end

        return { fg = colors.light_green }
    end

    return { fg = colors.light_grey }
end

-- Expose player projection through the uniform registered policy signature.
function view.run_player(ctx, input)
    return view.player(ctx, input)
end

-- Keep the registered route identical to direct entity projection.
function view.run_entity(ctx, input)
    return view.entity(ctx, input)
end

-- Reuse identification-aware naming for the terminal's inventory adapter.
function view.run_inventory_item(ctx, input)
    return view.inventory_item(ctx, input)
end

-- Terrain colors depend on view state alone, so the policy ignores context.
function view.run_terrain_color(_, input)
    return view.terrain_color(input)
end

-- Entity color projection is pure after the caller supplies catalog IDs.
function view.run_entity_color(_, input)
    return view.entity_color(input)
end

-- Convert combat defense to the half-scale shield value printed by the HUD;
-- sharing fighter.defense keeps display and hit resolution in agreement.
function view.run_defense(ctx)
    local defense = fighter.defense(ctx)

    return {
        ac = defense.ac,
        ev = defense.ev,
        sh = math.floor(defense.shield_class / 2),
    }
end

register.policy({
    id = "presentation.player",
    run = view.run_player,
})

register.policy({
    id = "presentation.entity",
    run = view.run_entity,
})

register.policy({
    id = "presentation.inventory_item",
    run = view.run_inventory_item,
})

register.policy({
    id = "presentation.terrain_color",
    run = view.run_terrain_color,
})

register.policy({
    id = "presentation.entity_color",
    run = view.run_entity_color,
})

register.policy({
    id = "presentation.detected_item",
    run = view.detected_item,
})

register.policy({
    id = "presentation.detected_creature",
    run = view.detected_creature,
})

register.policy({
    id = "presentation.altar",
    run = view.altar,
})

register.policy({
    id = "presentation.defense",
    run = view.run_defense,
})

return view
