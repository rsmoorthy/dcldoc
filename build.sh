docker run -u $(id -u):$(id -g) -it --rm -v ${PWD}:/docs mkdocs-material build

docker build -t dcldoc .
docker stop dcldoc; docker rm dcldoc
docker run --init -itd --name dcldoc -p 3000:3000 dcldoc:latest
