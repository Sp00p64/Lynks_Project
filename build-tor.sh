docker build . -t tor-bin -f Dockerfile-build-tor
id=$(docker create tor-bin)
docker cp $id:/root/tor/install/bin/tor.exe ./bin/tor.exe
docker cp $id:/donut/loader.zip ./bin/loader.zip
docker rm -v $id