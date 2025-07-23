FROM elixir:1.16-alpine

# Install tools
RUN apk add --no-cache build-base git npm inotify-tools

ENV MIX_ENV=dev \
    LANG=C.UTF-8

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy the entire project first (respects .dockerignore)
COPY . .

# Then install deps
RUN mix deps.get

ENV PROCESSOR_DEFAULT_URL=http://payment-processor-default:8080
ENV PROCESSOR_FALLBACK_URL=http://payment-processor-fallback:8080

CMD ["iex", "-S", "mix", "phx.server"]
