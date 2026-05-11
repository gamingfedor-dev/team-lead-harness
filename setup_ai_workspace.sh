#!/bin/bash
# ============================================================================
# AI Workspace Bootstrap - Self-Detecting Setup
# ============================================================================
# Detects your project's tech stack and sets up:
# - Obsidian vault with templates adapted to your stack
# - Claude Code config (CLAUDE.md + .claude/commands/ personas)
# - Cursor config (.cursorrules)
# - MCP server connections (Obsidian, Git, Figma)
# - doc_watcher.sh for automated documentation
#
# Usage:
#   ./setup_ai_workspace.sh                    # Auto-detect everything
#   ./setup_ai_workspace.sh --project-dir /path/to/project
#   ./setup_ai_workspace.sh --vault-dir /path/to/vault
#   ./setup_ai_workspace.sh --ide claude       # Claude Code only
#   ./setup_ai_workspace.sh --ide cursor       # Cursor only
#   ./setup_ai_workspace.sh --ide both         # Both (default)
#
# Requirements:
#   - Node.js 18+ (for MCP servers)
#   - Obsidian with Local REST API plugin (for vault MCP)
#   - Git
# ============================================================================

set -euo pipefail

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log()    { echo -e "${GREEN}[✓]${NC} $*"; }
warn()   { echo -e "${YELLOW}[!]${NC} $*"; }
info()   { echo -e "${BLUE}[i]${NC} $*"; }
header() { echo -e "\n${CYAN}══════════════════════════════════════════${NC}"; echo -e "${CYAN}  $*${NC}"; echo -e "${CYAN}══════════════════════════════════════════${NC}\n"; }
err()    { echo -e "${RED}[✗]${NC} $*" >&2; }

# ── Defaults ────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(pwd)"
VAULT_DIR=""
IDE_TARGET="both"
OBSIDIAN_API_KEY=""
DETECTED_STACK=()
DETECTED_BUILD=""
DETECTED_LANGUAGE=""
DETECTED_FRAMEWORK=""

# ── Parse Arguments ─────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
    case $1 in
        --project-dir) PROJECT_DIR="$2"; shift 2 ;;
        --vault-dir)   VAULT_DIR="$2"; shift 2 ;;
        --ide)         IDE_TARGET="$2"; shift 2 ;;
        --api-key)     OBSIDIAN_API_KEY="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--project-dir PATH] [--vault-dir PATH] [--ide claude|cursor|both] [--api-key KEY]"
            exit 0 ;;
        *) err "Unknown option: $1"; exit 1 ;;
    esac
done

# ── OS Detection ────────────────────────────────────────────────────────────
detect_os() {
    header "Detecting Operating System"
    case "$(uname -s)" in
        Darwin*) OS="macos"; log "macOS detected ($(sw_vers -productVersion 2>/dev/null || echo 'unknown'))" ;;
        Linux*)  OS="linux"; log "Linux detected ($(lsb_release -ds 2>/dev/null || cat /etc/os-release 2>/dev/null | head -1 || echo 'unknown'))" ;;
        MINGW*|MSYS*|CYGWIN*) OS="windows"; log "Windows detected" ;;
        *) OS="unknown"; warn "Unknown OS: $(uname -s)" ;;
    esac
}

# ── Tech Stack Detection ───────────────────────────────────────────────────
detect_tech_stack() {
    header "Detecting Tech Stack"
    local dir="$PROJECT_DIR"

    # ── Language Detection ──
    # C/C++
    if ls "$dir"/*.cpp "$dir"/src/**/*.cpp "$dir"/**/*.cpp 2>/dev/null | head -1 >/dev/null 2>&1 || \
       [ -f "$dir/CMakeLists.txt" ] || [ -f "$dir/Makefile" ] || [ -f "$dir/meson.build" ]; then
        DETECTED_STACK+=("cpp")
        DETECTED_LANGUAGE="cpp"
        log "C/C++ detected"
    fi

    # Python
    if [ -f "$dir/requirements.txt" ] || [ -f "$dir/pyproject.toml" ] || [ -f "$dir/setup.py" ] || \
       [ -f "$dir/Pipfile" ] || [ -f "$dir/poetry.lock" ]; then
        DETECTED_STACK+=("python")
        [ -z "$DETECTED_LANGUAGE" ] && DETECTED_LANGUAGE="python"
        log "Python detected"
    fi

    # JavaScript/TypeScript
    if [ -f "$dir/package.json" ]; then
        DETECTED_STACK+=("javascript")
        [ -z "$DETECTED_LANGUAGE" ] && DETECTED_LANGUAGE="javascript"
        log "JavaScript/Node.js detected"
        if [ -f "$dir/tsconfig.json" ]; then
            DETECTED_STACK+=("typescript")
            DETECTED_LANGUAGE="typescript"
            log "TypeScript detected"
        fi
    fi

    # Rust
    if [ -f "$dir/Cargo.toml" ]; then
        DETECTED_STACK+=("rust")
        [ -z "$DETECTED_LANGUAGE" ] && DETECTED_LANGUAGE="rust"
        log "Rust detected"
    fi

    # Go
    if [ -f "$dir/go.mod" ]; then
        DETECTED_STACK+=("go")
        [ -z "$DETECTED_LANGUAGE" ] && DETECTED_LANGUAGE="go"
        log "Go detected"
    fi

    # Java/Kotlin
    if [ -f "$dir/pom.xml" ] || [ -f "$dir/build.gradle" ] || [ -f "$dir/build.gradle.kts" ]; then
        DETECTED_STACK+=("java")
        [ -z "$DETECTED_LANGUAGE" ] && DETECTED_LANGUAGE="java"
        log "Java/Kotlin detected"
    fi

    # Swift
    if [ -f "$dir/Package.swift" ] || ls "$dir"/*.xcodeproj 2>/dev/null | head -1 >/dev/null 2>&1; then
        DETECTED_STACK+=("swift")
        [ -z "$DETECTED_LANGUAGE" ] && DETECTED_LANGUAGE="swift"
        log "Swift detected"
    fi

    # ── Framework Detection ──
    # Qt/QML
    if grep -rq "find_package.*Qt" "$dir/CMakeLists.txt" 2>/dev/null || \
       ls "$dir"/**/*.qml "$dir"/src/**/*.qml 2>/dev/null | head -1 >/dev/null 2>&1; then
        DETECTED_STACK+=("qt" "qml")
        DETECTED_FRAMEWORK="qt"
        log "Qt/QML framework detected"
    fi

    # React
    if [ -f "$dir/package.json" ] && grep -q '"react"' "$dir/package.json" 2>/dev/null; then
        DETECTED_STACK+=("react")
        [ -z "$DETECTED_FRAMEWORK" ] && DETECTED_FRAMEWORK="react"
        log "React detected"
    fi

    # Next.js
    if [ -f "$dir/next.config.js" ] || [ -f "$dir/next.config.mjs" ] || [ -f "$dir/next.config.ts" ]; then
        DETECTED_STACK+=("nextjs")
        [ -z "$DETECTED_FRAMEWORK" ] && DETECTED_FRAMEWORK="nextjs"
        log "Next.js detected"
    fi

    # Vue
    if [ -f "$dir/package.json" ] && grep -q '"vue"' "$dir/package.json" 2>/dev/null; then
        DETECTED_STACK+=("vue")
        [ -z "$DETECTED_FRAMEWORK" ] && DETECTED_FRAMEWORK="vue"
        log "Vue.js detected"
    fi

    # Angular
    if [ -f "$dir/angular.json" ]; then
        DETECTED_STACK+=("angular")
        [ -z "$DETECTED_FRAMEWORK" ] && DETECTED_FRAMEWORK="angular"
        log "Angular detected"
    fi

    # Django
    if [ -f "$dir/manage.py" ] && grep -rq "django" "$dir" --include="*.txt" --include="*.toml" -l 2>/dev/null | head -1 >/dev/null 2>&1; then
        DETECTED_STACK+=("django")
        [ -z "$DETECTED_FRAMEWORK" ] && DETECTED_FRAMEWORK="django"
        log "Django detected"
    fi

    # FastAPI / Flask
    if grep -rq "fastapi\|FastAPI" "$dir" --include="*.py" --include="*.toml" --include="*.txt" -l 2>/dev/null | head -1 >/dev/null 2>&1; then
        DETECTED_STACK+=("fastapi")
        [ -z "$DETECTED_FRAMEWORK" ] && DETECTED_FRAMEWORK="fastapi"
        log "FastAPI detected"
    fi

    # ── Build System Detection ──
    if [ -f "$dir/CMakeLists.txt" ]; then DETECTED_BUILD="cmake"; log "CMake build system"; fi
    if [ -f "$dir/Makefile" ] && [ -z "$DETECTED_BUILD" ]; then DETECTED_BUILD="make"; log "Make build system"; fi
    if [ -f "$dir/package.json" ] && [ -z "$DETECTED_BUILD" ]; then DETECTED_BUILD="npm"; log "npm/yarn build system"; fi
    if [ -f "$dir/Cargo.toml" ] && [ -z "$DETECTED_BUILD" ]; then DETECTED_BUILD="cargo"; log "Cargo build system"; fi
    if [ -f "$dir/go.mod" ] && [ -z "$DETECTED_BUILD" ]; then DETECTED_BUILD="go"; log "Go build system"; fi

    # ── Specialty Libraries ──
    if grep -rq "gstreamer\|GStreamer\|gst_" "$dir" --include="*.cpp" --include="*.h" --include="*.cmake" -l 2>/dev/null | head -1 >/dev/null 2>&1; then
        DETECTED_STACK+=("gstreamer")
        log "GStreamer detected"
    fi

    if [ -d "$dir/mavlink" ] || grep -rq "mavlink\|MAVLink" "$dir" --include="*.cpp" --include="*.h" -l 2>/dev/null | head -1 >/dev/null 2>&1; then
        DETECTED_STACK+=("mavlink")
        log "MAVLink detected"
    fi

    if grep -rq "prisma\|Prisma" "$dir" --include="*.ts" --include="*.json" -l 2>/dev/null | head -1 >/dev/null 2>&1; then
        DETECTED_STACK+=("prisma")
        log "Prisma ORM detected"
    fi

    if [ -f "$dir/docker-compose.yml" ] || [ -f "$dir/docker-compose.yaml" ] || [ -f "$dir/Dockerfile" ]; then
        DETECTED_STACK+=("docker")
        log "Docker detected"
    fi

    # ── Summary ──
    if [ ${#DETECTED_STACK[@]} -eq 0 ]; then
        warn "No tech stack auto-detected. You'll be prompted for manual config."
        DETECTED_LANGUAGE="unknown"
    else
        log "Stack summary: ${DETECTED_STACK[*]}"
    fi
}

# ── Vault Setup ─────────────────────────────────────────────────────────────
setup_vault() {
    header "Setting Up Obsidian Vault"

    # Determine vault location
    if [ -z "$VAULT_DIR" ]; then
        local project_name=$(basename "$PROJECT_DIR")
        VAULT_DIR="$(dirname "$PROJECT_DIR")/${project_name}Vault"
        info "Vault location: $VAULT_DIR"
        read -p "Use this location? (Y/n/custom path): " vault_choice
        case "$vault_choice" in
            n|N) read -p "Enter vault path: " VAULT_DIR ;;
            ""|y|Y) ;; # use default
            *) VAULT_DIR="$vault_choice" ;;
        esac
    fi

    # Create vault structure
    mkdir -p "$VAULT_DIR"/{daily,decisions,bugs,analysis,weekly,guides,plans/{active,planning,legacy/{completed,superseded}},reference,workflows,templates,memory}

    log "Vault directories created"

    # Copy templates
    create_vault_templates

    # Create dashboards
    create_dashboards

    # Create vault symlink in project
    if [ ! -L "$PROJECT_DIR/vault" ] && [ ! -d "$PROJECT_DIR/vault" ]; then
        ln -sf "$VAULT_DIR" "$PROJECT_DIR/vault"
        log "Created vault symlink: $PROJECT_DIR/vault -> $VAULT_DIR"
    else
        warn "vault link/dir already exists, skipping symlink"
    fi

    # Add vault symlink to .gitignore
    if [ -f "$PROJECT_DIR/.gitignore" ]; then
        if ! grep -q "^vault$" "$PROJECT_DIR/.gitignore" 2>/dev/null; then
            echo "vault" >> "$PROJECT_DIR/.gitignore"
            log "Added 'vault' to .gitignore"
        fi
    fi
}

create_vault_templates() {
    info "Creating vault templates..."

    # Daily template
    cat > "$VAULT_DIR/templates/Daily.md" << 'TMPL'
---
title: "Daily Log - {{date}}"
type: daily
tags: [daily, {{branch-tag}}]
created: {{date}}
updated: {{date}}
branch: {{branch}}
---

# Daily Log - {{date}}

## Active Branch
- `{{branch}}`

## Sessions
<!-- Auto-populated by /doc agent -->

| Time | Persona | Task | Files | Outcome |
|------|---------|------|---------|---------|
<!-- New sessions appended below -->

---

## Decision Trail (Auto-Generated)
<!-- Thought process entries appended here by doc agent -->

---

## Learning & Decisions
<!-- User fills at end of day -->

## Blockers & Questions
<!-- Auto-populated when encountered -->

## Tomorrow's Focus
<!-- User fills at end of day -->
TMPL

    # Decision template
    cat > "$VAULT_DIR/templates/Decision.md" << 'TMPL'
---
title: "ADR: {{title}}"
type: decision
status: accepted
tags: [decision, adr, {{component-tags}}]
created: {{date}}
branch: {{branch}}
---

# ADR: {{title}}

## Context
{{context}}

## Decision
{{decision}}

## Alternatives Considered
{{alternatives}}

## Consequences
**Positive:** {{benefits}}
**Negative:** {{tradeoffs}}

## Implementation
{{implementation}}

## Related
- Daily: [[{{daily-note}}]]
TMPL

    # Bug template
    cat > "$VAULT_DIR/templates/Bug.md" << 'TMPL'
---
title: "{{title}}"
type: bug
status: {{status}}
severity: {{severity}}
tags: [bug, {{component-tags}}]
created: {{date}}
branch: {{branch}}
---

# {{title}}

## Discovered
- **Date:** {{timestamp}}
- **Persona:** {{persona}}
- **Branch:** `{{branch}}`

## Symptoms
{{symptoms}}

## Root Cause
{{root-cause}}

## Fix Applied
{{fix-description}}

## Verification
{{verification}}

## Related
- Daily: [[{{daily-note}}]]
TMPL

    # Weekly template
    cat > "$VAULT_DIR/templates/Weekly.md" << 'TMPL'
---
title: "Weekly Summary - Week {{week-number}}"
type: weekly
tags: [weekly, summary]
created: {{date}}
week: {{week-number}}
---

# Weekly Summary - Week {{week-number}}

## Week Overview
- **Dates:** {{start-date}} to {{end-date}}
- **Active Branch(es):** {{branches}}

## Work Completed

### Features & Implementations
{{features}}

### Bug Fixes
{{bugs}}

### Refactoring & Improvements
{{refactoring}}

### Analysis & Research
{{analysis}}

## Key Decisions
{{decisions}}

## Learning & Insights
{{learning}}

## Blockers & Challenges
{{blockers}}

## Next Week Focus
{{next-week}}

## Daily Notes
{{daily-links}}
TMPL

    # Plan template
    cat > "$VAULT_DIR/templates/Plan.md" << 'TMPL'
---
type: plan
title: "{{title}}"
status: active
category: ""
priority: p2
tags: [plan]
created: {{date}}
updated: {{date}}
branch: ""
---

# {{title}}

## Problem Statement
[What problem does this solve?]

## Solution Overview
[High-level approach]

## Success Criteria
- [ ]
- [ ]

## Related Plans
-

## References
-
TMPL

    # Analysis template
    cat > "$VAULT_DIR/templates/Analysis.md" << 'TMPL'
---
title: "{{title}}"
type: analysis
tags: [analysis]
created: {{date}}
updated: {{date}}
---

# {{title}}

## Investigation Target

## Findings

## Recommendations

## Evidence
TMPL

    log "Vault templates created"
}

create_dashboards() {
    cat > "$VAULT_DIR/dashboards.md" << 'TMPL'
---
title: "Project Dashboards"
type: dashboard
tags: [dashboard, dataview]
created: {{date}}
---

# Project Dashboards

## Active Plans

```dataview
TABLE status, priority, branch
FROM "plans/active"
WHERE type = "plan"
SORT priority ASC
```

## Recent Decisions

```dataview
TABLE created, branch, status
FROM "decisions"
SORT created DESC
LIMIT 10
```

## Bug Timeline

```dataview
TABLE created, branch, severity
FROM "bugs"
SORT created DESC
LIMIT 10
```

> [!TIP] Requires the **Dataview** plugin in Obsidian.
TMPL

    log "Dashboards created"
}

# ── Best Practices Guide Generation ────────────────────────────────────────
generate_best_practices() {
    header "Generating Best Practices Guides"

    # Always create a general guide
    create_general_guide

    # Stack-specific guides (guard against empty array under set -u)
    for tech in "${DETECTED_STACK[@]:-}"; do
        [ -z "$tech" ] && continue
        case "$tech" in
            cpp)        create_cpp_guide ;;
            python)     create_python_guide ;;
            typescript|javascript) create_js_ts_guide ;;
            rust)       create_rust_guide ;;
            go)         create_go_guide ;;
            qt|qml)     create_qt_qml_guide ;;
            react)      create_react_guide ;;
            nextjs)     create_nextjs_guide ;;
            vue)        create_vue_guide ;;
            gstreamer)  create_gstreamer_guide ;;
            docker)     create_docker_guide ;;
        esac
    done
}

create_general_guide() {
    cat > "$VAULT_DIR/guides/code_review_checklist.md" << 'GUIDE'
---
title: "Code Review Checklist"
type: guide
tags: [guide, review]
created: auto-generated
---

# Code Review Checklist

## Security
- [ ] No hardcoded secrets, API keys, or credentials
- [ ] User input validated at system boundaries
- [ ] No SQL/command/XSS injection vectors
- [ ] Authentication/authorization checks in place
- [ ] Sensitive data not logged

## Error Handling
- [ ] Error paths tested and handled gracefully
- [ ] No swallowed exceptions without logging
- [ ] Resources cleaned up on error (RAII, try/finally, defer)
- [ ] User-facing errors are informative but not leaky

## Performance
- [ ] No N+1 queries or unbounded loops
- [ ] Heavy operations are async/background where appropriate
- [ ] Caching considered for expensive operations
- [ ] No memory leaks in long-running paths

## Code Quality
- [ ] Functions do one thing
- [ ] No premature abstraction
- [ ] Names are clear and descriptive
- [ ] Comments explain "why", not "what"
- [ ] No dead code or commented-out blocks
GUIDE
    log "General code review guide created"
}

create_cpp_guide() {
    cat > "$VAULT_DIR/guides/cpp_best_practices.md" << 'GUIDE'
---
title: "C++ Best Practices"
type: guide
tags: [guide, cpp, memory]
created: auto-generated
---

# C++ Best Practices

## Memory Management
- **RAII everywhere**: Resources acquired in constructors, released in destructors
- **Smart pointers**: `std::unique_ptr` for exclusive ownership, `std::shared_ptr` only when truly shared
- **Avoid raw `new/delete`**: Use `std::make_unique` / `std::make_shared`
- **Rule of 5/0**: Either define all 5 special members or none (use defaults)

## Modern C++ (17+)
- Prefer `std::optional` over nullable pointers for optional values
- Use `std::string_view` for non-owning string references
- Structured bindings: `auto [key, value] = pair;`
- `if constexpr` for compile-time branching
- `[[nodiscard]]` on functions where ignoring return is a bug

## Threading
- Prefer `std::jthread` (C++20) or `std::thread` with proper join/detach
- Use `std::mutex` + `std::lock_guard` / `std::scoped_lock`
- Avoid `std::recursive_mutex` — it hides design problems
- Prefer `std::atomic` for simple shared state

## Common Pitfalls
- **Dangling references**: Don't return references to locals
- **Iterator invalidation**: Modifying containers during iteration
- **Object slicing**: Passing derived by value to base parameter
- **Undefined behavior**: Signed overflow, null deref, out-of-bounds access

## Debugging
```bash
# Address Sanitizer
cmake -DCMAKE_CXX_FLAGS="-fsanitize=address -fno-omit-frame-pointer" ..

# Thread Sanitizer
cmake -DCMAKE_CXX_FLAGS="-fsanitize=thread" ..

# Valgrind (Linux)
valgrind --leak-check=full --track-origins=yes ./build/MyApp
```
GUIDE
    log "C++ best practices guide created"
}

create_python_guide() {
    cat > "$VAULT_DIR/guides/python_best_practices.md" << 'GUIDE'
---
title: "Python Best Practices"
type: guide
tags: [guide, python]
created: auto-generated
---

# Python Best Practices

## Project Structure
- Use `pyproject.toml` for project metadata (PEP 621)
- Virtual environments: `python -m venv .venv` or use `uv`
- Pin dependencies with lock files (`uv.lock`, `poetry.lock`, `requirements.txt`)

## Code Quality
- Type hints on all public functions: `def process(data: list[str]) -> bool:`
- Use `dataclasses` or `pydantic` for structured data, not raw dicts
- Prefer `pathlib.Path` over `os.path`
- Use `logging` module, not `print()` for debugging
- Context managers (`with`) for all resource management

## Error Handling
- Catch specific exceptions, never bare `except:`
- Use custom exception hierarchies for domain errors
- `raise ... from err` to preserve exception chains

## Testing
```bash
pytest tests/                    # Run all
pytest -x                        # Stop on first failure
pytest -k "test_name"            # Run specific test
pytest --cov=src --cov-report=html  # Coverage
```

## Performance
- Profile first: `python -m cProfile -s cumtime script.py`
- Use generators for large datasets
- `functools.lru_cache` for expensive pure functions
- Consider `asyncio` for I/O-bound, `multiprocessing` for CPU-bound

## Linting & Formatting
```bash
ruff check .                     # Lint
ruff format .                    # Format
mypy src/                        # Type checking
```
GUIDE
    log "Python best practices guide created"
}

create_js_ts_guide() {
    cat > "$VAULT_DIR/guides/js_ts_best_practices.md" << 'GUIDE'
---
title: "JavaScript/TypeScript Best Practices"
type: guide
tags: [guide, javascript, typescript]
created: auto-generated
---

# JavaScript/TypeScript Best Practices

## TypeScript Specifics
- Enable `strict: true` in `tsconfig.json`
- Prefer `interface` for object shapes, `type` for unions/intersections
- Use `unknown` over `any` — force type narrowing
- Avoid `enum` — use `as const` objects instead
- Use `satisfies` operator for type-safe object literals

## Async Patterns
- Always `await` or return promises — never fire-and-forget
- Use `Promise.all()` for independent parallel operations
- Handle errors with try/catch in async functions
- Avoid mixing callbacks and promises

## Error Handling
- Use custom Error classes: `class AppError extends Error {}`
- Always include `cause` in re-thrown errors: `throw new Error('msg', { cause: err })`
- Validate at boundaries (API input, env vars), trust internally

## Testing
```bash
npm test                         # Run all tests
npx vitest --reporter=verbose    # Vitest with detail
npx jest --coverage              # Jest with coverage
```

## Performance
- Avoid unnecessary re-renders (React: `memo`, `useMemo`, `useCallback`)
- Lazy load routes and heavy components
- Use `Map`/`Set` for frequent lookups instead of arrays
- Debounce/throttle event handlers

## Code Quality
- Prefer `const` over `let`, never `var`
- Destructure early: `const { name, age } = user`
- Small, focused functions (< 30 lines)
- Barrel exports (`index.ts`) only at package boundaries
GUIDE
    log "JS/TS best practices guide created"
}

create_rust_guide() {
    cat > "$VAULT_DIR/guides/rust_best_practices.md" << 'GUIDE'
---
title: "Rust Best Practices"
type: guide
tags: [guide, rust]
created: auto-generated
---

# Rust Best Practices

## Ownership & Borrowing
- Prefer borrowing (`&T`, `&mut T`) over cloning
- Use `Clone` only when semantically meaningful
- Understand the difference: `&str` (borrowed) vs `String` (owned)
- Use `Cow<'_, str>` when you might or might not need to allocate

## Error Handling
- Use `thiserror` for library errors, `anyhow` for application errors
- Prefer `?` operator over manual `match` on Result
- Never `unwrap()` in production code — use `expect("reason")` at minimum
- Custom error types for each module

## Performance
- Prefer iterators over manual loops (zero-cost abstraction)
- Use `#[inline]` sparingly — let the compiler decide
- Profile with `cargo flamegraph` or `perf`
- `cargo bench` with criterion for microbenchmarks

## Testing
```bash
cargo test                       # All tests
cargo test -- --nocapture        # Show println output
cargo test test_name             # Specific test
cargo clippy                     # Lint
```
GUIDE
    log "Rust best practices guide created"
}

create_go_guide() {
    cat > "$VAULT_DIR/guides/go_best_practices.md" << 'GUIDE'
---
title: "Go Best Practices"
type: guide
tags: [guide, go]
created: auto-generated
---

# Go Best Practices

## Error Handling
- Always check errors: `if err != nil { return fmt.Errorf("context: %w", err) }`
- Wrap errors with `%w` for unwrapping, `%v` for opaque
- Use sentinel errors (`var ErrNotFound = errors.New(...)`) for expected conditions
- Use custom error types for rich error info

## Concurrency
- "Don't communicate by sharing memory; share memory by communicating" (channels)
- Use `sync.WaitGroup` for fan-out/fan-in
- Always `defer mu.Unlock()` right after `mu.Lock()`
- Use `context.Context` for cancellation and timeouts

## Testing
```bash
go test ./...                    # All tests
go test -v -run TestName         # Specific test
go test -race ./...              # Race detector
go test -cover ./...             # Coverage
```

## Code Quality
- `gofmt` / `goimports` for formatting (non-negotiable)
- `golangci-lint run` for comprehensive linting
- Keep interfaces small (1-3 methods)
- Accept interfaces, return structs
GUIDE
    log "Go best practices guide created"
}

create_qt_qml_guide() {
    cat > "$VAULT_DIR/guides/qt_qml_best_practices.md" << 'GUIDE'
---
title: "Qt/QML Best Practices"
type: guide
tags: [guide, qt, qml, cpp]
created: auto-generated
---

# Qt/QML Best Practices

## C++ ↔ QML Integration
- Register C++ types via `qmlRegisterSingletonType` or `QML_ELEMENT`
- Use `Q_PROPERTY` with `NOTIFY` signals for reactive bindings
- Use `Q_INVOKABLE` for callable methods from QML
- Set `QQmlEngine::setObjectOwnership()` explicitly at transfer points

## QML Component Design
- **Atoms**: Basic elements (buttons, inputs) — no business logic
- **Molecules**: Composed atoms (form fields, card items)
- **Organisms**: Full features (settings panel, video player)
- Mark derived properties as `readonly`
- Use explicit types, avoid `var` for known types

## Signals & Slots
- Prefer declarative connections (`onSignalName:`) over `Connections {}`
- Use `Qt.callLater()` to batch rapid signal emissions
- Never emit signals in destructors
- Use `BlockingQueuedConnection` only when absolutely necessary (deadlock risk)

## Performance
- Use `Loader {}` for conditionally shown heavy components
- Set `ListView.cacheBuffer` and enable `reuseItems` (Qt 6.6+)
- Minimize binding reevaluations — avoid complex JS in bindings
- Use `ShaderEffectSource` sparingly

## Memory Management
- Qt parent-child ownership: parent deletes children
- Use `QScopedPointer` or `std::unique_ptr` for non-QObject resources
- Use `QPointer` for guarded references to QObjects
- Always `deleteLater()` for cross-thread deletion
- Never mix `delete` with Qt's parent-child system

## Thread Safety
- GUI operations MUST happen on main thread
- Use `QMetaObject::invokeMethod(obj, &Obj::method, Qt::QueuedConnection)` for cross-thread calls
- Use `QMutex` + `QMutexLocker` for shared state
GUIDE
    log "Qt/QML best practices guide created"
}

create_react_guide() {
    cat > "$VAULT_DIR/guides/react_best_practices.md" << 'GUIDE'
---
title: "React Best Practices"
type: guide
tags: [guide, react, javascript, typescript]
created: auto-generated
---

# React Best Practices

## Component Design
- Prefer function components with hooks
- Keep components small (< 150 lines)
- Lift state to lowest common ancestor
- Use composition over prop drilling (Context, compound components)

## State Management
- `useState` for local state
- `useReducer` for complex state logic
- Context for cross-cutting concerns (theme, auth, locale)
- External store (Zustand, Jotai) for global shared state

## Performance
- `React.memo()` for expensive pure components
- `useMemo` / `useCallback` only when you have measured a problem
- Lazy load routes: `React.lazy(() => import('./Page'))`
- Virtualize long lists (`react-window`, `@tanstack/react-virtual`)

## Hooks Rules
- Never call hooks conditionally or in loops
- Custom hooks for reusable logic: `useDebounce`, `useLocalStorage`
- Always include proper deps in `useEffect` dependency arrays
- Clean up side effects: return cleanup function from `useEffect`

## Testing
```bash
npx vitest                       # Run tests
npx vitest --coverage            # With coverage
```
- Use React Testing Library, test behavior not implementation
- `screen.getByRole()` > `screen.getByTestId()`
GUIDE
    log "React best practices guide created"
}

create_nextjs_guide() {
    cat > "$VAULT_DIR/guides/nextjs_best_practices.md" << 'GUIDE'
---
title: "Next.js Best Practices"
type: guide
tags: [guide, nextjs, react, typescript]
created: auto-generated
---

# Next.js Best Practices

## App Router (v13+)
- Default to Server Components — add `'use client'` only when needed
- Use `loading.tsx` for Suspense boundaries
- Use `error.tsx` for error boundaries
- Colocate: `page.tsx`, `layout.tsx`, `loading.tsx`, `error.tsx` per route

## Data Fetching
- Server Components: `async function Page()` with direct DB/API calls
- Client Components: TanStack Query or SWR for client-side fetching
- Use `revalidatePath()` / `revalidateTag()` for cache invalidation
- Prefer Server Actions over API routes for mutations

## Performance
- Use `next/image` for all images (automatic optimization)
- Use `next/font` for font loading
- Dynamic imports for heavy client components
- Edge runtime for lightweight API routes

## Security
- Validate all Server Action inputs with Zod
- Use `headers()` / `cookies()` only in server context
- Never expose API keys in client components
GUIDE
    log "Next.js best practices guide created"
}

create_vue_guide() {
    cat > "$VAULT_DIR/guides/vue_best_practices.md" << 'GUIDE'
---
title: "Vue.js Best Practices"
type: guide
tags: [guide, vue, javascript, typescript]
created: auto-generated
---

# Vue.js Best Practices

## Composition API
- Prefer `<script setup>` syntax
- Use `ref()` for primitives, `reactive()` for objects
- Extract reusable logic into composables (`use*.ts`)
- Use `computed()` instead of methods for derived state

## Component Design
- Props down, events up
- Use `defineProps<{ ... }>()` with TypeScript
- Use `defineEmits<{ ... }>()` for typed events
- Slots for flexible content projection

## State Management
- Pinia for global state
- Composables for shared logic without global state
- `provide` / `inject` for dependency injection in component trees

## Performance
- `v-once` for static content
- `v-memo` for expensive list items
- Lazy load routes with dynamic `import()`
- Use `shallowRef` / `shallowReactive` when deep reactivity not needed
GUIDE
    log "Vue.js best practices guide created"
}

create_gstreamer_guide() {
    cat > "$VAULT_DIR/guides/gstreamer_best_practices.md" << 'GUIDE'
---
title: "GStreamer Best Practices"
type: guide
tags: [guide, gstreamer, cpp, media]
created: auto-generated
---

# GStreamer Best Practices

## Pipeline Design
- Use `queue` elements between thread boundaries
- Set `max-size-buffers=1, leaky=2` on queues for low latency
- Use `tee` + `queue` for branching pipelines
- Always handle `GST_MESSAGE_ERROR` and `GST_MESSAGE_EOS` on the bus

## Reference Counting
| Function | Returns | Must Cleanup |
|----------|---------|-------------|
| `gst_element_factory_make()` | floating ref | sinks on bin add |
| `gst_bin_get_by_name()` | ref'd element | `gst_object_unref()` |
| `gst_element_get_bus()` | ref'd bus | `gst_object_unref()` |
| `gst_pad_get_current_caps()` | ref'd caps | `gst_caps_unref()` |
| `gst_sample_get_buffer()` | unref'd buffer | do NOT unref |

## State Management
- State changes: NULL → READY → PAUSED → PLAYING
- Always check return of `gst_element_set_state()` (can be ASYNC)
- Never change state from streaming thread callbacks
- Use `gst_element_get_state()` with timeout to wait for transitions

## Debugging
```bash
export GST_DEBUG=4                              # General debug
export GST_DEBUG=*category*:5                   # Specific category
export GST_DEBUG_DUMP_DOT_DIR=/tmp/dots         # Pipeline graph
dot -Tpng /tmp/dots/file.dot -o pipeline.png    # Visualize
```

## Common Pitfalls
- Destroying pipeline while decoder threads hold mutexes → deadlock
- Missing `gst_buffer_unmap()` after `gst_buffer_map()`
- Bus watch not removed before pipeline destruction
- Pad probes not removed on cleanup
GUIDE
    log "GStreamer best practices guide created"
}

create_docker_guide() {
    cat > "$VAULT_DIR/guides/docker_best_practices.md" << 'GUIDE'
---
title: "Docker Best Practices"
type: guide
tags: [guide, docker, devops]
created: auto-generated
---

# Docker Best Practices

## Dockerfile
- Use multi-stage builds to minimize image size
- Pin base image versions: `node:20-alpine`, not `node:latest`
- Order layers by change frequency (deps before code)
- Use `.dockerignore` to exclude node_modules, .git, build artifacts
- Run as non-root user: `USER node`

## Compose
- Use named volumes for persistent data
- Set resource limits: `mem_limit`, `cpus`
- Use healthchecks for service dependencies
- Use profiles for dev/test/prod variations
GUIDE
    log "Docker best practices guide created"
}

# ── Claude Code Setup ──────────────────────────────────────────────────────
setup_claude_code() {
    header "Setting Up Claude Code"

    # Create .claude/commands/ directory
    mkdir -p "$PROJECT_DIR/.claude/commands"
    mkdir -p "$PROJECT_DIR/.claude/scripts"

    # Generate CLAUDE.md
    generate_claude_md

    # Generate personas (copied from kit templates, structural placeholders substituted)
    generate_personas

    # Generate subagent metadata for forked-context skills
    generate_agents

    # Install hook scripts + helper scripts
    generate_hooks

    # Generate settings.local.json (permissions + hooks wiring)
    generate_settings

    # Generate doc_watcher.sh (legacy auto-doc shim)
    generate_doc_watcher

    # Generate token_strategy.md
    generate_token_strategy

    # Configure MCP servers
    configure_mcp_claude

    log "Claude Code setup complete"
}

generate_claude_md() {
    info "Generating CLAUDE.md..."

    local project_name=$(basename "$PROJECT_DIR")
    local build_cmd=""
    local test_cmd=""

    # Determine build/test commands
    case "$DETECTED_BUILD" in
        cmake) build_cmd="cmake -B build && cmake --build build"
               test_cmd="cd build && ctest --output-on-failure" ;;
        npm)   build_cmd="npm run build"
               test_cmd="npm test" ;;
        cargo) build_cmd="cargo build"
               test_cmd="cargo test" ;;
        go)    build_cmd="go build ./..."
               test_cmd="go test ./..." ;;
        make)  build_cmd="make"
               test_cmd="make test" ;;
        *)     build_cmd="# TODO: Set your build command"
               test_cmd="# TODO: Set your test command" ;;
    esac

    # Build tech stack line
    local stack_line=""
    for tech in "${DETECTED_STACK[@]:-}"; do
        [ -z "$tech" ] && continue
        stack_line+="$tech, "
    done
    stack_line="${stack_line%, }"
    [ -z "$stack_line" ] && stack_line="(detect or set manually)"

    # Build guides reference table
    local guides_table=""
    for guide in "$VAULT_DIR/guides/"*.md; do
        [ -f "$guide" ] || continue
        local guide_name=$(basename "$guide" .md)
        local guide_title=$(head -5 "$guide" | grep "^title:" | sed 's/title: *"*\(.*\)"*/\1/')
        guides_table+="| [\`vault/guides/${guide_name}.md\`](vault/guides/${guide_name}.md) | ${guide_title} |
"
    done

    cat > "$PROJECT_DIR/CLAUDE.md" << CLAUDE_EOF
# CLAUDE.md

This file provides guidance to Claude Code when working with code in this repository.

## Project Overview

**Project:** ${project_name}
**Tech Stack:** ${stack_line}
**Language:** ${DETECTED_LANGUAGE}
**Framework:** ${DETECTED_FRAMEWORK:-none}
**Build System:** ${DETECTED_BUILD:-unknown}

## Agent Selection (Default Behavior)

When user requests work without specifying an agent, select the appropriate agent directly:

| Request Pattern | Agent | Default Model (if Task) |
|----------------|-------|------------------------|
| Implement/add feature | /implementer | sonnet |
| Fix bug/crash/error | /implementer | sonnet |
| Code review | /reviewer | haiku |
| Explain/teach concept | /mentor | - (main conv) |
| Refactor decision | /pragmatist | - (main conv) |
| Gather evidence/research | /investigator | haiku |
| Complex multi-domain (3+ specialists) | /orchestrator | - (dispatcher) |

**Do NOT auto-invoke for:** Simple questions, direct agent requests, basic file operations, clarifications.

**Model override:** Pass \`--use-opus\` flag to any skill to force all Task subagents to use Opus.

## Build Commands

\`\`\`bash
# Build
${build_cmd}

# Test
${test_cmd}
\`\`\`

## Documentation Practices

**IMPORTANT:** All project documentation lives in the Obsidian vault at \`$(realpath --relative-to="$PROJECT_DIR" "$VAULT_DIR" 2>/dev/null || echo "../${project_name}Vault")/\` (accessible via \`vault/\` symlink from the project root).

**When creating or updating documentation:**
- Write all \`.md\` files directly to the vault in the appropriate subfolder
- Use YAML frontmatter with \`type\`, \`tags\`, \`created\`, and \`updated\` fields (see \`vault/templates/\`)
- Use Obsidian wikilinks \`[[filename]]\` for cross-references within the vault
- Use Obsidian callouts (\`> [!WARNING]\`, \`> [!NOTE]\`, \`> [!TIP]\`) for important notes

**Vault structure:**
- \`vault/daily/\` — Daily dev logs (auto-populated)
- \`vault/decisions/\` — Architecture Decision Records
- \`vault/bugs/\` — Bug reports
- \`vault/analysis/\` — Investigations and post-mortems
- \`vault/guides/\` — Best practices (auto-generated for your stack)
- \`vault/plans/\` — Design documents (\`active/\`, \`planning/\`, \`legacy/\`)
- \`vault/weekly/\` — Weekly summaries

## Best Practices

Read the relevant guide before implementing or reviewing code in that area.

| Guide | Covers |
|-------|--------|
${guides_table}

## Token Preservation Strategy

**CRITICAL: Agents are expensive. Direct tools are free.**

- **Use Grep/Glob/Read directly** for ALL code searches — each Task agent costs 30-40k tokens minimum
- **ONLY use agents for synthesis/judgment** over data you already gathered
- **Max budget:** ~5-7k tokens per agent, ~20k total for multi-agent work
- See \`.claude/token_strategy.md\` for full guidelines

## Standard Skill Workflows

### Context Initialization (Phase 0)
All skills begin by loading relevant context:
1. Check current branch: \`git branch --show-current\`
2. Search vault by branch name using \`obsidian_global_search\`
3. Read the most relevant results
4. Review active plans if task touches architecture

### Documentation Handoff (Final Phase)
All skills end by writing context_stream.json:
1. Build \`.claude/{branch}/context_stream.json\` with session data
2. Set status to "complete"
3. doc_watcher.sh handles all vault writes
4. Return to user immediately
CLAUDE_EOF

    log "CLAUDE.md generated"
}

generate_token_strategy() {
    cat > "$PROJECT_DIR/.claude/token_strategy.md" << 'STRATEGY'
# Token Preservation Strategy

## CRITICAL: Agents Are Expensive, Direct Tools Are Free

Each Task agent costs 30-40k tokens minimum. Direct tools cost ~0.

### The Rule
1. **NEVER spawn an agent to find code, read files, or search patterns** — use Grep/Glob/Read
2. **ONLY spawn agents for reasoning/synthesis** over data you already gathered
3. **If you must use agents**, keep prompts to 1-2 sentences
4. **Budget:** ~5-7k tokens per agent, ~20k total for multi-agent work

### Investigation Workflow (Correct)
```
Step 1: Grep for pattern → get file:line locations        (0 tokens)
Step 2: Read specific lines with offset/limit             (0 tokens)
Step 3: Synthesize yourself                               (0 tokens)
Step 4: ONLY IF complex reasoning needed → 1 agent        (~5k tokens)
```

### Anti-Patterns (NEVER DO)
- "Gather ALL references about X" → agent reads 30+ files
- "Map ALL lifecycle code" → agent reads entire directory
- Spawning 3+ agents in parallel for investigation

### Good Patterns
- Skip agents entirely — grep + read + your own analysis
- If agent needed: tight 1-2 sentence prompt, specific question
STRATEGY
    log "Token strategy created"
}

generate_personas() {
    info "Generating persona files from kit templates..."

    local src_dir="$SCRIPT_DIR/templates/personas"
    local dst_dir="$PROJECT_DIR/.claude/commands"

    if [ ! -d "$src_dir" ]; then
        err "Persona templates not found at $src_dir"
        return 1
    fi

    mkdir -p "$dst_dir"

    # Resolve build command for substitution
    local build_cmd=""
    case "$DETECTED_BUILD" in
        cmake) build_cmd="cmake -B build && cmake --build build" ;;
        npm)   build_cmd="npm run build" ;;
        cargo) build_cmd="cargo build" ;;
        go)    build_cmd="go build ./..." ;;
        make)  build_cmd="make" ;;
        *)     build_cmd="# TODO: set your build command" ;;
    esac

    local vault_name
    vault_name=$(basename "$VAULT_DIR")

    # Copy + substitute structural placeholders. Persona-flavor placeholders
    # ({{PERSONA_DESCRIPTION}}, expertise/safety areas, file patterns) stay
    # as TODO markers for the user to fill.
    local persona
    for persona in "$src_dir"/*.md; do
        local name
        name=$(basename "$persona")
        # domain-skill.md is a template, not a default persona — skip
        [ "$name" = "domain-skill.md" ] && continue

        sed \
            -e "s|{{IMPLEMENTER_NAME}}|implementer|g" \
            -e "s|{{INVESTIGATOR_NAME}}|investigator|g" \
            -e "s|{{REVIEWER_NAME}}|reviewer|g" \
            -e "s|{{SAFETY_NAME}}|safety|g" \
            -e "s|{{PERFORMANCE_NAME}}|performance|g" \
            -e "s|{{CRASH_NAME}}|crash|g" \
            -e "s|{{MENTOR_NAME}}|mentor|g" \
            -e "s|{{PRAGMATIST_NAME}}|pragmatist|g" \
            -e "s|{{ORCHESTRATOR_NAME}}|orchestrator|g" \
            -e "s|{{DESIGN_NAME}}|design|g" \
            -e "s|{{DOMAIN_NAME}}|domain|g" \
            -e "s|{{VAULT_NAME}}|${vault_name}|g" \
            -e "s|{{BUILD_COMMAND}}|${build_cmd}|g" \
            "$persona" > "$dst_dir/$name"
    done

    # Also copy the domain-skill template as a starter user can rename
    cp "$src_dir/domain-skill.md" "$dst_dir/domain-skill.md.template"

    log "All persona files created in .claude/commands/ ($(ls "$dst_dir"/*.md 2>/dev/null | wc -l | tr -d ' ') files)"
}

generate_hooks() {
    info "Installing hook scripts..."

    local src_dir="$SCRIPT_DIR/templates/scripts"
    local hooks_dst="$PROJECT_DIR/.claude/hooks"
    local scripts_dst="$PROJECT_DIR/.claude/scripts"

    if [ ! -d "$src_dir" ]; then
        err "Script templates not found at $src_dir"
        return 1
    fi

    mkdir -p "$hooks_dst" "$scripts_dst"

    local vault_name
    vault_name=$(basename "$VAULT_DIR")

    # Hook scripts (event-triggered)
    local hook
    for hook in _common.sh session_context.sh track_modified.sh on_commit.sh \
                session_cleanup.sh lint_on_edit.sh lint_precommit.sh \
                enforce_task_tests.sh on_agent_stop.sh pre_compact.sh; do
        if [ -f "$src_dir/$hook" ]; then
            sed "s|{{VAULT_NAME}}|${vault_name}|g" "$src_dir/$hook" > "$hooks_dst/$hook"
            chmod +x "$hooks_dst/$hook"
        fi
    done

    # Helper scripts (sourced/invoked, not event-triggered)
    if [ -f "$src_dir/skill_context.sh" ]; then
        sed "s|{{VAULT_NAME}}|${vault_name}|g" "$src_dir/skill_context.sh" > "$scripts_dst/skill_context.sh"
        chmod +x "$scripts_dst/skill_context.sh"
    fi

    log "Hooks installed in .claude/hooks/ ($(ls "$hooks_dst"/*.sh 2>/dev/null | wc -l | tr -d ' ') scripts)"
}

generate_agents() {
    info "Generating subagent metadata for forked-context skills..."

    local dst_dir="$PROJECT_DIR/.claude/agents"
    mkdir -p "$dst_dir"

    # The five personas that use context: fork need matching agent files
    local agent model_for cap
    for agent in implementer investigator reviewer safety performance; do
        if [ "$agent" = "implementer" ]; then model_for="sonnet"; else model_for="haiku"; fi
        # Capitalize first letter (bash 3 compatible — no ${var^} syntax)
        cap="$(echo "${agent:0:1}" | tr '[:lower:]' '[:upper:]')${agent:1}"
        cat > "$dst_dir/${agent}.md" <<EOF
---
name: ${agent}
description: ${agent} subagent — runs in forked context, returns structured findings
model: ${model_for}
memory: project
skills:
  - ${agent}
---

# ${cap} (Agent)

Subagent definition for the \`/${agent}\` skill. The Task tool consumes this
metadata when the orchestrator spawns ${agent} as part of a multi-agent run.

The persona body lives in the matching skill file at
\`.claude/commands/${agent}.md\`. This file only carries model + memory + skill
references; it deliberately does not duplicate the persona prompt.
EOF
    done

    log "Subagent metadata created in .claude/agents/ ($(ls "$dst_dir"/*.md 2>/dev/null | wc -l | tr -d ' ') files)"
}

generate_settings() {
    info "Generating .claude/settings.local.json..."

    local dst="$PROJECT_DIR/.claude/settings.local.json"
    local vault_name
    vault_name=$(basename "$VAULT_DIR")
    local vault_abs
    vault_abs=$(cd "$VAULT_DIR" 2>/dev/null && pwd) || vault_abs="$VAULT_DIR"

    # Per-stack build/test permission lines
    local build_perm=""
    local test_perm=""
    case "$DETECTED_BUILD" in
        cmake) build_perm='"Bash(cmake:*)",'; test_perm='"Bash(ctest:*)",' ;;
        npm)   build_perm='"Bash(npm run build:*)",'; test_perm='"Bash(npm test:*)", "Bash(npx:*)",' ;;
        cargo) build_perm='"Bash(cargo build:*)",'; test_perm='"Bash(cargo test:*)",' ;;
        go)    build_perm='"Bash(go build:*)",'; test_perm='"Bash(go test:*)",' ;;
        make)  build_perm='"Bash(make:*)",'; test_perm='"Bash(make test:*)",' ;;
        *)     build_perm=''; test_perm='' ;;
    esac

    cat > "$dst" <<EOF
{
  "permissions": {
    "allow": [
      "Bash(ls:*)",
      "Bash(git log:*)",
      "Bash(git checkout:*)",
      "Bash(git mv:*)",
      "Bash(tree:*)",
      "Bash(find:*)",
      "Bash(grep:*)",
      "Bash(cat:*)",
      "Bash(test:*)",
      "Bash(sed:*)",
      "Bash(date:*)",
      "Bash(chmod:*)",
      "Bash(wc:*)",
      "Bash(obsidian:*)",
      ${build_perm}
      ${test_perm}
      "mcp__obsidian__*",
      "mcp__git__*",
      "Write(${vault_abs}/*)",
      "StrReplace(${vault_abs}/*)",
      "Task(*)",
      "WebSearch",
      "Skill(pragmatist)",
      "Skill(investigator)"
    ],
    "additionalDirectories": [
      "${vault_abs}"
    ]
  },
  "enableAllProjectMcpServers": false,
  "enabledMcpjsonServers": [],
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          { "type": "command", "command": "\"\$CLAUDE_PROJECT_DIR\"/.claude/hooks/session_context.sh", "timeout": 3 }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Edit|Write|mcp__obsidian__obsidian_update_note|mcp__obsidian__obsidian_append_note",
        "hooks": [
          { "type": "command", "command": "\"\$CLAUDE_PROJECT_DIR\"/.claude/hooks/track_modified.sh", "timeout": 5, "async": true }
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          { "type": "command", "command": "\"\$CLAUDE_PROJECT_DIR\"/.claude/hooks/lint_on_edit.sh", "timeout": 30 }
        ]
      },
      {
        "matcher": "mcp__git__git_commit",
        "hooks": [
          { "type": "command", "command": "\"\$CLAUDE_PROJECT_DIR\"/.claude/hooks/on_commit.sh", "timeout": 10, "async": true }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "mcp__git__git_commit",
        "hooks": [
          { "type": "command", "command": "\"\$CLAUDE_PROJECT_DIR\"/.claude/hooks/lint_precommit.sh", "timeout": 120 }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": "\"\$CLAUDE_PROJECT_DIR\"/.claude/hooks/enforce_task_tests.sh", "timeout": 5 }
        ]
      }
    ],
    "PreCompact": [
      {
        "matcher": "auto",
        "hooks": [
          { "type": "command", "command": "\"\$CLAUDE_PROJECT_DIR\"/.claude/hooks/pre_compact.sh", "timeout": 5, "async": true }
        ]
      }
    ],
    "SubagentStop": [
      {
        "matcher": "implementer|reviewer|investigator|safety|performance",
        "hooks": [
          { "type": "command", "command": "\"\$CLAUDE_PROJECT_DIR\"/.claude/hooks/on_agent_stop.sh", "timeout": 5, "async": true }
        ]
      }
    ],
    "SessionEnd": [
      {
        "hooks": [
          { "type": "command", "command": "\"\$CLAUDE_PROJECT_DIR\"/.claude/hooks/session_cleanup.sh", "timeout": 5 }
        ]
      }
    ]
  }
}
EOF

    # Strip empty permission lines that may result from no build/test detection
    if command -v python3 &>/dev/null; then
        python3 -c "
import json, sys
with open('$dst') as f:
    data = json.load(f)
data['permissions']['allow'] = [p for p in data['permissions']['allow'] if p.strip() and p != '']
with open('$dst', 'w') as f:
    json.dump(data, f, indent=2)
" 2>/dev/null || true
    fi

    log "settings.local.json generated"
}

generate_doc_watcher() {
    cat > "$PROJECT_DIR/.claude/scripts/doc_watcher.sh" << WATCHER
#!/bin/bash
# doc_watcher.sh - Background watcher for context streaming documentation
set -euo pipefail

POLL_INTERVAL=0.5
TIMEOUT=300
VAULT="${VAULT_DIR}"

BRANCH=\$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")
CONTEXT_FILE=".claude/\${BRANCH}/context_stream.json"
COMPLETE_MARKER=".claude/\${BRANCH}/doc_complete"

mkdir -p ".claude/\${BRANCH}"

log() { echo "[doc_watcher \$(date '+%H:%M:%S')] \$*" >> ".claude/\${BRANCH}/doc_watcher.log"; }
log "Started watching \${CONTEXT_FILE}"

DAILY_NOTE_READY=false
START_TIME=\$(date +%s)

ensure_daily_note() {
    local today="\$1" branch="\$2"
    local daily_note="\${VAULT}/daily/\${today}.md"
    [ -f "\$daily_note" ] && { DAILY_NOTE_READY=true; return 0; }

    if [ -f "\${VAULT}/templates/Daily.md" ]; then
        sed -e "s/{{date}}/\${today}/g" -e "s/{{branch}}/\${branch}/g" -e "s/{{branch-tag}}/\${branch}/g" \\
            "\${VAULT}/templates/Daily.md" > "\$daily_note"
    else
        cat > "\$daily_note" << EOF
---
title: "Daily Log - \${today}"
type: daily
tags: [daily, \${branch}]
created: \${today}
branch: \${branch}
---
# Daily Log - \${today}
## Sessions
| Time | Persona | Task | Files | Outcome |
|------|---------|------|-------|---------|
<!-- New sessions appended below -->
---
## Decision Trail (Auto-Generated)
<!-- Thought process entries appended here by doc agent -->
EOF
    fi
    DAILY_NOTE_READY=true
    log "Daily note created"
}

auto_tag() {
    local context_file="\$1" note_path="\$2"
    local all_files=\$(jq -r '[.incremental_updates[]?.files_modified[]?] | unique | .[]' "\$context_file" 2>/dev/null || echo "")
    [ -z "\$all_files" ] && return 0
    # Auto-tagging by file path — extend the case patterns for your project structure
    log "Auto-tagging from modified files"
}

finalize_documentation() {
    local context_file="\$1"
    local persona=\$(jq -r '.persona // "unknown"' "\$context_file")
    local task_type=\$(jq -r '.task_type // "implement"' "\$context_file")
    local ts_complete=\$(jq -r '.timestamp_complete // empty' "\$context_file")
    local branch=\$(jq -r '.branch // "unknown"' "\$context_file")
    local today="\${ts_complete%% *}" time="\${ts_complete##* }"
    local daily_note="\${VAULT}/daily/\${today}.md"

    ensure_daily_note "\$today" "\$branch"

    local title=\$(jq -r '.specialized_note.title // empty' "\$context_file")
    local files=\$(jq -r '[.incremental_updates[]?.files_modified[]?] | unique | join(", ")' "\$context_file" 2>/dev/null || echo "")

    # Append session row
    local session_row="| \${time} | \${persona} | \${title} | \${files} | success |"
    if grep -q "<!-- New sessions appended below -->" "\$daily_note" 2>/dev/null; then
        sed -i'' -e "/<!-- New sessions appended below -->/a\\\\
\${session_row}
" "\$daily_note"
    fi

    # Create specialized note if title present
    if [ -n "\$title" ]; then
        local note_type="decision"
        [ "\$task_type" = "fix" ] && note_type="bug"
        local slug=\$(echo "\$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-\$//')
        local note_path="\${VAULT}/\${note_type}s/\${today}-\${slug}.md"

        local decision=\$(jq -r '.specialized_note.decision // empty' "\$context_file")
        local context_text=\$(jq -r '.specialized_note.context // empty' "\$context_file")

        local template_name=\$(echo "\$note_type" | awk '{print toupper(substr(\$0,1,1)) substr(\$0,2)}')
        local template_file="\${VAULT}/templates/\${template_name}.md"

        if [ -f "\$template_file" ]; then
            sed -e "s|{{title}}|\${title}|g" -e "s|{{date}}|\${today}|g" -e "s|{{branch}}|\${branch}|g" \\
                -e "s|{{context}}|\${context_text}|g" -e "s|{{decision}}|\${decision}|g" \\
                -e "s|{{daily-note}}|\${today}|g" -e "s|{{component-tags}}|\${branch}|g" \\
                "\$template_file" > "\$note_path"
        fi
        log "Created \${note_type}: \${today}-\${slug}.md"
    fi

    rm -f "\$context_file"
    log "Documentation finalized"
}

while true; do
    ELAPSED=\$(( \$(date +%s) - START_TIME ))
    [ \$ELAPSED -gt \$TIMEOUT ] && { log "Timeout"; exit 1; }
    [ ! -f "\$CONTEXT_FILE" ] && { sleep "\$POLL_INTERVAL"; continue; }

    STATUS=\$(jq -r '.status // "unknown"' "\$CONTEXT_FILE" 2>/dev/null || echo "unknown")
    case "\$STATUS" in
        "in_progress")
            if [ "\$DAILY_NOTE_READY" = false ]; then
                local_today=\$(jq -r '.timestamp_start // empty' "\$CONTEXT_FILE" | cut -d' ' -f1)
                local_branch=\$(jq -r '.branch // "unknown"' "\$CONTEXT_FILE")
                ensure_daily_note "\$local_today" "\$local_branch"
            fi ;;
        "complete")
            finalize_documentation "\$CONTEXT_FILE"
            touch "\$COMPLETE_MARKER"
            exit 0 ;;
        "cancelled") exit 0 ;;
    esac
    sleep "\$POLL_INTERVAL"
done
WATCHER

    chmod +x "$PROJECT_DIR/.claude/scripts/doc_watcher.sh"
    log "doc_watcher.sh created"
}

configure_mcp_claude() {
    info "Configuring MCP servers for Claude Code..."

    local claude_config="$HOME/.claude.json"
    local abs_project=$(cd "$PROJECT_DIR" && pwd)

    # Get Obsidian API key (skip prompt in non-interactive environments)
    if [ -z "$OBSIDIAN_API_KEY" ]; then
        if [ -t 0 ]; then
            echo ""
            warn "Obsidian Local REST API key needed for MCP integration."
            echo "  1. Open Obsidian → Settings → Community Plugins → Install 'Local REST API'"
            echo "  2. Enable the plugin and copy the API key"
            echo ""
            read -p "Paste API key (or press Enter to skip MCP setup): " OBSIDIAN_API_KEY
        else
            warn "Non-interactive run + no --api-key. Skipping MCP configuration."
            warn "Re-run with --api-key <key> to configure MCP later."
        fi
    fi

    if [ -z "$OBSIDIAN_API_KEY" ]; then
        warn "Skipping MCP configuration. Run setup again with --api-key to configure later."
        return 0
    fi

    # Check if claude.json exists
    if [ ! -f "$claude_config" ]; then
        warn "$claude_config not found. Create it after installing Claude Code."
        echo ""
        echo "Add this to your ~/.claude.json under projects.\"$abs_project\".mcpServers:"
        cat << MCP_EOF

{
  "git": {
    "command": "npx",
    "args": ["-y", "@mseep/git-mcp-server"]
  },
  "obsidian": {
    "command": "npx",
    "args": ["-y", "obsidian-mcp-server"],
    "env": {
      "OBSIDIAN_API_KEY": "${OBSIDIAN_API_KEY}",
      "OBSIDIAN_BASE_URL": "https://127.0.0.1:27124",
      "OBSIDIAN_VERIFY_SSL": "false"
    }
  }
}
MCP_EOF
        return 0
    fi

    # Auto-configure using jq if available
    if command -v jq &>/dev/null; then
        local tmp=$(mktemp)
        jq --arg project "$abs_project" \
           --arg api_key "$OBSIDIAN_API_KEY" \
           '.projects[$project] //= {} |
            .projects[$project].mcpServers //= {} |
            .projects[$project].mcpServers.git = {
              "command": "npx",
              "args": ["-y", "@mseep/git-mcp-server"]
            } |
            .projects[$project].mcpServers.obsidian = {
              "command": "npx",
              "args": ["-y", "obsidian-mcp-server"],
              "env": {
                "OBSIDIAN_API_KEY": $api_key,
                "OBSIDIAN_BASE_URL": "https://127.0.0.1:27124",
                "OBSIDIAN_VERIFY_SSL": "false"
              }
            } |
            .projects[$project].hasTrustDialogAccepted = true' \
           "$claude_config" > "$tmp" && mv "$tmp" "$claude_config"
        log "MCP servers configured in ~/.claude.json"
    else
        warn "jq not found — printing MCP config for manual addition"
        echo "Add to ~/.claude.json → projects.\"$abs_project\".mcpServers"
    fi
}

# ── Cursor Setup ───────────────────────────────────────────────────────────
setup_cursor() {
    header "Setting Up Cursor"

    generate_cursorrules

    log "Cursor setup complete"
}

generate_cursorrules() {
    info "Generating .cursorrules..."

    local project_name=$(basename "$PROJECT_DIR")

    local build_cmd=""
    local test_cmd=""
    case "$DETECTED_BUILD" in
        cmake) build_cmd="cmake -B build && cmake --build build"; test_cmd="cd build && ctest" ;;
        npm)   build_cmd="npm run build"; test_cmd="npm test" ;;
        cargo) build_cmd="cargo build"; test_cmd="cargo test" ;;
        go)    build_cmd="go build ./..."; test_cmd="go test ./..." ;;
        make)  build_cmd="make"; test_cmd="make test" ;;
        *)     build_cmd="# Set build command"; test_cmd="# Set test command" ;;
    esac

    local stack_line=""
    for tech in "${DETECTED_STACK[@]:-}"; do
        [ -z "$tech" ] && continue
        stack_line+="$tech, "
    done
    stack_line="${stack_line%, }"

    local guides_list=""
    for guide in "$VAULT_DIR/guides/"*.md; do
        [ -f "$guide" ] || continue
        local name=$(basename "$guide" .md)
        guides_list+="- vault/guides/${name}.md
"
    done

    cat > "$PROJECT_DIR/.cursorrules" << CURSOR_EOF
# Cursor Rules — ${project_name}

## Project
- **Tech Stack:** ${stack_line}
- **Language:** ${DETECTED_LANGUAGE}
- **Framework:** ${DETECTED_FRAMEWORK:-none}
- **Build:** \`${build_cmd}\`
- **Test:** \`${test_cmd}\`

## Architecture

Understand the codebase before making changes. Read relevant files first.

## Coding Standards

### General
- Prefer editing existing files over creating new ones
- Make surgical, minimal changes — don't refactor unrelated code
- No premature abstraction — only extract when 3+ usages with actual bugs
- Comments explain "why", not "what"
- No hardcoded secrets or credentials
- Validate at system boundaries, trust internal code

### Error Handling
- Handle error paths explicitly
- Clean up resources on error (RAII, try/finally, defer, context managers)
- Never swallow exceptions silently

### Testing
- Write tests for new functionality
- Run existing tests after changes to verify no regressions

## Documentation

Project documentation lives in the Obsidian vault (accessible via \`vault/\` symlink).

- \`vault/daily/\` — Daily dev logs
- \`vault/decisions/\` — Architecture Decision Records
- \`vault/bugs/\` — Bug reports and fixes
- \`vault/guides/\` — Best practices for this tech stack
- \`vault/plans/\` — Design documents and implementation plans

When making significant decisions, create an ADR in \`vault/decisions/\`.

## Best Practices Guides

Read these before working in the relevant area:

${guides_list}

## Commit Messages

Use Conventional Commits: \`type(scope): subject\`
Types: feat, fix, docs, style, refactor, test, chore

## Agent/Persona Commands

This project has specialized AI personas available as slash commands in Claude Code.
In Cursor, reference the persona rules manually when needed:

| Task | Persona File | Purpose |
|------|-------------|---------|
| Implement feature | .claude/commands/implementer.md | Implementation with system knowledge |
| Code review | .claude/commands/reviewer.md | Find failure points and code smells |
| Gather evidence | .claude/commands/investigator.md | Code references and investigation |
| Learn concept | .claude/commands/mentor.md | Teaching with examples |
| Evaluate complexity | .claude/commands/pragmatist.md | Challenge over-engineering |
| Orchestrate | .claude/commands/orchestrator.md | Multi-step task planning |
| Document | .claude/commands/doc.md | Vault documentation updates |
| Weekly summary | .claude/commands/weekly.md | Aggregate daily notes |

### How to use in Cursor:
1. Open the persona file (e.g., \`.claude/commands/reviewer.md\`)
2. Copy the relevant instructions into your prompt
3. Or reference: "Follow the rules in .claude/commands/implementer.md to implement..."

## Token Efficiency

- Search codebase before asking for broad context
- Read specific files/lines, not entire directories
- Be surgical with changes — edit, don't rewrite
CURSOR_EOF

    log ".cursorrules generated"
}

# ── Summary ─────────────────────────────────────────────────────────────────
print_summary() {
    header "Setup Complete!"

    echo -e "${GREEN}What was created:${NC}"
    echo ""
    echo "  Vault:      $VAULT_DIR"
    echo "  Symlink:    $PROJECT_DIR/vault -> $VAULT_DIR"
    echo "  Stack:      ${DETECTED_STACK[*]}"
    echo ""

    if [ "$IDE_TARGET" = "both" ] || [ "$IDE_TARGET" = "claude" ]; then
        echo -e "  ${CYAN}Claude Code:${NC}"
        echo "    CLAUDE.md                        — Project rules"
        echo "    .claude/commands/*.md             — Persona skills ($(ls "$PROJECT_DIR/.claude/commands/"*.md 2>/dev/null | wc -l | tr -d ' '))"
        echo "    .claude/scripts/doc_watcher.sh    — Auto-documentation"
        echo "    .claude/token_strategy.md         — Token optimization rules"
        echo ""
    fi

    if [ "$IDE_TARGET" = "both" ] || [ "$IDE_TARGET" = "cursor" ]; then
        echo -e "  ${CYAN}Cursor:${NC}"
        echo "    .cursorrules                     — Project rules"
        echo ""
    fi

    echo -e "  ${CYAN}Vault:${NC}"
    echo "    templates/                       — Daily, Decision, Bug, Weekly, Plan, Analysis"
    echo "    guides/                          — $(ls "$VAULT_DIR/guides/"*.md 2>/dev/null | wc -l | tr -d ' ') best practice guides (auto-detected)"
    echo "    dashboards.md                    — Dataview queries"
    echo ""

    echo -e "${YELLOW}Next steps:${NC}"
    echo "  1. Open Obsidian and add vault: $VAULT_DIR"
    echo "  2. Install Obsidian plugins: Local REST API, Dataview"
    echo "  3. Configure Local REST API and note the API key"
    if [ -z "$OBSIDIAN_API_KEY" ]; then
        echo "  4. Re-run: $0 --api-key YOUR_KEY"
    fi
    echo "  5. Review and customize CLAUDE.md for your project specifics"
    echo "  6. Review .cursorrules for any project-specific additions"
    echo ""
    echo -e "${GREEN}Done! Your AI workspace is ready.${NC}"
}

# ── Main ────────────────────────────────────────────────────────────────────
main() {
    header "AI Workspace Bootstrap"
    echo "Project: $PROJECT_DIR"
    echo "IDE:     $IDE_TARGET"
    echo ""

    detect_os
    detect_tech_stack
    setup_vault
    generate_best_practices

    case "$IDE_TARGET" in
        claude) setup_claude_code ;;
        cursor) setup_cursor ;;
        both)   setup_claude_code; setup_cursor ;;
        *) err "Invalid --ide value: $IDE_TARGET (use: claude, cursor, both)"; exit 1 ;;
    esac

    print_summary
}

main "$@"
