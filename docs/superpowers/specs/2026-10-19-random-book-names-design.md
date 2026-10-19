# Source random-book title design

## Goal

Generated themed and single-level spellbooks already carry their source
spell lists, but both currently receive a generic syllable title and a
generic hidden appearance. The committed `randbook.txt` phrase groups should
name them according to the selected schools or level. The title and hidden
appearance remain saved on the physical item so a later mod change cannot
rename an existing book.

## Ownership and flow

`random_books.lua` selects spells and records the schools and level it used.
It passes those facts to the existing artefact naming entrypoint, which owns
the one cosmetic seed. A focused `random_book_names.lua` policy consumes its
private seeded draw function to choose an author, subject, and title from the effective
Lua name catalog. The same seed draws the `book appearance` group. School
display names and title-group IDs live in named constants imported by policy.

Themed books use the source's owner selection and either a rare independent
subject or a title built from one or two discipline names. Single-level
books use the source difficulty bands, optional author, owner-specific title
group, and `@level@` substitution. Source `__NONE` owner entries mean no
author. Xom-gifted level books have a separate coinflip for an absurd title.
Authored subjects can contain source placeholders and resolve with the same
catalog rules. The old C++ single-school owner lookup omits a space before
`owner`; the port uses the intended group that exists in the source database.

The generation request can carry a `god_id`, `owner`, or `subject` for later
divine-gift and authored-vault flows. Empty owner and subject values mean
the ordinary random choice. Ordinary generated books need none of them.
Unknown source book groups are optional where C++
falls back, while bad references inside a registered group still fail at boot.

## Verification

Lua tests cover the four level bands, thematic school phrasing, owner and
subject paths, absence of unresolved tokens, book appearances, and saved
seed behavior. A Go vault-generation test confirms the actual chosen title
and appearance survive restore. Run the Lua rules suite and related Go tests
after the category is implemented, then commit, fast-forward `main`, and push.
