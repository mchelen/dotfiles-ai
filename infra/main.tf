# GitHub repo settings as code, via the official GitHub Terraform provider.
#
# Apply locally with an admin-scoped token:
#   export GITHUB_TOKEN=$(gh auth token)   # or a fine-grained PAT with
#                                          # "Administration: write" on this repo
#   cd infra && terraform init && terraform apply
#
# The import block adopts the existing repo on first apply — no manual
# `terraform import` step, and nothing is created or destroyed.

terraform {
  required_version = ">= 1.5"

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  owner = "mchelen" # auth comes from the GITHUB_TOKEN env var
}

import {
  to = github_repository.dotfiles_ai
  id = "dotfiles-ai"
}

resource "github_repository" "dotfiles_ai" {
  name         = "dotfiles-ai"
  description  = "Dotfiles, but for AI coding assistants: reusable personal defaults, synced across projects and tools"
  homepage_url = "https://mchelen.github.io/dotfiles-ai/"
  visibility   = "public"

  has_issues      = true
  has_projects    = false
  has_wiki        = false
  has_discussions = false

  allow_squash_merge     = true
  allow_merge_commit     = false
  allow_rebase_merge     = false
  delete_branch_on_merge = true

  vulnerability_alerts = true

  # The static site: published by .github/workflows/deploy-pages.yml
  # through the Actions deployment path.
  pages {
    build_type = "workflow"
  }

  # Platform layer of defaults/secrets.md (replaces the manual
  # Settings -> Advanced Security step).
  security_and_analysis {
    secret_scanning {
      status = "enabled"
    }
    secret_scanning_push_protection {
      status = "enabled"
    }
  }
}

# defaults/ci-gated-main.md, applied to this repo. Possible only since the
# artifact-regeneration workflow stopped pushing here (ADR-0004): with a bot
# writing to main, this rule would have needed a bypass, and a gate you can
# walk around is a gate for other people.
resource "github_branch_protection" "main" {
  repository_id = github_repository.dotfiles_ai.node_id
  pattern       = "main"

  # Includes administrators. The rule is worth nothing if the person most
  # likely to be in a hurry is exempt from it.
  enforce_admins = true

  required_status_checks {
    # `test` runs ./test.sh: the install.sh acceptance scenarios, plus the
    # checks that every generated artifact matches what the tools produce.
    contexts = ["test"]

    # Branches must be current with main before merging. Without this, two
    # module changes can each pass on their own base and still leave main
    # holding artifacts that match neither — the failure the artifact checks
    # exist to prevent, arriving through the back door. The cost is updating
    # a branch when main has moved.
    strict = true
  }

  # No force-pushes, no deletion. Ordinary pull requests are unaffected.
  allows_force_pushes = false
  allows_deletions    = false

  # Deliberately not requiring reviews: this is a single-maintainer repo, and
  # a required approval nobody can give is a rule that gets turned off. The
  # gate here is the check, not a second pair of eyes.
}
