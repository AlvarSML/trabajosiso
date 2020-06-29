############ FUNCIONES ############

#############################
#   Obtiene los datos basicos por pantalla
#
#############################
function pedirDatos() {

    #? Prioridades
    printf "\e[1A%80s\r" " "
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

    until [[ $procPagina -gt 0 ]] && [[ $(($dirTotales % $procPagina)) = 0 ]]; do
        printf "\e[1A%80s\r" " " #imprimir 80 espacios en color 1A
        read -p "Número de direcciones por pagina: " procPagina
        printf "\e[91mINTRODUCE UN NÚMERO SUPERIOR A 0 Y DIVISOR DE %s \e[39m\r" $dirTotales
    done
    printf "%*s\n" "$(tput cols)" " "

    ((numMarcos = $dirTotales / $procPagina))

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
        printf "\e[1A%0s\r" " "

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
    local -i size, start

    segmentosLibres=();

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
    for ((i=0;i<$numMarcos;i++)); do
        memPrincipal[$i]=-1
    done
}

#############################
#   Desplaza la cola de prioridades un paso a la iquierda (elimina el primer valor)
#   Solo afecta a ordenPrioridad[]
#############################

function desplazarPrioridad() {
    for ((i=1;i<${#ordenPrioridad[@]};i++)); do
        ordenPrioridad[(($i-1))]=${ordenPrioridad[$i]} 
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
        for ((i=$2;i<(($2+marcos));i++)); do
            memPrincipal[$i]=$1
        done
    fi
}

#############################
#   Introduce procesos de la cola por prioridades en memoria
#   Input <- ordenPrioridad
#   Output -> memPrincipal
#############################

function introducirEnMemoria() {
    # por cada proceso segun prioridad
    for ((p=0;p<${#ordenPrioridad[@]};p++))
    do
        local -i optimo, exceso

        #Actualizar segmentos vacios
        buscarSegmentosVacios

        #? buscar segmento
        for seg in segmentosLibres
        do
            #buscar mejor hueco
            # Si no hay uno previo se guarda el primero en el que quepa
            if [[ -z $optimo ]] && [[ ${procTamano[$p]} -le ${segmentosLibres[$seg]} ]]
            then
                optimo=$seg
                exceso=((${segmentosLibres[$seg]} - ${procTamano[$p]}))
            # si hay uno previo y se encuentra uno mejor se cambia
            elif [[ -n optimo ]] && [[ ${procTamano[$p]} -le ${segmentosLibres[$seg]} ]] && [[ ((${segmentosLibres[$seg]} - ${procTamano[$p]})) -lt exceso ]]
            then
                optimo=$seg
                exceso=((${segmentosLibres[$seg]} - ${procTamano[$p]}))
            fi
        done

        # Si no se ha conseguido introducir el proceso, no se puede meter el siguiente
        if [[ -z $optimo ]]
        then
            p=${#ordenPrioridad[@]}
        # Si se ha conseguido, se desplaza la cola hacia la izquierda y se modifica la memoria
        # ademas se introduce el primer marco si tiene prioridad
        else
            procesosMemoria[$p]=$optimo
            desplazarPrioridad
        fi

        optimo=""
        exceso=""
    done
}

#############################
#   Introduce una pagina en un proceso en memoria fisica
#   Input <-- numero del proceso
#############################
function introducirPagina() {
    local -a paginas

    if [[ $# -ne 1 ]]; then
        echo "Numero incorrecto de parametros"
    else
        local -i proceso=$1

        #se obtienen las paginas
        IFS=', ' read -r -a paginas <<< "${procPaginas}"

        #se obtienen los marcos vacios       

    fi
}


#############################
#   Paso de la ejecucion
#
#############################
function paso() {

    #? se introducen los procesos que han llegado en la cola segun prioridad
    for proceso in ordenarLlegada; do
        if [[ ${procLlegada[$proceso]} -eq $tiempo ]]; then
            introducirPrioridad $proceso
        fi
    done

    #? si hay espacio en memoria y hay procesos en la cola se introduce
    ## Primero se buscan los segmentos libres
    buscarSegmentosVacios

    if [[ ${#segmentosLibres[@]} -gt 0 ]] && [[ ${@ordenPrioridad[@]} -gt 0 ]]
    then
        introducirEnMemoria
    fi

    ## Despues se introducen los procesos que quepan en esos segmentos
    ((tiempo++))
}

############ VARIABLES ############

declare -i priMayor priMenor invertido=0 #? si se ha invertido la prioridad mayor/menor
declare prioridad                        #? m o M

declare -i dirTotales
declare -i procPagina #? Numero de procesos por pagina
declare -i numMarcos  #? Numero de marcos en memoria principal

declare -i tiempo #! IMPORTANTE: tiempo de ejecucion, solo se aumenta en paso

declare -a procPrioridad procTamano procLlegada procDirecciones ordenLlegada
declare -a ordenPrioridad

declare -a proc_color_secuencia=(1,0 2,0 3,0 4,0 5,0 6,0 208,0 23,0 88,0 92,0 123,0 147,0 202,0 222,0 243,0)

#! Bandas de memoria
declare -a memPrincipal  #? memoria usada, N = proceso, -1 = vacia, cada indice es un marco
declare -a memPagina #? que pagina se encuentra en que marco

declare -A procesosMemoria #? procesos que se encuentran en memoria y su posicion inicial  
declare -A segmentosLibres #? segmentos de memoria vacions indice = posicon, valor = tamaño

#! Relativo a las paginas
# no se incluye procDirecciones y memPaginas
declare -A paginasRestantes #? paginas que quedan por cada proceso
declare -a ubicacionProceso #? marco inicial de cada proceso

#! datos estadisticos
# relativos al rendimiento del algoritmo
declare -a fallosProceso

############ EJECUCION PRINCIPAL ############

# Recogida de datos
clear
pedirDatos

clear
pedirProcesos

# Se pasan los espacios de memoria no ocupados a -1

# Ordenar segun orden de llegada
ordenarLlegada

until [[ finlaizado -eq 1 ]]; do
    paso
done

# echo "${procPrioridad[@]}"
# echo "${procTamano[@]}"
# echo "${procDirecciones[@]}"
