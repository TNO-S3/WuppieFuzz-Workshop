#!/bin/bash

IMAGE_BASE_NAME="petstore"
CONTAINER_BASE_NAME="petstore_fuzz"

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
    CONTAINER_NAME="${CONTAINER_BASE_NAME}_patched"
    IMAGE_NAME="${IMAGE_BASE_NAME}_patched"
elif [ "$1" == "false" ]; then
# patch -p1 < ../petstore.patch
    APPLY_PATCH=""
    CONTAINER_NAME="${CONTAINER_BASE_NAME}_raw"
    IMAGE_NAME="${IMAGE_BASE_NAME}_raw"
else
    echo "Error: invalid option selected"
    usage
fi

# Check if Docker is running
docker info &> /dev/null
ret_code=$?
if [ $ret_code != 0 ]; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit;
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
    echo "[*] Patching target application..."
    patch -p1 < ../petstore.patch > /dev/null
fi

cd ..

# Build the Petstore Docker image if not exists
if [ -z "$(docker images -q $IMAGE_NAME 2> /dev/null)" ]; then
    echo "[*] Building Docker image \"$IMAGE_NAME\"..."
    docker build -t $IMAGE_NAME .
else
    echo "[*] Not building Docker image, already found: \"$IMAGE_NAME\""
fi

# Kill the existing container if it exists
containers=$(docker ps -q --filter="name=$CONTAINER_BASE_NAME")
if [[ ! -z $containers ]]; then
    echo "[*] Stopping existing containers \"$containers\"..."
    docker stop $containers > /dev/null
fi

# Start a container if exists, otherwise create a new one
container=$(docker ps -a -q --filter="name=$CONTAINER_NAME")
if [[ ! -z $container ]]; then
    echo "[*] Starting the existing container \"$container\"..."
    docker start $container > /dev/null
else
    echo "[*] Creating a new Docker container with name \"$CONTAINER_NAME\"..."
    docker run -itd -p 8080:8080 --name $CONTAINER_NAME $IMAGE_NAME > /dev/null
fi


# Loop until the container responds
echo "[*] Waiting for the container to start up..."
while true; do
    curl http://localhost:8080/api &> /dev/null
    ret_code=$?
    if [ $ret_code = 0 ]; then
        break
    fi
    sleep 1
done

echo "[+] Container \"$CONTAINER_NAME\" is up and running!"


# Test the output
echo -e '[*] Sending a test request to the pet store container. The output: \n'
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
echo -e '\n\n'

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
