 #!/usr/bin/env bash
set -eu

# Creates a spotify playlist from the top tracks of a list of artist read from a file
# Usage: ./create_playlist_from_artists.sh <filename>
# Requires: curl and jq

# Configure the access_token in config.cfg

source ./cfg/config.cfg
source ./getToken.sh

if [ -z "$LIVELLODEBUG" ]; then
  LIVELLODEBUG=0
fi
# Internal settings
country="IT"

#if need refresh token
access_token=$(refreshToken)
	#echo $access_token
headers=(-H "Accept application/json" -H "Authorization: Bearer ${access_token}" )

#user_id=$(curl -s -X GET "https://api.spotify.com/v1/me" "${headers[@]}" | jq -r ".id")
response=$(curl -s -X GET "https://api.spotify.com/v1/me" "${headers[@]}")
if [ $? -ne 0 ] || [ -z "$response" ]; then
    echo "Errore: impossibile ottenere i dettagli utente" >&2
    exit 1
fi
user_id=$(echo "$response" | jq -r ".id")

#debug
if [ "$LIVELLODEBUG" -gt 0 ]; then
	echo "user ID: "$user_id
fi
#echo "Access Token: "$access_token
#echo "header: "${headers[@]}

getSongId(){
#get song id from song name and Artist
if [ -z "$1" ] || [ "$1" == "null" ]; then
		return
	fi
	#echo "$1"
	#strigaSenzaSpazi=${1// /'%20'}
	#strigaSenzaSpazi=${strigaSenzaSpazi//'/\'}
	strigaSenzaSpazi=$(jq -rn --arg str "$1" '$str | @uri')

	curl -s -X GET "https://api.spotify.com/v1/search?q='$strigaSenzaSpazi'&type=track&country=IT" "${headers[@]}" | jq -r ".tracks.items[0].id"
	
}

removeDuplicatedTracks (){

if [ -z "$1" ] || [ "$1" == "null" ]; then
		echo "removeDuplicatedTracks: Paramentri mancanti"	
		return
	fi
#echo "songID: "$1	
fileTracksDeduplicated="$1-deduplicated"

#debug
if [ "$LIVELLODEBUG" -gt 0 ]; then
	echo "ST removeDuplicatedTracks 900 * $fileTracksDeduplicated" >&2
fi

#elimino le righe duplicate
awk '!a[$0]++' $1 > $fileTracksDeduplicated

#debug
if [ "$LIVELLODEBUG" -gt 0 ]; then
	echo "ST:removeDuplicatedTracks 001000 * $1"
fi
	
cp $1 "$1-ieri"
#debug
if [ "$LIVELLODEBUG" -gt 0 ]; then
	echo "ST:removeDuplicatedTracks 001001 * shuf  $fileTracksDeduplicated > $1"
fi	

shuf  $fileTracksDeduplicated > $1

#debug
#if [ "$LIVELLODEBUG" -gt 0 ]; then
#	echo "ST removeDuplicatedTracks 970 * $fileTracksDeduplicated" >&2
#fi
#awk '!a[$0]++' "$1" | sort -R > "$1-deduplicated"
#mv "$1-deduplicated" "$1"

}


getSongListId() {

ora_minima=$C_ora_minima
ora_massima=$C_ora_massima
stringaGiorni=$C_stringaGiorni

almenoUnaCanzone=0

filename=$1
tracks=""
trackIDs=""
prefissoTrack="spotify:track:"
	#echo "getSongListId" >&2
	i=0
	#per ogni canzone in elenco
	almenoUnaCanzone=0
	while read song; do
		#echo "song""$song" >&2
		
		#la variabile $song contiene data/ora di riproduzione e il titolo
		#qua le separo
		# Estrai la data
		data=${song:1:19}
		# Estrai il testo
		nomeCanzone=${song:22}
		# Estrai l'ora
		ora=$(date -d "$data" +"%H:%M:%S")

		#debug
		if [ "$LIVELLODEBUG" -gt 0 ]; then
			# Stampa la data e il testo
			echo "Data: $data" >&2
			echo "NomeCanzone: $nomeCanzone" >&2
			echo "Ora: $ora" >&2
		fi
		
		giorno_numero=$(date -d "$data" +%w)
		
		if [[ $stringaGiorni =~ $giorno_numero ]]; then
			
			if [[ "$ora" > "$ora_minima" && "$ora" < "$ora_massima" ]]; then

				#se il giorno e l'ora della canzone sono OK 
				#recupero l'id della canzone e lo metto in coda nel file
				
				songId=$(getSongId "$nomeCanzone")
				##songId=$(removeDuplicatedTracks "$songId")
				#debug
				if [ "$LIVELLODEBUG" -gt 0 ]; then
					echo "$nomeCanzone":"$songId" >&2 
				fi
				if [ "$songId" != "null" ] && [ "$songId" != "" ]; then
					#trackIDs=$(echo -e "$trackIDs$prefissoTrack$songId,")
					trackIDs+=$songId"\n"
					#echo $trackIDs			
				fi
				almenoUnaCanzone=1
				sleep 1
			else
				#debug
				if [ "$LIVELLODEBUG" -gt 0 ]; then
					echo "Scarto per l'ora $nomeCanzone Data: $data Ora: $ora" >&2
				fi
			fi
		else
			#debug
			if [ "$LIVELLODEBUG" -gt 0 ]; then
				echo "Scarto per la data $nomeCanzone Data: $data Ora: $ora" >&2
			fi
		fi
	#fine ciclo	
	done < $filename
	#debug
	if [ "$LIVELLODEBUG" -gt 0 ]; then
		echo "ST getSongListId 1000 * fineCiclo: almenoUnaCanzone= $almenoUnaCanzone" >&2
	fi
	
	#se c'è almeno una canzone inserisce la nuova playlist
	if [ "$almenoUnaCanzone" -eq 1 ]; then	
		
		#debug
		if [ "$LIVELLODEBUG" -gt 0 ]; then
			echo "ST getSongListId 1100 *trovate nuove canzoni" >&2
		fi
		
		echo -e $trackIDs > "$filename-tracks"
		removeDuplicatedTracks "$filename-tracks"
	else
	#se non ci suono nuove canzoni rimescola la playlist vecchia
		#debug
		if [ "$LIVELLODEBUG" -gt 0 ]; then
			echo "ST getSongListId 1200 * non ci sono nuove canzoni" >&2
		fi
		#faccio ri-randomizzare l'elenco
		mv $filename-tracks-deduplicated $filename-tracks
		removeDuplicatedTracks "$filename-tracks"
	fi
	#debug
	if [ "$LIVELLODEBUG" -gt 0 ]; then
		echo "ST getSongListId 1300 *  alla fine" >&2
	fi
	echo $almenoUnaCanzone

}

checkPlaylist(){
	#echo "0300CheckPlaylist"
	#echo "playlistNameG: "$playlistNameG
	# TEST: curl -s -X GET https://api.spotify.com/v1/users/romaruss/playlists -H Accept application/json -H  "Authorization: Bearer BQDfGoZFiKyN5K7jasua7cka_i1rMTp3DQ5kSHIgoS7aux_Zy2P84-ZBH40ZGHJTeLHbHvY-xsPCaetL2j81oVne2fdD05HkA4tVT9nwq9412sUZDNW95hzAkhUIRn2CyBk9PkiIcMBcifh8q52ShEwmXWKHiePGVW-wjTr_RiXVZUKLpJs2sVw8EZis"
	#continua# | jq -r --arg instance "Deejay yesterday" '.items | .[] | select (.name==$instance) |.id'
	myPlaylistID=""
	#myPlaylistID=$(curl -s -X GET https://api.spotify.com/v1/users/$user_id/playlists "${headers[@]}" | jq -r --arg instance "$playlistNameG" '.items | .[] | select(.name == $instance) | .id')
	myPlaylistID=$(curl -s -X GET https://api.spotify.com/v1/users/$user_id/playlists "${headers[@]}" | jq -r --arg instance "$playlistNameG" '.items | .[] | select(.name == $instance) | .id')

echo $myPlaylistID

}

getPlaylistSnapshot(){
	myPlaylistSnapshot=""
	myPlaylistSnapshot=$(curl -s -X GET https://api.spotify.com/v1/users/$user_id/playlists "${headers[@]}" | jq -r --arg instance "$playlistNameG" '.items | .[] | select(.name == $instance) | .snapshot_id')
echo $myPlaylistSnapshot

}

create_playlist() {
	# Creates a new private playlist if not exists
	name=$1
	#echo "0200createPlaylist: "
	#echo $1
	#echo $(checkPlaylist)
	idPlaylist=""
	idPlaylist=$(checkPlaylist)
	
	myPlaylistSnapshot=""
	myPlaylistSnapshot=$(getPlaylistSnapshot)
	
	#echo "idPlaylistTrovato: " $idPlaylist
	#echo "0500CheckPlaylistDentroCreate "$(checkPlaylist)
	if [ $idPlaylist ]; then
		#playlist exists
		#echo "playlist esiste"
		#idPlaylist=$(checkPlaylist)
		#debug
		if [ "$LIVELLODEBUG" -gt 0 ]; then
			echo "ST create_playlist 1000 playlist esiste, idPlaylist=$idPlaylist  myPlaylistSnapshot=$myPlaylistSnapshot" >&2
		fi
		#svuoto la playlist
		response=$(curl -s -X PUT "https://api.spotify.com/v1/playlists/${idPlaylist}/tracks?uris=" "${headers[@]}" | jq '.snapshot_id // .error.message')
		#debug
		if [ "$LIVELLODEBUG" -gt 0 ]; then
			echo "ST create_playlist 1100 risposta svuoto la playlist: $response" >&2
		fi
	else	
		#need to create new playlist
		#echo "playlist da creare"
		idPlaylist=$(curl -s -X POST "https://api.spotify.com/v1/users/${user_id}/playlists" --data "{\"name\":\"$playlistNameG\", \"public\":false}" "${headers[@]}" | jq -r ".id")
	fi 
	
	#echo "stmt:0900"
echo $idPlaylist
}

checkTrackExist(){
playlistId=$1
trackId=$2


}
add_tracks_to_playlist() {
	# Add track_ids from a file to a playlist_id
	filename=$1
	playlist=$2
	count=1
	trackuris=""
	spotifyString="spotify:track:"
	#debug
	if [ "$LIVELLODEBUG" -gt 0 ]; then
		echo "ST:add_tracks_to_playlist 00900 * entro nel ciclo per aggiungere tracce alla playlist entro nel file $filename-tracks"
	fi
	for track in $(cat -v $filename-tracks); do
	
	#debug
	if [ "$LIVELLODEBUG" -gt 0 ]; then
		echo "ST:add_tracks_to_playlist 001000 * count=$count"
	fi
	
		if [ $count -lt 10 ]; then
		#echo "accoda id canzone"
		#debug
		if [ "$LIVELLODEBUG" -gt 0 ]; then
			echo "ST:add_tracks_to_playlist 001050 * track=$track"  >$2
		fi
			#trackuris+="spotify:track:$track,"
			trackuris=$trackuris$spotifyString
			trackuris+=${track/"^M"/""}","	
			#printf $trackuris"\n"
			count=$(expr $count + 1)
			
		else
			#debug
			if [ "$LIVELLODEBUG" -gt 0 ]; then
				echo "ST:add_tracks_to_playlist 001100 * invia il comando di caricamento tracce"
			fi
			
			trackuris+=$spotifyString${track/"^M"/""}
			#echo "lista tracce da aggiungere:"$trackuris
			response=$(curl -s -X POST "https://api.spotify.com/v1/users/${user_id}/playlists/${playlist}/tracks?uris=$trackuris" "${headers[@]}")
			trackuris=""
			count=1
			#debug
			if [ "$LIVELLODEBUG" -gt 0 ]; then
				echo "ST:add_tracks_to_playlist 001100 * response=$response"
			fi
			sleep 1
		fi
	#echo "$trackuris"	
	done
	if [ -n "$trackuris" ]; then
		#debug
		if [ "$LIVELLODEBUG" -gt 0 ]; then
			echo "response=-s -X POST https://api.spotify.com/v1/users/${user_id}/playlists/${playlist}/tracks?uris=$trackuris ${headers[@]})"
		fi
		response=$(curl -s -X POST "https://api.spotify.com/v1/users/${user_id}/playlists/${playlist}/tracks?uris=$trackuris" "${headers[@]}")
		
		#debug
		if [ "$LIVELLODEBUG" -gt 0 ]; then
			echo "ST:add_tracks_to_playlist 001200 * response=$response"
		fi
	fi
}


run() {

		filename=$workfolder$trackFileName	
		touch $workfolder$trackFileName
		
		echo "ora inizio: "  $(date)
		bash ./scaricaElencoTracce.sh
		#debug
		if [ "$LIVELLODEBUG" -gt 0 ]; then
			echo "ST run 1000 * elenco tracce creato";
		fi
		#getSongListId $filename
		
		nuoveCanzoni=$(getSongListId $filename)
		#debug
		if [ "$LIVELLODEBUG" -gt 0 ]; then
			echo "ST run 1100 * ci sono nuove canzoni: $nuoveCanzoni" >&2
		fi
	
		#echo "id canzoni creato";
		idPlaylist=$(create_playlist $(basename $filename))
		#echo "0100Playlist:"$idPlaylist
		#echo "0110"
		add_tracks_to_playlist $filename $idPlaylist
		
		echo "ora fine: "  $(date)
		#debug
		if [ "$LIVELLODEBUG" -gt 0 ]; then
			echo "ST run 1200 * tracce aggiunte alla playlist"
		fi
		mv $filename"-tracks" $filename"-tracksOld"
		#rm log_createplaylist

}

run