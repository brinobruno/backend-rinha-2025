FROM elixir:1.16-alpine

# Install tools
RUN apk add --no-cache build-base git npm inotify-tools

# Set environment
ENV MIX_ENV=dev \
    LANG=C.UTF-8

# Create app directory
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && mix local.rebar --force

# Copy mix files
COPY mix.exs mix.lock ./
COPY config config

# Install deps
RUN mix deps.get

# Copy the rest
COPY . .

# Run server
CMD ["mix", "phx.server"]
