.PHONY: help setup run test analyze format lint build-runner clean

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-13s\033[0m %s\n", $$1, $$2}'

setup: ## Fetch Dart/Flutter packages
	flutter pub get

run: ## Run on a connected device / emulator
	flutter run

test: ## Run widget/unit tests
	flutter test

analyze: ## Static analysis
	flutter analyze

format: ## Sort imports and apply Dart fixes
	dart run import_sorter:main
	dart fix --apply

lint: ## Check import order + analyze (no auto-fix)
	dart run import_sorter:main --exit-if-changed
	dart analyze
	dart fix --dry-run

build-runner: ## Regenerate *.g.dart for Riverpod + JSON models
	dart run build_runner build --delete-conflicting-outputs

clean: ## Remove build artifacts
	flutter clean
