#!/usr/bin/env bash
set -euo pipefail
# tools/create-gh-environment.sh - Create a GitHub Environment and optionally add required reviewer rules via the GitHub API
# Usage: ./tools/create-gh-environment.sh <environment-name> [--reviewers user1,user2] [--teams org/team1,org/team2]

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <environment-name> [--reviewers user1,user2] [--teams org/team1,org/team2]"
  exit 1
fi

ENV_NAME="$1"
shift
REVIEWERS=""
TEAMS=""
OWNER=""
REPO=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --reviewers)
      REVIEWERS="$2"; shift 2;;
    --teams)
      TEAMS="$2"; shift 2;;
    --org)
      OWNER="$2"; shift 2;;
    --repo)
      REPO="$2"; shift 2;;
    *)
      echo "Unknown arg: $1"; exit 1;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not found. Install GH CLI and run 'gh auth login' to authenticate."
  exit 1
fi

if [ -z "$OWNER" ] || [ -z "$REPO" ]; then
  echo "Detecting owner and repo from current git repo..."
  REPO_INFO=$(gh repo view --json name,owner -q '.owner.login + "/" + .name' 2>/dev/null || true)
  if [ -z "$REPO_INFO" ]; then
    echo "Please run this script inside a git repo or pass --org and --repo arguments."
    exit 1
  fi
  OWNER=$(echo "$REPO_INFO" | cut -d'/' -f1)
  REPO=$(echo "$REPO_INFO" | cut -d'/' -f2)
fi

echo "Creating environment: $ENV_NAME in repo $OWNER/$REPO"

# Create environment by calling the REST API: PUT /repos/{owner}/{repo}/environments/{env_name}
if gh api --method PUT "/repos/$OWNER/$REPO/environments/$ENV_NAME" -f name="$ENV_NAME" >/dev/null 2>&1; then
  echo "Created or updated environment $ENV_NAME"
else
  echo "Failed to create environment $ENV_NAME (do you have repo admin rights?)."
  exit 1
fi

if [ -n "$REVIEWERS" ] || [ -n "$TEAMS" ]; then
  echo "Configuring required reviewers for environment $ENV_NAME"
  # Build reviewers JSON
  USERS_JSON="[]"
  TEAMS_JSON="[]"
  jq_installed=false
  if command -v jq >/dev/null 2>&1; then
    jq_installed=true
  fi

  # Build users list
  if [ -n "$REVIEWERS" ]; then
    IFS=',' read -ra RARR <<< "$REVIEWERS"
    USERS_JSON="[]"
    for username in "${RARR[@]}"; do
      user_id=$(gh api /users/$username --jq '.id' 2>/dev/null || true)
      if [ -z "$user_id" ]; then
        echo "Warning: Could not find GitHub user $username; skipping reviewer."
        continue
      fi
      # Append to users array
      USERS_JSON=$(printf '%s' "$USERS_JSON" | jq --argjson id $user_id '. + [$id]') || true
    done
  fi

  if [ -n "$TEAMS" ]; then
    IFS=',' read -ra TARR <<< "$TEAMS"
    TEAMS_JSON="[]"
    for team in "${TARR[@]}"; do
      # team should be 'org/team-slug'
      org=$(echo $team | cut -d'/' -f1)
      slug=$(echo $team | cut -d'/' -f2)
      team_id=$(gh api /orgs/$org/teams/$slug --jq '.id' 2>/dev/null || true)
      if [ -z "$team_id" ]; then
        echo "Warning: Could not find team $team; skipping."
        continue
      fi
      TEAMS_JSON=$(printf '%s' "$TEAMS_JSON" | jq --argjson id $team_id '. + [$id]') || true
    done
  fi

  # Compose final payload
  REVIEWERS_PAYLOAD=$(jq -n --arg users "$USERS_JSON" --arg teams "$TEAMS_JSON" '{ "type":"required_reviewers", "reviewers": {"users": $users, "teams": $teams}}') || true
  if [ -z "$REVIEWERS_PAYLOAD" ]; then
    echo "Could not build reviewers payload: jq not available or failed. Skipping automated reviewer setup. You can add required reviewers in the GitHub UI under Settings > Environments > $ENV_NAME."
    exit 0
  fi

  # POST the protection rule
  echo "Creating a required_reviewers deployment protection rule for environment $ENV_NAME."
  if gh api --method POST "/repos/$OWNER/$REPO/environments/$ENV_NAME/deployment_protection_rules" --input - <<-JSON
  $REVIEWERS_PAYLOAD
  JSON
  then
    echo "Created deployment protection rule to require reviewers."
  else
    echo "Failed to create deployment protection rule: ensure your token has admin:org or repository admin permissions. You can create the rule manually in the GitHub UI under Settings > Environments > $ENV_NAME."
  fi
fi

echo "Done. Please review environment settings in GitHub UI and add required reviewers if necessary."
exit 0
