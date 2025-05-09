#!/bin/bash


function refreshToken(){
#echoes the new token

#echo "base64ClientIDSecret: " $base64ClientIDSecret
#echo "refreshTokenCFG: " $refreshTokenCFG

if [ -z $refreshTokenCFG ]; then

	refreshTokenCFG=$(cat $refreshTokenFile)
fi

curl -s -H "Authorization: Basic $base64ClientIDSecret" -d grant_type=refresh_token -d refresh_token=$refreshTokenCFG https://accounts.spotify.com/api/token | jq -r ".access_token"


#curl  -H "Authorization: Basic NGNjMGVmMjljMzIyNDZmNzk3OWIwZTY4ZmZkNjFmYzk6MzQ1ZGU2N2U3NjAzNDFjOGEyMmQyOTBlZDFkNTE3MWY=" -d grant_type=refresh_token -d refresh_token=AQBSPRBKZvYQAr8Orm7xcH3MufYk9v5QG4C-sRvs-h9fE9_wT8f4jxhttt9P3yOij1jeoQLsKxYY6HhlSf32vBatK-wbuKPUOT6SvdSzb2E53gvmBoN9atEUokDfltoZ8nQ https://accounts.spotify.com/api/token | jq ".access_token"
}

function getRefreshTokenFromCode()
{
if [ -f "$codeUsedFile" ]; then
	exit
fi
curl -s -H "Authorization: Basic $base64ClientIDSecret" -d grant_type=authorization_code -d code=$code -d redirect_uri=http%3A%2F%2Flocalhost%3A8082 https://accounts.spotify.com/api/token | jq -r .refresh_token > $refreshTokenFile
touch codeUsedFile
}


#source ./config.cfg
#getRefreshTokenFromCode

#refreshToken