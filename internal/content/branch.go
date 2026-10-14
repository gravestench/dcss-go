package content

import (
	"fmt"
	"regexp"
	"slices"
	"strings"
)

type BranchDef struct {
	ID         string `json:"id"`
	NumericID  int    `json:"numeric_id"`
	EnumLine   int    `json:"enum_line"`
	SourceLine int    `json:"source_line"`

	ParentID      string   `json:"parent_id"`
	MinDepth      int      `json:"min_depth"`
	MaxDepth      int      `json:"max_depth"`
	Depth         int      `json:"depth"`
	AbsoluteDepth int      `json:"absolute_depth"`
	Flags         []string `json:"flags"`

	EntryFeature  string `json:"entry_feature"`
	ExitFeature   string `json:"exit_feature"`
	EscapeFeature string `json:"escape_feature"`

	ShortName    string `json:"short_name"`
	LongName     string `json:"long_name"`
	Abbreviation string `json:"abbreviation"`
	EntryMessage string `json:"entry_message,omitempty"`

	FloorColor     string   `json:"floor_color"`
	RockColor      string   `json:"rock_color"`
	TravelShortcut string   `json:"travel_shortcut"`
	Runes          []string `json:"runes"`
	AmbientNoise   string   `json:"ambient_noise"`
	MonDieSizeExpr string   `json:"mon_die_size_expr,omitempty"`
}

type BranchArtifact struct {
	SchemaVersion   int             `json:"schema_version"`
	SourceRevision  string          `json:"source_revision"`
	TagMajorVersion int             `json:"tag_major_version"`
	SourceFiles     []JobSourceFile `json:"source_files"`
	Branches        []BranchDef     `json:"branches"`
}

var branchToken = regexp.MustCompile(`^[A-Z][A-Z0-9_]*$`)

func (b BranchDef) clone() BranchDef {
	b.Flags = slices.Clone(b.Flags)
	b.Runes = slices.Clone(b.Runes)

	return b
}

func (b BranchDef) validate() error {
	invalidIdentity := !strings.HasPrefix(b.ID, "BRANCH_") ||
		b.NumericID < 0 || b.EnumLine <= 0 || b.SourceLine <= 0
	invalidParent := b.ParentID != "NUM_BRANCHES" &&
		!strings.HasPrefix(b.ParentID, "BRANCH_")
	invalidDepth := b.Depth < 0 || b.AbsoluteDepth < 0
	invalidNames := b.ShortName == "" || b.LongName == "" ||
		b.Abbreviation == "" || len([]rune(b.TravelShortcut)) != 1 ||
		b.AmbientNoise == ""

	if invalidIdentity || invalidParent || invalidDepth || invalidNames {
		return fmt.Errorf("invalid branch %q", b.ID)
	}

	if b.MinDepth > b.MaxDepth || b.MaxDepth < -1 {
		return fmt.Errorf("invalid branch depth for %s", b.ID)
	}

	for _, token := range []string{
		b.EntryFeature,
		b.ExitFeature,
		b.EscapeFeature,
		b.FloorColor,
		b.RockColor,
	} {
		if !branchToken.MatchString(token) {
			return fmt.Errorf("invalid branch token %q for %s", token, b.ID)
		}
	}

	for _, flag := range b.Flags {
		if flag == "" {
			return fmt.Errorf("empty branch flag for %s", b.ID)
		}
	}

	for _, runeID := range b.Runes {
		if !strings.HasPrefix(runeID, "RUNE_") {
			return fmt.Errorf("invalid rune %q for %s", runeID, b.ID)
		}
	}

	return nil
}

func (a BranchArtifact) Validate() error {
	if a.SchemaVersion != 1 || a.SourceRevision == "" || a.TagMajorVersion != 34 ||
		len(a.Branches) == 0 || len(a.SourceFiles) != 3 {
		return fmt.Errorf("invalid branch artifact metadata")
	}

	seen := make(map[string]bool, len(a.Branches))

	for i, branch := range a.Branches {
		if err := branch.validate(); err != nil {
			return err
		}

		if branch.NumericID != i || seen[branch.ID] {
			return fmt.Errorf("branch identity/order mismatch at %d", i)
		}

		seen[branch.ID] = true
	}

	for _, branch := range a.Branches {
		if branch.ParentID != "NUM_BRANCHES" && !seen[branch.ParentID] {
			return fmt.Errorf("branch %s has unknown parent %s", branch.ID, branch.ParentID)
		}
	}

	return nil
}
