# dcldoc


## One-time

```
docker build -t mkdocs-material -f Dockerfile.mkdocs-material .
```


## Develop


```
docker run -u $(id -u):$(id -g) -it --rm -p 8000:8000 -v ${PWD}:/docs mkdocs-material
```

## Build and Deploy

```
docker run -u $(id -u):$(id -g) -it --rm -v ${PWD}:/docs mkdocs-material build

docker build -t dcldoc .
```

# Run and Use

```
# Pull the latest
docker stop dcldoc; docker rm dcldoc
docker run --init -itd --name dcldoc -p 3000:3000 dcldoc:latest
```


