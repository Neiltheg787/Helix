FROM ubuntu:24.04

ARG JAC_VERSION=0.34.7

RUN apt-get update \
  && apt-get install -y --no-install-recommends curl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://raw.githubusercontent.com/jaseci-labs/jaseci/main/scripts/install.sh | bash -s -- --version "${JAC_VERSION}"
ENV PATH="/root/.local/bin:${PATH}"

WORKDIR /app
COPY . .
RUN jac install
RUN jac check .
RUN jac build

EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://localhost:8000/walker/Health -X POST || exit 1

CMD ["sh", "-c", "jac start --host 0.0.0.0 --port ${PORT:-8000}"]
