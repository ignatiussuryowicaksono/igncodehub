import boto3
import json
import pprint
import os
import sys
from dotenv import load_dotenv

def main():
    # Retrieve EXECUTION_DIR from environment variables
    execution_dir = os.getenv('EXECUTION_DIR')

    if execution_dir:
        dotenv_path = os.path.join(execution_dir, '.env')
        if os.path.isfile(dotenv_path):
            # Load environment variables from the .env file in EXECUTION_DIR
            load_dotenv(dotenv_path)
            # Optional: Print a confirmation message to the log file via stdout (captured by bash)
            print(f"Loaded .env from {dotenv_path}")
        else:
            print(f"ERROR: .env file not found at {dotenv_path}.", file=sys.stderr)
            sys.exit(1)
    else:
        # Fallback: Attempt to load .env from the current directory
        dotenv_path = '.env'
        if os.path.isfile(dotenv_path):
            load_dotenv(dotenv_path)
            print(f"Loaded .env from current directory: {dotenv_path}")
        else:
            print("ERROR: EXECUTION_DIR not set and .env file not found in the current directory.", file=sys.stderr)
            sys.exit(1)

    # Retrieve variables from environment
    region = os.getenv('AWS_REGION')
    model_id = os.getenv('MODEL_ID')

    if not region:
        print("ERROR: AWS_REGION not found in the environment variables.", file=sys.stderr)
        sys.exit(1)
    if not model_id:
        print("ERROR: MODEL_ID not found in the environment variables.", file=sys.stderr)
        sys.exit(1)

    try:
        # Initialize the Bedrock runtime client
        client = boto3.client(service_name='bedrock-runtime', region_name=region)

        # Define the configuration for the Llama model
        llama_config = json.dumps({
            "prompt": "Which country won the 2022 World Cup?",
            "max_gen_len": 512,
            "temperature": 0,
            "top_p": 0.9,
        })

        # Invoke the model
        response = client.invoke_model(
            body=llama_config,
            modelId=model_id,
            accept="application/json",
            contentType="application/json"
        )

        # Parse the response body
        response_body = json.loads(response.get('body').read())

        # Extract the generation result
        generation = response_body.get("generation", {})

        if generation:
            # Pretty-print the generation result to stdout
            pp = pprint.PrettyPrinter(indent=4)
            print(pp.pformat(generation))
        else:
            print("No generation found in the response.", file=sys.stderr)

    except boto3.exceptions.Boto3Error as e:
        print(f"An error occurred while invoking the model: {e}", file=sys.stderr)
        sys.exit(1)
    except json.JSONDecodeError:
        print("Failed to decode the response body as JSON.", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"An unexpected error occurred: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    main()
