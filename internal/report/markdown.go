package report

import (
	"encoding/json"
	"fmt"
	"sort"
	"strings"

	"github.com/Mkamono/tf-diff-reporter/internal/model"
)

// MarkdownFormatter formats the report as Markdown
type MarkdownFormatter struct{}

// NewMarkdownFormatter creates a new Markdown formatter
func NewMarkdownFormatter() *MarkdownFormatter {
	return &MarkdownFormatter{}
}

// FormatMerged generates a Markdown formatted report for merged comparisons
func (mf *MarkdownFormatter) FormatMerged(result model.MergedComparisonResult) (string, error) {
	return mf.formatMerged(result), nil
}

// formatMerged generates the merged report content
func (mf *MarkdownFormatter) formatMerged(result model.MergedComparisonResult) string {
	var sb strings.Builder

	// Title
	sb.WriteString(fmt.Sprintf("# Terraform 環境間差分レポート (基準: %s)\n\n", result.BaseEnv))

	// Summary
	sb.WriteString("## 📊 サマリー\n\n")
	sb.WriteString("| | |\n")
	sb.WriteString("| --- | --- |\n")
	sb.WriteString(fmt.Sprintf("| 基準環境 | `%s` |\n", result.BaseEnv))
	sb.WriteString(fmt.Sprintf("| 未認識差分 (−) | %d |\n", result.TotalUnknownDiffs))
	sb.WriteString(fmt.Sprintf("| 認識済み差分 (✓) | %d |\n\n", result.TotalAcknowledgedDiffs))

	// Unknown differences section
	if result.TotalUnknownDiffs > 0 {
		sb.WriteString("## 未認識差分\n\n")
		sb.WriteString(mf.formatMergedDiffTableWithOp(result, false))
		sb.WriteString("\n\n")
	}

	// Acknowledged differences section
	if result.TotalAcknowledgedDiffs > 0 {
		sb.WriteString("## 認識済み差分 (ignore.json)\n\n")
		sb.WriteString(mf.formatMergedDiffTableWithOp(result, true))
		sb.WriteString("\n\n")
	}

	return sb.String()
}

// formatValue converts a value to a string representation
func (mf *MarkdownFormatter) formatValue(val interface{}) string {
	if val == nil {
		return "−"
	}

	var strVal string
	switch v := val.(type) {
	case string:
		strVal = v
	case bool:
		strVal = fmt.Sprintf("%v", v)
	case float64:
		strVal = fmt.Sprintf("%v", v)
	case int:
		strVal = fmt.Sprintf("%d", v)
	case map[string]interface{}, []interface{}:
		// JSONをフォーマット
		if b, err := json.MarshalIndent(v, "", "  "); err == nil {
			strVal = string(b)
		} else {
			strVal = fmt.Sprintf("%v", v)
		}
	default:
		strVal = fmt.Sprintf("%v", v)
	}

	// Escape special characters for markdown/KaTeX compatibility
	strVal = strings.ReplaceAll(strVal, "$", "\\$")

	// Replace newlines with <br> and spaces with &nbsp; for markdown table compatibility
	strVal = strings.ReplaceAll(strVal, "\n", "<br>")
	strVal = strings.ReplaceAll(strVal, "  ", "&nbsp;&nbsp;")
	return strVal
}

// formatMergedDiffTableWithOp creates a markdown table with operation symbols (+, -, ~)
func (mf *MarkdownFormatter) formatMergedDiffTableWithOp(result model.MergedComparisonResult, acknowledged bool) string {
	var sb strings.Builder

	// Collect diffs by path
	var allDiffs []model.Difference
	for _, envDiff := range result.CompareEnvs {
		var diffs []model.Difference
		if acknowledged {
			diffs = envDiff.AcknowledgedDiffs
		} else {
			diffs = envDiff.UnknownDiffs
		}
		allDiffs = append(allDiffs, diffs...)
	}

	// Group diffs by path with environment name
	type DiffWithEnv struct {
		Diff model.Difference
		Env  string
	}
	diffsByPath := make(map[string][]DiffWithEnv)
	for _, envDiff := range result.CompareEnvs {
		var diffs []model.Difference
		if acknowledged {
			diffs = envDiff.AcknowledgedDiffs
		} else {
			diffs = envDiff.UnknownDiffs
		}
		for _, diff := range diffs {
			diffsByPath[diff.Path] = append(diffsByPath[diff.Path], DiffWithEnv{diff, envDiff.EnvName})
		}
	}

	// Build header
	sb.WriteString("| 属性パス |")
	for _, envDiff := range result.CompareEnvs {
		if result.Reversed {
			sb.WriteString(fmt.Sprintf(" %s → %s |", envDiff.EnvName, result.BaseEnv))
		} else {
			sb.WriteString(fmt.Sprintf(" %s → %s |", result.BaseEnv, envDiff.EnvName))
		}
	}
	if acknowledged {
		sb.WriteString(" 理由 |")
	}
	sb.WriteString("\n")

	// Build separator
	sb.WriteString("| :--- |")
	for range result.CompareEnvs {
		sb.WriteString(" :--- |")
	}
	if acknowledged {
		sb.WriteString(" :--- |")
	}
	sb.WriteString("\n")

	// Build rows
	var paths []string
	for path := range diffsByPath {
		paths = append(paths, path)
	}
	sort.Strings(paths)

	for _, path := range paths {
		sb.WriteString(fmt.Sprintf("| %s |", path))

		diffsWithEnv := diffsByPath[path]
		// Index diffs by environment name
		diffsByEnv := make(map[string]model.Difference)
		var firstDiff model.Difference
		for _, dwe := range diffsWithEnv {
			diffsByEnv[dwe.Env] = dwe.Diff
			firstDiff = dwe.Diff
		}

		// Build cells for each compare environment
		for _, envDiff := range result.CompareEnvs {
			diff, exists := diffsByEnv[envDiff.EnvName]
			if !exists {
				sb.WriteString(" − |")
				continue
			}

			// Format the cell with operation symbol and values
			cell := mf.formatDiffCell(diff)
			sb.WriteString(fmt.Sprintf(" %s |", cell))
		}

		// Add reason if acknowledged
		if acknowledged && len(diffsWithEnv) > 0 {
			reason := firstDiff.Reason
			sb.WriteString(fmt.Sprintf(" %s |", reason))
		}

		sb.WriteString("\n")
	}

	return sb.String()
}

// formatDiffCell formats a diff cell in Terraform plan style
// Shows only the values, with symbols indicating operation (+ - ~)
func (mf *MarkdownFormatter) formatDiffCell(diff model.Difference) string {
	symbol := "~" // default for replace
	switch diff.Op {
	case "add":
		symbol = "+"
		return fmt.Sprintf("%s %s", symbol, mf.formatValue(diff.ToValue))
	case "remove":
		symbol = "−"
		return fmt.Sprintf("%s %s", symbol, mf.formatValue(diff.FromValue))
	default: // replace
		fromStr := mf.formatValue(diff.FromValue)
		toStr := mf.formatValue(diff.ToValue)
		return fmt.Sprintf("%s %s<br>→ %s", symbol, fromStr, toStr)
	}
}
