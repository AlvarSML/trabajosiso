############ FUNCIONES ############

#############################
#   Obtiene los datos basicos por pantalla
#
#############################
function pedirDatos() {

    #? Prioridades
    #printf "\e[1A%80s\r" " "
    read -p " Prioridad menor:" priMenor
    printf "\n"

    printf "\e[1A%80s\r" " "
    read -p " Prioridad mayor:" priMayor
    printf "\n"

    until [[ $prioridad = 'M' ]] || [[ $prioridad = 'm' ]]; do
        printf "\e[1A%80s\r" " "
        read -p " Tipo de Prioridad (M/m):" prioridad
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
        read -p " Número de direcciones totales de la memoria: " dirTotales
        printf "\e[91mINTRODUCE UN NÚMERO SUPERIOR A 0\e[39m\r"
    done
    printf "%*s\n" "$(tput cols)" " "

    until [[ $dirPagina -gt 0 ]] && [[ $(($dirTotales % $dirPagina)) = 0 ]]; do
        printf "\e[1A%80s\r" " " #imprimir 80 espacios en color 1A
        read -p " Número de direcciones por pagina: " dirPagina
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
        clear
        header 0 0

        if [[ nProceso -ne 0 ]]; then
            salidaProceso
        fi

        printf " Proceso [%s]\n" $([[ $nProceso < 10 ]] && echo "0$nProceso" || echo $nProceso)
        echo

        until [[ ${procPrioridad[nProceso]} -ge $priMenor ]] && [[ ${procPrioridad[$nProceso]} -le $priMayor ]] && [[ -n "${procPrioridad[$nProceso]}" ]]; do
            printf "\e[1A%80s\r" " "
            read -p " Prioridad: " procPrioridad[$nProceso]
            printf "\e[91mINTRODUCE UN NÚMERO ENTRE %s Y %s \e[39m\r" $priMenor $priMayor
        done
        printf "%*s\n" "$(tput cols)" " "

        until [[ ${procTamano[$nProceso]} -le $numMarcos ]] && [[ ${procTamano[$nProceso]} -gt 0 ]]; do
            printf "\e[1A%80s\r" " "
            read -p " Numero de marcos: " procTamano[$nProceso]
            printf "\e[91mINTRODUCE UN NÚMERO ENTRE %s Y %s \e[39m\r" "0" $numMarcos
        done
        printf "%*s\n" "$(tput cols)" " "

        until [[ ${procLlegada[$nProceso]} -ge 0 ]] && [[ -n "${procLlegada[$nProceso]}" ]]; do
            printf "\e[1A%0s\r" " "
            read -p " Tiempo de llegada: " procLlegada[$nProceso]
            printf "\e[91mINTRODUCE UN NÚMERO MAYOR O IGUAL QUE 0 \e[39m\r"
        done
        printf "%*s\n" "$(tput cols)" " "

        # TODO: comprobacion por regex
        until [[ -n "${procDirecciones[$nProceso]}" ]]; do
            printf "\e[1A%80s\r" " "
            read -p " Secuencia de direcciones (separadas por comas): " procDirecciones[$nProceso]
            printf "\e[91mINTRODUCE UN NÚMERO MAYOR O IGUAL QUE 0 \e[39m\r"
        done
        printf "%*s\n" "$(tput cols)" " "

        printf "\e[1A%80s\r" " "
        ((procesosRestantes++))
        ((nProceso++))

        read -p " Introducir otro proceso s/n [s]: " -n1 continuar
        echo

    done

}

#############################
#   Ordena los procesos segun tiempo de llegada
#   Input <- procLlegada[] #? procesos desordenados
#   Outpu -> ordenLlegada[] #? procesos ordenadaos por orden de llegada
#############################
function ordenarLlegada() {
    local -a tiempos
    ordenLlegada=()
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
        if [[ ${#ordenPrioridad[@]} -eq 0 ]]; then
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
        memPagina[$i]=-1
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

function desplazarPaginasRestantes() {
    #printf "${Rojo} Desplazando ${NC}\n"
    if [[ $# -ne 1 ]]; then
        echo "Numero incorrecto de parametros se esperaban 1 [desplazarPaginasRestantes]"
    else
        local paginas=${paginasRestantes[$1]}
        local -a arrPaginas

        IFS=', ' read -r -a arrPaginas <<<"$paginas"

        if [[ ${#arrPaginas[@]} -ne 0 ]]; then
            for ((i = 1; i < ${#arrPaginas[@]}; i++)); do
                arrPaginas[(($i - 1))]=${arrPaginas[$i]}
            done

            unset "arrPaginas[((${#arrPaginas[@]}-1))]"

            join_by , ${arrPaginas[@]}
        fi
    fi
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
        tiempoEntrada[$1]=$tiempo
    fi
}

#############################
#   libera memoria de un proceso en la banda de memoria y paginas
#   Input <-- parametros: $1-proceso
#   Output --> memPrincipal memPagina
#############################
function liberarMemoria() {
    if [[ $# -ne 1 ]]; then
        echo "Numero incorrecto de parametros se esperaba 1 [liberarMemoria]"
    else
        local -i inicio=${procesosMemoria[$1]} marcos=${procTamano[$1]}

        if [[ -z $inicio ]]; then
            echo "El proceso $1 no esta em memoria"
        else
            for ((i = $inicio; i < (($inicio + $marcos)); i++)); do
                memPrincipal[$i]=-1
                memPagina[$i]=-1
            done

            unset procesosMemoria[$1]
            tiempoSalida[$i]=$tiempo
        fi
    fi
}

#############################
# Recorre los procesos en memoria, si su cola de marcos esta vacia los expulsa
#############################
function vaciarMemoria() {

    for p in ${!paginasRestantes[@]}; do
        if [[ -z ${paginasRestantes[$p]} ]]; then
            liberarMemoria $p
            #! Importante disminuir el numero de procesos
            ((procesosRestantes--))
            unset paginasRestantes[$p]
            echo -e "${Rojo}Quedan $procesosRestantes procesos${NC}"
        fi
    done
}

#############################
#   Introduce procesos de la cola por prioridades en memoria
#   Reserva mememoria, no introduce paginas
#   Input <- ordenPrioridad
#   Output -> memPrincipal
#############################

function introducirEnMemoria() {
    # por cada proceso segun prioridad
    local -i procesos=${#ordenPrioridad[@]}

    for p in ${ordenPrioridad[@]}; do
        local -i optimo exceso

        #Actualizar segmentos vacios
        buscarSegmentosVacios

        #? buscar segmento en el que meter el proceso
        for seg in ${!segmentosLibres[@]}; do
            # buscar mejor hueco
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
            #? el proceso se guarda en memoria en la  posicion mas optima
            procesosMemoria[$p]=$optimo

            #? se reserva la memoria para el proceso ultimo de la lista SIEMPRE
            reservarMemoria ${ordenPrioridad[0]} $optimo

            #? se elimina el proceso de la cola
            desplazarPrioridad
            #se pasan las paginas a la lista de paginas resatantes


        fi

        unset optimo
        unset exceso
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
        echo "Numero incorrecto de parametros [convertirDireciones]"
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
    local -a paginas inicio

    if [[ $# -ne 1 ]]; then
        echo "Numero incorrecto de parametros [introducirPagina]"
    else
        local -i proceso=$1 marco=${procesosMemoria[$1]} vacios

        #se obtienen los marcos vacios
        marcosVacios $1

        #si hay marcos vacios en el proceso
        if [[ $? -gt 0 ]]; then
            #TODO: introduccion simple de marco
            introducirPaginaVacios $1
        else
            sustituirPagina $1
        fi
    fi
}

##############################
#   Introducir en banda de tiempo
#   Input <-- $1=proceso $2=pagina
#############################

#############################
#   Obtiene los marcos vacios de un proceso en memoria
#   Input <-- $1 = proceso
#   Output --> marcos vacios
#############################

function marcosVacios() {
    local -i vacios=0

    if [[ $# -ne 1 ]]; then
        echo "Numero incorrecto de parametros [marcosVacios]"
    else

        local -i inicio=${procesosMemoria[$1]} marcos=${procTamano[$1]}
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
    if [[ $# -ne 1 ]]; then
        echo "${Rojo}Numero incorrecto de parametros${NC}"
    else
        local -a enMemoria restantes
        local -A tiempoPagina #? tiempo que va a tardar la pagina en volver k=pagina v=tiempo



        IFS=', ' read -r -a restantes <<<"${paginasRestantes[$1]}"

        #1 se recogen todas las paginas introducidas en memoria para el proceso
        local -i inicio=${procesosMemoria[$1]} marcos=${procTamano[$1]}
        local -i pagina #pagina a comprobar en cada momento

        local -i mayorTiempo=$inicio #posicion de la pagina con mayor tiempo o -1

        # por cada pagina en memoria del proceso $1
        for ((i = $inicio; i < (($inicio + $marcos)); i++)); do
            pagina=${memPagina[$i]}

            tiempoPagina[$i]=-1 #? por defectp, si no se encuentra
            for ((j = 0; j < ${#restantes[@]}; j++)); do
                if [[ ${restantes[$j]} -eq $pagina ]]; then
                    #posicion de la pagina = tiempo

                    tiempoPagina[$i]=$j
                fi
            done
        done

        #! si hay un 0 no se produce un fallo de pagina, se corre la lista
        if [[ ! ${tiempoPagina[@]} =~ 0 ]]; then
            #se busca el mayor tiempo o un 0
            for p in ${!tiempoPagina[@]}; do
                if [[ ${tiempoPagina[$p]} -eq -1 ]]; then
                    mayorTiempo=$p
                    break
                elif [[ ${tiempoPagina[$p]} -gt ${tiempoPagina[$mayorTiempo]} ]]; then
                    mayorTiempo=$p
                fi
            done
            ((fallosProceso[$1]++))
            memPagina[$mayorTiempo]=${restantes[0]}
        fi

        paginasRestantes[$1]=$(desplazarPaginasRestantes $1)

    fi

}

#############################
#   Introduce la siguinte pagina en un marco vacio
#   !IMPORTANTE solo sirve para procesos con marcos libres
#   Input <-- $1 = proceso
#   Output --> Modifica memPagina y paginasRestantes
#############################

function introducirPaginaVacios() {
    if [[ $# -ne 1 ]]; then
        echo "${Rojo}Numero incorrecto de parametros${NC}"
    else
        local -i inicio=${procesosMemoria[$1]} marcos=${procTamano[$1]}
        local -a paginas

        #se obtienen las paginas
        echo "Se va a introducir una pagina al proceso $1"
        IFS=', ' read -r -a paginas <<<"${paginasRestantes[$1]}"

        if [[ -z inicio ]]; then
            echo "${Rojo}!Error, el proceso $1 no esta en memoria${NC}"
        else

            for ((i = $inicio; i < (($inicio + $marcos)); i++)); do
                if [[ ${memPagina[$i]} -eq -1 ]]; then
                    memPagina[$i]=${paginas[0]}
                    paginasRestantes[$1]=$(desplazarPaginasRestantes $1)
                    #!solo se puede meter uno por ud de tiempo
                    i=$(($inicio + $marcos))
                    #? Se produce un fallo de pagina

                    ((fallosProceso[$1]++))
                elif [[ ${memPagina[$i]} -eq ${paginas[0]} ]]; then
                    #? No se produce fallo de pagina
                    paginasRestantes[$1]=$(desplazarPaginasRestantes $1)
                    i=$(($inicio + $marcos))
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
    clear
    header 0 0
    header 1 0
    echo
    salidaEjecucion

    #? Se eliminan los proceos que han terminado
    vaciarMemoria

    #? se introducen los procesos que han llegado en la cola segun prioridad
    for proceso in ${ordenLlegada[@]}; do
        if [[ ${procLlegada[$proceso]} -eq $tiempo ]]; then
            echo -e "${Rojo}Se introduce el proceso $proceso en la cola ${NC}"
            introducirPrioridad $proceso
        fi
    done

    #? si hay espacio en memoria y hay procesos en la cola se introduce
    ## Primero se buscan los segmentos libres
    buscarSegmentosVacios

    if [[ ${#segmentosLibres[@]} -gt 0 ]] && [[ ${#ordenPrioridad[@]} -gt 0 ]]; then
        introducirEnMemoria
    fi

    #? por cada proceso en memoria se elige uno por paso para introducir una pagina nueva (segun prioridad)
    #TODO: se ppuedo meter en un modulo
    local -i gtPri elegido

    
    for p in ${!procesosMemoria[@]}; do
        echo "Comprobando proceso $p"
        if [[ $prioridad = "m" ]]; then
            if [[ $invertido -eq 1 ]]; then
                echo "PRI m INVERTIDO"
                # a mas numero mas prioridad
                if [[ ${procPrioridad[$p]} -gt $gtPri ]] || [[ -z "$gtPri" ]]; then
                    gtPri=${procPrioridad[$p]}
                    elegido=$p
                    
                fi
            else
                echo "PRI m NO INVERTIDO"
                # a menos numero mas prioridad
                if [[ ${procPrioridad[$p]} -lt $gtPri ]] || [[ -z "$gtPri" ]]; then
                    echo "##############"
                    gtPri=${procPrioridad[$p]}
                    elegido=$p
                    echo "Proceso $elegido"
                fi
            fi

        else # prioridad = M

            if [[ $invertido -eq 1 ]]; then
                # a menos numero mas prioridad
                echo "PRI M INVERTIDO"
                if [[ ${procPrioridad[$p]} -lt $gtPri ]] || [[ -z "$gtPri" ]]; then
                    echo "##############"
                    gtPri=${procPrioridad[$p]}
                    elegido=$p
                fi
            else
                # a mas numero mas prioridad
                echo "PRI M NO INVERTIDO"
                if [[ ${procPrioridad[$p]} -gt $gtPri ]] || [[ -z "$gtPri" ]]; then
                    echo "##############"
                    gtPri=${procPrioridad[$p]}
                    elegido=$p
                fi
            fi

        fi

    done

    if [[ -n $elegido ]]; then
        echo "Se va a introducir una pagina en el proceso $elegido"
        introducirPagina $elegido
    fi

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
        linea=" ${underline}${bold}PRIORIDAD MAYOR/MENOR NO EXPULSOR, OPTIMO, CONTINUA Y NO REUBICABLE"
        pantalla "$linea"
    else
        [[ $invertido -eq 0 ]] && min=$priMenor || min=$priMayor
        [[ $invertido -eq 0 ]] && max=$priMayor || max=$priMenor

        linea+=$(printf " T:%2d    Número de Procesos:%d   Prioridad:%s    Valor Menor:%d  Valor Mayor:%d" \
            "$tiempo" "${#procTamano[@]}" "$prioridad" "$min" "$max")

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

function salidaEjecucion() {
    #? tamaño de columna
    local -r colsize=3 marco=5

    local -r formatoTitulo=" ${bold}${underline}%${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %-${colsize}s${nounderline}\n"
    local -r formatoFilas=" %1s%03d%${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s\n"

    local pagina
    printf "${formatoTitulo}" \
        "Ref" "Tll" "Tej" "Mem" "Pri" "Esp" "Ret" "Resp" "Est" "Paginas"

    ordenarLlegada

    for p in ${ordenLlegada[@]}; do
        printf "\033[${proc_color_secuencia[$p]}m${formatoFilas}" \
            "" "$p" "${procLlegada[$p]}" "0" "${procTamano[$p]}" "${procPrioridad[$p]}" "0" "3" "${fallosProceso[$p]}" "0" "${paginasRestantes[$p]}"
    done
    printf "${NC}"
    

    #! banda de memoria

    printf " ${bold}${underline}BM${nounderline}"

    printf "${bold}║"

    for ((mc = 0; mc < ${#memPrincipal[@]}; mc++)); do
        if [[ ${memPrincipal[$mc]} -eq -1 ]]; then
            printf "\033[1;47m%${marco}s|"
        else
            if [[ ${memPagina[$mc]} -ne -1 ]]; then
                pagina=${memPagina[$mc]}
            else
                pagina=
            fi

            printf "${Negro}\e[${fondos[${memPrincipal[$mc]}]}m%${marco}s|" $pagina
        fi

    done

    printf "${NC}${normal}║\n"

    #! linea de tiempo

    printf "\n ${bold}${underline}BT${nounderline}"

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
#######################
#   Calcula el tiempo de ejecucion
#
#######################
function calcularEjec() {
    local -a direcs
    IFS=', ' read -r -a direcs <<<"${procDirecciones[$1]}"
    echo ${#direcs[@]}
}

#######################
#   Muenstra los datos de los procesos introducidos
#
#######################
function salidaProceso() {
    ordenarLlegada

    local -r colsize=4

    local -i diff=$(($colsize - 3))

    local -r formatoTitulo=" ${bold}${underline}%${colsize}s%${colsize}s%${colsize}s%${colsize}s%${colsize}s  %-${colsize}s${normal}"
    local -r formatoFilas=" ${nounderline} %03d%${colsize}s%${colsize}s%${colsize}s%${colsize}s  %${colsize}s${normal}"

    printf "${formatoTitulo}\n" \
        "Ref" "Tll" "Tej" "Mem" "Pri" "Dir"

    #TODO: calcular tiempo de ejecucion

    printf "${nounderline}"

    for p in ${ordenLlegada[@]}; do
        ejecucion=$(calcularEjec $p)
        printf "\033[${proc_color_secuencia[$p]}m${formatoFilas}${NC}\n" \
            "$p" "${procLlegada[$p]}" "$ejecucion" "${procTamano[$p]}" "${procPrioridad[$p]}" "${procDirecciones[$p]}"
    done
}

############ DEBUG ############
function valoresIniciales() {
    priMayor=10
    priMenor=0
    prioridad='m'
    dirPagina=100
    dirTotales=1000
    numMarcos=10
    procPrioridad=(1 2 0)
    procLlegada=(0 0 5)
    procTamano=(3 4 4)
    procDirecciones=(123,34,543,412,534,789,434,900,400,300 6456,445,345,87,324,654,876,922,1293,344,2344,534,678 654,234,568,234,7569,78,3456,8678,35,75,6783,345,65,688)
    fallosProceso=(0 0 0)
    #ordenLlegada=(0 1)
    procesosRestantes=3
}

############ VARIABLES ############

declare -i finalizado priMayor priMenor invertido=0 #? si se ha invertido la prioridad mayor/menor
declare prioridad                                   #? m o M

declare -i dirTotales procesosTotales procesosRestantes
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
# no se incluye procDirecciones y memPagina
declare -A paginasRestantes #? paginas que quedan por cada proceso

#! datos estadisticos
# relativos al rendimiento del algoritmo
declare -a fallosProceso tiempoEspera tiempoRetorno tiempoEjecucion tiempoREjecucion
declare -a tiempoEntrada tiempoSalida

#! colores
declare Rojo='\033[0;31m' Negro='\033[0;30m' NC='\033[0m'

#! otros estilos
declare underline=$(tput smul) nounderline=$(tput rmul) bold=$(tput bold) normal=$(tput sgr0)
declare -a proc_color_secuencia=("1;31" "32" "1;33" "34" "35" "36" "1;35" "37")
declare -a fondos=("1;41" "42" "1;43" "44" "45" "46" "1;45" "40")

#! relativo a eventos
declare -i mostar #? si queremos que se muestre un paso de la ejecucion
declare -i ninguno debug #? si queremos que no se muestre ningun paso o que se muestren todos

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
# clear
# Se pasan los espacios de memoria no ocupados a -1

# Ordenar segun orden de llegada
ordenarLlegada

# Llena la memoria de -1
inicializarMemoria

# Se inicializa la cola de paginas restantes
for ((p = 0; p < ${#procLlegada[@]}; p++)); do
    paginasRestantes+=([$p]=$(convertirDirecciones ${procDirecciones[$p]}))
done

# hasta que finalize la cola, o hay una parada por limite de tiempo (para evitar un bucle infinito)
tiempo=0
until [[ $procesosRestantes -eq 0 ]] || [[ $tiempo -gt 1000 ]]; do
    paso
    ((tiempo++))
done

#TODO: Resumen final

echo "EJECUCION FINALIZADA"

# echo "${procPrioridad[@]}"
# echo "${procTamano[@]}"
# echo "${procDirecciones[@]}"
