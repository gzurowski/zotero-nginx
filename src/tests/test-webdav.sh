#!/usr/bin/env bash
#
# Integration tests for validating WebDAV functionality.
#

set -e

BASE_URL="${BASE_URL:-http://localhost:8888}"
USERNAME="${USERNAME:-zotero}"
PASSWORD="${PASSWORD:-zotero}"
WEBDAV_PATH="/zotero"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

TESTS_PASSED=0
TESTS_FAILED=0

log_pass() {
    printf "${GREEN}✓ PASS${NC}: %s\n" "$1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

log_fail() {
    printf "${RED}✗ FAIL${NC}: %s\n" "$1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

wait_for_server() {
    echo "Waiting for server to be ready..."
    for i in {1..30}; do
        if curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/health" | grep -q "200"; then
            echo "Server is ready"
            return 0
        fi
        sleep 1
    done
    echo "Server failed to start"
    return 1
}

# Test 1: Health check endpoint
test_health_check() {
    echo "Testing health check endpoint..."
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}/health")
    if [ "$response" = "200" ]; then
        log_pass "Health check returns 200"
    else
        log_fail "Health check returned $response (expected 200)"
    fi
}

# Test 2: Authentication required
test_auth_required() {
    echo "Testing authentication requirement..."
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" "${BASE_URL}${WEBDAV_PATH}/")
    if [ "$response" = "401" ]; then
        log_pass "Unauthenticated request returns 401"
    else
        log_fail "Unauthenticated request returned $response (expected 401)"
    fi
}

# Test 3: Authentication works
test_auth_works() {
    echo "Testing authentication..."
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -u "${USERNAME}:${PASSWORD}" "${BASE_URL}${WEBDAV_PATH}/")
    if [ "$response" = "200" ] || [ "$response" = "207" ]; then
        log_pass "Authenticated request succeeds"
    else
        log_fail "Authenticated request returned $response (expected 200 or 207)"
    fi
}

# Test 4: PROPFIND (list directory)
test_propfind() {
    echo "Testing PROPFIND (list directory)..."
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -u "${USERNAME}:${PASSWORD}" \
        -X PROPFIND "${BASE_URL}${WEBDAV_PATH}/")
    if [ "$response" = "207" ]; then
        log_pass "PROPFIND returns 207 Multi-Status"
    else
        log_fail "PROPFIND returned $response (expected 207)"
    fi
}

# Test 5: Upload file with PUT
test_put_file() {
    echo "Testing PUT (upload file)..."
    local response
    response=$(echo "Hello Zotero Test!" | curl -s -o /dev/null -w "%{http_code}" \
        -u "${USERNAME}:${PASSWORD}" \
        -T - "${BASE_URL}${WEBDAV_PATH}/test-file.txt")
    if [ "$response" = "201" ] || [ "$response" = "204" ]; then
        log_pass "PUT file returns 201/204"
    else
        log_fail "PUT file returned $response (expected 201 or 204)"
    fi
}

# Test 6: Download file with GET
test_get_file() {
    echo "Testing GET (download file)..."
    local content
    content=$(curl -s -u "${USERNAME}:${PASSWORD}" "${BASE_URL}${WEBDAV_PATH}/test-file.txt")
    if [ "$content" = "Hello Zotero Test!" ]; then
        log_pass "GET file returns correct content"
    else
        log_fail "GET file returned unexpected content: $content"
    fi
}

# Test 7: Create directory with MKCOL
test_mkcol() {
    echo "Testing MKCOL (create directory)..."
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -u "${USERNAME}:${PASSWORD}" \
        -X MKCOL "${BASE_URL}${WEBDAV_PATH}/test-dir/")
    if [ "$response" = "201" ]; then
        log_pass "MKCOL returns 201"
    else
        log_fail "MKCOL returned $response (expected 201)"
    fi
}

# Test 8: PUT file in subdirectory
test_put_file_subdir() {
    echo "Testing PUT in subdirectory..."
    local response
    response=$(echo "Nested file content" | curl -s -o /dev/null -w "%{http_code}" \
        -u "${USERNAME}:${PASSWORD}" \
        -T - "${BASE_URL}${WEBDAV_PATH}/test-dir/nested.txt")
    if [ "$response" = "201" ] || [ "$response" = "204" ]; then
        log_pass "PUT in subdirectory succeeds"
    else
        log_fail "PUT in subdirectory returned $response (expected 201 or 204)"
    fi
}

# Test 9: COPY file
test_copy() {
    echo "Testing COPY..."
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -u "${USERNAME}:${PASSWORD}" \
        -X COPY \
        -H "Destination: ${BASE_URL}${WEBDAV_PATH}/test-file-copy.txt" \
        "${BASE_URL}${WEBDAV_PATH}/test-file.txt")
    if [ "$response" = "201" ] || [ "$response" = "204" ]; then
        log_pass "COPY returns 201/204"
    else
        log_fail "COPY returned $response (expected 201 or 204)"
    fi
}

# Test 10: MOVE file
test_move() {
    echo "Testing MOVE..."
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -u "${USERNAME}:${PASSWORD}" \
        -X MOVE \
        -H "Destination: ${BASE_URL}${WEBDAV_PATH}/test-file-moved.txt" \
        "${BASE_URL}${WEBDAV_PATH}/test-file-copy.txt")
    if [ "$response" = "201" ] || [ "$response" = "204" ]; then
        log_pass "MOVE returns 201/204"
    else
        log_fail "MOVE returned $response (expected 201 or 204)"
    fi
}

# Test 11: DELETE file
test_delete_file() {
    echo "Testing DELETE file..."
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -u "${USERNAME}:${PASSWORD}" \
        -X DELETE "${BASE_URL}${WEBDAV_PATH}/test-file.txt")
    if [ "$response" = "204" ]; then
        log_pass "DELETE file returns 204"
    else
        log_fail "DELETE file returned $response (expected 204)"
    fi
}

# Test 12: DELETE directory (recursive)
test_delete_dir() {
    echo "Testing DELETE directory..."
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" -u "${USERNAME}:${PASSWORD}" \
        -X DELETE "${BASE_URL}${WEBDAV_PATH}/test-dir/")
    if [ "$response" = "204" ]; then
        log_pass "DELETE directory returns 204"
    else
        log_fail "DELETE directory returned $response (expected 204)"
    fi
}

# Test 13: OPTIONS (check allowed methods)
test_options() {
    echo "Testing OPTIONS..."
    local allow_header
    allow_header=$(curl -s -u "${USERNAME}:${PASSWORD}" -X OPTIONS \
        -I "${BASE_URL}${WEBDAV_PATH}/" 2>/dev/null | grep -i "^allow:" || true)
    if echo "$allow_header" | grep -qi "PROPFIND"; then
        log_pass "OPTIONS returns WebDAV methods"
    else
        log_fail "OPTIONS missing WebDAV methods in Allow header"
    fi
}

# Test 14: Large file upload (1MB)
test_large_file() {
    echo "Testing large file upload (1MB)..."
    local response
    response=$(dd if=/dev/zero bs=1024 count=1024 2>/dev/null | curl -s -o /dev/null -w "%{http_code}" \
        -u "${USERNAME}:${PASSWORD}" \
        -T - "${BASE_URL}${WEBDAV_PATH}/large-file.bin")
    if [ "$response" = "201" ] || [ "$response" = "204" ]; then
        log_pass "Large file upload succeeds"
    else
        log_fail "Large file upload returned $response (expected 201 or 204)"
    fi
}

# Cleanup any remaining test files
cleanup() {
    echo "Cleaning up test files..."
    curl -s -u "${USERNAME}:${PASSWORD}" -X DELETE "${BASE_URL}${WEBDAV_PATH}/test-file.txt" > /dev/null 2>&1 || true
    curl -s -u "${USERNAME}:${PASSWORD}" -X DELETE "${BASE_URL}${WEBDAV_PATH}/test-file-copy.txt" > /dev/null 2>&1 || true
    curl -s -u "${USERNAME}:${PASSWORD}" -X DELETE "${BASE_URL}${WEBDAV_PATH}/test-file-moved.txt" > /dev/null 2>&1 || true
    curl -s -u "${USERNAME}:${PASSWORD}" -X DELETE "${BASE_URL}${WEBDAV_PATH}/test-dir/" > /dev/null 2>&1 || true
    curl -s -u "${USERNAME}:${PASSWORD}" -X DELETE "${BASE_URL}${WEBDAV_PATH}/large-file.bin" > /dev/null 2>&1 || true
}

# Main
main() {
    echo "========================================"
    echo " Integration Tests"
    echo "========================================"
    echo "URL: ${BASE_URL}"
    echo ""

    wait_for_server || exit 1

    echo ""
    echo "Running tests..."
    echo "----------------------------------------"

    test_health_check
    test_auth_required
    test_auth_works
    test_propfind
    test_options
    test_put_file
    test_get_file
    test_mkcol
    test_put_file_subdir
    test_copy
    test_move
    test_delete_file
    test_delete_dir
    test_large_file

    cleanup

    echo "----------------------------------------"
    echo ""
    echo "Results: ${TESTS_PASSED} passed, ${TESTS_FAILED} failed"
    echo ""

    if [ "$TESTS_FAILED" -gt 0 ]; then
        printf "${RED}Some tests failed!${NC}\n"
        exit 1
    else
        printf "${GREEN}All tests passed!${NC}\n"
        exit 0
    fi
}

main "$@"
