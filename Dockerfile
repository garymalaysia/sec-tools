FROM python:3.10-alpine

WORKDIR /home/sec-tool

# Install MUSL-dev
RUN apk add --no-cache musl-dev

# Install GCC & cURL
RUN apk add --no-cache gcc curl

# Pull Trivy from public as binary
COPY --from=aquasec/trivy:0.27.1 /usr/local/bin/trivy /usr/local/bin/trivy

# Install Semgrep using Pip
RUN python3 -m pip install semgrep

# Install Oras
RUN curl -LO https://github.com/oras-project/oras/releases/download/v0.12.0/oras_0.12.0_linux_amd64.tar.gz
RUN mkdir -p oras-install/
RUN tar -zxf oras_0.12.0_*.tar.gz -C oras-install/
RUN mv oras-install/oras /home/sec-tool/
RUN rm -rf oras_0.12.0_*.tar.gz oras-install/

# Set non root userars
RUN adduser -D sec-tool --u 1001 && chown -R 1001 /home/sec-tool/ 
USER sec-tool

# For offline vulnerability db
RUN mkdir -p /home/sec-tool/.cache/trivy/db
RUN chmod 754 /home/sec-tool/.cache/trivy

# Download and Move DB to trivy location
RUN /home/sec-tool/oras pull ghcr.io/aquasecurity/trivy-db:2 -a
RUN mv db.tar.gz /home/sec-tool/.cache/trivy/db/db.tar.gz

# Remove Oras
RUN rm /home/sec-tool/oras

# Untar it to cache dir
RUN tar -zxvf  /home/sec-tool/.cache/trivy/db/db.tar.gz -C  /home/sec-tool/.cache/trivy/db
RUN rm /home/sec-tool/.cache/trivy/db/db.tar.gz

# Download semgrep rule offline
RUN mkdir -p /home/sec-tool/semgrep-rules
RUN wget --no-check-certificate https://semgrep.dev/c/p/ci -O /home/sec-tool/semgrep-rules/ci
RUN wget --no-check-certificate https://semgrep.dev/c/p/secrets -O /home/sec-tool/semgrep-rules/secrets

# Copy Custom semgrep rule to semgrep-rules directory
# COPY custom-rules.yaml  /home/sec-tool/semgrep-rules/custom-rules

COPY entrypoint.sh /home/sec-tool/entrypoint.sh
ENTRYPOINT [ "sh","/home/sec-tool/entrypoint.sh" ]