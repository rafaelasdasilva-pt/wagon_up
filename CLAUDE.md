# CLAUDE.md
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands
```bash
# Setup
bundle install
rails db:create db:migrate

# Development
bin/dev                        # Start server (Puma)

# Testing
rails test                     # Run all tests
rails test test/models/user_test.rb  # Run a single test file
rails test:system              # Run system tests (Capybara + Selenium)

# Code quality
bundle exec rubocop            # Lint Ruby
bundle exec brakeman           # Security scan
bundle exec bundler-audit      # Gem vulnerability scan
```

## Architecture
Rails 8.1 app bootstrapped from [Le Wagon's template](https://github.com/lewagon/rails-templates).

*Authentication*: Devise — ApplicationController requires authenticate_user! by default. PagesController#home skips it for the public landing page.

*Frontend*: No Node/Webpack. Uses Importmap for JS (ESM-native), Hotwire (Turbo + Stimulus), Bootstrap 5.3 via SCSS, Font Awesome 6.1.

*SCSS structure* (app/assets/stylesheets/):
- config/ — Bootstrap variable overrides (colors, fonts)
- components/ — Reusable UI (navbar, forms, alerts, avatar)
- pages/ — Page-specific styles

*Infrastructure*: Solid Stack (database-backed Cache, Queue, Cable) — no Redis needed.

*Deployment*: Heroku.

*Testing*: Minitest with fixtures (not RSpec). Parallel execution enabled.

## Wagon Up — Le Wagon Brasil Final Project

**Goal**: AI platform for bootcamp graduates preparing for tech job interviews.

**Stack**: Rails 8.1, PostgreSQL, Anthropic Claude API, Active Storage

**Models and relationships**:
- User → Analysis → Role → Interview → Answer
- PDF uploaded by user, text extracted to `cv_text` via `app/services/pdf_parser.rb`
- Claude API analyses `cv_text` and returns 3 career paths (Roles) with market data

**Services**:
- `ClaudeAnalyser` — receives `cv_text`, calls Anthropic API, returns 3 career paths with justification and market fit data
- `ChloeInterviewer` — generates interview questions per role, evaluates answers, returns score + feedback

**Critical rules**:
- Always save the full API response in `raw_json` on Analysis — never call the API twice for the same CV
- PDF text must be extracted before calling ClaudeAnalyser — never pass the raw file to the API
- All services live in `app/services/`
- API keys must never be hardcoded — use ENV variables (`ANTHROPIC_API_KEY`)

**Key references**:
@config/routes.rb @db/schema.rb @app/services/
