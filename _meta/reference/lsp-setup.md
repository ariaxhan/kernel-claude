# LSP Tool Setup

**Purpose:** 600x faster code navigation. LSP understands your code structure; grep just searches text.

## Why This Matters

| Without LSP | With LSP |
|-------------|----------|
| Grep through hundreds of files | Jump to definition in 50ms |
| Guess which file handles auth | Trace actual call hierarchy |
| Find type errors 10 prompts later | Catch errors immediately after edit |
| Waste tokens on wrong files | Precise navigation, fewer tokens |

## Quick Setup (2 minutes)

```bash
# 1. Enable LSP in settings
mkdir -p ~/.claude
echo '{"env":{"ENABLE_LSP_TOOL":"1"}}' > ~/.claude/settings.json

# Or merge with existing settings:
# jq '. + {"env":{"ENABLE_LSP_TOOL":"1"}}' ~/.claude/settings.json > tmp && mv tmp ~/.claude/settings.json

# 2. Install language servers (pick what you use)

# TypeScript/JavaScript (most common)
npm i -g @vtsls/language-server typescript

# Python
npm i -g pyright

# Go
go install golang.org/x/tools/gopls@latest

# Rust
rustup component add rust-analyzer

# 3. Add official plugin marketplace
claude plugin marketplace add claude-plugins-official https://cdn.jsdelivr.net/gh/anthropics/claude-plugins@latest

# 4. Install and enable plugins
claude plugin install typescript-lsp@claude-plugins-official
claude plugin enable typescript-lsp

claude plugin install pyright-lsp@claude-plugins-official
claude plugin enable pyright-lsp

# 5. Restart Claude Code
```

## Supported Languages (20)

| Language | Server | Install |
|----------|--------|---------|
| TypeScript/JS | vtsls | `npm i -g @vtsls/language-server typescript` |
| Python | pyright | `npm i -g pyright` |
| Go | gopls | `go install golang.org/x/tools/gopls@latest` |
| Rust | rust-analyzer | `rustup component add rust-analyzer` |
| Java | jdtls | Eclipse installer or brew |
| C/C++ | clangd | `brew install llvm` or system package |
| C# | OmniSharp | `dotnet tool install -g omnisharp` |
| Ruby | ruby-lsp | `gem install ruby-lsp` |
| PHP | phpactor | `composer global require phpactor/phpactor` |
| Vue | volar | `npm i -g @vue/language-server` (use v2.x) |
| HTML/CSS | vscode-langservers | `npm i -g vscode-langservers-extracted` |
| Kotlin | kotlin-language-server | Gradle/Maven or manual |
| Scala | metals | `cs install metals` |
| LaTeX | texlab | `brew install texlab` |
| Julia | LanguageServer.jl | `julia -e 'using Pkg; Pkg.add("LanguageServer")'` |
| OCaml | ocaml-lsp | `opam install ocaml-lsp-server` |
| Dart | dart | Included with Dart SDK |
| Solidity | solidity-ls | `npm i -g solidity-language-server` |

## Verify It's Working

```bash
# Check LSP loaded
grep "LSP servers loaded" ~/.claude/debug/latest

# Should show N > 0

# List plugins
claude plugin list

# Check Status: enabled
```

## Gotchas

1. **Binary must be in PATH** - plugins configure connection, don't include the server binary
2. **Plugins default to disabled** - run `claude plugin enable <name>` after install
3. **Requires Claude Code 2.1.0+** - earlier versions have LSP bugs
4. **Vue requires v2.x** - v3 broke TypeScript communication
5. **Add CLAUDE.md hint** - tell Claude to prefer LSP over grep (see below)

## CLAUDE.md Addition

Add to your project's CLAUDE.md:

```xml
<lsp>
Prefer LSP tools over Grep/Glob for:
- Finding definitions (LSP goto_definition)
- Finding references (LSP find_references)
- Getting type info (LSP hover)
- Listing symbols (LSP document_symbols)

LSP understands code structure. Grep just searches text.
Use Grep only when LSP unavailable or for string literals.
</lsp>
```

## Debug Commands

```bash
# See what servers are running
ps aux | grep -E "(pyright|vtsls|gopls|rust-analyzer)"

# Check plugin status
claude plugin list --verbose

# View recent LSP activity
tail -100 ~/.claude/debug/latest | grep -i lsp
```
