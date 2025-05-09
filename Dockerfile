# Usa Alpine per un'immagine leggera
FROM alpine:latest

# Installa Bash, Git e Curl (o altri pacchetti necessari)
RUN apk add --no-cache bash git curl

# Imposta la directory di lavoro
WORKDIR /app

# Copia gli script, il file di configurazione e la cartella workdir
COPY . .

# Rendi eseguibili gli script
RUN chmod +x *.sh

# Specifica un comando di default (può essere uno script principale o un menu)
CMD ["bash", "./createPlaylist.sh"]

