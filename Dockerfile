FROM elixir:1.16-alpine

# Install tools
RUN apk add --no-cache build-base git npm inotify-tools

ENV MIX_ENV=prod \
    LANG=C.UTF-8

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy mix files first for better caching
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

# Copy the entire project
COPY . .

# Compile the application
RUN mix compile

# Set environment variables
ENV PROCESSOR_DEFAULT_URL=http://payment-processor-default:8080
ENV PROCESSOR_FALLBACK_URL=http://payment-processor-fallback:8080
ENV PORT=9999
ENV PHX_SERVER=true

# Use the compiled application
CMD ["mix", "phx.server"]
