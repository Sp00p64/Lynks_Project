# Lynks Project

## DISCLAIMER

This is a project because i'm passionate about malware dev, this should absolutely not be used on a computer without it's owner permission, and is just a POC which only allows for a rudimentary shell.

## Intro

Lynks is a WIP advanced POC of a C&C malware written in NIM over Tor with a python flask server using libcurl for network requests 

(<i> Why libcurl ? Because for now the httpclient module of NIM doesnt support SOCKS5 needed by tor </i>)

## What makes this malware different ?

-  <b> Communication protocol  </b>: This malware injects TOR compressed shellcode within itself to open the port 9050 for SOCKS5H connections allowing network requests over the tor network

-  <b>Size </b> : Thanks to NIM and my own implementation of the libcurll dll this malware once compiled stays at a low 5-8mb 

-  <b>Speed </b> : Communications via requests over TOR usually takes a lot of time because of all the hops a request has to go through. To solve this issue my implementation of libcurl establishes a WebSocket over the hidden service. Thanks to this the establishment of the session is slow but once established the shell is quite responsive and fast for a TOR communication

## Install :
(For now the malware can only be built on windows and deployed on windows machines, linux support is coming soon)


- Install NIM
- Install necessary modules : 
    
      nimble install -y memlib zippy nimclipboard

- Now launch the batch script (This script will construct a docker image to build tor as a static binary and then encode it to a shellcode file)

      ./build-tor.bat

- Compile the project 

      nim c -d:release main.nim

## What's next ?

- Increase stability 
- Bug fix
- Mutli-session/shell mechanism
- Modules

## Credits 

Thanks to Araq 
[Libcurl wrapper in NIM](https://github.com/Araq/libcurl/tree/master) I had a starting point but I needed to add the websocket implementation

Also thanks to this project : 
[build_tor_static](https://github.com/fugitivus/tor-static/blob/master/tor-static-linux.sh) 
I had a way to cross-compile tor, i just had to change some settings and then dockerize it