# Function to log messages to the log file with timestamps
log() {
  echo "$(date +"%Y-%m-%d %H:%M:%S") : [$1] $2"
}

# Function to handle errors by logging and exiting if critical
handle_error() {
  log "ERROR" "$1"
  exit 1
}

# ... [Other functions remain unchanged] ...

# ----------------------------------------
# New Function: Model Selection
# ----------------------------------------
select_model() {
  echo "----------------------------------------"
  echo "Choose the model to deploy:"
  echo "----------------------------------------"

  # Define the list of available models with their IDs
  declare -A models
  models=(
    [1]="Amazon|Titan Text G1 - Express|1.x|amazon.titan-text-express-v1"
    [2]="Amazon|Titan Text G1 - Lite|1.x|amazon.titan-text-lite-v1"
    [3]="Anthropic|Claude|2.0|anthropic.claude-v2"
    [4]="Anthropic|Claude|2.1|anthropic.claude-v2:1"
    [5]="Anthropic|Claude Instant|1.x|anthropic.claude-instant-v1"
    [6]="Meta|Llama 3 8B Instruct|1.x|meta.llama3-8b-instruct-v1:0"
    [7]="Meta|Llama 3 70B Instruct|1.x|meta.llama3-70b-instruct-v1:0"
    [8]="Meta|Llama 3.1 8B Instruct|1.x|meta.llama3-1-8b-instruct-v1:0"
    [9]="Mistral AI|Mistral 7B Instruct|0.x|mistral.mistral-7b-instruct-v0:2"
    [10]="Mistral AI|Mixtral 8X7B Instruct|0.x|mistral.mixtral-8x7b-instruct-v0:1"
    [11]="Mistral AI|Mistral Large|1.x|mistral.mistral-large-2402-v1:0"
  )

  # Define the desired display order of model IDs
  display_order=(1 2 3 4 5 6 7 8 9 10 11)

  # Display the models in the specified order
  for key in "${display_order[@]}"; do
    IFS='|' read -r provider model_name version model_id <<< "${models[$key]}"
    echo "$key. $provider - $model_name (Version: $version)"
  done

  # Prompt the user for selection
  while true; do
    read -p "Enter the number corresponding to the model: " model_choice

    # Check if the input is a valid number
    if ! [[ "$model_choice" =~ ^[0-9]+$ ]]; then
      echo "Invalid input. Please enter a number."
      continue
    fi

    # Check if the number is within the valid model IDs
    if [[ ! " ${display_order[@]} " =~ " ${model_choice} " ]]; then
      echo "Invalid choice. Please select a valid number from the list."
      continue
    fi

    # Extract the MODEL_ID
    selected_model="${models[$model_choice]}"
    IFS='|' read -r provider model_name version model_id <<< "$selected_model"
    log "INFO" "Selected Model: $provider - $model_name (Version: $version)"
    log "INFO" "Model ID set to: $model_id"

    # Set the MODEL_ID environment variable
    export MODEL_ID="$model_id"

    # Confirmation message to the user
    echo "You have selected: $provider - $model_name (Version: $version)"
    log "INFO" "MODEL_ID set to: $MODEL_ID"

    break
  done
}

# Main Execution Flow

# ... [Previous steps like check_internet, load .env, etc.] ...

# ----------------------------------------
# New Step: Model Selection
# ----------------------------------------
select_model

# ... [Rest of your script continues as before] ...
