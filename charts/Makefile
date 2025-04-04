include Makefile.common

.PHONY: lint-all-charts
lint-all-charts:
	@echo "Linting all Helm charts..."
	@for dir in dz-control-plane dz-data-plane dz-control-plane-deps dz-data-plane-deps; do \
		echo "Linting $$dir..."; \
		cd $$dir && $(MAKE) lint-helm && cd ..; \
	done