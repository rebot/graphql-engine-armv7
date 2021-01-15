# graphql-engine-armv7
Dockerfile for hasura/graphql-engine to run on ARMv7

# Build from source (or skip this step to pull image from hub.docker.com)
```bash
git clone https://github.com/b0hr/graphql-engine-armv7
cd graphql-engine-armv7
docker build -t rebot/graphql-engine-armv7 .
```

# Start a Hasura instance on ARMv7
```bash
docker run -d -p 8080:8080 \
  -e HASURA_GRAPHQL_DATABASE_URL=postgres://username:password@hostname:port/dbname \
  -e HASURA_GRAPHQL_ENABLE_CONSOLE=true \
  -e HASURA_GRAPHQL_ADMIN_SECRET=myadminsecretkey \
  fedormelexin/graphql-engine-armv7
```

Hasura Console will be available at http://localhost:8080

# Using docker-compose
Example docker-compose.yaml for hasura and postgres:
```yaml
version: '3.6'
services:
  postgres:
    image: postgres
    restart: always
    volumes:
    - db_data:/var/lib/postgresql/data
  graphql-engine:
    image: b0hr/graphql-engine-armv7
    ports:
    - "8080:8080"
    depends_on:
    - "postgres"
    restart: always
    environment:
      HASURA_GRAPHQL_DATABASE_URL: postgres://postgres:@postgres:5432/postgres
      HASURA_GRAPHQL_ENABLE_CONSOLE: "true" # set to "false" to disable console
      ## uncomment next line to set an admin secret
      # HASURA_GRAPHQL_ADMIN_SECRET: myadminsecretkey
volumes:
  db_data:
```
