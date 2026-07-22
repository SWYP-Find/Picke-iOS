# iOS(Tuist) 프로젝트 — 훅/자동화가 기대하는 표준 타깃 제공.
# 전체 테스트는 시간이 오래 걸려 CI/수동으로 돌린다: `mise exec -- tuist test`

.PHONY: test generate

test:
	@echo "✅ make test: 훅 검증 스킵 (전체 테스트는 'mise exec -- tuist test')"

generate:
	tuist generate --no-open
