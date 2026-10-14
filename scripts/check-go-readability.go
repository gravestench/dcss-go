package main

import (
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	issues := 0

	for _, root := range []string{
		"cmd",
		"internal",
		"scripts",
	} {
		err := filepath.WalkDir(root, func(path string, entry fs.DirEntry, walkErr error) error {
			if walkErr != nil {
				return walkErr
			}

			if entry.IsDir() || !strings.HasSuffix(path, ".go") {
				return nil
			}

			found, err := checkFile(path)
			issues += found

			return err
		})

		if err != nil {
			fmt.Fprintln(os.Stderr, err)
			os.Exit(1)
		}
	}

	if issues > 0 {
		os.Exit(1)
	}
}

func checkFile(path string) (int, error) {
	source, err := os.ReadFile(path)

	if err != nil {
		return 0, err
	}

	lines := strings.Split(string(source), "\n")
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, path, source, parser.ParseComments)

	if err != nil {
		return 0, err
	}

	issues := 0
	report := func(pos token.Pos, message string) {
		fmt.Printf("%s: %s\n", fset.Position(pos), message)
		issues++
	}
	multilineLiteralEndsAt := func(statement ast.Stmt, line int) bool {
		found := false

		ast.Inspect(statement, func(node ast.Node) bool {
			literal, ok := node.(*ast.CompositeLit)

			if ok && fset.Position(literal.Rbrace).Line == line &&
				fset.Position(literal.Lbrace).Line < line {
				found = true
			}

			return true
		})

		return found
	}
	checkStatements := func(statements []ast.Stmt) {
		for index := 1; index < len(statements); index++ {
			previous := statements[index-1]
			next := statements[index]
			previousEndLine := fset.Position(previous.End() - 1).Line
			adjacent := previousEndLine+1 == fset.Position(next.Pos()).Line
			_, returns := next.(*ast.ReturnStmt)

			if isControl(next) && !isControl(previous) &&
				adjacent {
				report(next.Pos(), "leave a blank line before the control block")
			}

			if returns && !isControl(previous) &&
				adjacent {
				report(next.Pos(), "leave a blank line before the return")
			}

			if isControl(previous) && adjacent {
				report(next.Pos(), "leave a blank line after the control block")
			}

			if !isControl(previous) && !isControl(next) && !returns && adjacent &&
				multilineLiteralEndsAt(previous, previousEndLine) {
				report(next.Pos(), "leave a blank line after the multiline literal")
			}
		}
	}
	checkClauses := func(clauses []ast.Stmt) {
		for index := 1; index < len(clauses); index++ {
			previous := clauses[index-1]
			next := clauses[index]

			if fset.Position(previous.End()-1).Line+1 == fset.Position(next.Pos()).Line {
				report(next.Pos(), "leave a blank line between switch or select cases")
			}
		}
	}
	blockEndLines := make(map[int]bool)

	for index := 1; index < len(file.Decls); index++ {
		previous := file.Decls[index-1]
		next := file.Decls[index]

		if fset.Position(previous.End()-1).Line+1 == fset.Position(next.Pos()).Line {
			report(next.Pos(), "leave a blank line between top-level declarations")
		}
	}

	ast.Inspect(file, func(node ast.Node) bool {
		switch value := node.(type) {
		case *ast.SwitchStmt:
			checkClauses(value.Body.List)

		case *ast.TypeSwitchStmt:
			checkClauses(value.Body.List)

		case *ast.SelectStmt:
			checkClauses(value.Body.List)

		case *ast.ValueSpec:
			if len(value.Names) > 1 {
				report(value.Pos(), "declare each named value on its own line")
			}

		case *ast.StructType:
			for _, field := range value.Fields.List {
				if len(field.Names) > 1 {
					report(field.Pos(), "declare each struct field on its own line")
				}
			}

		case *ast.AssignStmt:
			if value.Tok == token.DEFINE && len(value.Lhs) >= 4 && len(value.Rhs) >= 4 {
				report(value.Pos(), "declare parser and other local state one variable per line")
			}

			if value.Tok != token.ASSIGN || len(value.Lhs) < 2 || len(value.Rhs) < 2 {
				break
			}

			allFields := true

			for _, target := range value.Lhs {
				_, field := target.(*ast.SelectorExpr)
				allFields = allFields && field
			}

			if allFields || len(value.Lhs) >= 3 {
				report(value.Pos(), "assign mutable fields and unrelated values one per line")
			}

		case *ast.BlockStmt:
			blockEndLines[fset.Position(value.Rbrace).Line] = true

			if len(value.List) > 0 && sameLine(fset, value.Lbrace, value.Rbrace) {
				report(value.Lbrace, "expand this inline block")
			}

			checkStatements(value.List)

		case *ast.CaseClause:
			checkStatements(value.Body)

		case *ast.CommClause:
			checkStatements(value.Body)

		case *ast.CompositeLit:
			if len(value.Elts) < 2 {
				break
			}

			keyedFields := true

			for _, element := range value.Elts {
				_, keyed := element.(*ast.KeyValueExpr)
				keyedFields = keyedFields && keyed
			}

			_, named := value.Type.(*ast.Ident)
			_, qualified := value.Type.(*ast.SelectorExpr)
			_, anonymous := value.Type.(*ast.StructType)
			_, generic := value.Type.(*ast.IndexExpr)
			_, genericList := value.Type.(*ast.IndexListExpr)
			fixedArray, array := value.Type.(*ast.ArrayType)
			compactFixedArray := array && fixedArray.Len != nil &&
				scalarElements(value.Elts)

			if ((len(value.Elts) >= 3 && !compactFixedArray) ||
				len(value.Elts) >= 4 || keyedFields || named || qualified ||
				anonymous || generic || genericList) &&
				entriesShareLine(fset, value) {
				report(value.Lbrace, "put literal entries on separate lines")
			}
		}

		return true
	})

	for _, group := range file.Comments {
		line := fset.Position(group.Pos()).Line

		if blockEndLines[line-1] && strings.TrimSpace(lines[line-2]) == "}" {
			report(group.Pos(), "leave a blank line after the block before its comment")
		}
	}

	return issues, nil
}

func sameLine(fset *token.FileSet, left, right token.Pos) bool {
	return fset.Position(left).Line == fset.Position(right).Line
}

func scalarElements(elements []ast.Expr) bool {
	for _, element := range elements {
		switch value := element.(type) {
		case *ast.BasicLit, *ast.Ident:
			continue

		case *ast.UnaryExpr:
			if _, literal := value.X.(*ast.BasicLit); literal {
				continue
			}
		}

		return false
	}

	return true
}

func entriesShareLine(fset *token.FileSet, literal *ast.CompositeLit) bool {
	if sameLine(fset, literal.Lbrace, literal.Elts[0].Pos()) ||
		sameLine(fset, literal.Elts[len(literal.Elts)-1].End()-1, literal.Rbrace) {
		return true
	}

	for index := 1; index < len(literal.Elts); index++ {
		if sameLine(fset, literal.Elts[index-1].End()-1, literal.Elts[index].Pos()) {
			return true
		}
	}

	return false
}

func isControl(statement ast.Stmt) bool {
	switch statement.(type) {
	case *ast.IfStmt, *ast.ForStmt, *ast.RangeStmt,
		*ast.SwitchStmt, *ast.TypeSwitchStmt, *ast.SelectStmt:
		return true
	}

	return false
}
