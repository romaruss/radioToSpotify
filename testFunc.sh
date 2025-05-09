 #!/usr/bin/env bash
set -eu

# Creates a spotify playlist from the top tracks of a list of artist read from a file
# Usage: ./create_playlist_from_artists.sh <filename>
# Requires: curl and jq

# Configure the access_token in config.cfg

source ./config.cfg
source ./getToken.sh


# Internal settings
country="IT"

#if need refresh token
access_token=$(refreshToken)
	#echo $access_token
headers=(-H "Accept application/json" -H "Authorization: Bearer ${access_token}" )

user_id=$(curl -s -X GET "https://api.spotify.com/v1/me" "${headers[@]}" | jq -r ".id")
echo "user ID: "$user_id
#echo "Access Token: "$access_token
#echo "header: "${headers[@]}

getSongId(){
#get song id from song name and Artist
if [ -z "$1" ] || [ "$1" == "null" ]; then
		return
	fi
	#echo "$1"
	strigaSenzaSpazi=${1// /'%20'}
	strigaSenzaSpazi=${strigaSenzaSpazi//'/\'}

	curl -s -X GET "https://api.spotify.com/v1/search?q='$strigaSenzaSpazi'&type=track&country=IT" "${headers[@]}" | jq -r ".tracks.items[0].id"
	
}

removeDuplicatedTracks (){

if [ -z "$1" ] || [ "$1" == "null" ]; then
		echo "removeDuplicatedTracks: Paramentri mancanti"	
		return
	fi
#echo "songID: "$1	
fileTracksDeduplicated="$1-deduplicated"
echo $fileTracksDeduplicated
awk '!a[$0]++' $1 > $fileTracksDeduplicated
oggi=$(date +"%d_%m_%Y")
mv $1 "$1-"$oggi
mv $fileTracksDeduplicated $1
}


getSongListId() {
filename=$1
tracks=""
trackIDs=""
prefissoTrack="spotify:track:"
	#echo "getSongListId"
	i=0
	while read song; do
		#echo "$song"
		songId=$(getSongId "$song")
		##songId=$(removeDuplicatedTracks "$songId")
		#echo "$song":"$songId"		
		if [ "$songId" != "null" ] && [ "$songId" != "" ]; then
			#trackIDs=$(echo -e "$trackIDs$prefissoTrack$songId,")
			trackIDs+=$songId"\n\r"
			#echo $trackIDs			
		fi
		sleep 1
	done < $filename
		
	echo -e $trackIDs > "$filename-tracks"
    removeDuplicatedTracks "$filename-tracks"
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
create_playlist() {
	# Creates a new private playlist if not exists
	name=$1
	#echo "0200createPlaylist: "
	#echo $1
	#echo $(checkPlaylist)
	idPlaylist=""
	idPlaylist=$(checkPlaylist)
	#echo "idPlaylistTrovato: " $idPlaylist
	#echo "0500CheckPlaylistDentroCreate "$(checkPlaylist)
	if [ $idPlaylist ]; then
		#playlist exists
		#echo "playlist esiste"
		#idPlaylist=$(checkPlaylist)
		#svuoto la playlist
		response=$(curl -s -X PUT "https://api.spotify.com/v1/users/${user_id}/playlists/${idPlaylist}/tracks?uris=" "${headers[@]}")
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

	for track in $(cat -v $filename-tracks); do
		if [ $count -lt 10 ]; then
		#echo "accoda id canzone"
		#echo -e $track
			#trackuris+="spotify:track:$track,"
			trackuris=$trackuris$spotifyString
			trackuris+=${track/"^M"/""}","	
			#printf $trackuris"\n"
			count=$(expr $count + 1)
			
		else
		#echo "invia il comando di caricamento tracce"
			trackuris+=$spotifyString${track/"^M"/""}	
			echo "lista tracce da aggiungere:"$trackuris
			response=$(curl -s -X POST "https://api.spotify.com/v1/users/${user_id}/playlists/${playlist}/tracks?uris=$trackuris" "${headers[@]}")
			#echo $response
			trackuris=""
			count=1
			sleep 1
		fi
	#echo "$trackuris"	
	done
	if [ -n "$trackuris" ]; then
	
		response=$(curl -s -X POST "https://api.spotify.com/v1/users/${user_id}/playlists/${playlist}/tracks?uris=$trackuris" "${headers[@]}")
	fi
}


run() {

	filename=$trackFileName	
	touch $trackFileName
	date
	bash ./scaricaElencoTracce.sh
	echo "elenco tracce creato";
	#getSongListId $filename
	#echo "id canzoni creato";
	idPlaylist=$(create_playlist $(basename $filename))
	#echo "0100Playlist:"$idPlaylist
	#echo "0110"
	
	add_tracks_to_playlist $filename $idPlaylist
	echo date": tracce aggiunte alla playlist";
	rm $filename-tracks
	#rm log_createplaylist
	
	
}

run