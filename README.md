# WuppieFuzz-Workshop

Requirements:
- Docker
- Linux (or WSL)

## Setup

### Setting up WuppieFuzz

Install WuppieFuzz. [The repository is here](https://github.com/TNO-S3/WuppieFuzz), but you can also directly use the installer script for the latest version:
```sh
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/TNO-S3/WuppieFuzz/releases/download/v1.2.0/wuppiefuzz-installer.sh | sh
```

Make sure the directory the fuzzer is installed into is part of your `PATH`.

### WuppieFuzz dashboard

Install the Wuppiefuzz dashboard. [The repository is here](https://github.com/TNO-S3/WuppieFuzz-dashboard), but here too you can use our installer script for the latest version:
```sh
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/TNO-S3/WuppieFuzz-dashboard/releases/download/v0.1.0/wuppiefuzz-dashboard-installer.sh | sh
```

### Setting up the target

Use the bash script from this repository to build the target Docker container and start it.

It expects an argument; give `false` for now (if `true`, the script patches a bug we will find using the fuzzer).

```sh
./start_petstore.sh false
```

This will start the target in its original form. It also loads the API specification from the target and converts it to a compatible format using the online Swagger convert service.

## Fuzzing

Once the target is active, we can start fuzzing:
```sh
wuppiefuzz fuzz --config blackbox-config.yaml
```

You will see a lot of output. The fuzzer also creates many files while it is working.

When WuppieFuzz has finished, we can look at the fuzzing results in the dashboard:

```sh
docker pull grafana/grafana-enterprise:latest
wuppiefuzz-dashboard start --database reports/grafana/report.db
```

The dashboard should be served at [localhost:3000](http://localhost:3000). You can stop the grafana server using

```sh
wuppiefuzz-dashboard stop
```

### Investigating bugs

View the logs of the pet store container using e.g.

```sh
docker logs --tail 1000 petstore_fuzz
```

The patch file in this repository fixes one error handling bug, that could cause 500 errors to appear during your fuzzing campaign.
It can be applied to the source code, and the fixed version hosted via Docker, using

```sh
./start_petstore.sh true
```

Try fuzzing again, and see if there is a difference!

Note that the bash script also sends a test request to the container. This request triggers the bug patched in this tutorial, i.e. when called with `false` the test returns a `500` status code, and when called with `true` it correctly returns `400` to indicate a bad request.
