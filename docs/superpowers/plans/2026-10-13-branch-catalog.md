# Branch catalog implementation plan

1. Add failing parser and runtime-validation tests for tag-34 enum aliases, nested rune lists, joined string literals, optional aggregate tail, and malformed rows.
2. Implement a narrow `branchimport` parser and deterministic developer command against `branch-type.h` and `branch-data.h`, recording pinned hashes and source lines.
3. Generate and commit `generated/branches.json`; validate exact enum/table coverage and load an immutable branch map/order through `content.Catalog`.
4. Verify importer `-check`, Go tests/vet/build, diff hygiene, and a read-only whole-branch review. Commit this category and fast-forward local Go `main`.
