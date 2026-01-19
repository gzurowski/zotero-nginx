# Zotero Nginx

A Docker image providing WebDAV access for Zotero, built on the official Nginx Alpine Linux image.

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
