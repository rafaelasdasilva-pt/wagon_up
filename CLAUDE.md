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

**Authentication**: Devise — `ApplicationController` requires `authenticate_user!` by default. `PagesController#home` skips it for the public landing page.

**Frontend**: No Node/Webpack. Uses Importmap for JS (ESM-native), Hotwire (Turbo + Stimulus), Bootstrap 5.3 via SCSS, Font Awesome 6.1.

**SCSS structure** (`app/assets/stylesheets/`):
- `config/` — Bootstrap variable overrides (colors, fonts)
- `components/` — Reusable UI (navbar, forms, alerts, avatar)
- `pages/` — Page-specific styles

**Infrastructure**: Solid Stack (database-backed Cache, Queue, Cable) — no Redis needed.

**Deployment**: Kamal (Docker containers).

**Testing**: Minitest with fixtures (not RSpec). Parallel execution enabled.

## Wagon Up - Le Wagon Brasil Final Project
## Goal: AI platform for bootcamp graduates preparing for tech job interviews
## Stack: Ruby on Rails 7, PostgreSQL, Anthropic Claude API, Active Storage
## Services: ClaudeAnalyser (CV → 3 career paths), ChloeInterviewer (mock interviews)
## @config/routes.rb @db/schema.rb @app/services/
