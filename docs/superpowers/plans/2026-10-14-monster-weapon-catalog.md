# Monster weapon catalog implementation plan

1. Define a source-traced, immutable content shape for declarative primary
   and secondary monster weapon specs and add a catalog query.
2. Parse the pinned initializer tables and their named aliases with a narrow
   brace/identifier/integer parser. Reject unsupported syntax and duplicates.
3. Reconcile monster, weapon, and brand identities with committed catalogs;
   write the generated JSON with a source hash and `-check` mode.
4. Load the committed artifact at startup and verify runtime deep copies.
5. Document this content category and the remaining runtime equipment work.
   Run category-wide verification, review, commit, and merge to local main.
