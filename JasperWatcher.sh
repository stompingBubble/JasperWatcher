#!/bin/bash

source config.sh 

searchunit=$1
baseurl='https://tele2.jasperwireless.com/provision'

# login to Jasper 
curl -L --cookie-jar ./cookiefile -X POST ''"${baseurl}"'/j_acegi_security_check' --data 'j_username='"${user}"'&j_password='"${pass}"'' > temp.temp

# temp file for the curl output 
rm temp.temp

# search for device based on inputed search unit 
echo $(curl -L -c ./cookiefile -b ./cookiefile ''"${baseurl}"'/api/v1/sims?_dc=1569325734759&page=1&limit=50&sort=deviceId&dir=ASC&search=%5B%7B%22property%22%3A%22oneBox%22%2C%22type%22%3A%22CONTAINS%22%2C%22value%22%3A%22*'"${searchunit}"'*%22%2C%22id%22%3A%22oneBox%22%7D%5D' -H 'Sec-Fetch-Mode: cors' -H 'Referer: '"${baseurl}"'/ui/terminals/sims/sims.html' --compressed) > outputfile.temp

# number of units found 
nunits=$(cat outputfile.temp | jq ".totalCount")
# if there are more than one unit found 
if [ ${nunits} -gt 1 ]
then 
	echo ${nunits} units found with search pattern ${searchunit}
	
	for (( c=0; c<${nunits}; c++))
	do 
		deviceid=$(cat outputfile.temp | jq ".data[${c}].deviceId") && deviceid="${deviceid%\"}" && deviceid="${deviceid#\"}"
		simid=$(cat outputfile.temp | jq ".data[${c}].simId") 
		iccid=$(cat outputfile.temp | jq ".data[${c}].iccid") && iccid="${iccid%\"}" && iccid="${iccid#\"}"
		insession=$(cat outputfile.temp | jq ".data[${c}].inSession") 

		if [ "${insession}" == "true" ]
        	then
                	echo $(curl -c ./cookiefile -b ./cookiefile ''"${baseurl}"'/api/v1/sims/searchDetails?_dc=1569332941718&page=1&limit=50&search=%5B%7B"property"%3A"simId"%2C"type"%3A"LONG_EQUALS"%2C"value"%3A'"${simid}"'%2C"id"%3A"simId"%7D%5D') > output.temp
                	ip=$(cat output.temp | jq ".data[].currentSessionInfo.deviceIpAddress")
                	
		fi
		printf "Device id: ${deviceid}\nSim id: ${simid} | ICCID: ${iccid} | In Session: ${insession}"
		
		if [ -n "${ip}" ]; then printf " | IP : ${ip}\n\n"; else printf "\n\n"; fi
		unset ip

	done	
		
# if there are no units found
elif [ ${nunits} -eq 0 ]
then
        echo No unit found with search pattern ${searchunit}
# if there are one unit found 
else
	deviceid=$(cat outputfile.temp | jq ".data[].deviceId")
        simid=$(cat outputfile.temp | jq ".data[].simId")
	iccid=$(cat outputfile.temp | jq ".data[].iccid") 
	insession=$(cat outputfile.temp | jq ".data[].inSession")
	echo Found one unit with search pattern ${searchunit} 
	printf "\nDevice id: ${deviceid}\nSim id: ${simid}\nICCID: ${iccid}\nIn session: ${insession}\n"
	if [ "${insession}" == "true" ]
	then
		echo $(curl -c ./cookiefile -b ./cookiefile ''"${baseurl}"'/api/v1/sims/searchDetails?_dc=1569332941718&page=1&limit=50&search=%5B%7B"property"%3A"simId"%2C"type"%3A"LONG_EQUALS"%2C"value"%3A'"${simid}"'%2C"id"%3A"simId"%7D%5D') > output.temp
		ip=$(cat output.txt | jq ".data[].currentSessionInfo.deviceIpAddress")
		echo IP: ${ip} 
	fi
fi 	




