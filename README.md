![Docker Pull](https://img.shields.io/docker/pulls/dockerhub2600/sec-tools)

## Motivation: `Docker scan` is not free

# sec-tools
Sec-Tools is a FREE docker container built with SAST and container scanning features.
It is also built for CICD pipeline for air-gapped environment.

## Tools included
- [Trivy](https://github.com/aquasecurity/trivy)
- [Semgrep](https://github.com/returntocorp/semgrep)

## Usage:

### Gitlab CI
in `.gitlab-ci.yml`, include the following snippet to pipeline config:

``` 
stages:
  - static_scan
  - docker_build
  - container_scan

static_analysis:
  stage: static_scan
  image: dockerhub2600/sec-tools:1.0.3
  script:
    -  semgrep --config=/home/sec-tool/semgrep-rules/ci --config=/home/sec-tool/semgrep-rules/secrets
  allow_failure: false

container_build:
  stage: docker_build
  image: docker:20.10.11
  script:
    - docker build  -t <DOCKER IMAGE TO BE SCANNED> .
  tags:
    - docker_build

container_scan:
  stage: container_scan
  image: dockerhub2600/sec-tools:1.0.3
  script:
    - trivy image  --severity CRITICAL --skip-update --offline-scan --no-progress <DOCKER IMAGE TO BE SCANNED>
  dependencies:
    - container_build
  allow_failure: true
  tags:
    - docker_build

  ```
###### Note: If you have multiple runners configured for the pipeline, each job in the pipeline may be picked up by a different runner. To ensure the same runner is used for `container_scan` and `container_build`, a dedicated `docker_build` tag is created. If `container_build` job and `container_scan` job do not share the same runner, `container_scan` job may fail due to an image not found. 

###### A solution is to create a custom tag and label it on 1 dedicated runner.


### Github Action
Enable Github Action for your repository.
Copy and paste the following snippet into `.github/workflows/main.yml`.
Replace `<DOCKER IMAGE TO BE SCANNED>` with the container name for scanning
```
name: Semgrep Scan
on: [push]
jobs:
  repo-scan:
    runs-on: ubuntu-latest
    container:
      image: docker://dockerhub2600/sec-tools:1.0.3
      options: --user 1001
    steps:
      - uses: actions/checkout@v3
      - run: > 
          semgrep 
          --config=/home/sec-tool/semgrep-rules/ci 
          --config=/home/sec-tool/semgrep-rules/secrets
  
  # setup Docker buld action
  docker-build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      
      - name: Build Docker Image
        run: docker build -t <DOCKER IMAGE TO BE SCANNED>:${{ github.sha }} .

      - name: Allow trivy to scan local images
        run: sudo chmod 666 /var/run/docker.sock
  
      - name: Container Scan with Trivy
        uses: docker://dockerhub2600/sec-tools:1.0.3
        with:
          args: >
            trivy --cache-dir /home/sec-tool/.cache/trivy/ 
            image --format sarif -o trivy-results.sarif 
            --severity CRITICAL 
            --skip-update --offline-scan --no-progress 
            <DOCKER IMAGE TO BE SCANNED>:${{ github.sha }}

      - name: Upload Trivy scan results to GitHub Security tab
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

###### Note: Do add `.semgrepignore` to ignore any file from scanning by semgrep.


