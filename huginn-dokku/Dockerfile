# Huginn on Dokku
# Uses the official huginn image with PostgreSQL
FROM huginn/huginn:latest

# Don't copy .env - let Huginn's init script create it from ENV vars
# The init script at /scripts/init handles this automatically

# Set required environment variables for PostgreSQL
ENV PORT=3000 \
    RAILS_ENV=production \
    DATABASE_ADAPTER=postgresql \
    HUGINN_DATABASE_ADAPTER=postgresql \
    DO_NOT_CREATE_DATABASE=false \
    START_MYSQL=false \
    RAILS_SERVE_STATIC_FILES=true

EXPOSE 3000

# Use Huginn's built-in init script
CMD ["/scripts/init"]
