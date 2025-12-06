#!/usr/bin/env bash
# One Command Deployment Wrapper
# Single entry point for full AI-assisted automation workflow
# Embodies "One Command = Full Automation" principle

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="${LOG_FILE:-/tmp/one-command-deploy.log}"

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    echo "${timestamp} [${level}] ${message}" | tee -a "$LOG_FILE"
}

# Usage help
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

One Command Deployment Wrapper - Full AI-Assisted Automation Workflow

This script serves as the single entry point for deploying projects using AI workflow orchestration.
It performs prerequisite checks, sets up the environment, handles user inputs, executes the workflow,
monitors progress in real-time, reports final status, and performs cleanup.

Options:
  -p, --project NAME      Project name (default: default-project)
  -i, --idea PROMPT       Idea generation prompt (default: Generate innovative ideas for a secure cloud application)
  -d, --dev PROMPT        Development prompt (default: Develop the application code using best practices)
  -t, --test CMD          Test command to execute (default: echo 'Running tests...')
  -s, --scripts SCRIPTS   Space-separated list of deployment scripts (default: auto-deploy-azure-security.sh automate-raptor-cli.sh)
  -h, --help              Show this help message

Examples:
  $0
  $0 --project my-app --idea "Create a web app for task management"
  $0 -p secure-api -d "Build REST API with authentication"

EOF
}

# Parse command line arguments
PROJECT_NAME="default-project"
IDEA_PROMPT="Generate innovative ideas for a secure cloud application"
DEV_PROMPT="Develop the application code using best practices"
TEST_COMMAND="echo 'Running tests...'"
DEPLOY_SCRIPTS="auto-deploy-azure-security.sh automate-raptor-cli.sh"

while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--project)
            PROJECT_NAME="$2"
            shift 2
            ;;
        -i|--idea)
            IDEA_PROMPT="$2"
            shift 2
            ;;
        -d|--dev)
            DEV_PROMPT="$2"
            shift 2
            ;;
        -t|--test)
            TEST_COMMAND="$2"
            shift 2
            ;;
        -s|--scripts)
            DEPLOY_SCRIPTS="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Prerequisite checks
check_prerequisites() {
    log "INFO" "Checking prerequisites..."

    if ! command -v az &> /dev/null; then
        log "ERROR" "Azure CLI (az) not found. Please install Azure CLI."
        exit 1
    fi
    log "INFO" "✓ Azure CLI found"

    if ! command -v gh &> /dev/null; then
        log "ERROR" "GitHub CLI (gh) not found. Please install GitHub CLI."
        exit 1
    fi
    log "INFO" "✓ GitHub CLI found"

    if ! command -v python3 &> /dev/null; then
        log "ERROR" "Python 3 not found. Please install Python 3."
        exit 1
    fi
    log "INFO" "✓ Python 3 found"

    # Check if qwe server is running
    if ! pgrep -f "qwe.py" > /dev/null; then
        log "ERROR" "qwe server not running. Please start the qwe server first."
        exit 1
    fi
    log "INFO" "✓ qwe server running"
}

# Environment setup
setup_environment() {
    log "INFO" "Setting up environment..."

    # Run venv setup if available
    if [ -f "${SCRIPT_DIR}/venv-setup.sh" ]; then
        log "INFO" "Setting up virtual environment..."
        bash "${SCRIPT_DIR}/venv-setup.sh"
    fi

    # Export workflow parameters as environment variables
    export PROJECT_NAME
    export IDEA_PROMPT
    export DEV_PROMPT
    export TEST_COMMAND
    export DEPLOY_SCRIPTS
    export LOG_FILE

    log "INFO" "Environment setup completed"
}

# Execute workflow with real-time monitoring
execute_workflow() {
    log "INFO" "Starting AI workflow orchestration..."

    # Start tailing the orchestrator log in background for real-time monitoring
    local orchestrator_log="/tmp/ai-workflow-orchestrator.log"
    touch "$orchestrator_log"
    tail -f "$orchestrator_log" &
    local tail_pid=$!

    # Execute the orchestrator
    local exit_code=0
    if bash "${SCRIPT_DIR}/ai-workflow-orchestrator.sh"; then
        log "INFO" "Workflow completed successfully"
    else
        exit_code=$?
        log "ERROR" "Workflow failed with exit code $exit_code"
    fi

    # Stop tailing
    kill $tail_pid 2>/dev/null || true
    wait $tail_pid 2>/dev/null || true

    return $exit_code
}

# Final status reporting
report_status() {
    local exit_code=$1
    if [ $exit_code -eq 0 ]; then
        log "SUCCESS" "Deployment completed successfully for project: $PROJECT_NAME"
        echo "🎉 Deployment SUCCESS: $PROJECT_NAME"
    else
        log "FAILED" "Deployment failed for project: $PROJECT_NAME"
        echo "❌ Deployment FAILED: $PROJECT_NAME"
    fi
}

# Cleanup function
cleanup() {
    log "INFO" "Performing cleanup..."
    # Remove temporary log files
    rm -f "/tmp/ai-workflow-orchestrator.log"
    rm -f "$LOG_FILE"
    log "INFO" "Cleanup completed"
}

# Error handling
error_handler() {
    local exit_code=$?
    log "ERROR" "Script failed with exit code $exit_code"
    cleanup
    report_status $exit_code
    exit $exit_code
}

# Main execution
main() {
    log "INFO" "One Command Deploy started"

    check_prerequisites
    setup_environment

    if execute_workflow; then
        report_status 0
    else
        report_status 1
        exit 1
    fi

    cleanup
    log "INFO" "One Command Deploy finished"
}

# Trap for cleanup on exit
trap error_handler EXIT

# Run main
main "$@"