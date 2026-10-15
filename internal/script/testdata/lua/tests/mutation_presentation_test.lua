local mutations = require("ids.mutations")
local records = require("policy.mutations.records")
local screen = require("policy.presentation.mutations")
local input = require("policy.input.mutations")
local harness = require("tests.harness")

local test = {}

local function row_text(result)
    local lines = {}

    for _, write in ipairs(result.writes) do
        lines[#lines + 1] = write.text
    end

    return table.concat(lines, "\n")
end

function test.run(ctx)
    local player = ctx:create()

    local empty = screen.rows(ctx, {
        owner = player,
        height = 24,
    })

    harness.truthy(row_text(empty):find("You are rather mundane.", 1, true),
        "empty mutation screen follows DCSS")

    records.grant_acquired(ctx, player, mutations.MUT_ROBUST, 1)
    records.grant_temporary(ctx, player, mutations.MUT_AGILE, 1, 50)
    records.grant_innate(ctx, player, mutations.MUT_HORNS, 2)

    local result = screen.rows(ctx, {
        owner = player,
        height = 24,
    })
    local text = row_text(result)
    local horns = text:find("You have a pair of horns on your head.", 1, true)
    local robust = text:find("You are robust. (+10% HP)", 1, true)
    local agile = text:find("[You are agile.", 1, true)

    harness.truthy(horns, "innate source description")
    harness.truthy(robust, "acquired source description")
    harness.truthy(agile, "temporary source description is bracketed")
    harness.truthy(horns < robust and robust < agile,
        "innate, acquired, temporary ordering")
    harness.equal(result.options[1].key, "a", "source mutation hotkey")
    harness.equal(result.options[1].id, mutations.MUT_HORNS,
        "first hotkey examines first innate mutation")

    local detail = screen.rows(ctx, {
        owner = player,
        height = 24,
        width = 79,
        selected = mutations.MUT_HORNS,
    })

    harness.truthy(row_text(detail):find("You have horns on your head", 1, true),
        "mutation examine uses the source long description")

    local first_page = screen.rows(ctx, {
        owner = player,
        height = 6,
        page = 0,
    })
    local second_page = screen.rows(ctx, {
        owner = player,
        height = 6,
        page = 1,
    })

    harness.equal(first_page.pages, 2, "mutation menu page count")
    harness.truthy(row_text(first_page):find("You are robust.", 1, true),
        "first page shows acquired mutation")
    harness.falsy(row_text(first_page):find("You are agile.", 1, true),
        "first page leaves room for the transient legend")
    harness.truthy(row_text(second_page):find("[You are agile.", 1, true),
        "second page shows transient mutation")

    local next_page = input.route({
        key = "pgdown",
        page = 0,
        pages = 2,
    })
    local last_page = input.route({
        key = "pgdown",
        page = 1,
        pages = 2,
    })
    local previous_page = input.route({
        key = "pgup",
        page = 1,
        pages = 2,
    })

    harness.equal(next_page.page, 1, "page down advances")
    harness.equal(last_page.page, 1, "page down clamps at the end")
    harness.equal(previous_page.page, 0, "page up returns")

    local examine = input.route({
        key = "a",
        page = 0,
        pages = 2,
        options = first_page.options,
    })
    local close_detail = input.route({
        key = "esc",
        page = 0,
        pages = 2,
        selected = mutations.MUT_HORNS,
    })

    harness.equal(examine.action, "mutation_detail",
        "mutation letter opens examine view")
    harness.equal(examine.id, mutations.MUT_HORNS,
        "examine action identifies the selected mutation")
    harness.equal(close_detail.action, "mutation_close_detail",
        "escape returns from detail to the list")
end

return test
