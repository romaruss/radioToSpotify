#!/bin/bash


function refreshToken(){
#echoes the new token

#echo "base64ClientIDSecret: " $base64ClientIDSecret
#echo "refreshTokenCFG: " $refreshTokenCFG

if [ -z "${refreshTokenCFG:-}" ]; then

    # Se il file non esiste, crealo con contenuto "null"
    if [ ! -f "$refreshTokenFile" ]; then
        echo "null" > "$refreshTokenFile"
    fi

    # Leggi il contenuto del file
    refreshTokenCFG=$(cat "$refreshTokenFile")
fi

curl -s -H "Authorization: Basic $base64ClientIDSecret" -d grant_type=refresh_token -d refresh_token=$refreshTokenCFG https://accounts.spotify.com/api/token | jq -r ".access_token"

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