# Hit-Triggered Summons, Fog, and Artefact Drawbacks Plan

**Spec:** `docs/superpowers/specs/2026-10-21-remaining-hit-reactions-design.md`

**Integration unit:** One contiguous category commit on `main`, pushed to
`origin`. The user's standing approval covers the recommended native path.

## Work

- [x] Write failing production-schema Lua tests for Xom butterflies,
      Dithmenos/Thief/Xom fog precedence, and artefact drawbacks.
- [x] Add source-ordered religion reaction modules and ordinary Xom summon
      restore validation, reusing the common summon and cloud owners.
- [x] Add artefact callbacks through the worn-property collector. Extend
      corrosion's degree input so multiple `*Corrode` properties have one
      source-shaped duration and independent protection rolls.
- [x] Add save and combat regression cases for the new reactions; document
      the extension points and update the port inventory.
- [x] Run the related Lua and game suites, all-package build, Go style,
      changed-file line-length and staged-diff checks.
- [x] Review the entire category and fix material findings.
- Integrate the reviewed category as one `main` commit and push it.

The focused Lua reaction and affected Slow tests pass, as do related game
tests and all-package compilation. The broad `internal/script` suite was
stopped after 513 seconds without a result. The Go style checker reports
pre-existing violations in untouched Go files; this category changes no Go
source. The changed Lua files meet the 120-character limit.

## Review focus

1. Xom ejection must fail its source or threshold gate without consuming
   count or placement draws; the source performs its chance before count.
2. Fog chooses only one of Dithmenos, Thief, or Xom branches per hit.
3. Carried or melded artefacts cannot trigger wearer-only drawbacks.
4. Corrosion applies rCorr protection per degree but increases its saved
   duration only once for a successful application.
5. Save validation accepts Xom butterflies and rejects an unrelated
   forged god-origin summon.
