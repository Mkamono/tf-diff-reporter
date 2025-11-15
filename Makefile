.PHONY: help build test clean fmt vet

BINARY := tf-diff-reporter
CMD := ./cmd/cli

# test直下のテストケースを自動認識（env1を持つディレクトリ）
TEST_CASES := $(patsubst test/%/env1,%,$(wildcard test/*/env1))
TEST_TARGETS := $(addprefix test-,$(TEST_CASES))

help:
	@echo "Targets: help, build, test, clean, fmt, vet"
	@echo "Tests: $(TEST_TARGETS)"

build:
	go build -o $(BINARY) $(CMD)

test: build $(TEST_TARGETS)

$(addprefix test-,$(TEST_CASES)): test-%: build
	@mkdir -p test/$*/.tfdr/reports
	@cd test/$* && ../../$(BINARY) compare $$(ls -d env* | tr '\n' ' ') || true

clean:
	rm -f $(BINARY)
	find test -type d -name reports -exec rm -rf {} + 2>/dev/null || true

fmt:
	go fmt ./...

vet:
	go vet ./...
