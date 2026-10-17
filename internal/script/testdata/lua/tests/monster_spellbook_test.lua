local book_policy = require("policy.combat.monster_spellbook")
local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local vault_spells = require("constants.vault_spell_override")

local test = {}

local function source_book(ctx)
    local monster = harness.actor_with(ctx, component.ACTOR, {
        kind_id = monsters.MONS_ENDOPLASM,
        speed = 10,
    })
    local book = book_policy.for_actor(ctx, monster)
    local definition = catalog.get("monsters", monsters.MONS_ENDOPLASM)

    harness.equal(book.id, definition.spellbook_id,
        "actor uses its source book")
    harness.equal(book_policy.slot(book, 1, spells.SPELL_FREEZE).spell_id,
        spells.SPELL_FREEZE, "source slot validates")

    local rat = harness.actor_with(ctx, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })

    harness.falsy(book_policy.for_actor(ctx, rat),
        "no-spell sentinel has no registered book")

    return monster
end

local function duplicate_ids_have_distinct_slots()
    local book = {
        slots = {
            {
                spell_id = spells.SPELL_BLINK,
                frequency = 9,
                flags = { "MON_SPELL_WIZARD" },
            },

            {
                spell_id = spells.SPELL_BLINK,
                frequency = 18,
                flags = { "MON_SPELL_EMERGENCY" },
            },
        },
    }

    harness.equal(book_policy.slot(book, 1, spells.SPELL_BLINK).frequency,
        9, "first duplicate retains its flags")
    harness.equal(book_policy.slot(book, 2, spells.SPELL_BLINK).frequency,
        18, "second duplicate retains its flags")

    local okay = pcall(book_policy.slot, book, 2, spells.SPELL_FREEZE)

    harness.falsy(okay, "mismatched ID cannot be substituted")
end

function test.run(ctx)
    local monster = source_book(ctx)

    ctx:add(monster, component.VAULT_ACTOR_OVERRIDES, {
        base_id = "",
        variant = "",
        colour = "",
        attitude = "hostile",
        spells = { vault_spells.EMPTY_BOOK },
    })

    harness.falsy(book_policy.for_actor(ctx, monster),
        "vault empty-book override suppresses casting")

    duplicate_ids_have_distinct_slots()
end

return test
