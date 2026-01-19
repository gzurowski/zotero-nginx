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
