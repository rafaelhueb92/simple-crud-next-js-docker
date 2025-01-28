PORT=3000

if docker ps -q -f name=$1; then
    echo "Container is running. Stopping . . . "
    docker stop $1
    docker rm $1
fi

docker build -t $1:latest .
docker run -d --name $1 -p $PORT:$PORT $1:latest 

echo "Container $1 running at http://localhost:$PORT"