@echo off
docker build . -t tor-bin -f Dockerfile-build-tor
FOR /F "tokens=*" %%i IN ('docker create tor-bin') DO SET id=%%i
docker cp %id%:/root/tor/install/bin/tor.exe ./bin/tor.exe
docker cp %id%:/donut/loader.zip ./bin/loader.zip
docker rm -v %id%