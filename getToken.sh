#!/bin/bash

# Funzione per aggiornare il token di accesso utilizzando il refresh token
function refreshToken() {
    # Debug
    if [ -n "$LIVELLODEBUG" ] && [ "$LIVELLODEBUG" -gt 0 ]; then
        echo "ST 1000 base64ClientIDSecret: $base64ClientIDSecret"
        echo "ST 1100 refreshTokenCFG: $refreshTokenCFG"
    fi

    # Verifica se la variabile refreshTokenCFG è vuota
    if [ -z "$refreshTokenCFG" ]; then
        if [ -f "$refreshTokenFile" ]; then
            refreshTokenCFG=$(cat "$refreshTokenFile")
        else
            echo "Errore: Il file $refreshTokenFile non esiste."
            exit 1
        fi
    fi

    # Richiede il nuovo token
    curl -s -H "Authorization: Basic $base64ClientIDSecret" \
        -d grant_type=refresh_token \
        -d refresh_token="$refreshTokenCFG" \
        https://accounts.spotify.com/api/token | jq -r ".access_token"
}

# Funzione per ottenere il refresh token dal codice di autorizzazione
function getRefreshTokenFromCode() {
    # Verifica se il codice è già stato utilizzato
    if [ -f "$codeUsedFile" ]; then
        echo "Il codice è già stato utilizzato."
        exit
    fi

    # Richiede il refresh token
    curl -s -H "Authorization: Basic $base64ClientIDSecret" \
        -d grant_type=authorization_code \
        -d code="$code" \
        -d redirect_uri=http%3A%2F%2Flocalhost%3A8082 \
        https://accounts.spotify.com/api/token | jq -r ".refresh_token" > "$refreshTokenFile"

    # Segna il codice come utilizzato
    touch "$codeUsedFile"
}

# Esempio di utilizzo
# source ./config.cfg
# getRefreshTokenFromCode
# refreshToken
