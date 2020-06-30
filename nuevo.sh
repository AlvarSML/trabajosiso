############ FUNCIONES ############

#############################
#   Obtiene los datos basicos por pantalla
#
#############################
function pedirDatos() {

    #? Prioridades
    #printf "\e[1A%80s\r" " "
    read -p "Prioridad menor:" priMenor
    printf "\n"

    printf "\e[1A%80s\r" " "
    read -p "Prioridad mayor:" priMayor
    printf "\n"

    until [[ $prioridad = 'M' ]] || [[ $prioridad = 'm' ]]; do
        printf "\e[1A%80s\r" " "
        read -p "Tipo de Prioridad (M/m):" prioridad
        printf "\e[91mINTRODUCE M O m \e[39m\r"

    done
    printf "%*s\n" "$(tput cols)" " "

    # Calcular el numero mayor
    if [[ $priMenor -gt $priMayor ]]; then
        a=$priMenor
        priMenor=$priMayor
        priMayor=$a
        invertido=1
    fi

    #? Direcciones de memoria
    until [[ $dirTotales > 0 ]]; do
        printf "\e[1A%80s\r" " " #imprimir 80 espacios en color 1A
        read -p "Número de direcciones totales de la memoria: " dirTotales
        printf "\e[91mINTRODUCE UN NÚMERO SUPERIOR A 0\e[39m\r"
    done
    printf "%*s\n" "$(tput cols)" " "

    until [[ $dirPagina -gt 0 ]] && [[ $(($dirTotales % $dirPagina)) = 0 ]]; do
        printf "\e[1A%80s\r" " " #imprimir 80 espacios en color 1A
        read -p "Número de direcciones por pagina: " dirPagina
        printf "\e[91mINTRODUCE UN NÚMERO SUPERIOR A 0 Y DIVISOR DE %s \e[39m\r" $dirTotales
    done
    printf "%*s\n" "$(tput cols)" " "

    ((numMarcos = $dirTotales / $dirPagina))

}

#############################
#   Obtiene los datos de los procesos por pantalla
#
#############################
function pedirProcesos() {
    local continuar='s' nProceso=0

    until [[ $continuar == 'n' ]]; do
        printf "Proceso [%s]\n" $([[ $nProceso < 10 ]] && echo "0$nProceso" || echo $nProceso)
        echo

        until [[ ${procPrioridad[nProceso]} -ge $priMenor ]] && [[ ${procPrioridad[$nProceso]} -le $priMayor ]] && [[ -n "${procPrioridad[$nProceso]}" ]]; do
            printf "\e[1A%80s\r" " "
            read -p "Prioridad: " procPrioridad[$nProceso]
            printf "\e[91mINTRODUCE UN NÚMERO ENTRE %s Y %s \e[39m\r" $priMenor $priMayor
        done
        printf "%*s\n" "$(tput cols)" " "

        until [[ ${procTamano[$nProceso]} -le $numMarcos ]] && [[ ${procTamano[$nProceso]} -gt 0 ]]; do
            printf "\e[1A%80s\r" " "
            read -p "Numero de marcos: " procTamano[$nProceso]
            printf "\e[91mINTRODUCE UN NÚMERO ENTRE %s Y %s \e[39m\r" "0" $numMarcos
        done
        printf "%*s\n" "$(tput cols)" " "

        until [[ ${procLlegada[$nProceso]} -ge 0 ]] && [[ -n "${procLlegada[$nProceso]}" ]]; do
            printf "\e[1A%0s\r" " "
            read -p "Tiempo de llegada: " procLlegada[$nProceso]
            printf "\e[91mINTRODUCE UN NÚMERO MAYOR O IGUAL QUE 0 \e[39m\r"
        done
        printf "%*s\n" "$(tput cols)" " "

        # TODO: comprobacion por regex
        until [[ -n "${procDirecciones[$nProceso]}" ]]; do
            printf "\e[1A%80s\r" " "
            read -p "Secuencia de direcciones (separadas por comas): " procDirecciones[$nProceso]
            printf "\e[91mINTRODUCE UN NÚMERO MAYOR O IGUAL QUE 0 \e[39m\r"
        done
        printf "%*s\n" "$(tput cols)" " "
        
        printf "\e[1A%80s\r" " "        
        read -p "Introducir otro proceso s/n [s]: " -n1 continuar
        echo
        ((nProceso++))
    done
}

#############################
#   Ordena los procesos segun tiempo de llegada
#   Input <- procLlegada[] #? procesos desordenados
#   Outpu -> ordenLlegada[] #? procesos ordenadaos por orden de llegada
#############################
function ordenarLlegada() {
    local -a tiempos

    tiempos[0]=${procLlegada[0]}
    ordenLlegada[0]=0
    # echo ${ordenLlegada[0]}

    for ((pl = 1; pl < ${#procLlegada[@]}; pl++)); do
        for ((p = ((${#ordenLlegada[@]} - 1)); p >= 0; p--)); do
            if [[ ${procLlegada[$pl]} -ge ${tiempos[$p]} ]]; then
                tiempos[((p + 1))]=${procLlegada[$pl]}
                ordenLlegada[((p + 1))]=$pl
                p=-1
            elif [[ $p -eq 0 ]]; then
                tiempos[((p + 1))]=${tiempos[$p]}ñ
                ordenLlegada[((p + 1))]=${ordenLlegada[$p]}

                tiempos[$p]=${procLlegada[$pl]}
                ordenLlegada[$p]=$pl
            else
                tiempos[((p + 1))]=${tiempos[$p]}
                ordenLlegada[((p + 1))]=${ordenLlegada[$p]}

            fi
        done

        echo ${ordenLlegada[@]}
        echo ${tiempos[@]}
        echo "##############"
    done

}

#############################
#   Introduce un proceso segun su prioridad
#   Input <- parametro (numero de proceso)
#   Output -> posicion de ordenPrioridad[]
#############################
function introducirPrioridad() {
    local -i prioridad
    if [[ $# -ne 1 ]]; then
        echo "Numero incorrecto de parametros"
    else
        if [[ ${#ordenPrioridad[@]} -eq 1 ]]; then
            #para el primer proceso
            ordenPrioridad[0]=$1
        else
            for ((p = ((${#ordenPrioridad[@]} - 1)); p >= 0; p--)); do
                prioridad=${procPrioridad[${ordenPrioridad[$p]}]}

                if [[ ${procPrioridad[$1]} -ge prioridad ]]; then
                    ordenPrioridad[(($p + 1))]=$1
                    p=-1
                elif [[ $p -eq 0 ]]; then
                    ordenPrioridad[(($p + 1))]=ordenPrioridad[$p]

                    ordenPrioridad[0]=$1
                else
                    ordenPrioridad[(($p + 1))]=${ordenPrioridad[$p]}
                fi
            done
        fi
    fi
}

#############################
#   Busca segmentos vacios en la memoria
#   Input <- memPrincipal
#   Output -> segmentosLibres (Asocitativo)
#############################
function buscarSegmentosVacios() {
    local -i size start

    segmentosLibres=()

    for ((i = 0; i < ${#memPrincipal[@]}; i++)); do
        if [[ ${memPrincipal[$i]} -eq -1 ]]; then
            if [[ $size -eq 0 ]]; then
                start=$i
                size=1
            else
                ((size++))
            fi
        elif [[ $size -gt 0 ]]; then
            segmentosLibres+=([$start]=$size)
            size=0
        fi
    done

    if [[ $size -gt 0 ]]; then
        segmentosLibres+=([$start]=$size)
    fi
}

#############################
#   Inicia la memoria vacia
#
#############################

function inicializarMemoria() {
    for ((i = 0; i < $numMarcos; i++)); do
        memPrincipal[$i]=-1
    done
}

#############################
#   Desplaza la cola de prioridades un paso a la iquierda (elimina el primer valor)
#   Solo afecta a ordenPrioridad[]
#############################

function desplazarPrioridad() {
    for ((i = 1; i < ${#ordenPrioridad[@]}; i++)); do
        ordenPrioridad[(($i - 1))]=${ordenPrioridad[$i]}
    done
    unset "ordenPrioridad[((${#ordenPrioridad[@]}-1))]"
}

#############################
#   Reserva memoria para un proceso en la banda de memoria
#   Input <-- parametros: $1-proceso $2-inicio
#   Output --> memPrincipal
#############################

function reservarMemoria() {
    if [[ $# -ne 2 ]]; then
        echo "Numero incorrecto de parametros se esperaban 2"
    else
        local -i marcos=${procTamano[$1]}
        for ((i = $2; i < (($2 + marcos)); i++)); do
            memPrincipal[$i]=$1
        done
    fi
}

#############################
#   Introduce procesos de la cola por prioridades en memoria
#   Reserva mememoria, no introduce paginas
#   Input <- ordenPrioridad
#   Output -> memPrincipal
#############################

function introducirEnMemoria() {
    # por cada proceso segun prioridad
    for ((p = 0; p < ${#ordenPrioridad[@]}; p++)); do
        local -i optimo, exceso

        #Actualizar segmentos vacios
        buscarSegmentosVacios

        #? buscar segmento en el que meter el proceso
        for seg in segmentosLibres; do
            #buscar mejor hueco
            # Si no hay uno previo se guarda el primero en el que quepa
            if [[ -z $optimo ]] && [[ ${procTamano[$p]} -le ${segmentosLibres[$seg]} ]]; then
                optimo=$seg
                exceso=$((${segmentosLibres[$seg]} - ${procTamano[$p]}))
            # si hay uno previo y se encuentra uno mejor se cambia
            elif [[ -n optimo ]] && [[ ${procTamano[$p]} -le ${segmentosLibres[$seg]} ]] && [[ $((${segmentosLibres[$seg]} - ${procTamano[$p]})) -lt exceso ]]; then
                optimo=$seg
                exceso=$((${segmentosLibres[$seg]} - ${procTamano[$p]}))
            fi
        done

        #? Si no se ha conseguido introducir el proceso, no se puede meter el siguiente
        if [[ -z $optimo ]]; then
            p=${#ordenPrioridad[@]}
        #? Si se ha conseguido, se desplaza la cola hacia la izquierda y se modifica la memoria
        # ademas se introduce el primer marco si tiene prioridad
        else
            procesosMemoria[$p]=$optimo
            desplazarPrioridad
            reservarMemoria $p $optimo
            #se pasan las paginas a la lista de paginas resatantes
            paginasRestantes[$p]=${dirPaginas[$p]}
        fi

        optimo=""
        exceso=""
    done
}

#############################
#   Convertir direcciones: transforma las direcciones segun las direcciones por marco
#   join_by: convierte un array en series de comas, permite la matrices bidimensionales
#############################
function join_by() {
    local IFS="$1"
    shift
    echo "$*"
}
function convertirDirecciones() {
    local -a paginas
    local cadena

    if [[ $# -ne 1 ]]; then
        echo "Numero incorrecto de parametros"
    else
        IFS=', ' read -r -a paginas <<<"$1"
        for ((i = 0; i < ${#paginas[@]}; i++)); do
            paginas[$i]="$((paginas[$i] / dirPagina))"
        done
    fi

    #! output por echo
    join_by , ${paginas[@]}
}

#############################
#   Introduce una pagina en un proceso en memoria fisica
#   Input <-- $1 = numero del proceso
#   Output -->
#############################
function introducirPagina() {
    local -a paginas

    if [[ $# -ne 1 ]]; then
        echo "Numero incorrecto de parametros"
    else
        local -i proceso=$1 marco=${procesosMemoria[$1]} vacios

        #se obtienen las paginas
        IFS=', ' read -r -a paginas <<<"${dirPaginas}"

        #se obtienen los marcos vacios
        marcosVacios $1
        if [[ $? -eq 0 ]]; then
            #TODO: introduccion simple de marco
            echo
        else
            sustituirPagina
        fi
    fi
}

#############################
#   Obtiene los marcos vacios de un proceso en memoria
#   Input <-- $1 = proceso
#   Output --> marcos vacios
#############################

function marcosVacios() {
    if [[ $# -ne 1 ]]; then
        echo "Numero incorrecto de parametros"
    else
        local -i inicio=${procesosMemoria[$1]} vacios=0 marcos=${procTamano[$1]}
        if [[ -z inicio ]]; then
            echo "${Rojo}!Error, el proceso $1 no esta en memoria${NC}"
        else
            for ((i = $inicio; i < (($inicio + $marcos)); i++)); do
                if [[ ${memPagina[$i]} -eq -1 ]]; then
                    ((vacios++))
                fi
            done
        fi
    fi

    return $vacios
}

#############################
#   Sustituye de una forma optima un marco del proceso indicado
#   Input <-- $1 = proceso
#   Output --> Modifica memPagina y paginasRestantes
#############################

function sustituirPagina() {
    echo
}

#############################
#   Introduce la siguinte pagina en un marco vacio
#   !IMPORTANTE solo sirve para procesos con marcos libres
#   Input <-- $1 = proceso
#   Output --> Modifica memPagina y paginasRestantes
#   TODO: eliminar de paginas restantes
#############################

function introducirPagina() {
    if [[ $# -ne 1 ]]; then
        echo "${Rojo}Numero incorrecto de parametros${NC}"
    else
        local -i inicio=${procesosMemoria[$1]} marcos=${procTamano[$1]}
        if [[ -z inicio ]]; then
            echo "${Rojo}!Error, el proceso $1 no esta en memoria${NC}"
        else
            for ((i = $inicio; i < (($inicio + $marcos)); i++)); do
                if [[ ${memPagina[$i]} -eq -1 ]]; then
                    #sacar pagina de la cola
                    echo "---"
                fi
            done
        fi
    fi
}

#############################
#   Paso de la ejecucion
#
#############################
function paso() {

    salidaEjecucucion

    #? se introducen los procesos que han llegado en la cola segun prioridad
    for proceso in ordenarLlegada; do
        if [[ ${procLlegada[$proceso]} -eq $tiempo ]]; then
            introducirPrioridad $proceso
        fi
    done

    #? si hay espacio en memoria y hay procesos en la cola se introduce
    ## Primero se buscan los segmentos libres
    buscarSegmentosVacios

    if [[ ${#segmentosLibres[@]} -gt 0 ]] && [[ ${#ordenPrioridad[@]} -gt 0 ]]; then
        introducirEnMemoria
    fi

    #? por cada proceso en memoria se elige uno por paso para introducir una pagina nueva

    ## Despues se introducen los procesos que quepan en esos segmentos

    read -p "Pulsa [Intro] para continuar"
}

############! FUNCIONES DE SALIDA POR PANTALLA !############

#######################################
#	Muestra cabeceras gráficas
#	Argumentos:
#		$1 = modo:
#			0 = cabecera principal
#			1 = cabecera secundaria
#		$2 = salida:
#			0 = pantalla y log
#			1 = pantalla
#			2 = log
#	Devuelve:
#   Texto
#######################################
function header() {
    local -ri modo=$1 salida=$2
    local linea linea_no_esc linea_buffer max min

    if [[ $modo -eq 0 ]]; then
        linea=
        linea="${underline}${bold}ALGORITMO PRIORIDAD MAYOR/MENOR NO EXPULSOR, PAGINACIÓN OPTIMA, MEMORIA CONTINUA Y NO REUBICABLE"
        pantalla "$linea"
    else
        [[ $invertido -eq 0 ]] && min=$priMenor || min=$priMayor
        [[ $invertido -eq 0 ]] && max=$priMayor || max=$priMenor

        linea+=$(printf "Tiempo: %3d    Número de Procesos:%d   Prioridad:%s    Valor Menor:%d  Valor Mayor:%d" \
            "$tiempo" "${#procTamano[@]}" "$prioridad" "$min" "$max")
        linea+='\n'
        pantalla "$linea"
        log 3 "$(printf "\e[38;5;17m#\e[39m%42sINSTANTE: %3d%43s\e[38;5;17m#\e[39m" " " "$tiempo" " ")" "$(printf "#%42sINSTANTE: %3d%43s#" " " "$tiempo" " ")"
    fi
}

#######################################
#	Escribe en pantalla
#	Globales:
#		modo_silencio
#	Argumentos:
#		Mensaje con escapes
#	Devuelve:
#		Nada
#######################################
function pantalla() {
    local -r mensaje=$1
    if [[ -z $modo_silencio ]]; then
        echo -e "${NC}$mensaje${NC}"
    fi
}

#######################################
#	Escribe en ficheros de salida
#	Globales:
#		nivel_log
#	Argumentos:
#		Nível
#		Mensaje con escapes:
#			NULL = Linea vacia
#		Mensaje sin escapes:
#			NULL = Linea vacia
#			@ = Mismo mensaje que con esc.
#	Devuelve:
#		Nada
#######################################
function log() {

    local -ri nivel=$1
    local -r mensaje=$2 mensaje_noesc=$3

    if [[ $nivel -ge $nivel_log ]]; then

        echo >>salida.txt

        if [[ -n $mensaje_noesc ]]; then
            if [[ $mensaje_noesc == '@' ]]; then
                echo "[${nivel}] > ${mensaje}" >>salidaNoEsc.txt
            else
                echo "[${nivel}] > ${mensaje_noesc}" >>salidaNoEsc.txt
            fi
        else
            echo >>salidaNoEsc.txt
        fi

    fi
}

#############################
#   Muestra el estado de la ejecucion
#   Datos de los procesos
#   Banda de memoria
#   banda de tiempo
#############################

function salidaEjecucucion() {
    #? tamaño de columna
    local -r colsize=9 marco=7

    local -r formatoTitulo="${bold}${underline}%${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %-${colsize}s\n"
    local -r formatoFilas="${nounderline}%7s%03d%${colsize}d %${colsize}d %${colsize}d %${colsize}d %${colsize}d %${colsize}d %${colsize}d %${colsize}d %${colsize}s\n"

    printf "${formatoTitulo}" \
        "Proceso" "T.Lleg" "T.Ejec" "N.Marcos" "Prioridad" "T.Esp" "T.Ret" "T.R.Ejec" "Estado" "Paginas"

    for p in ${ordenLlegada[@]}; do
        printf "\033[${proc_color_secuencia[$p]}m${formatoFilas}" \
            '' $p ${procLlegada[$p]} 0 ${procTamano[$p]} ${procPrioridad[$p]} 0 3 2 1 "${procDirecciones[$p]}"
    done
    printf "${NC}"

    #! banda de memoria

    printf "\n${bold}${underline}BANDA DE MEMORIA${nounderline}\n\n"

    printf "${bold}║"

    for ((mc = 0; mc < ${#memPrincipal[@]}; mc++)); do
        if [[ ${memPrincipal[$mc]} -eq -1 ]]; then
            printf "\033[1;47m%${marco}s|"
        else
            printf "${Negro}\e[${fondos[${memPrincipal[$mc]}]}m%${marco}s|" ${memPagina[$mc]}
        fi

    done

    printf "${NC}${normal}║\n"

    #! linea de tiempo

    printf "\n${bold}${underline}BANDA DE MEMORIA${nounderline}\n\n"

    printf "${bold}║"

    for ((mc = 0; mc < ${#bandaTiempoProceso[@]}; mc++)); do
        if [[ ${bandaTiempoProceso[$mc]} -eq -1 ]]; then
            printf "\033[1;47m%${marco}s|"
        else
            printf "${Negro}\e[${fondos[${bandaTiempoProceso[$mc]}]}m%${marco}s|" ${bandaTiempoMarco[$mc]}
        fi
    done

    printf "${NC}${normal}║\n"

}

############ DEBUG ############
function valoresIniciales() {
    priMayor=10
    priMenor=0
    prioridad='m'
    dirPagina=100
    dirTotales=1000
    numMarcos=10
    procPrioridad=(0 0)
    procLlegada=(0 0)
    procTamano=(5 5)
    procDirecciones=(123,34,543,412,534 761,435,654,123,98,34,123)
    #ordenLlegada=(0 1)
}

############ VARIABLES ############

declare -i finalizado priMayor priMenor invertido=0 #? si se ha invertido la prioridad mayor/menor
declare prioridad                                   #? m o M

declare -i dirTotales
declare -i dirPagina #? Numero de procesos por pagina
declare -i numMarcos #? Numero de marcos en memoria principal

declare -i tiempo #! IMPORTANTE: tiempo de ejecucion, solo se aumenta en paso

declare -a procPrioridad procTamano procLlegada procDirecciones ordenLlegada
declare -a ordenPrioridad

#! Bandas de memoria
declare -a memPrincipal #? memoria usada, N = proceso, -1 = vacia, cada indice es un marco
declare -a memPagina    #? que pagina se encuentra en que marco

declare -A procesosMemoria #? procesos que se encuentran en memoria y su posicion inicial
declare -A segmentosLibres #? segmentos de memoria vacions indice = posicon, valor = tamaño

#! Banda  de tiempo
declare -a bandaTiempoProceso #? Que proceso se ha ejecutado en cada momento
declare -a bandaTiempoMarco   #? Que pagina se ha introducido en que momento

#! Relativo a las paginas
# no se incluye procDirecciones y memPaginas
declare -A paginasRestantes #? paginas que quedan por cada proceso

#! datos estadisticos
# relativos al rendimiento del algoritmo
declare -a fallosProceso tiempoEspera tiempoRetorno tiempoEjecucion tiempoREjecucion

#! colores
declare Rojo='\033[0;31m' Negro='\033[0;30m' NC='\033[0m'

#! otros estilos
declare underline=$(tput smul) nounderline=$(tput rmul) bold=$(tput bold) normal=$(tput sgr0)
declare -a proc_color_secuencia=("1;31" "32" "1;33" "34" "35" "36" "1;35" "37")
declare -a fondos=("1;41" "42" "1;43" "44" "45" "46" "1;45" "40")

############ EJECUCION PRINCIPAL ############

# Recogida de datos
clear
header 0 1
#pedirDatos

clear
header 0 1
header 1 1
#pedirProcesos

valoresIniciales
clear
# Se pasan los espacios de memoria no ocupados a -1

# Ordenar segun orden de llegada
ordenarLlegada

# Llena la memoria de -1
inicializarMemoria

# hasta que finalize la cola, o hay una parada por limite de tiempo (para evitar un bucle infinito)
tiempo=0
until [[ finalizado -eq 1 ]] || [[ $tiempo -gt 1000 ]]; do
    paso
    ((tiempo++))
done

# echo "${procPrioridad[@]}"
# echo "${procTamano[@]}"
# echo "${procDirecciones[@]}"
