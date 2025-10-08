# info/ 폴더 설명

이 폴더는 프로젝트별 상세 규칙을 저장하는 공간입니다.

---

## 🚀 [덮어쓰기] 명령어

루트의 `CLAUDE.md`를 템플릿 규칙으로 덮어쓰거나 병합합니다.

### 사용법

```
[덮어쓰기]
```

### 상세 설명

`init-integration-guide.md` 파일을 참고하세요.

**요약:**
- `/init` 후 병합: 코드베이스 분석 + 템플릿 규칙
- 템플릿만 사용: 순수 템플릿 규칙 복사

---

## 📋 용도

### CLAUDE.md vs .claude/info/*.md

**CLAUDE.md (루트):**
- 자동 프롬프팅 (Claude가 자동으로 읽음)
- 간결한 개요와 참조
- 태그 정의
- 규칙 프로세스 설명

**.claude/CLAUDE.md.backup:**
- 템플릿 규칙 백업 (보존용)
- `/init`이나 수동 편집으로부터 보호됨
- `[덮어쓰기]` 명령어의 소스

**.claude/info/*.md:**
- 상세한 규칙 내용
- 구체적인 패턴
- 예시 코드
- 베스트 프랙티스

---

## 🎯 사용 방법

### 새 규칙 파일 생성 시

```
[규칙 추가] {카테고리} - {규칙 내용}
```

Claude가 자동으로 `.claude/info/{카테고리}.md` 생성

### 파일명 규칙

- 소문자 사용
- 하이픈으로 단어 구분
- 카테고리-주제.md 형식

**예시:**
- `coding-rules.md`
- `git-workflow.md`
- `testing-guide.md`
- `api-standards.md`

---

## 📁 템플릿 기본 파일

### init-integration-guide.md
`/init` 명령어 후 통합 가이드

새 프로젝트에서 공통으로 사용되는 전역 규칙입니다.

---

## 🔄 프로젝트 시작 시

### 1. 템플릿 설치

```
[템플릿 설치] ~/your-project
```

자동으로 다음 파일 생성:
- `.claude/CLAUDE.md.backup` (템플릿 규칙)
- `.claude/info/` (상세 규칙)

### 2. CLAUDE.md 생성

**옵션 A: /init 사용 후 병합**
```
/init
[덮어쓰기]
→ 2️⃣ 병합
```

**옵션 B: 템플릿만 사용**
```
[덮어쓰기]
→ 1️⃣ 덮어쓰기
```

### 3. 프로젝트별 규칙 추가

```
[규칙 추가] {카테고리} - {규칙 내용}
```

---

## 💡 Best Practices

### ✅ 좋은 예

**명확한 파일명:**
- `react-component-rules.md`
- `database-query-guidelines.md`

**구조화된 내용:**
```markdown
# 제목

## 규칙 1
- 설명
- 예시
- 안티패턴

## 규칙 2
...
```

### ❌ 나쁜 예

**모호한 파일명:**
- `rules.md` (무슨 규칙?)
- `temp.md` (임시?)

**너무 긴 파일:**
- 하나의 파일에 모든 규칙 몰아넣기
- → 카테고리별로 분리 권장

---

## 📌 참고

- **RULE-SYSTEM-GUIDE.md** - 규칙 시스템 전체 가이드
- **CLAUDE.md** (루트) - 자동 프롬프팅 파일
- **.claude/CLAUDE.md.backup** - 템플릿 규칙 백업
