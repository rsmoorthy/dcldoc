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

# To build as root directory
docker build -t dcldoc .
# To build under docs/ url
docker build --build-arg PREFIX=docs -t dcldoc .
```

# Run and Use

```
# Pull the latest
docker stop dcldoc; docker rm dcldoc
docker run --init -itd --name dcldoc --restart=always -p 3000:3000 dcldoc:latest
```


