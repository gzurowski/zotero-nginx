# Zotero Nginx

A Docker image providing WebDAV access for Zotero, built on the official Nginx Alpine Linux image.

## Quick Start

> **Important:** Replace `myuser` and `mysecretpassword` in the examples below with your own credentials.

### Using Docker

```sh
docker run -d \
  --name zotero-webdav \
  -p 8080:80 \
  -e ZOTERO_USER=myuser \
  -e ZOTERO_PASS=mysecretpassword \
  -v zotero-data:/var/lib/dav/data \
  gzurowski/zotero-nginx
```

### Using Docker Compose

Create a `docker-compose.yml`:

```yaml
services:
  zotero:
    image: gzurowski/zotero-nginx
    ports:
      - "8080:80"
    environment:
      - ZOTERO_USER=myuser
      - ZOTERO_PASS=mysecretpassword
    volumes:
      - zotero-data:/var/lib/dav/data

volumes:
  zotero-data:
```

Then run:

```sh
docker compose up -d
```

## Development

Clone this repository:

```sh
git clone https://github.com/gzurowski/zotero-nginx.git
```

### Build

```sh
docker compose build
```

### Run

```sh
docker compose run --build
```

The server will be available at http://localhost:8888 with default credentials `zotero:zotero`.

### Test

```sh
# Health check
curl http://localhost:8888/health

# List directory
curl -u zotero:zotero -X PROPFIND http://localhost:8888/zotero/

# Upload a test file
echo "Hello Zotero!" | curl -u zotero:zotero -T - http://localhost:8888/zotero/test.txt

# Download the file
curl -u zotero:zotero http://localhost:8888/zotero/test.txt

# Delete the file
curl -u zotero:zotero -X DELETE http://localhost:8888/zotero/test.txt
```

Uploaded files are stored in the `./data` directory.
