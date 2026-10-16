package vaultimport

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"path"
	"slices"
	"strings"
)

type sourceLine struct {
	number int
	text   string
}

var sourceDirectives = map[string]bool{
	"NAME":     true,
	"TAGS":     true,
	"ORIENT":   true,
	"WEIGHT":   true,
	"CLEAR":    true,
	"SUBST":    true,
	"NSUBST":   true,
	"SHUFFLE":  true,
	"KFEAT":    true,
	"KMONS":    true,
	"KITEM":    true,
	"KMASK":    true,
	"KPROP":    true,
	"MONS":     true,
	"ITEM":     true,
	"COLOUR":   true,
	"FTILE":    true,
	"RTILE":    true,
	"TILE":     true,
	"MARKER":   true,
	"SUBVAULT": true,
}

func splitSource(
	fileName string,
	body []byte,
	ports map[string]portRecipe,
) (map[string][]byte, error) {
	lines := numberedLines(body)
	output := make(map[string][]byte)
	var current []sourceLine
	inMap := false

	flush := func() error {
		if len(current) == 0 {
			return nil
		}

		name, err := vaultName(current[0])

		if err != nil {
			return fmt.Errorf("%s:%d: %w", fileName, current[0].number, err)
		}

		recipe, scripted := ports[name]

		if scripted &&
			recipe.SourceFile != "" &&
			recipe.SourceFile != fileName {
			return fmt.Errorf("%s: recipe for %s names source %s", fileName, name, recipe.SourceFile)
		}

		generated, err := portVault(fileName, name, current, recipe)

		if err != nil {
			return err
		}

		filePath := path.Join("vaults/arrival", name+".des")

		if _, duplicate := output[filePath]; duplicate {
			return fmt.Errorf("%s: duplicate vault %s", fileName, name)
		}

		output[filePath] = generated

		return nil
	}

	for _, line := range lines {
		if !inMap && strings.HasPrefix(line.text, "NAME:") {
			if err := flush(); err != nil {
				return nil, err
			}

			current = []sourceLine{line}
			continue
		}

		if len(current) == 0 {
			if line.text != "" && !strings.HasPrefix(line.text, "#") {
				return nil, fmt.Errorf("%s:%d: content before first NAME", fileName, line.number)
			}

			continue
		}

		current = append(current, line)

		if line.text == "MAP" {
			inMap = true
		} else if line.text == "ENDMAP" {
			inMap = false
		}
	}

	if inMap {
		return nil, fmt.Errorf("%s: unterminated MAP", fileName)
	}

	if err := flush(); err != nil {
		return nil, err
	}

	return output, nil
}

func numberedLines(body []byte) []sourceLine {
	text := strings.TrimSuffix(string(body), "\n")
	parts := strings.Split(text, "\n")
	lines := make([]sourceLine, len(parts))

	for index, part := range parts {
		lines[index] = sourceLine{
			number: index + 1,
			text:   strings.TrimSuffix(part, "\r"),
		}
	}

	return lines
}

func vaultName(line sourceLine) (string, error) {
	name := strings.TrimSpace(strings.TrimPrefix(line.text, "NAME:"))

	if name == "" || strings.ContainsAny(name, "/\\ \t") {
		return "", fmt.Errorf("invalid vault name %q", name)
	}

	return name, nil
}

func portVault(
	fileName string,
	name string,
	lines []sourceLine,
	recipe portRecipe,
) ([]byte, error) {
	edits := slices.Clone(recipe.Edits)

	slices.SortFunc(edits, func(a, b portEdit) int {
		return a.StartLine - b.StartLine
	})

	output := make([]string, 0, len(lines)+2)
	output = append(output, lines[0].text)
	output = append(output, fmt.Sprintf(
		"# Source: crawl-ref/source/dat/des/arrival/%s:%d",
		fileName,
		lines[0].number,
	))

	inMap := false
	editIndex := 0
	continuation := false

	for index := 1; index < len(lines); index++ {
		line := lines[index]

		if editIndex < len(edits) && line.number == edits[editIndex].StartLine {
			edit := edits[editIndex]
			endIndex := index + edit.EndLine - edit.StartLine

			if edit.EndLine < edit.StartLine || endIndex >= len(lines) {
				return nil, fmt.Errorf("%s:%d: invalid port span for %s", fileName, line.number, name)
			}

			block := lines[index : endIndex+1]
			sum := sha256.Sum256([]byte(joinSourceLines(block)))

			if hex.EncodeToString(sum[:]) != edit.SHA256 {
				return nil, fmt.Errorf("%s:%d: source script drift for %s", fileName, line.number, name)
			}

			if !validPortMethod(edit.Method) ||
				(edit.Stage != "run" && edit.Stage != "veto") {
				return nil, fmt.Errorf("%s:%d: invalid port hook for %s", fileName, line.number, name)
			}

			output = append(output, fmt.Sprintf(": vault.%s(%q)", edit.Stage, edit.Method))

			for _, source := range block {
				output = append(output, "# source: "+source.text)
			}

			index = endIndex
			editIndex++
			continue
		}

		if editIndex < len(edits) && line.number > edits[editIndex].StartLine {
			return nil, fmt.Errorf("%s:%d: skipped port span for %s", fileName, line.number, name)
		}

		if line.text == "MAP" {
			inMap = true
			output = append(output, line.text)
			continue
		}

		if line.text == "ENDMAP" {
			inMap = false
			output = append(output, line.text)
			continue
		}

		if !inMap && !continuation {
			if err := validateSourceLine(line.text); err != nil {
				return nil, fmt.Errorf("%s:%d: %s: %w", fileName, line.number, name, err)
			}
		}

		continuation = strings.HasSuffix(strings.TrimSpace(line.text), "\\")
		output = append(output, line.text)
	}

	if continuation {
		return nil, fmt.Errorf("%s: unterminated directive continuation in %s", fileName, name)
	}

	if editIndex != len(edits) {
		return nil, fmt.Errorf("%s: unused port edit for %s", fileName, name)
	}

	for len(output) > 0 && output[len(output)-1] == "" {
		output = output[:len(output)-1]
	}

	return []byte(strings.Join(output, "\n") + "\n"), nil
}

func joinSourceLines(lines []sourceLine) string {
	text := make([]string, len(lines))

	for index, line := range lines {
		text[index] = line.text
	}

	return strings.Join(text, "\n") + "\n"
}

func validPortMethod(method string) bool {
	if method == "" {
		return false
	}

	for _, char := range method {
		if char == '_' ||
			char >= 'a' && char <= 'z' ||
			char >= '0' && char <= '9' {
			continue
		}

		return false
	}

	return true
}

func validateSourceLine(line string) error {
	if line == "" || strings.HasPrefix(line, "#") {
		return nil
	}

	if strings.HasPrefix(line, ":") ||
		strings.HasPrefix(line, "veto {{") ||
		line == "}}" {
		return fmt.Errorf("unported source Lua %q", line)
	}

	before, _, found := strings.Cut(line, ":")

	if !found || !sourceDirectives[before] {
		return fmt.Errorf("unknown DES directive %q", line)
	}

	return nil
}
