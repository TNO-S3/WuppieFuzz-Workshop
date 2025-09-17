#!/bin/bash

# Exit on failure
set -e

usage() {
    echo
    echo "Usage: $0 <apply patch>"
    echo
    echo "Arguments:"
    echo "  <apply patch>    Indicate whether to apply a patch or not. Options: \"true\", \"false\""
    echo

    exit
}

if [ $# -ne 1 ]; then
    echo "Error: missing argument"
    usage
fi
if [ "$1" == "true" ]; then
    APPLY_PATCH="True"
elif [ "$1" == "false" ]; then
# patch -p1 < ../petstore.patch
    APPLY_PATCH=""
else
    echo "Error: invalid option selected"
    usage
fi

# Download the pet store if it's not been downloaded before
# (we choose a specific older version with a bug we can find quickly)
if [ ! -f swagger-petstore-v2-1.0.6.tar.gz ]; then
    wget https://github.com/swagger-api/swagger-petstore/archive/refs/tags/swagger-petstore-v2-1.0.6.tar.gz
fi

tar xf swagger-petstore-v2-1.0.6.tar.gz         # Extract the contents
cd swagger-petstore-swagger-petstore-v2-1.0.6/  # Go into the extracted directory

if [ -z $APPLY_PATCH ]; then
    # Don't apply the patch
    :
else
    # Apply the patch
    patch -p1 < ../petstore.patch
fi

cd ..

# Build the Petstore Docker image
docker build -t petstore .

# Kill the existing container if it exists
if [[ ! -z $(docker ps | grep petstore_fuzz) ]]; then
    echo "[*] Killing petstore container..."
    docker kill petstore_fuzz
    docker rm petstore_fuzz
fi

CONTAINER_ID=$(docker run -itd -p 8080:8080 --name petstore_fuzz petstore)
sleep 5


echo ''
echo 'Sending a test request to the pet store container ...'

# Test the output
curl -X 'POST' \
  'http://localhost:8080/api/pet' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "id": 0,
  "category": {
    "id": 0,
    "name": "string"
  },
  "name": "doggie",
  "photoUrls": [
    "string"
  ],
  "tags": "",
  "status": "available"
}'

# Download the API specification from the running container,
# and use the Swagger online service to convert it to a modern format
#   (and to yaml instead of json for human-readability)
# and replace https by http since our docker server is plaintext
curl -s http://localhost:8080/api/swagger.json | \
  curl -s -X 'POST' \
    'https://converter.swagger.io/api/convert' \
    -H 'accept: application/yaml' \
    -H 'content-type: application/json' \
    -d @- | \
  sed 's/https/http/g' > openapi.yaml