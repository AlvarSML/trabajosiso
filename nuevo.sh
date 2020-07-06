############ FUNCIONES ############
#############################
#   Obtiene los datos por archivo
#
#############################
function leerArchivo() {
    if [[ $# -eq 1 ]]; then
        echo "Especifica un nombre de archivo"
        exit 1
    else
        if [[ -f $2 ]]; then
            #? lectura de datos
            input="$2"
            local i=0
            while IFS= read -r line; do
                #? para leer los valores iniciales
                if [[ ! $line == +* ]] && [[ -n $line ]]; then
                    procPrioridad[$i]=$(echo $line | cut -d ';' -f1)   #guarda el tamaño, porque va cortando todolo separado por ; y coge la 1ª columna(-f1)
                    procTamano[$i]=$(echo $line | cut -d ';' -f2)      #guarda las paginas
                    procDirecciones[$i]=$(echo $line | cut -d ';' -f3) #guarda el tiempo de llegada
                    procLlegada[$i]=$(echo $line | cut -d ';' -f4)     #guarda el tiempo de llegada
                    ((i++))
                else
                    #? para leer los proceos
                    echo "probando $(echo $line | tr -d '+' | cut -d ':' -f1)"
                    case $(echo $line | tr -d '+' | cut -d ':' -f1) in
                    "VALOR_MENOR")
                        priMenor=$(echo $line | cut -d ':' -f2)
                        ;;
                    "VALOR_MAYOR")
                        priMayor=$(echo $line | cut -d ':' -f2)
                        ;;
                    "DIRECCIONES_TOTALES")
                        dirTotales=$(echo $line | cut -d ':' -f2)
                        ;;
                    "DIRECCIONES_PAGINA")
                        dirPagina=$(echo $line | cut -d ':' -f2)
                        ;;
                    "PRIORIDAD")
                        prioridad=$(echo $line | cut -d ':' -f2)
                        ;;
                    *)
                        echo 'CONFIGURACIÓN EN FICHERO NO VÁLIDA'
                        exit 1
                        ;;
                    esac
                fi
            done <"$input"

        else
            echo "El archivo no existe"
            exit 1
        fi
    fi

    procesosRestantes=$i
}

#############################
#   Obtiene los argumentos
#   -d - modo debug
#   -f - file + nombre
#   -s - solo salida por archivo
#   -h - ayuda
#############################
function leerArgumentos() {
    if [[ $# -gt 0 ]]; then
        case $1 in
        -d | --debug) #si el parametro es s o silencio
            debug=1
            ;;
        -f | --file)
            mArchivo=1
            leerArchivo $@
            ;;
        -s | --silencio)
            silencio=1
            ;;
        -h | --help)
            mostrarAyuda
            ;;
        esac
    fi
}

#############################
#   Muestra la ayuda del programa
#############################
function mostrarAyuda() {
    clear
    echo "--AYUDA--"
    echo "-d|--debug - modo debug"
    echo "-f|--file - archivo + nombre del nombre"
    echo "-s|--silencio - solo salida por archivo"
    echo "-h|--help - ayuda(estas aqui)"
    echo
    echo "--INFO--"
    echo "Autor: Alvar San Martin"
    echo "Fecha de ultima modificacion: 05/07/2020"
    echo "Repositorio: https://github.com/alvarsnow/trabajosiso"
    read -p "--- Intro para salir ---"
    echo
    exit 0
}

#############################
#   Obtiene los datos basicos por pantalla
#
#############################
function pedirDatos() {
    clear
    header 0 1
    echo
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

    #? Prioridades
    printf "\e[1A%80s\r" " "
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

}

#############################
#   Obtiene los datos de los procesos por pantalla
#
#############################
function pedirProcesos() {
    local continuar='s' nProceso=0

    until [[ $continuar == 'n' ]] || [[ $continuar == 'N' ]]; do
        clear
        header 0 1
        header 1 1
        
        if [[ nProceso -ne 0 ]]; then
            salidaProceso
        fi

        printf " Proceso [%s]\n" $([[ $nProceso < 10 ]] && echo "0$nProceso" || echo $nProceso)
        echo

        until [[ ${procLlegada[$nProceso]} -ge 0 ]] && [[ -n "${procLlegada[$nProceso]}" ]]; do
            printf "\e[1A%0s\r" " "
            read -p " Tiempo de llegada: " procLlegada[$nProceso]
            printf "\e[91mINTRODUCE UN NÚMERO MAYOR O IGUAL QUE 0 \e[39m\r"
        done
        printf "%*s\n" "$(tput cols)" " "

        until [[ ${procTamano[$nProceso]} -le $numMarcos ]] && [[ ${procTamano[$nProceso]} -gt 0 ]]; do
            printf "\e[1A%80s\r" " "
            read -p " Numero de marcos: " procTamano[$nProceso]
            printf "\e[91mINTRODUCE UN NÚMERO ENTRE %s Y %s \e[39m\r" "0" $numMarcos
        done
        printf "%*s\n" "$(tput cols)" " "

        until [[ ${procPrioridad[nProceso]} -ge $priMenor ]] && [[ ${procPrioridad[$nProceso]} -le $priMayor ]] && [[ -n "${procPrioridad[$nProceso]}" ]]; do
            printf "\e[1A%80s\r" " "
            read -p " Prioridad: " procPrioridad[$nProceso]
            printf "\e[91mINTRODUCE UN NÚMERO ENTRE %s Y %s \e[39m\r" $priMenor $priMayor
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
        read -p " $continuar "
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
                tiempos[((p + 1))]=${tiempos[$p]}
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
        fallosProceso[$i]=0
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

        mostrar=1
        cadenaEventos="${cadenaEventos} ${normal}\e[${procColor[$p]}mt(${tiempo})Proceso[${1}]>A memoria${NC}"

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
            tiempoSalida[$1]=$tiempo
            #? se modifica el estado

        fi

        mostrar=1
        procEstado[$p]=4
        cadenaEventos="${cadenaEventos} ${normal}\e[${procColor[$p]}mt(${tiempo})Proceso[${1}]>Terminado${NC}"
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

            #? se modifica el estado
            procEstado[${ordenPrioridad[0]}]=2

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

function introducirBandaTiempo() {
    if [[ $# -ne 2 ]]; then
        echo "Numero incorrecto de parametros [introducirBandaTiempo] se esperaban 2"
    else
        bandaTiempoProceso+=($1)
        bandaTiempoMarco+=($2)
    fi
}

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

        introducirBandaTiempo $1 ${restantes[0]}
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

        IFS=', ' read -r -a paginas <<<"${paginasRestantes[$1]}"

        if [[ -z inicio ]]; then
            echo "${Rojo}!Error, el proceso $1 no esta en memoria${NC}"
        else

            for ((i = $inicio; i < (($inicio + $marcos)); i++)); do
                if [[ ${memPagina[$i]} -eq -1 ]]; then
                    memPagina[$i]=${paginas[0]}
                    introducirBandaTiempo $1 ${paginas[0]}
                    paginasRestantes[$1]=$(desplazarPaginasRestantes $1)
                    #!solo se puede meter uno por ud de tiempo
                    i=$(($inicio + $marcos))
                    #? Se produce un fallo de pagina

                    ((fallosProceso[$1]++))
                elif [[ ${memPagina[$i]} -eq ${paginas[0]} ]]; then
                    #? No se produce fallo de pagina
                    introducirBandaTiempo $1 ${paginas[0]}
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

    #? Se eliminan los proceos que han terminado
    vaciarMemoria

    #? se introducen los procesos que han llegado en la cola segun prioridad
    for proceso in ${ordenLlegada[@]}; do
        if [[ ${procLlegada[$proceso]} -eq $tiempo ]]; then
            #echo -e "${Rojo}Se introduce el proceso $proceso en la cola ${NC}"
            introducirPrioridad $proceso
            # se modifica el estado
            procEstado[$proceso]=1
            mostrar=1
            cadenaEventos="${cadenaEventos} ${normal}\e[${procColor[$p]}mt(${tiempo})Proceso{${proceso}}>Llega${NC}"
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
        if [[ $prioridad -eq "m" ]]; then
            if [[ $invertido -eq 1 ]]; then
                # a mas numero mas prioridad
                if [[ ${procPrioridad[$p]} -gt $gtPri ]] || [[ -z "$gtPri" ]]; then
                    gtPri=${procPrioridad[$p]}
                    elegido=$p

                fi
            else
                # a menos numero mas prioridad
                if [[ ${procPrioridad[$p]} -lt $gtPri ]] || [[ -z "$gtPri" ]]; then
                    gtPri=${procPrioridad[$p]}
                    elegido=$p
                fi
            fi

        else # prioridad = M

            if [[ $invertido -eq 1 ]]; then
                # a menos numero mas prioridad
                if [[ ${procPrioridad[$p]} -lt $gtPri ]] || [[ -z "$gtPri" ]]; then

                    gtPri=${procPrioridad[$p]}
                    elegido=$p
                fi
            else
                # a mas numero mas prioridad
                if [[ ${procPrioridad[$p]} -gt $gtPri ]] || [[ -z "$gtPri" ]]; then

                    gtPri=${procPrioridad[$p]}
                    elegido=$p
                fi
            fi

        fi

    done

    #? como solo puede haber un proceso en ejecucion, el que lo estaba antes pasa a en pausa
    for ((p = 0; p < ${#procEstado[@]}; p++)); do
        if [[ ${procEstado[$p]} -eq 3 ]]; then
            procEstado[$p]=2
        fi
    done

    if [[ -n $elegido ]]; then
        introducirPagina $elegido
        #? se modifica el estado a ejecutandose
        procEstado[$elegido]=3
    fi

    if [[ $mostrar -eq 1 ]] || [[ $debug -eq 1 ]] && [[ $silencio -eq 0 ]]; then
        clear
        header 0 1
        header 1 1
        echo
        salidaEjecucion
        read -p "Pulsa [Intro] para continuar"
    fi

    mostrar=0

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
        linea=" ${underline}${bold}PRIORIDAD MAYOR/MENOR NO EXPULSOR, OPTIMO, CONTINUA Y NO REUBICABLE${normal}"
        printf "$linea\n"
    else
        [[ $invertido -eq 0 ]] && min=$priMenor || min=$priMayor
        [[ $invertido -eq 0 ]] && max=$priMayor || max=$priMenor

        linea+=$(printf " T:%2d    Número de Procesos:%d   Prioridad:%s    Valor Menor:%d  Valor Mayor:%d" \
            "$tiempo" "${#procTamano[@]}" "$prioridad" "$min" "$max")

        printf "$linea\n"

    fi
}

#######################################
#	Escribe en pantalla
#	Globales:
#		silencio
#	Argumentos:
#		Mensaje con escapes
#	Devuelve:
#		Nada
#######################################
function pantalla() {
    local -r mensaje=$1
    if [[ -z $silencio ]]; then
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
    local -r colsize=4 marco=3

    local -r formatoTitulo="${bold}${underline}%${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %-13s %-${colsize}s${nounderline}\n"
    local -r formatoFilas="%1s%03d%${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s %${colsize}s  %-13s %${colsize}s\n"

    local pagina
    printf "${formatoTitulo}" \
        "Ref" "Tll" "Tej" "Nma" "Pri" "Esp" "Ret" "Resp" "Estado" "Paginas"

    ordenarLlegada

    local estado
    local tEjec tRet tResp tEsp

    for p in ${ordenLlegada[@]}; do

        #? estado
        case "${procEstado[$p]}" in
        "0")
            estado="Fuera"
            ;;
        "1")
            estado="En cola"
            ;;
        "2")
            estado="En memoria"
            ;;
        "3")
            estado="En ejecucion"
            ;;
        "4")
            estado="Finalizado"
            ;;
        esac

        #? tiempo de retorno
        tEjec=$(calcularEjec $p)
        if [[ tiempoSalida[$p] -ne 0 ]]; then
            tRet=$((tiempoSalida[$p] - tiempoEntrada[$p]))
        else
            tRet="---"
        fi

        #? tiempo de respuesta
        if [[ tiempoSalida[$p] -ne 0 ]]; then
            tResp=$((tiempoSalida[$p] - procLlegada[$p]))
        else
            tResp="---"
        fi

        #? tiempo de espera
        if [[ $((tiempoEntrada[$p] - procLlegada[$p])) -ge 0 ]]; then
            tEsp=$((tiempoEntrada[$p] - procLlegada[$p]))
        else
            tEsp="---"
        fi

        printf "\033[${procColor[$p]}m${formatoFilas}" \
            "" "$p" "${procLlegada[$p]}" "$tEjec" "${procTamano[$p]}" "${procPrioridad[$p]}" "$tEsp" "$tRet" "$tResp" "$estado" "${paginasRestantes[$p]}"
    done
    printf "${NC}"

    #! banda de memoria

    #? identificadores

    printf "%4s" " "
    local -i espacios
    local color

    for p in ${!procesosMemoria[@]}; do
        espacios=$((${procTamano[$p]} * $marco))
        color=${procColor[$p]}
        printf "\e[${color}m%03d%${espacios}s${NC}" $p " "
    done
    printf "\n"

    #? banda

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

    #? numeros
    local -i espacios anterior
    printf "%3s" " "
    local -i posicion=0 final=$((${#memPrincipal[@]} - 1))
    for p in ${memPrincipal[@]}; do
        if [[ $p -ne $anterior ]] || [[ -z $anterior ]] || [[ $posicion -eq $final ]]; then
            espacios=$(($marco - 2))
            color=${procColor[$p]}
            printf "\e[${color}m%${espacios}s%-${marco}s${NC}" " " $posicion
        else
            espacios=$(($marco + 1))
            printf "%${espacios}s" " "
        fi
        anterior=$p
        ((posicion++))
    done
    printf "\n"

    #! banda de tiempo
    #! para permitir que sea multilinea
    local -i ancho=10

    for ((i = 0; i < ${#bandaTiempoProceso[@]}; i = i + ancho)); do
        imprimirBanda $i $((i + ancho)) $marco
    done

    #! historial
    echo -e "$cadenaEventos"

}

#######################
#   Calcula el tiempo de ejecucion
#   Input <- $1 numero del proceso
#######################
function calcularEjec() {
    local -a direcs
    IFS=', ' read -r -a direcs <<<"${procDirecciones[$1]}"
    echo ${#direcs[@]}
}

#######################
#   Imprime una seccion de la banda de tiempo
#   $1 = inicio $2 = maximo $3 = ancho para el marco
#
#######################
function imprimirBanda() {
    local -i ini=$1 max=$2 marco=$3
    local anterior

    if [[ $max -ge ${#bandaTiempoProceso[@]} ]]; then
        max=$((${#bandaTiempoProceso[@]}))
    fi

    if [[ $ini -gt ${#bandaTiempoProceso[@]} ]]; then
        ini=$((${#bandaTiempoProceso[@]} - 1))
    fi

    #? identificadores
    local -i espacios
    printf "%3s" " "
    until [[ $ini -eq $max ]]; do
        if [[ ${bandaTiempoProceso[$ini]} -ne $anterior ]] || [[ -z $anterior ]]; then
            espacios=$(($marco - 2))
            color=${procColor[${bandaTiempoProceso[$ini]}]}
            printf "\e[${color}m%${espacios}s%03d${NC}" " " ${bandaTiempoProceso[$ini]}
        else
            espacios=$(($marco + 1))
            printf "%${espacios}s" " "
        fi
        anterior=${bandaTiempoProceso[$ini]}
        let ini++
    done
    printf "${NC}${normal}\n"

    #? banda
    ini=$1

    if [[ $ini -eq 0 ]]; then
        printf " ${bold}${underline}BM${nounderline}║"
    else
        printf "%4s" " "
    fi

    until [[ $ini -eq $max ]]; do
        if [[ ${bandaTiempoProceso[$ini]} -eq -1 ]]; then
            printf "\033[1;47m%${marco}s|"
        else
            printf "${Negro}\e[${fondos[${bandaTiempoProceso[$ini]}]}m%${marco}s|" ${bandaTiempoMarco[$ini]}
        fi
        let ini++
    done
    printf "${NC}${normal}\n"

    #? numeros
    printf "%3s" " "
    ini=$1
    final=$((${#bandaTiempoProceso[@]} - 1))
    local anterior=
    until [[ $ini -eq $max ]]; do
        if [[ ${bandaTiempoProceso[$ini]} -ne $anterior ]] || [[ -z $anterior ]]; then
            espacios=$(($marco - 2))
            color=${procColor[${bandaTiempoProceso[$ini]}]}
            printf "\e[${color}m%${espacios}s%-${marco}s${NC}" " " $ini
        elif [[ $ini -eq $((max - 1)) ]]; then
            espacios=0
            color=${procColor[${bandaTiempoProceso[$ini]}]}
            printf "\e[${color}m%${espacios}s%-${marco}s${NC}" " " $ini
        else
            espacios=$(($marco + 1))
            printf "%${espacios}s" " "
        fi
        anterior=${bandaTiempoProceso[$ini]}
        ((ini++))
    done
    printf "\n"
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
        printf "\033[${procColor[$p]}m${formatoFilas}${NC}\n" \
            "$p" "${procLlegada[$p]}" "$ejecucion" "${procTamano[$p]}" "${procPrioridad[$p]}" "${procDirecciones[$p]}"
    done
}

#######################
#   Muenstra los datos de los procesos al finalizar la ejecucion
#
#######################
function resumenFinal() {
    local -i colsize=11

    local -r formatoTitulo=" ${bold}${underline} %3s%${colsize}s%${colsize}s%${colsize}s%${colsize}s %${colsize}s${normal}"
    local -r formatoFilas=" ${nounderline} %03d%${colsize}s%${colsize}s%${colsize}s%${colsize}s %${colsize}s${normal}"

    printf "${formatoTitulo}\n" \
        "Ref" "Llegada" "Salida" "Espera" "Respuesta" "Fallos"

    local -i tResp tEsp
    for ((p = 0; p < ${#procLlegada[@]}; p++)); do
        #? tiempo de respuesta
        tResp=$((tiempoSalida[$p] - procLlegada[$p]))
        #? tiempo de espera
        tEsp=$((tiempoEntrada[$p] - procLlegada[$p]))
        printf "\033[${procColor[$p]}m${formatoFilas}" \
            "$p" "${procLlegada[$p]}" "${tiempoSalida[$p]}" "$tEsp" "$tResp" "${fallosProceso[$p]}"
        printf "\n"
    done

    #? valores medios
    local -i mEsp=0 mResp=0 mFail=0

    for ((p = 0; p < ${#procLlegada[@]}; p++)); do
        let mEsp+=$((tiempoEntrada[$p] - procLlegada[$p]))
        let mResp+=$((tiempoSalida[$p] - procLlegada[$p]))

        let mFail+=${fallosProceso[$p]}
    done

    printf " Tiempo de espera medio: %s \n" $(bc <<<"scale=2; $mEsp/${#procLlegada[@]}")
    printf " Tiempo de respuesta medio: %s\n" $(bc <<<"scale=2; $mResp/${#procLlegada[@]}")
    printf " Numero de fallos medio: %s\n" $(bc <<<"scale=2; $mFail/${#procLlegada[@]}")
}

############ DEBUG ############
function valoresIniciales() {
    priMayor=10
    priMenor=0
    prioridad='m'
    dirPagina=100
    dirTotales=1000
    numMarcos=10
    procPrioridad=(3 0 1)
    procLlegada=(0 2 5)
    procTamano=(3 4 4)
    procDirecciones=(123,34,543,412,534,789,434,900,400,300 6456,445,345,87,324,654,876,922,1293,344,2344,534,678 654,234,568,234,7569,78,3456,8678,35,75,6783,345,65,688)
    fallosProceso=(0 0 0)
    #ordenLlegada=(0 1)
    procesosRestantes=3
}

############ VARIABLES ############

declare -i finalizado priMayor priMenor invertido=0 #? si se ha invertido la prioridad mayor/menor
declare prioridad                                   #? m o M
declare archivo

declare -i dirTotales procesosTotales procesosRestantes
declare -i dirPagina #? Numero de procesos por pagina
declare -i numMarcos #? Numero de marcos en memoria principal

declare -i tiempo #! IMPORTANTE: tiempo de ejecucion, solo se aumenta en paso

declare -a procPrioridad procTamano procLlegada procDirecciones ordenLlegada
declare -a ordenPrioridad #? Procesos que hayan llegado por orden de prioridad

##########################
#   Estados
#   0 - no ha llegado
#   1 - ha llegado, en cola
#   2 - en memoria principla
#   3 - ejecutandose
#   4 - terminado
##########################
declare -a procEstado

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
declare cadenaEventos

#! colores
declare Rojo='\033[0;31m' Negro='\033[0;30m' NC='\033[0m'

#! otros estilos
declare underline=$(tput smul) nounderline=$(tput rmul) bold=$(tput bold) normal=$(tput sgr0)
declare -a procColor=("1;31" "32" "1;33" "34" "35" "36" "1;35" "37")
declare -a fondos=("1;41" "42" "1;43" "44" "45" "46" "1;45" "40")

#! relativo a eventos
declare -i mostrar=1             #? si queremos que se muestre un paso de la ejecucion
declare -i ninguno=0 debug=0     #? si queremos que no se muestre ningun paso o que se muestren todos
declare -i silencio=0 mArchivo=0 #? si estamos en modo silencio o modo archivos
#####!####### EJECUCION PRINCIPAL #####!#######

leerArgumentos $@

if [[ $mArchivo -eq 0 ]]; then
    # Recogida de datos

    pedirDatos
    #? calculo del numero de marcos en la memoria
    ((numMarcos = $dirTotales / $dirPagina))

    pedirProcesos
else
    ((numMarcos = $dirTotales / $dirPagina))
    if [[ $priMenor -gt $priMayor ]]; then
        a=$priMenor
        priMenor=$priMayor
        priMayor=$a
        invertido=1
    fi
fi

# Ordenar segun orden de llegada
ordenarLlegada

# Llena la memoria de -1
inicializarMemoria

# Se inicializa la cola de paginas restantes y los estados
for ((p = 0; p < ${#procLlegada[@]}; p++)); do
    paginasRestantes+=([$p]=$(convertirDirecciones ${procDirecciones[$p]}))
    procEstado[$p]=0
done

# hasta que finalize la cola, o hay una parada por limite de tiempo (para evitar un bucle infinito)
tiempo=0
until [[ $procesosRestantes -eq 0 ]] || [[ $tiempo -gt 1000 ]]; do
    paso
    ((tiempo++))
done

#TODO: Resumen final

clear
header 0 1
header 1 1
resumenFinal
exit 0

# echo "${procPrioridad[@]}"
# echo "${procTamano[@]}"
# echo "${procDirecciones[@]}"
