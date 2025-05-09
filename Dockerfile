# Usa Alpine per un'immagine leggera
FROM alpine:3.21.3


# Installa Bash, Git, Curl e altri pacchetti necessari
RUN apk add --no-cache bash git curl jq coreutils gawk 

# Imposta la directory di lavoro
WORKDIR /app

# Crea la cartella di lavoro
RUN mkdir -p workfiles

# Copia gli script, il file di configurazione e la cartella workfiles
COPY . .

# Rendi eseguibili gli script
RUN chmod +x *.sh

# Crea la cartella per i cron job
RUN mkdir -p /etc/crontabs/

# Aggiungi il cron job
RUN echo "${CRON} /bin/bash /app/createPlaylist.sh >> /app/cron.log 2>&1" > /etc/crontabs/root

# Assicurati che il log file esista
RUN touch /app/cron.log

# Avvia crond in modalità foreground
CMD ["crond", "-f", "-l", "2"]
