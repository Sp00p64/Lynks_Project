docker build . -t tor-bin
id=$(docker create tor-bin)
docker cp %id%:/root/tor/install/bin/tor.exe ./bin/tor.exe
docker rm -v $id