#!/bin/bash

# Version Script Information
VERSION="1.0.5"

# Define Log File
LOG_FILE="setup.log"

# Repository Information
REPO_URL="https://github.com/ignatiussuryowicaksono/igncodehub.git"
CLONE_DIR="amazon-bedrock"
SCRIPT_TO_RUN="aws-ai/bedrock.py"  # Updated to run bedrock.py directly

# Function to log messages to the log file with timestamps and print to terminal
log() {
  local MESSAGE="$(date +"%Y-%m-%d %H:%M:%S") : $1"
  echo "$MESSAGE" | tee -a "$LOG_FILE"
}

# Function to handle errors by logging them and printing to terminal
handle_error() {
  log "ERROR: $1" >&2
}

# Print Version Information to Terminal
echo "Running script version: $VERSION"
log "Running script version: $VERSION"

# Determine the directory where the script resides
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log "Script directory determined as: $SCRIPT_DIR"

# Define the path to the .env file located in the same directory
ENV_FILE="$SCRIPT_DIR/.env"
log "Looking for .env file at: $ENV_FILE"

# Function to check if Python is installed
check_python_installed() {
  case "$OS" in
    WINDOWS*|CYGWIN*|MINGW*|MSYS*)
      if command -v python &>/dev/null; then
        PYTHON_CMD="python"
        log "Python (likely Python 3) is already installed on Windows."
        return 0
      elif command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
        log "Python3 is already installed on Windows."
        return 0
      else
        handle_error "Python is not installed on Windows."
        return 1
      fi
      ;;
    Linux*|Darwin*)
      if command -v python3 &>/dev/null; then
        PYTHON_CMD="python3"
        log "Python3 is already installed."
        return 0
      elif command -v python &>/dev/null; then
        PYTHON_CMD="python"
        log "Python is already installed."
        return 0
      else
        handle_error "Python is not installed."
        return 1
      fi
      ;;
    *)
      handle_error "Unsupported OS: $OS."
      return 1
      ;;
  esac
}

# Function to install Python3 and venv on Debian/Ubuntu-based systems
install_python3_venv() {
  log "Attempting to install python3 and python3-venv..."
  if [[ "$OS" == "Linux" ]]; then
    sudo apt update >> "$LOG_FILE" 2>&1
    sudo apt install -y python3 python3-venv >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
      log "Successfully installed python3 and python3-venv."
    else
      handle_error "Failed to install python3 or python3-venv."
    fi
  else
    handle_error "install_python3_venv is only supported on Linux."
  fi
}

# Function to install Python3 on Unix-based systems (if not already installed)
install_python_unix() {
  log "Python not found. Installing Python on Unix-like system..."
  curl -O https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/devsecops/install_python.sh >> "$LOG_FILE" 2>&1
  if [ $? -ne 0 ]; then
    handle_error "Failed to download install_python.sh."
    exit 1
  fi
  chmod +x install_python.sh
  ./install_python.sh >> "$LOG_FILE" 2>&1
  if [ $? -ne 0 ]; then
    handle_error "Failed to execute install_python.sh."
    exit 1
  fi
}

# Function to install Python on Windows
install_python_windows() {
  log "Python not found. Installing Python on Windows system..."
  powershell -Command "Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force" >> "$LOG_FILE" 2>&1
  powershell -Command "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/GDP-ADMIN/codehub/refs/heads/main/devsecops/install_python.ps1' -OutFile 'install_python.ps1'" >> "$LOG_FILE" 2>&1
  if [ $? -ne 0 ]; then
    handle_error "Failed to download install_python.ps1."
    exit 1
  fi
  powershell -File install_python.ps1 >> "$LOG_FILE" 2>&1
  if [ $? -ne 0 ]; then
    handle_error "Failed to execute install_python.ps1."
    exit 1
  fi
}

# Function to install AWS CLI if not already installed
install_aws_cli() {
  if ! command -v aws &>/dev/null; then
    log "AWS CLI not found. Installing AWS CLI..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
      handle_error "Failed to download AWS CLI."
      return 1
    fi
    unzip awscliv2.zip >> "$LOG_FILE" 2>&1
    if [ $? -ne 0 ]; then
      handle_error "Failed to unzip AWS CLI installer."
      return 1
    fi
    sudo ./aws/install >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
      log "AWS CLI installed successfully."
    else
      handle_error "Failed to install AWS CLI."
    fi
    # Clean up
    rm -rf awscliv2.zip aws
  else
    log "AWS CLI is already installed."
  fi
}

# Function to clone the repository
clone_repository() {
  if [ -d "$CLONE_DIR" ]; then
    log "Repository directory '$CLONE_DIR' already exists. Skipping clone."
  else
    log "Cloning repository from $REPO_URL..."
    git clone "$REPO_URL" "$CLONE_DIR" >> "$LOG_FILE" 2>&1
    if [ $? -eq 0 ]; then
      log "Repository cloned successfully into '$CLONE_DIR'."
    else
      handle_error "Failed to clone repository from $REPO_URL."
      exit 1
    fi
  fi
}

# Function to run bedrock.py from the cloned repository
run_bedrock_script() {
  local SCRIPT_PATH="$SCRIPT_DIR/$CLONE_DIR/$SCRIPT_TO_RUN"

  if [ -f "$SCRIPT_PATH" ]; then
    log "Executing script: $SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    bash "$SCRIPT_PATH" >> "$LOG_FILE" 2>&1
    local exit_code=$?
    if [ $exit_code -eq 0 ]; then
      log "Script '$SCRIPT_TO_RUN' executed successfully."
    else
      handle_error "Script '$SCRIPT_TO_RUN' encountered an error during execution. Exit code: $exit_code"
      exit 1
    fi
  else
    handle_error "Script '$SCRIPT_PATH' not found."
    exit 1
  fi
}

# Function to load environment variables from the .env file
load_env() {
  if [ -f "$ENV_FILE" ]; then
    # Use 'export' and 'source' to load the .env file
    set -a
    source "$ENV_FILE"
    set +a
    log ".env file loaded successfully from '$ENV_FILE'."

    # Debugging: Check if variables are set (without printing sensitive information)
    if [ -n "$AWS_ACCESS_KEY_ID" ]; then
      log "AWS_ACCESS_KEY_ID is set."
    else
      handle_error "AWS_ACCESS_KEY_ID is not set after loading .env."
    fi

    if [ -n "$AWS_SECRET_ACCESS_KEY" ]; then
      log "AWS_SECRET_ACCESS_KEY is set."
    else
      handle_error "AWS_SECRET_ACCESS_KEY is not set after loading .env."
    fi

    if [ -n "$AWS_REGION" ]; then
      log "AWS_REGION is set to '$AWS_REGION'."
    else
      handle_error "AWS_REGION is not set after loading .env."
    fi

    if [ -n "$MODEL_ID" ]; then
      log "MODEL_ID is set to '$MODEL_ID'."
    else
      handle_error "MODEL_ID is not set after loading .env."
    fi
  else
    handle_error ".env file not found at '$ENV_FILE'. Please ensure it exists in the script's directory."
    exit 1
  fi
}

# Function to configure AWS CLI profile and export AWS_PROFILE environment variable
configure_aws_profile() {
  local profile_name=$1
  local aws_access_key_id=$AWS_ACCESS_KEY_ID
  local aws_secret_access_key=$AWS_SECRET_ACCESS_KEY
  local aws_region=$AWS_REGION

  # Configure AWS CLI profile using values from .env
  aws configure set aws_access_key_id "$aws_access_key_id" --profile "$profile_name" >> "$LOG_FILE" 2>&1
  if [ $? -ne 0 ]; then
    handle_error "Failed to set AWS_ACCESS_KEY_ID for profile '$profile_name'."
  fi

  aws configure set aws_secret_access_key "$aws_secret_access_key" --profile "$profile_name" >> "$LOG_FILE" 2>&1
  if [ $? -ne 0 ]; then
    handle_error "Failed to set AWS_SECRET_ACCESS_KEY for profile '$profile_name'."
  fi

  aws configure set region "$aws_region" --profile "$profile_name" >> "$LOG_FILE" 2>&1
  if [ $? -ne 0 ]; then
    handle_error "Failed to set AWS_REGION for profile '$profile_name'."
  fi

  # Export the AWS_PROFILE environment variable
  export AWS_PROFILE="$profile_name"
  log "AWS profile '$profile_name' has been configured and exported as AWS_PROFILE."
}

# Store AWS profile info (profile name)
profile_name="bedrock-serverless"

# Load environment variables from the .env file
load_env

# Ensure that AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, and AWS_REGION are set
if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$AWS_REGION" ]; then
  handle_error "AWS credentials or region not found in the .env file. Please check the .env file."
  exit 1
fi

# Configure AWS CLI profile
configure_aws_profile "$profile_name"

# Clone the repository
clone_repository

# Run the bedrock.py script from the cloned repository
run_bedrock_script

# Detect if the system is running on Windows or Unix
OS="$(uname -s 2>/dev/null || echo "Windows")"
log "Detected OS: $OS"

# OS-specific logic for Python environment
case "$OS" in
  Linux*|Darwin*)
    log "Detected Unix-like system ($OS)."
    if ! check_python_installed; then
      install_python_unix
      # Re-check if Python is installed after installation attempt
      check_python_installed
    fi
    # Check and install AWS CLI
    install_aws_cli
    ;;
  CYGWIN*|MINGW*|MSYS*|Windows*)
    log "Detected Windows system ($OS)."
    if ! check_python_installed; then
      install_python_windows
      # Re-check if Python is installed after installation attempt
      check_python_installed
    fi
    ;;
  *)
    handle_error "Unsupported OS: $OS."
    ;;
esac

# Create and activate a Python virtual environment based on OS
if [ -n "$PYTHON_CMD" ]; then
  # Check if virtual environment exists
  if [ -d "my_venv" ]; then
    log "Virtual environment 'my_venv' already exists. Activating it."
    case "$OS" in
      Linux*|Darwin*)
        source my_venv/bin/activate
        ;;
      CYGWIN*|MINGW*|MSYS*|Windows*)
        source my_venv/Scripts/activate
        ;;
    esac
  else
    # Create and activate the virtual environment
    case "$OS" in
      Linux*|Darwin*)
        log "Creating Python virtual environment for Unix..."
        "$PYTHON_CMD" -m venv my_venv >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
          source my_venv/bin/activate
          log "Virtual environment 'my_venv' activated."
        else
          handle_error "Failed to create virtual environment."
        fi
        ;;
      CYGWIN*|MINGW*|MSYS*|Windows*)
        log "Creating Python virtual environment for Windows..."
        "$PYTHON_CMD" -m venv my_venv >> "$LOG_FILE" 2>&1
        if [ $? -eq 0 ]; then
          source my_venv/Scripts/activate
          log "Virtual environment 'my_venv' activated."
        else
          handle_error "Failed to create virtual environment."
        fi
        ;;
    esac
  fi
else
  handle_error "Python command not found. Cannot create virtual environment."
fi

# Install required AWS SDK libraries and other dependencies
log "Installing required Python packages..."
pip install --disable-pip-version-check boto3 awscli python-dotenv >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
  log "Python packages installed successfully."
else
  handle_error "Failed to install some Python packages."
fi

# Confirm installation
pip list --disable-pip-version-check | grep "boto3\|awscli\|python-dotenv" >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
  log "Confirmed installation of boto3, awscli, and python-dotenv."
else
  handle_error "Some required Python packages are not installed."
fi

# Run the bedrock.py script and capture the model response
if [ -f "bedrock.py" ]; then
  log "Running bedrock.py script..."

  # Execute bedrock.py, capture stdout (model response), and log all errors
  MODEL_RESPONSE=$("$PYTHON_CMD" bedrock.py 2>> "$LOG_FILE")

  # Check if the Python script executed successfully
  if [ $? -eq 0 ]; then
    # Print the model response to the terminal
    echo "$MODEL_RESPONSE"
    log "bedrock.py executed successfully."
  else
    handle_error "bedrock.py encountered an error during execution."
  fi
else
  handle_error "bedrock.py script not found in the current directory."
fi

# Deactivate the virtual environment if it's activated
if [[ "$VIRTUAL_ENV" != "" ]]; then
  deactivate
  log "Virtual environment 'my_venv' deactivated."
else
  log "No virtual environment to deactivate."
fi

# Print completion messages to the terminal
echo "AWS environment setup and bedrock.py script execution complete."
echo "Check 'setup.log' for detailed logs."

# Log completion messages
log "AWS environment setup and bedrock.py script execution complete."
log "Check 'setup.log' for detailed logs."
