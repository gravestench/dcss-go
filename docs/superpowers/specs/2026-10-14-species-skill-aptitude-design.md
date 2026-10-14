# Species skill aptitude thresholds

## Context

The checked-in species catalog includes every ordinary skill aptitude, but
training, combat projection, save validation, and the skills screen still
interpret stored skill points using Human's aptitude zero. The previous slice
made experience-level thresholds species-aware. This slice makes the existing
skill domain read the same selected species through the player's ECS identity.

## Source rule

`crawl-ref/source/skills.cc:2043-2113` computes
`skill_exp_needed(level, skill, species)` as the historical skill cost times
`apt_to_factor(species_apt(skill, species))`. The factor is returned as a
`float`; the resulting product is truncated to unsigned integer. Historical
cost breakpoints are 9, 18, and 26. `skills.cc:224-275` gives starting skills
Human-priced points before reassessing them for the selected species.
`player.cc:3831-3847` scales baseline HP with Fighting and the immutable
species HP modifier; mutation and permanent adjustment terms follow later.

## Design

- Keep immutable threshold arithmetic in `character`. Replace Human-only
  threshold and level helpers with aptitude-taking functions. Scale displayed
  fractional levels using the same aptitude.
- Read aptitude from the selected `PlayerControlled.SpeciesID` and checked-in
  species catalog at each game boundary. Training spends into ECS `Skills` and
  `SkillTraining` as before. Combat and HUD project those points; they do not
  own another copy.
- The Human/Fighter start remains the only playable start until species
  mutations, full vitals, and job rules are ported. Its skill points and
  observable behavior remain unchanged. Base HP recalculation reads selected
  species Fighting aptitude and HP modifier so training cannot partially
  mutate a non-Human ECS player before failing. Other species' pure skill
  thresholds are source-tested, ready for their starts.
- Skill-cost level remains based on aptitude-one XP thresholds, independent
  of species and individual skill aptitude.
- Saved skills are validated against the saved player's selected species.
  Malformed or unusable aptitudes are errors, not implicit Human fallbacks.

## Acceptance

- A standalone pinned-source oracle agrees with representative thresholds
  across the catalog aptitude range and at historical breakpoints.
- Human/Fighter tests continue to pass unchanged in behavior.
- A non-Human ECS species test demonstrates that training, projection, and
  save validation use its aptitude without opening unsupported character
  creation paths.
- `go test ./...`, `go vet ./...`, `go build ./...`, and style checks pass.
