# WuppieFuzz-Workshop

Requirements:
- Docker
- Linux (or WSL)

## Setup

### Setting up the target

Use the bash script to build the target Docker container and start it



### Setting up WuppieFuzz

Install WuppieFuzz

[repository](https://github.com/TNO-S3/WuppieFuzz/tree/main)

Installer script for the latest version:
```sh
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/TNO-S3/WuppieFuzz/releases/download/v1.2.0/wuppiefuzz-installer.sh | sh
```

### WuppieFuzz dashboard

Install the Wuppiefuzz dashboard

[repository](https://github.com/TNO-S3/WuppieFuzz-dashboard)

Copy wuppiefuzz to a directory that is already in your path so that it can be run from anywhere.

Installer script for the latest version:
```sh
curl --proto '=https' --tlsv1.2 -LsSf https://github.com/TNO-S3/WuppieFuzz-dashboard/releases/download/v0.1.0/wuppiefuzz-dashboard-installer.sh | sh
```


## Fuzzing

The target can be started using the script by running the following:
```sh
./apply_patch.sh false
```

This will start the target in its original form. Alternatively, the target can be directly started with Docker:
```sh
docker build -t petstore .
docker run -itd -p 8080:8080 --name petstore_fuzz petstore
```

Once the target is active, we can start fuzzing:
```sh
cd fuzzing
wuppiefuzz fuzz --config blackbox.yaml
```

Alternatively, we can edit the file `blackbox.yaml` to change the `timeout` parameter. This parameter indicates how long Wuppiefuzz will fuzz the target.


When WuppieFuzz has finished we can look at the fuzzing results in the dashboard:
```sh
