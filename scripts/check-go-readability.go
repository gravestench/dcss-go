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
	fset := token.NewFileSet()
	file, err := parser.ParseFile(fset, path, nil, 0)

	if err != nil {
		return 0, err
	}

	issues := 0
	report := func(pos token.Pos, message string) {
		fmt.Printf("%s: %s\n", fset.Position(pos), message)
		issues++
	}
	checkStatements := func(statements []ast.Stmt) {
		for index := 1; index < len(statements); index++ {
			previous := statements[index-1]
			next := statements[index]

			if isControl(next) && !isControl(previous) &&
				fset.Position(previous.End()-1).Line+1 == fset.Position(next.Pos()).Line {
				report(next.Pos(), "leave a blank line before the control block")
			}

			if _, returns := next.(*ast.ReturnStmt); returns && !isControl(previous) &&
				fset.Position(previous.End()-1).Line+1 == fset.Position(next.Pos()).Line {
				report(next.Pos(), "leave a blank line before the return")
			}

			if isControl(previous) &&
				fset.Position(previous.End()-1).Line+1 == fset.Position(next.Pos()).Line {
				report(next.Pos(), "leave a blank line after the control block")
			}
		}
	}

	ast.Inspect(file, func(node ast.Node) bool {
		switch value := node.(type) {
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
