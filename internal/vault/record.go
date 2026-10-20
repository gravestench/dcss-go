package vault

import "fmt"

// Kind identifies one source vault effect without depending on a DES string
// expression. Effects without an active gameplay system remain pending.
type Kind string

const (
	KindSourceFeature Kind = "source_feature"
	KindFeature       Kind = "feature"
	KindMonster       Kind = "monster"
	KindItem          Kind = "item"
	KindMarker        Kind = "marker"
	KindColour        Kind = "colour"
	KindTile          Kind = "tile"
	KindMask          Kind = "mask"
	KindProperty      Kind = "property"
	KindGeneration    Kind = "generation_rule"
	KindDelayedDecay  Kind = "delayed_decay"
	KindFeatureName   Kind = "feature_name"
	KindBorderFill    Kind = "border_fill"
	KindEntryMessage  Kind = "entry_message"
	KindOctaRoom      Kind = "octa_room"
	KindSmearMap      Kind = "smear_map"
	KindVeto          Kind = "veto"
)

var validKinds = map[Kind]bool{
	KindSourceFeature: true,
	KindFeature:       true,
	KindMonster:       true,
	KindItem:          true,
	KindMarker:        true,
	KindColour:        true,
	KindTile:          true,
	KindMask:          true,
	KindProperty:      true,
	KindGeneration:    true,
	KindDelayedDecay:  true,
	KindFeatureName:   true,
	KindBorderFill:    true,
	KindEntryMessage:  true,
	KindOctaRoom:      true,
	KindSmearMap:      true,
	KindVeto:          true,
}

type ValueKind string

const (
	ValueBool   ValueKind = "bool"
	ValueInt    ValueKind = "int64"
	ValueString ValueKind = "string"
)

// Argument is a tagged scalar. Only the field selected by Kind may be set.
type Argument struct {
	Name   string    `json:"name"`
	Kind   ValueKind `json:"kind"`
	Bool   bool      `json:"bool,omitempty"`
	Int    int64     `json:"int,omitempty"`
	String string    `json:"string,omitempty"`
}

func (a Argument) Validate() error {
	if a.Name == "" {
		return fmt.Errorf("vault argument has no name")
	}

	switch a.Kind {
	case ValueBool:
		if a.Int != 0 || a.String != "" {
			return fmt.Errorf("vault argument %s has mismatched bool value", a.Name)
		}

	case ValueInt:
		if a.Bool || a.String != "" {
			return fmt.Errorf("vault argument %s has mismatched int64 value", a.Name)
		}

	case ValueString:
		if a.Bool || a.Int != 0 {
			return fmt.Errorf("vault argument %s has mismatched string value", a.Name)
		}

	default:
		return fmt.Errorf("vault argument %s has unknown value kind %q", a.Name, a.Kind)
	}

	return nil
}

// Record is level-owned placement intent or a retained source feature.
type Record struct {
	Kind           Kind       `json:"kind"`
	SourceID       string     `json:"source_id"`
	Identity       string     `json:"identity,omitempty"`
	SourceGlyph    string     `json:"source_glyph,omitempty"`
	Directive      string     `json:"directive,omitempty"`
	ActivationHook string     `json:"activation_hook,omitempty"`
	X              int        `json:"x"`
	Y              int        `json:"y"`
	Line           int        `json:"line,omitempty"`
	Pending        bool       `json:"pending,omitempty"`
	Overridden     bool       `json:"overridden,omitempty"`
	Arguments      []Argument `json:"arguments,omitempty"`
}

func (r Record) Validate(width, height int) error {
	if !validKinds[r.Kind] {
		return fmt.Errorf("unknown vault record kind %q", r.Kind)
	}

	if r.SourceID == "" {
		return fmt.Errorf("vault record %s has no source ID", r.Kind)
	}

	if r.X < 0 ||
		r.X >= width ||
		r.Y < 0 ||
		r.Y >= height {
		return fmt.Errorf("vault record %s has invalid location (%d,%d)", r.Kind, r.X, r.Y)
	}

	if len(r.SourceGlyph) > 1 || r.Line < 0 {
		return fmt.Errorf("vault record %s has invalid source coordinates", r.Kind)
	}

	if (r.Kind == KindSourceFeature ||
		r.Kind == KindItem ||
		r.Kind == KindMonster ||
		r.Kind == KindFeature) &&
		r.Identity == "" {
		return fmt.Errorf("vault record %s has no source identity", r.Kind)
	}

	seen := make(map[string]bool, len(r.Arguments))

	for _, argument := range r.Arguments {
		if err := argument.Validate(); err != nil {
			return err
		}

		if seen[argument.Name] {
			return fmt.Errorf("vault record %s repeats argument %s", r.Kind, argument.Name)
		}

		seen[argument.Name] = true
	}

	return nil
}

func Clone(records []Record) []Record {
	copy := make([]Record, len(records))

	for index, record := range records {
		copy[index] = record
		copy[index].Arguments = append([]Argument(nil), record.Arguments...)
	}

	return copy
}
