
local book_policy = require("policy.combat.monster_spellbook")
local catalog = require("policy.catalog")
local component = require("constants.component")
local harness = require("tests.harness")
local monsters = require("ids.monsters")
local spells = require("ids.spells")
local vault_spells = require("constants.vault_spell_override")
local flags = require("constants.monster_spell_flags")
local source_spellbook = require("policy.monsters.source_spellbook")
local attitudes = require("constants.attitude")

local test = {}

-- A live actor resolves its monster book through catalog identity.
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

-- Repeated spell IDs may carry different flags in separate authored slots.
local function duplicate_ids_have_distinct_slots()
    local book = {
        slots = {
            {
                spell_id = spells.SPELL_BLINK,
                frequency = 9,
                flags = { flags.WIZARD },
            },

            {
                spell_id = spells.SPELL_BLINK,
                frequency = 18,
                flags = { flags.EMERGENCY },
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

-- Source DES spells: defines a full spellbook for one vault actor. It must
-- override a species with no native book and preserve each slot's frequency.
local function authored_spellbook(ctx)
    local actor = harness.actor_with(ctx, component.ACTOR, {
        kind_id = monsters.MONS_RAT,
        speed = 10,
    })

    ctx:add(actor, component.VAULT_ACTOR_OVERRIDES, {
        spells = {
            "throw_flame.53.magical;throw_frost.22.natural",
        },
    })

    local book = book_policy.for_actor(ctx, actor)

    harness.equal(#book.slots, 2, "authored spell count")
    harness.equal(book.slots[1].spell_id, spells.SPELL_THROW_FLAME,
        "first authored spell")
    harness.equal(book.slots[1].frequency, 53,
        "source spell frequency")
    harness.equal(book.slots[1].flags[1], flags.MAGICAL,
        "source magical flag")
    harness.equal(book.slots[2].spell_id, spells.SPELL_THROW_FROST,
        "second authored spell")
    harness.equal(book.slots[2].flags[1], flags.NATURAL,
        "source natural flag")
    harness.falsy(source_spellbook.parse(vault_spells.NONE),
        "source none has no spellbook")
    harness.falsy(source_spellbook.parse("no_spell"),
        "source no-spell alias has no spellbook")
end

-- Mismatched ID cannot be substituted.
function test.run(ctx)
    local monster = source_book(ctx)

    ctx:add(monster, component.VAULT_ACTOR_OVERRIDES, {
        base_id = "",
        variant = "",
        colour = "",
        attitude = attitudes.HOSTILE,
        spells = { vault_spells.EMPTY_BOOK },
    })

    harness.falsy(book_policy.for_actor(ctx, monster),
        "vault empty-book override suppresses casting")

    duplicate_ids_have_distinct_slots()
    authored_spellbook(ctx)
end

return test
