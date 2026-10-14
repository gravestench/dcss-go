# Complete monster spellbook catalog implementation plan

1. Change the immutable monster spell slot to ordered `Flags` and add its
   source line. Validate book uniqueness and deep-copy the nested flags.
2. Build `internal/content/monsterbookimport` to parse the pinned table,
   reconcile ordered book IDs with `mon-mst.h`, validate flags from
   `externs.h`, and cross-check spells against the committed catalog.
3. Add `cmd/importmonsterbooks` with `-source`, `-out`, and `-check`.
   Generate and commit the complete JSON artifact; normal builds never
   invoke the command.
4. Add parser, generator, and catalog tests. Keep the existing endoplasm
   runtime behavior unchanged while it reads the new artifact.
5. Update port inventory and ECS roadmap; run source `-check` and full
   Go test, vet, build, style, and diff checks. Commit this content
   category and fast-forward local Go `main`.
