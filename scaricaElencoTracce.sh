 #!/usr/bin/env bash
set -eu

# https://onlineradiobox.com/it/deejay/playlist/
 
#urlLink="https://onlineradiobox.com/it/deejay/playlist/"
#removeHtmlChar='s/&nbsp;/ /g; s/&amp;/\&/g; s/&lt;/\</g; s/&gt;/\>/g; s/&quot;/\"/g; s/&#39;/\'"'"'/g; s/&ldquo;/\"/g; s/&rdquo;/\"/g;'
#selectTrackBefore="s/\<td\>.*ajax\"\>//g;"
#selectTrackAfter="s/\<.*td\>//"


urlLink="https://www.smarttuner.net/titoli/radio-deejay/"
removeHtmlChar='s/&nbsp;/ /g; s/&amp;/\&/g; s/&lt;/\</g; s/&gt;/\>/g; s/&quot;/\"/g; s/&#39;/\'"'"'/g; s/&ldquo;/\"/g; s/&rdquo;/\"/g; '
removeHtmlChar=$removeHtmlChar"s/\%27/'/g;"

selectTrackBefore="s/.*spotify:search://"
selectTrackAfter="sed s/\"\>Spotify.*//"

       
source ./config.cfg

#echo $urlLink
#echo $selectTrackBefore
#echo $removeHtmlChar
#echo "ciao"
#seleziona le righe con le tracce, togli e il "prima", toglie il "dopo", pulisce l'html 
#curl -s $urlLink | grep \"track\" | sed s/.*spotify:search://g | sed s/\"\>Spotify.*//g | sed "$removeHtmlChar" > $trackFileName
 
#curl -s $urlLink | grep \"track\" | sed s/.*spotify:search://g | sed s/\"\>Spotify.*//g | sed "$removeHtmlChar" > $workfolder$trackFileName

#nuova stringa che tiene data e ora della canzone
curl -s $urlLink | grep \"track\" | sed s/.*datetime=//g | sed s/\"\>Spotify.*//g | sed s/\>.*search:/\ /g | sed "$removeHtmlChar" > $workfolder$trackFileName
#curl https://radio-streaming.it/playlists/radio-deejay | grep \/track\/ | sed s/\<td\>.*ajax\"\>// | sed s/\<.*td\>// | sed 's/&nbsp;/ /g; s/&amp;/\&/g; s/&lt;/\</g; s/&gt;/\>/g; s/&quot;/\"/g; s/#&#39;/\'"'"'/g; s/&ldquo;/\"/g; s/&rdquo;/\"/g;'
#curl https://www.smarttuner.net/titoli/radio-deejay/ | grep \"track\" | sed s/.*spotify:search://g | sed s/\"\>Spotify.*//g

 