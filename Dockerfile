FROM elixir:1.16-alpine

RUN apk add --no-cache build-base git npm inotify-tools

ENV MIX_ENV=prod \
    LANG=C.UTF-8

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

# Caching
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY . .

RUN mix compile

ENV PAYMENT_SERVICE_URL_DEFAULT=http://payment-processor-default:8080
ENV PAYMENT_SERVICE_URL_FALLBACK=http://payment-processor-fallback:8080
ENV PORT=9999
ENV PHX_SERVER=true

CMD ["mix", "phx.server"]
