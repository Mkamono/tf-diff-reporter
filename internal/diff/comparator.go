package diff

import (
	"github.com/Mkamono/tf-diff-reporter/internal/model"
	"github.com/Mkamono/tf-diff-reporter/internal/tools"
)

// Comparator classifies jd diffs into ignored/unknown categories
type Comparator struct {
	ignoreManager *IgnoreManager
}

// NewComparator creates a new comparator
func NewComparator(ignoreManager *IgnoreManager) *Comparator {
	return &Comparator{
		ignoreManager: ignoreManager,
	}
}

// ClassifyDiffs converts jd diffs into unknown and acknowledged categories
func (c *Comparator) ClassifyDiffs(diffs []tools.JDDiff) (unknown, acknowledged []model.Difference) {
	for _, diff := range diffs {
		modelDiff := model.Difference{
			Path: diff.Path,
			Op:   diff.Op,
		}

		// RFC 6902: remove/add/replace operations
		switch diff.Op {
		case "remove":
			modelDiff.FromValue = diff.Value
			modelDiff.ToValue = nil
		case "add":
			modelDiff.FromValue = nil
			modelDiff.ToValue = diff.Value
		case "replace":
			modelDiff.FromValue = diff.From
			modelDiff.ToValue = diff.Value
		}

		if c.ignoreManager.IsIgnored(diff.Path) {
			modelDiff.Ignored = true
			modelDiff.Reason = c.ignoreManager.GetReason(diff.Path)
			acknowledged = append(acknowledged, modelDiff)
		} else {
			unknown = append(unknown, modelDiff)
		}
	}

	return unknown, acknowledged
}
