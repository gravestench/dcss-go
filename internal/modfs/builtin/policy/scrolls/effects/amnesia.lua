-- Source: item-use.cc:SCR_AMNESIA and spl-util.cc:del_spell_from_memory.
local catalog = require("policy.catalog")
local item_ids = require("ids.items")
local learning = require("policy.character.spell_learning")
local records = require("policy.character.spell_records")
local scrolls = require("policy.scrolls")
local selection = require("policy.scrolls.selection")

local effect = {}

local function options(ctx, player)
    local found = {}

    for _, entry in ipairs(records.list(ctx, player)) do
        if entry.state.known_slot > 0 then
            local spell = catalog.get("spells", entry.state.spell_id)

            found[#found + 1] = {
                id = spell.id,
                label = spell.name,
            }
        end
    end

    return found
end

function effect.prepare(ctx, player, request)
    return selection.prepare(request, "spell", "Forget which spell?",
        "You have no spells to forget!", options(ctx, player))
end

function effect.apply(ctx, player, request)
    if request.target_id == "" then
        ctx:emit("read", "You feel forgetful for a moment.")

        return
    end

    learning.forget(ctx, player, request.target_id)
end

scrolls.register(item_ids.SCR_AMNESIA, effect)

return effect
