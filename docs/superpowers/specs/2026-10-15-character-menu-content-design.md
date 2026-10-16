# Character menu content owned by species and jobs

## Intent

A species or job file should own the text and ordering that appear on the
character menu. The current generated `data/presentation.lua` repeats 27
species IDs, 25 job IDs, and their descriptions after those same definitions
have been registered. A mod can add a definition without changing that file,
but a same-path override must consult two places to understand its menu.

Preserve the pinned menu exactly for bundled content. Keep startup modes and
skill columns as shared presentation policy because they are not properties
of a species or job. Retire the unused Lua `data/item_identities.lua` export:
all 368 concrete item identities already live in item files, while 40 more removed
identities and 10 aliases remain in the committed JSON import artifact for
upstream checks.

## Ownership and import

`content/species/<id>.lua` owns its description and its existing
`difficulty` and `difficulty_priority` fields. `content/jobs/<id>.lua` owns
its description, `menu_group`, and `menu_order`. The character generator
joins the committed presentation artifact by ID, checks source revisions and
complete selectable coverage, and writes source comments beside descriptions
and job menu fields. Normal builds read only the generated Lua files.

`constants.menu_groups` names the pinned groups and their display order.
It also records each group's source-derived screen capacity. Entries beyond
that capacity appear on the Modded page so they cannot overwrite the next
fixed screen heading.
Generated species and job definitions import the constants they use. This
module contains group labels and order, not a second list of content IDs.
`data.presentation` retains the pinned startup modes, skill columns, and
source version, but no species/job ID lists or descriptions. The exporter
regenerates both shared modules from the committed presentation artifact.

`policy.character.menu` assembles groups from registered definitions. It
orders bundled choices by their own numeric priority, uses each definition's
description, and sends selectable definitions without pinned group metadata
to the existing Modded choices page in registration order. A same-path
override may change its description, group, or order through that one file.
There is no fallback to the old aggregate ID list.

## Validation and parity

At boot, a selectable grouped member must have a nonempty description
and a positive integral order. A group value must be a known species/job
group, and orders must be unique within a group. Mod-added definitions may
omit group metadata and use their name as the menu description; if they
choose a pinned group, they must provide a valid order. The error names the
owning content path. Nonselectable entries do not appear on the menu.
An override that removes both group fields intentionally moves its choice
to the Modded page.

The generated 27 species and 25 jobs retain the same group labels, order,
and description bytes as the pinned source. Runtime tests exercise the menu
projection and same-path overrides, and exporter tests check complete
source joins. The effective Lua file bytes continue to define ruleset
identity. The JSON import artifacts remain committed for deliberate refresh.
