# Production checklist: loan-api 1.0.0

## 1. Slim base image

Command:
```bash
grep '^FROM' Dockerfile.prod
```

Output:
```
FROM python:3.12-slim AS builder
FROM python:3.12-slim
```

Command:
```bash
docker images loan-api
```

Output:
```
IMAGE           ID             DISK USAGE   CONTENT SIZE   EXTRA
loan-api:test   a93637c0fa99        817MB          172MB   U    
```

## 2. Multi-stage build

Command:
```bash
grep -nE '^FROM|COPY --from' Dockerfile.prod
```

Output:
```
2:FROM python:3.12-slim AS builder
12:FROM python:3.12-slim
17:COPY --from=builder /opt/venv /opt/venv
18:COPY --from=builder /app/models/model.joblib /app/models/model.joblib
```

Command:
```bash
docker run --rm loan-api:prod ls -a /app
```

Output:
```
Unable to find image 'loan-api:prod' locally
docker: Error response from daemon: pull access denied for loan-api, repository does not exist or may require 'docker login'

Run 'docker run --help' for more information
```

## 3. Dev dependencies separated

Command:
```bash
cat requirements.txt
```

Output:
```
fastapi[standard]==0.150.0
scikit-learn==1.9.1
pandas==3.0.6
numpy==2.5.4
joblib==1.6.0
```

Command:
```bash
cat requirements-dev.txt
```

Output:
```
-r requirements.txt
pytest==9.1.1
httpx
```

Command:
```bash
docker run --rm loan-api:prod pip show pytest
```

Output:
```
Unable to find image 'loan-api:prod' locally
docker: Error response from daemon: pull access denied for loan-api, repository does not exist or may require 'docker login'

Run 'docker run --help' for more information
```

## 4. Non-root user

Command:
```bash
docker run --rm loan-api:prod whoami
```

Output:
```
Unable to find image 'loan-api:prod' locally
docker: Error response from daemon: pull access denied for loan-api, repository does not exist or may require 'docker login'

Run 'docker run --help' for more information
```

Command:
```bash
docker run --rm loan-api:prod id
```

Output:
```
Unable to find image 'loan-api:prod' locally
docker: Error response from daemon: pull access denied for loan-api, repository does not exist or may require 'docker login'

Run 'docker run --help' for more information
```

## 5. Pinned versions

Command:
```bash
grep '^FROM' Dockerfile.prod
```

Output:
```
FROM python:3.12-slim AS builder
FROM python:3.12-slim
```

Command:
```bash
grep -vE '==|^[[:space:]]*$|^#' requirements.txt || echo 'every line in requirements.txt is pinned'
```

Output:
```
every line in requirements.txt is pinned
```

Command:
```bash
grep 'image:' compose.yaml
```

Output:
```
    image: postgres:16-alpine
```

## 6. HEALTHCHECK

Command:
```bash
docker run -d --name prod -p 8000:8000 loan-api:prod
```

Output:
```
Unable to find image 'loan-api:prod' locally
docker: Error response from daemon: pull access denied for loan-api, repository does not exist or may require 'docker login'

Run 'docker run --help' for more information
```

Command:
```bash
sleep 35; docker ps --filter name=prod
```

Output:
```
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```

Command:
```bash
docker inspect --format '{{.State.Health.Status}}' prod
```

Output:
```

error: no such object: prod
```

Command:
```bash
docker rm -f prod
```

Output:
```
```

## 7. Vulnerability scan (Trivy 0.69.3, HIGH and CRITICAL)

Command:
```bash
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:0.69.3 image --severity HIGH,CRITICAL loan-api:prod
```

Output:
```
Unable to find image 'aquasec/trivy:0.69.3' locally
0.69.3: Pulling from aquasec/trivy
afb5f192254f: Pulling fs layer
15e23908324b: Pulling fs layer
d8ad8cd72600: Pulling fs layer
95841b475c1b: Pulling fs layer
afb5f192254f: Download complete
d8ad8cd72600: Download complete
d8ad8cd72600: Pull complete
95841b475c1b: Download complete
95841b475c1b: Pull complete
15e23908324b: Download complete
afb5f192254f: Pull complete
15e23908324b: Pull complete
Digest: sha256:bcc376de8d77cfe086a917230e818dc9f8528e3c852f7b1aff648949b6258d1c
Status: Downloaded newer image for aquasec/trivy:0.69.3
2026-11-05T03:54:50Z	INFO	[vulndb] Need to update DB
2026-11-05T03:54:50Z	INFO	[vulndb] Downloading vulnerability DB...
2026-11-05T03:54:50Z	INFO	[vulndb] Downloading artifact...	repo="mirror.gcr.io/aquasec/trivy-db:2"
127.25 KiB / 132.22 MiB [>___________________________________________________________] 0.09% ? p/s ?383.25 KiB / 132.22 MiB [>___________________________________________________________] 0.28% ? p/s ?1.31 MiB / 132.22 MiB [>_____________________________________________________________] 0.99% ? p/s ?2.69 MiB / 132.22 MiB [>________________________________________________] 2.03% 4.24 MiB p/s ETA 30s9.12 MiB / 132.22 MiB [--->_____________________________________________] 6.90% 4.24 MiB p/s ETA 29s17.31 MiB / 132.22 MiB [------>________________________________________] 13.09% 4.24 MiB p/s ETA 27s22.75 MiB / 132.22 MiB [-------->______________________________________] 17.21% 6.14 MiB p/s ETA 17s29.03 MiB / 132.22 MiB [---------->____________________________________] 21.96% 6.14 MiB p/s ETA 16s34.06 MiB / 132.22 MiB [------------>__________________________________] 25.76% 6.14 MiB p/s ETA 15s38.59 MiB / 132.22 MiB [------------->_________________________________] 29.19% 7.45 MiB p/s ETA 12s43.59 MiB / 132.22 MiB [--------------->_______________________________] 32.97% 7.45 MiB p/s ETA 11s45.01 MiB / 132.22 MiB [---------------->______________________________] 34.04% 7.45 MiB p/s ETA 11s48.99 MiB / 132.22 MiB [----------------->_____________________________] 37.05% 8.07 MiB p/s ETA 10s51.52 MiB / 132.22 MiB [------------------>_____________________________] 38.97% 8.07 MiB p/s ETA 9s56.46 MiB / 132.22 MiB [-------------------->___________________________] 42.70% 8.07 MiB p/s ETA 9s58.46 MiB / 132.22 MiB [--------------------->__________________________] 44.22% 8.58 MiB p/s ETA 8s62.63 MiB / 132.22 MiB [---------------------->_________________________] 47.37% 8.58 MiB p/s ETA 8s66.63 MiB / 132.22 MiB [------------------------>_______________________] 50.39% 8.58 MiB p/s ETA 7s67.87 MiB / 132.22 MiB [------------------------>_______________________] 51.33% 9.03 MiB p/s ETA 7s74.60 MiB / 132.22 MiB [--------------------------->____________________] 56.42% 9.03 MiB p/s ETA 6s79.66 MiB / 132.22 MiB [---------------------------->___________________] 60.25% 9.03 MiB p/s ETA 5s86.72 MiB / 132.22 MiB [------------------------------>________________] 65.59% 10.48 MiB p/s ETA 4s91.19 MiB / 132.22 MiB [-------------------------------->______________] 68.97% 10.48 MiB p/s ETA 3s98.22 MiB / 132.22 MiB [---------------------------------->____________] 74.29% 10.48 MiB p/s ETA 3s102.25 MiB / 132.22 MiB [----------------------------------->__________] 77.33% 11.48 MiB p/s ETA 2s108.50 MiB / 132.22 MiB [------------------------------------->________] 82.06% 11.48 MiB p/s ETA 2s112.56 MiB / 132.22 MiB [--------------------------------------->______] 85.13% 11.48 MiB p/s ETA 1s116.60 MiB / 132.22 MiB [---------------------------------------->_____] 88.18% 12.28 MiB p/s ETA 1s122.60 MiB / 132.22 MiB [------------------------------------------>___] 92.73% 12.28 MiB p/s ETA 0s128.38 MiB / 132.22 MiB [-------------------------------------------->_] 97.10% 12.28 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 13.17 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 13.17 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 13.17 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 12.32 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 12.32 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 12.32 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 11.53 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 11.53 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 11.53 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 10.78 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 10.78 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 10.78 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 10.09 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 10.09 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------->] 100.00% 10.09 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 9.44 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 9.44 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 9.44 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 8.83 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 8.83 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 8.83 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 8.26 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 8.26 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 8.26 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 7.73 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 7.73 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 7.73 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 7.23 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 7.23 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 7.23 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 6.76 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 6.76 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 6.76 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 6.33 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 6.33 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 6.33 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 5.92 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 5.92 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 5.92 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 5.54 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 5.54 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 5.54 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 5.18 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 5.18 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 5.18 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 4.84 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 4.84 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [--------------------------------------------->] 100.00% 4.84 MiB p/s ETA 0s132.22 MiB / 132.22 MiB [-------------------------------------------------] 100.00% 8.48 MiB p/s 16s2026-11-05T03:55:07Z	INFO	[vulndb] Artifact successfully downloaded	repo="mirror.gcr.io/aquasec/trivy-db:2"
2026-11-05T03:55:07Z	INFO	[vuln] Vulnerability scanning is enabled
2026-11-05T03:55:07Z	INFO	[secret] Secret scanning is enabled
2026-11-05T03:55:07Z	INFO	[secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
2026-11-05T03:55:07Z	INFO	[secret] Please see https://trivy.dev/docs/v0.69/guide/scanner/secret#recommendation for faster secret detection

📣 [34mNotices:[0m
  - Version 0.76.1 of Trivy is now available, current version is 0.69.3

To suppress version checks, run Trivy scans with the --skip-version-check flag

2026-11-05T03:55:10Z	FATAL	Fatal error	run error: image scan error: scan error: unable to initialize a scan service: unable to initialize artifact: unable to initialize container image: unable to find the specified image "loan-api:prod" in ["docker" "containerd" "podman" "remote"]: 4 errors occurred:
	* docker error: unable to inspect the image (loan-api:prod): Error response from daemon: No such image: loan-api:prod
	* containerd error: containerd socket not found: /run/containerd/containerd.sock
	* podman error: unable to initialize Podman client: no podman socket found: stat podman/podman.sock: no such file or directory
	* remote error: GET https://index.docker.io/v2/library/loan-api/manifests/prod: UNAUTHORIZED: authentication required; [map[Action:pull Class: Name:library/loan-api Type:repository]]


```

## Compose stack on the production image

Command:
```bash
docker compose up -d --build
```

Output:
```
 Image postgres:16-alpine Pulling 
 b42df618ae2f Pulling fs layer 0B
 83a0667f02af Pulling fs layer 0B
 12eb05ec409b Pulling fs layer 0B
 4c61df2d098f Pulling fs layer 0B
 c16ec84c7f8a Pulling fs layer 0B
 3159dc2110dd Pulling fs layer 0B
 a5b991b88e79 Pulling fs layer 0B
 b17bb49abe22 Pulling fs layer 0B
 4f775f9c8b66 Pulling fs layer 0B
 340c083268fd Pulling fs layer 0B
 b42df618ae2f Download complete 0B
 4c61df2d098f Download complete 0B
 12eb05ec409b Download complete 0B
 12eb05ec409b Extracting 1B
 c16ec84c7f8a Download complete 0B
 12eb05ec409b Extracting 1B
 12eb05ec409b Extracting 1B
 83a0667f02af Downloading 2.097MB
 12eb05ec409b Extracting 1B
 3159dc2110dd Download complete 0B
 83a0667f02af Downloading 2.097MB
 12eb05ec409b Extracting 1B
 83a0667f02af Downloading 5.243MB
 12eb05ec409b Extracting 1B
 83a0667f02af Downloading 8.389MB
 340c083268fd Download complete 0B
 12eb05ec409b Extracting 1B
 83a0667f02af Downloading 13.63MB
 b17bb49abe22 Download complete 0B
 12eb05ec409b Extracting 1B
 83a0667f02af Downloading 14.68MB
 12eb05ec409b Extracting 1B
 a5b991b88e79 Download complete 0B
 83a0667f02af Downloading 16.78MB
 12eb05ec409b Extracting 1B
 83a0667f02af Downloading 19.92MB
 12eb05ec409b Extracting 1B
 4f775f9c8b66 Download complete 0B
 83a0667f02af Downloading 25.17MB
 12eb05ec409b Extracting 2B
 83a0667f02af Downloading 30.41MB
 12eb05ec409b Extracting 2B
 83a0667f02af Downloading 34.6MB
 4c61df2d098f Pull complete 0B
 12eb05ec409b Pull complete 0B
 c16ec84c7f8a Pull complete 0B
 3159dc2110dd Pull complete 0B
 83a0667f02af Downloading 37.75MB
 83a0667f02af Downloading 40.89MB
 83a0667f02af Downloading 45.09MB
 83a0667f02af Downloading 49.28MB
 d335ff64513c Download complete 0B
 83a0667f02af Downloading 54.53MB
 83a0667f02af Downloading 59.77MB
 83a0667f02af Downloading 60.82MB
 83a0667f02af Downloading 65.01MB
 83a0667f02af Downloading 70.25MB
 156554aa89fc Download complete 0B
 83a0667f02af Downloading 75.5MB
 83a0667f02af Downloading 80.74MB
 83a0667f02af Downloading 80.74MB
 83a0667f02af Downloading 84.93MB
 83a0667f02af Downloading 90.18MB
 83a0667f02af Downloading 95.42MB
 83a0667f02af Downloading 100.7MB
 83a0667f02af Downloading 101.7MB
 83a0667f02af Downloading 105.9MB
 83a0667f02af Download complete 0B
 83a0667f02af Extracting 1B
 83a0667f02af Extracting 1B
 83a0667f02af Extracting 1B
 83a0667f02af Extracting 1B
 83a0667f02af Extracting 1B
 83a0667f02af Extracting 1B
 83a0667f02af Extracting 1B
 83a0667f02af Extracting 1B
 83a0667f02af Extracting 1B
 83a0667f02af Extracting 1B
 b42df618ae2f Pull complete 0B
 340c083268fd Pull complete 0B
 b17bb49abe22 Pull complete 0B
 a5b991b88e79 Pull complete 0B
 4f775f9c8b66 Pull complete 0B
 83a0667f02af Pull complete 0B
 Image postgres:16-alpine Pulled 
 Image loan-api-api Building 
#1 [internal] load local bake definitions
#1 reading from stdin 527B done
#1 DONE 0.0s

#2 [internal] load build definition from Dockerfile.prod
#2 transferring dockerfile: 1.03kB done
#2 DONE 0.0s

#3 [auth] library/python:pull token for registry-1.docker.io
#3 DONE 0.0s

#4 [internal] load metadata for docker.io/library/python:3.12-slim
#4 DONE 1.5s

#5 [internal] load .dockerignore
#5 transferring context: 119B done
#5 DONE 0.0s

#6 [internal] load build context
#6 transferring context: 177B done
#6 DONE 0.0s

#7 [builder 1/7] FROM docker.io/library/python:3.12-slim@sha256:b18b261e1b4974b4f321451ad5251ded85abb22c2b8b262da527dda1d031ab30
#7 resolve docker.io/library/python:3.12-slim@sha256:b18b261e1b4974b4f321451ad5251ded85abb22c2b8b262da527dda1d031ab30 0.0s done
#7 DONE 0.0s

#8 [builder 2/7] WORKDIR /app
#8 CACHED

#9 [builder 7/7] RUN python train.py --out /app/models/model.joblib
#9 CACHED

#10 [builder 6/7] COPY loan-api/train.py .
#10 CACHED

#11 [builder 3/7] RUN python -m venv /opt/venv
#11 CACHED

#12 [stage-1 3/6] WORKDIR /app
#12 CACHED

#13 [stage-1 2/6] RUN useradd --create-home --uid 1000 appuser
#13 CACHED

#14 [builder 4/7] COPY requirements.txt .
#14 CACHED

#15 [stage-1 4/6] COPY --from=builder /opt/venv /opt/venv
#15 CACHED

#16 [builder 5/7] RUN pip install --no-cache-dir -r requirements.txt
#16 CACHED

#17 [stage-1 5/6] COPY --from=builder /app/models/model.joblib /app/models/model.joblib
#17 CACHED

#18 [stage-1 6/6] COPY loan-api/schemas.py loan-api/main.py ./
#18 CACHED

#19 exporting to image
#19 exporting layers done
#19 exporting manifest sha256:07f857763e3316af4f33f89cc9ecd2f5f23f695e1a7d73591c1758b683ba0e4e 0.0s done
#19 exporting config sha256:fd7c03c90a335cc8b1f6cc2dccbbd7dfefc8d54e2548e561fe502e52e81964cc 0.0s done
#19 exporting attestation manifest sha256:407390f49b206ceea6a5eb9d0b55f6a94e1d8588790b03e1c6480b9cc7ffa575 0.0s done
#19 exporting manifest list sha256:f08356d22b3526fbdfdfa899624d82be4e6ae7f618fcf142b8ea8caf572e5d86 done
#19 naming to docker.io/library/loan-api-api:latest done
#19 unpacking to docker.io/library/loan-api-api:latest done
#19 DONE 0.1s

#20 resolving provenance for metadata file
#20 DONE 0.0s
 Image loan-api-api Built 
 Volume loan-api_postgres-data Creating 
 Volume loan-api_model-data Creating 
 Network loan-api_default Creating 
 Volume loan-api_postgres-data Creating 
 Volume loan-api_model-data Creating 
 Network loan-api_default Creating 
 Volume loan-api_model-data Created 
 Volume loan-api_model-data Created 
 Volume loan-api_postgres-data Created 
 Volume loan-api_postgres-data Created 
 Network loan-api_default Created 
 Network loan-api_default Created 
 Container loan-api-db-1 Creating 
 Container loan-api-db-1 Created 
 Container loan-api-api-1 Creating 
 Container loan-api-api-1 Created 
 Container loan-api-db-1 Starting 
 Container loan-api-db-1 Started 
 Container loan-api-db-1 Waiting 
 Container loan-api-db-1 Healthy 
 Container loan-api-api-1 Starting 
Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint loan-api-api-1 (b3d72af8a448d922147b167c8e86af612c147264f8477a94b76f5abb4ef1cda6): Bind for 0.0.0.0:8000 failed: port is already allocated
```

Command:
```bash
sleep 35; docker compose ps
```

Output:
```
NAME            IMAGE                COMMAND                  SERVICE   CREATED          STATUS                    PORTS
loan-api-db-1   postgres:16-alpine   "docker-entrypoint.s…"   db        41 seconds ago   Up 40 seconds (healthy)   0.0.0.0:5432->5432/tcp, [::]:5432->5432/tcp
```

Command:
```bash
docker compose down
```

Output:
```
 Container loan-api-api-1 Stopping 
 Container loan-api-api-1 Stopped 
 Container loan-api-api-1 Removing 
 Container loan-api-api-1 Removed 
 Container loan-api-db-1 Stopping 
 Container loan-api-db-1 Stopped 
 Container loan-api-db-1 Removing 
 Container loan-api-db-1 Removed 
 Network loan-api_default Removing 
 Network loan-api_default Removed 
```

## No secrets

Command:
```bash
grep -rniE 'password|secret|token|api_key' --exclude-dir=.git --exclude=CHECKLIST.md --exclude=make_checklist.sh . || echo none
```

Output:
```
./checklist.md:232:2026-11-05T03:55:07Z	INFO	[secret] Secret scanning is enabled
./checklist.md:233:2026-11-05T03:55:07Z	INFO	[secret] If your scanning is slow, please try '--scanners vuln' to disable secret scanning
./checklist.md:234:2026-11-05T03:55:07Z	INFO	[secret] Please see https://trivy.dev/docs/v0.69/guide/scanner/secret#recommendation for faster secret detection
./checklist.md:354:#3 [auth] library/python:pull token for registry-1.docker.io
./checklist.md:472:## No secrets
./checklist.md:476:grep -rniE 'password|secret|token|api_key' --exclude-dir=.git --exclude=CHECKLIST.md --exclude=make_checklist.sh . || echo none
./compose.yaml:23:      POSTGRES_PASSWORD: loan
```

Command:
```bash
docker history --no-trunc loan-api:prod | grep -iE 'password|secret|token|api_key' || echo 'no secrets in image history'
```

Output:
```
Error response from daemon: No such image: loan-api:prod
no secrets in image history
```
