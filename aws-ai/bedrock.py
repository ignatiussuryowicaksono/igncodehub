import boto3
import json
import pprint
import os
import sys
from dotenv import load_dotenv

def main():
    # Load environment variables from .env file
    load_dotenv()

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
