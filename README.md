
# API JSON E2E Test Suite

This project is a lightweight, scalable test harness for validating REST API responses against expected JSON outputs using `curl`, `jq`, and Bash. It is designed to run locally or as part of a CI pipeline (e.g., GitHub Actions).

## Features

- Declarative test configuration via `test_config.json`
- Supports multiple endpoints
- Automatic key sorting with `jq` for reliable comparisons
- CI integration with GitHub Actions
- Simple `diff`-based failure output for easy debugging

## Project Structure

```

.
├── run\_tests.sh           # Bash script that runs the tests
├── test\_config.json       # Configuration file with endpoints and expected JSON
└── .github
└── workflows
└── api-tests.yml  # GitHub Actions CI workflow

````

## Getting Started

### Prerequisites

- Bash
- `curl`
- [`jq`](https://stedolan.github.io/jq/) (install via `sudo apt install jq` or `brew install jq`)

### Running Tests Locally

1. Edit the `test_config.json` with your host and test cases.
2. Make sure the test script is executable:
   ```bash
   chmod +x run_tests.sh
    ```

3. Run the script:

   ```bash
   ./run_tests.sh
   ```

### Sample `test_config.json`

```json
{
  "host": "http://localhost:8000",
  "tests": [
    {
      "endpoint": "/api/whatever",
      "expectedResult": {
        "status": "success",
        "data": {
          "id": 123,
          "message": "Hello World"
        }
      }
    },
    {
      "endpoint": "/api/other",
      "expectedResult": {
        "status": "ok",
        "value": 42
      }
    }
  ]
}
```

## CI Integration (GitHub Actions)

This project includes a GitHub Actions workflow that automatically runs the tests on each push or pull request to `main`.

### Example: `.github/workflows/api-tests.yml`

```yaml
name: API E2E Tests

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  test-api:
    runs-on: ubuntu-latest

    steps:
    - name: Checkout code
      uses: actions/checkout@v3

    - name: Install jq
      run: sudo apt-get update && sudo apt-get install -y jq

    - name: Make test script executable
      run: chmod +x run_tests.sh

    - name: Run E2E API tests
      run: ./run_tests.sh
```

## Customization

* You can override the host by modifying the script to support `HOST_OVERRIDE` via env vars.
* Extend the script to ignore volatile fields like timestamps, UUIDs, etc.
* Add logging or reporting as needed.



