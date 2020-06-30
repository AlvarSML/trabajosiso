#! /bin/bash
# Simula la ejeución de una serie de procesos en un algoritmo Prioridad Mayor/Menor
# AUTHOR: Rodrigo Díaz, Diego González
# LICENSE: MIT

if ! [[ (${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -eq 3 && ${BASH_VERSINFO[2]} -ge 48) || (${BASH_VERSINFO[0]} -eq 4 && ${BASH_VERSINFO[1]} -gt 3) || ${BASH_VERSINFO[0]} -gt 4 ]]; then read -n 1 -p "VERSIÓN DE BASH < 4.3.48, la ejecución en esta versión no ha sido testeada, ¿continuar (s/n)? "; [[ ! $REPLY =~ ^[SsYy] ]] && echo && exit 90; fi
if [[ $(tput cols) -lt 100 ]]; then read -n 1 -p "El programa esta diseñado para funcionar con una ventana de al menos 100 caracteres de ancho, ¿continuar (s/n)? "; [[ ! $REPLY =~ ^[SsYy] ]] && echo && exit 91; fi
echo "">salida.txt
echo "">salidaNoEsc.txt


#_____________________________________________
# COMIENZO DE FUNCIONES
#_____________________________________________

#######################################
#	Muestra cabeceras gráficas
#	Globales:
#		mem_tamano
#		mem_tamano_abreviacion
#		mem_tamano_redondeado
#		mem_usada
#		mem_usada_abreviacion
#		mem_usada_redondeado
#		modo_silencio
#		proc_count
#		proc_count_abreviacion
#		proc_count_redondeado
#		tiempo
#	Argumentos:
#		modo:
#			0 = linea separación
#			1 = cabecera principal
#			2 = cabecera secundaria
#		salida:
#			0 = pantalla y log
#			1 = pantalla
#			2 = log
#	Devuelve:
#   Texto
#######################################
function header() {
	local -ri modo=$1 salida=$2
	local linea linea_no_esc linea_buffer
	if [[ $modo -eq 0 ]]; then
		linea=
		linea_no_esc=
		for i in {17..21} {21..17} ; do
			linea+="\e[38;5;${i}m##########"
			linea_no_esc+='##########'
		done
		if [[ $salida -eq 0 ]]; then
			pantalla "$linea"; log 3 "$linea" "$linea_no_esc"
		elif [[ $salida -eq 1 ]]; then
			pantalla "$linea"
		else
			log 3 "$linea" "$linea_no_esc"
		fi
	elif [[ $modo -eq 1 ]]; then
		linea=
		if [[ -z $modo_silencio ]]; then clear && clear; fi
		header 0 $salida
		linea='\e[38;5;17m#\e[0m\e[48;5;17m ALGORITMO PRIORIDAD MAYOR/MENOR EXPULSOR, PAGINACIÓN FIFO, MEMORIA CONTINUA Y REUBICABLE\e[0m                  \e[38;5;17m#'
		pantalla "$linea"
	else
		header 1 $salida

		
		linea+=$(printf "\e[48;5;17mTiempo: %3d\e[0m         \e[48;5;17mNúmero de Procesos:%d    Prioridad:%s   Valor Menor:%d  Valor Mayor:%d" "$tiempo" "$proc_count" "$prioridad" "$ValorMenorUsuario" "$ValorMayorUsuario")
		linea+='\e[0m             \e[38;5;17m#'
		pantalla "$linea"
		log 3 "$(printf "\e[38;5;17m#\e[39m%42sINSTANTE: %3d%43s\e[38;5;17m#\e[39m" " " "$tiempo" " ")" "$(printf "#%42sINSTANTE: %3d%43s#" " " "$tiempo" " ")"
		header 0
	fi
}

#######################################
#	Solicita datos al usuario
#	Globales:
#		mem_tamano
#		proc_color
#		proc_color_secuencia
#		proc_count
#		proc_estado
#		proc_id
#		proc_pagina_tamano
#		proc_paginas
#		proc_tamano
#		proc_tiempo_ejecucion
#		proc_tiempo_ejecucion_esperado
#		proc_tiempo_ejecucion_restante
#		proc_tiempo_llegada
#		tiempo_final
#	Argumentos:
#		Nada
#	Devuelve:
#		Nada
#######################################
numProcesos=0; #numero de procesos contabilizados

function pedirDatos() {
	
		
	local -i i finalizado
	pantalla
	if [[ -z $proc_color_secuencia ]]; then
		proc_color_secuencia=(1,0 2,0 3,0 4,0 5,0 6,0 208,0 23,0 88,0 92,0 123,0 147,0 202,0 222,0 243,0)

	fi


	if [[ -z $ValorMenor ]]; then
		printf "\e[1A%80s\r" " "
		read -p "Valor menor:" ValorMenor
		printf "\e[91mINTRODUCE M O m \e[39m\r"

	printf "%*s\n" "$(tput cols)" " "
	
	fi



	if [[ -z $ValorMayor ]]; then

		printf "\e[1A%80s\r" " "
		read -p "ValorMayor:" ValorMayor
		printf "\e[91mINTRODUCE M O m \e[39m\r"

	printf "%*s\n" "$(tput cols)" " "
	
	fi
	
	# valores introducidos por el usuario como mayor y menor
	ValorMenorUsuario=$ValorMenor;
	ValorMayorUsuario=$ValorMayor;

	if [[ -z $prioridad ]]; then
	until [[ $prioridad = 'M' ]] || [[ $prioridad = 'm' ]]; do
		printf "\e[1A%80s\r" " "
		read -p "Tipo de Prioridad (M/m):" prioridad
		printf "\e[91mINTRODUCE M O m \e[39m\r"

	done
	printf "%*s\n" "$(tput cols)" " "
	
	fi

	if test $prioridad = M; then
		if test $ValorMenor -le $ValorMayor; then
			priReal="M";
		fi
		
		if test $ValorMenor -ge $ValorMayor; then
			priReal="m";
		fi

	fi


	if test $prioridad = m; then
		if test $ValorMenor -le $ValorMayor; then
			priReal="m";
		fi
		
		if test $ValorMenor -ge $ValorMayor; then
			priReal="M";
		fi

	fi
	
	if test $ValorMenor -ge $ValorMayor;then
		 a=$ValorMenor;
		 b=$ValorMayor;
		ValorMenor=$b;
		ValorMayor=$a;
	fi


	Correcto='0';
	
	##si no es exacta la division entre 		mem_tamano=$dir_tot/$proc_pagina_tamano; lo vuelve a pedir
	if [[ -z $mem_tamano ]]; then
		until [[ $Correcto -eq '1' ]];do
			if [[ -z $dir_tot ]]; then #si el tamaño de memoria nulo
				until [[ $dir_tot =~ ^[0-9]+$ ]] && [[ ! $dir_tot -eq 0 ]]; do #hasta el tamaño de memoria empiece entre 0 y 9 Y sea diferente a 0 hacer...
					
					printf "\e[1A%80s\r" " " #imprimir 80 espacios en color 1A
					read -p "Número de direcciones totales de la memoria: " dir_tot  
					
					printf "\e[91mINTRODUCE UN NÚMERO SUPERIOR A 0\e[39m\r" #te muestra en pantalla el texto y vuelve a la linea anterior
				done
				printf "%*s\n" "$(tput cols)" " "
			fi

			if [[ -z $proc_pagina_tamano ]]; then
				until [[ $proc_pagina_tamano =~ ^[0-9]+$ ]] && [[ ! $proc_pagina_tamano -eq '0' ]];do #|| [[ Pedir -eq 1 ]]; do
					printf "\e[1A%80s\r" " "
					read -p "Direcciones por pagina: " proc_pagina_tamano
					
					printf "\e[91mINTRODUCE UN NÚMERO SUPERIOR A 0\e[39m\r"
				done
			printf "%*s\n" "$(tput cols)" " "
			fi



		mem_tamano=$dir_tot/$proc_pagina_tamano;
		a=$mem_tamano*$proc_pagina_tamano;
		if [[ $a -eq $dir_tot ]]; then
			Correcto='1';
			
		else
			unset dir_tot;
			unset proc_pagina_tamano;
		fi
		done
	fi


	j=0; #Cifra izquierda
	k=1; #Cifra derecha

	if [[ -z $proc_id_decenas ]]; then
		for ((i=0; finalizado!=1; i++)); do
			
			
			until [[ -n ${proc_priori[i]} ]] &&[[ ${proc_priori[i]-#} -le ${ValorMayor-#} ]]&& [[ ${proc_priori[i]-#} -ge ${ValorMenor-#} ]]  ; do
				printf "\e[1A%80s\r" " "
				read -p "[P${j}${k}] Prioridad: " proc_priori[i]
				if [[ -z ${proc_priori[i]}  ]]  ; then finalizado=1; unset proc_tamano[$i]; fi
				printf "\e[91m${proc_priori[i]} no esta entre $ValorMenor y $ValorMayor\e[39m\r"

			done
			printf "%*s\n" "$(tput cols)" " "
			
			
			

			until [[ ${proc_tamano[i]} =~ ^[0-9]+$ ]] && [[ ! ${proc_tamano[i]} -eq 0 ]] || [[ $finalizado -eq 1 ]]; do
				printf "\e[1A%80s\r" " "
				read -p "[P${j}${k}] Marcos de página: " proc_tamano[$i]
				if [[ -z ${proc_tamano[i]} ]]; then finalizado=1; unset proc_tamano[$i]; fi
				printf "\e[91mINTRODUCE UN NÚMERO SUPERIOR A 0\e[39m\r"
			done
			printf "%*s\n" "$(tput cols)" " "




			until [[ ${proc_tiempo_llegada[i]} =~ ^[0-9]+$ ]] || [[ $finalizado -eq 1 ]]; do
				printf "\e[1A%80s\r" " "
				read -p "[P${j}${k}] Tiempo de llegada: " proc_tiempo_llegada[$i]
				if [[ -z ${proc_tiempo_llegada[i]} ]]; then
					finalizado=1
					unset proc_tamano[$i]
					unset proc_tiempo_llegada[$i]
				fi
				printf "\e[91mINTRODUCE UN NÚMERO SUPERIOR A 0\e[39m\r"
			done
			printf "%*s\n" "$(tput cols)" " "

			until [[ -n ${proc_direcciones[i]} ]] ||[[ $finalizado -eq 1 ]]; do
				printf "\e[1A%80s\r" " "
				read -p "[P${j}${k}] Secuencia de direcciones: " proc_direcciones[$i]
				proc_direcciones[$i]=$(echo ${proc_direcciones[i]} | tr -d ' ')
				if [[ -z ${proc_direcciones[i]} ]]; then
					finalizado=1
					unset proc_tamano[$i]
					unset proc_tiempo_llegada[$i]
					unset proc_direcciones[$i]
				fi
				if [[ ${proc_direcciones[i]} =~ ([0-9]+,)*[0-9]+ ]]; then
					proc_direcciones[$i]="${BASH_REMATCH[0]}"
				else
					unset proc_direcciones[$i]
				fi
				if [[ -z ${proc_direcciones[i]} ]]; then
					printf "\e[91mINTRODUCE NÚMEROS SEPARADOS POR COMAS\e[39m\r"
				fi
			done
			printf "%*s\n" "$(tput cols)" " "

			if [[ -z $finalizado ]]; then
				printf "%*s\r" "$(tput cols)" " "
				proc_paginas[$i]=$(convertirDireccion ${proc_direcciones[i]})
				proc_id[$i]="P${i}" #Si no tiene la id asignada le da una
				proc_id_decenas[$i]="P${j}${k}" 
				proc_estado[$i]=1
				if [[ $i -lt ${#proc_color_secuencia[@]} ]]; then
				proc_color[$i]="48;5;$(echo ${proc_color_secuencia[i]} | cut -d ',' -f2);38;5;$(echo ${proc_color_secuencia[i]} | cut -d ',' -f1)"

					proc_f[$i]="48;5;$(echo ${proc_color_fondo[i]} | cut -d ',' -f2);38;5;$(echo ${proc_color_fondo[i]} | cut -d ',' -f1)"
				else
					proc_color[$i]="48;5;$(shuf -i 0-256 -n 1);38;5;$(shuf -i 0-256 -n 1)"
					proc_f[$i]="48;5;$(shuf -i 0-256 -n 1);38;5;$(shuf -i 0-256 -n 1)"
					
				fi
				proc_tiempo_ejecucion[$i]=0
				proc_tiempo_ejecucion_esperado[$i]=$(echo ${proc_paginas[i]} | tr ',' ' ' | wc -w) #Asigna el tiempo rastante al numero de paginas
				proc_tiempo_ejecucion_restante[$i]=${proc_tiempo_ejecucion_esperado[i]}
				log 3 "Proceso \e[44m${i}\e[49m, con ID \e[44m${proc_id[i]}\e[49m, Secuencia \e[44m${proc_paginas[i]}\e[49m, Marcos \e[44m${proc_tamano[i]}\e[49m, Llegada \e[44m${proc_tiempo_llegada[i]}" "Proceso <${j}${k}>, con ID <${proc_id[i]}>, Secuencia <${proc_paginas[i]}>, Marcos <${proc_tamano[i]}>, Llegada <${proc_tiempo_llegada[i]}>"
			else
				echo -ne '\e[1A'
				read -n 1 -p "Terminar introducción de datos (s/n)? "
				printf "\r%80s" " "
				if [[ ! $REPLY =~ ^[SsYy] ]]; then
					unset finalizado
					((i--))
				fi
			fi

		let "k=k+1"
		if [[ $k -eq 9 ]]; then
			let "j=j+1";
			let "k=0";
		fi

	let "numProcesos=numProcesos+1"; # Suma el proceso que acaba de annadir
	linea='\e[38;5;17m\e[39mREF TLL TEj NMA PRI TREJ TES TRET ESTADO            Paginas\e[38;5;17m\e[39m'

	pantalla "$linea"; log 3 "$linea" "$linea_no_esc"
	
	for (( n=0;n<numProcesos;n++)); do
		estado='FUERA DEL SISTEMA'
		linea=$(printf "\e[%sm\e[49m${proc_id_decenas[$n]} %3d %3d %3d %3d %3d %3d %3d  %s\e[8m%d\e[49m\e[0m " "${proc_color[n]}" "${proc_tiempo_llegada[n]}"     "${proc_tiempo_ejecucion_esperado[n]}"     "${proc_tamano[n]}"  "${proc_priori[n]}"     "${proc_tiempo_ejecucion_restante[n]}"    "${proc_tiempo_espera[n]}"     "${proc_tiempo_respuesta[n]}"       "$estado")
	

		veces=`grep -o "," <<< "${proc_direcciones[$n]}" | wc -l`;
	
		for ((l=0;l<veces;l++)); do
			let "p=l+1";
			dir=`echo "${proc_direcciones[n]}"|cut -d ',' -f $p`
			pag=$(convertirDireccion ${dir})
			linea+=$(printf "\e[%sm\e[49m%2d(%2d)" "${proc_color[n]}" "$pag" "$dir")


	
		done

		pantalla "$linea"; log 3 "$linea" "$linea_no_esc"
	
	done
		pantalla "\n";
		unset linea;
		unset linea_no_esc;

		for (( b=0;b<${mem_tamano-1};b++)); do
			linea+='\e[107m   ';
			linea_no_esc+='\e[107m    ';
		done
		pantalla "$linea"; log 3 "$linea" "$linea_no_esc" 


		unset linea;
		unset linea_no_esc;

	
		for (( c=0;c<=${mem_tamano};c++)); do
			if [[ $c -eq 0 ]] || [[ $c -eq ${mem_tamano-1} ]]; then 
				linea+="$(printf "%d  " "$c")"; linea_no_esc+="$(printf "%2d  " "$c")";
			else
				linea+="$(printf "   " )"; linea_no_esc+="$(printf "   " )";
			fi
		done
		
			
		


	pantalla "$linea\n"; log 3 "$linea" "$linea_no_esc" 
	unset linea;
	unset linea_no_esc;


	done

		proc_count=${#proc_id_decenas[@]}
		if [[ $proc_count -eq 0 ]]; then
			$proc_count=1;
			finalizarEjecucion 21
		fi
	fi
	tiempo_final="$(ultimoTiempo)"
}

#######################################
#	Lee argumentos de ejecución
#	Globales:
#		filename
#		mem_tamano
#		modo_debug
#		modo_silencio
#		nivel_log
#		proc_count
#		tiempo_break
#		tiempo_unbreak
#	Argumentos:
#		-b	TIEMPO
#			Habilita modo debug en TIEMPO
#		-d
#			Habilita modo debug
#		-f	FILENAME
#			Cargar datos desde FILENAME
#		-l	NIVEL
#			Nivel de salida por fichero:
#				0		debug
#				1		extendido
#				2		estructural
#				3		por defecto
#				4		alertas
#				5		mínimo
#				9		ejecición
#				10	deshabilitado
#		-m	MARCOS
#			Tamaño de memoria en marcos
#		-p	NÚMERO
#			Número de procesos
#		-s
#			Deshabilita salida por pantalla
#		-u	TIEMPO
#			Deshabilita modo debug en TIEMPO
#	Devuelve:
#		Nada
#######################################
function leerArgs() {
	while [[ $1 != "" ]]; do #mientras el parametro 1 no esté vacio
		case $1 in
			-s|--silencio) #si el parametro es s o silencio
				modo_silencio=1
				log 3 'Salida gráfica deshabilitada' '@';;
			-d|--debug)
				modo_debug=1
				nivel_log=0
				log 3 'Entrando modo debug' '@';;
			-f|--filename)
			  if [[ -n $2 ]] && [[ ! $2 == -* ]]; then
					filename=$2
					log 5 "Argumento de archivo introducido \e[44m$filename" "Argumento de archivo introducido <${filename}>"
					shift 2
					continue
			  else
					echo 'ERROR: "--filename" requiere un argumento válido/no vacio.'
					log 9 '\e[91m!!!\e[39m El argumento \e[91mfilename\e[39m contiene errores \e[91m!!!\e[39m' '!!! El argumento filename contiene errores !!!'
					finalizarEjecucion 40
			  fi;;
			-m|--memoria)
			  if [[ -n $2 ]] && [[ ! $2 == -* ]]; then
					local -ri tmp_mem_tamano=$2
					log 5 "Argumento de memoria introducido \e[44m$tmp_mem_tamano" "Argumento de memoria introducido ${tmp_mem_tamano}"
					shift 2
					continue
			  else
					echo 'ERROR: "--memoria" requiere un argumento válido/no vacio.'
					log 9 '\e[91m!!!\e[39m El argumento \e[91mmemoria\e[39m contiene errores \e[91m!!!\e[39m' '!!! El argumento memoria contiene errores !!!'
					finalizarEjecucion 41
			  fi;;
			-p|--procesos)
			  if [[ -n $2 ]] && [[ ! $2 == -* ]]; then
					proc_count=$2
					log 5 "Argumento de procesos introducido \e[44m$proc_count" "Argumento de procesos introducido <${proc_count}>"
					shift 2
					continue
			  else
					echo 'ERROR: "--procesos" requiere un argumento válido/no vacio.'
					log 9 '\e[91m!!!\e[39m El argumento \e[91mprocesos\e[39m contiene errores \e[91m!!!\e[39m' '!!! El argumento procesos contiene errores !!!'
					finalizarEjecucion 42
			  fi;;
			-l|--log)
			  if [[ -n $2 ]] && [[ ! $2 == -* ]]; then
					nivel_log=$2
				  log 5 "Establecido nivel de log a \e[44m$nivel_log" "Establecido nivel de log a <${nivel_log}>"
					shift 2
					continue
			  else
					echo 'ERROR: "--log" requiere un argumento válido/no vacio.'
					log 9 '\e[91m!!!\e[39m El argumento \e[91mlog\e[39m contiene errores \e[91m!!!\e[39m' '!!! El argumento log contiene errores !!!'
					finalizarEjecucion 43
			  fi;;
				-b|--breakpoint)
					if [[ -n $2 ]] && [[ ! $2 == -* ]]; then
						tiempo_break=$2
						log 9 "Estableciendo breakpoint en \e[44m$tiempo_break" "Estableciendo breakpoint en <${tiempo_break}>"
						shift 2
						continue
				  else
						echo 'ERROR: "--breakpoint" requiere un argumento válido/no vacio.'
						log 9 '\e[91m!!!\e[39m El argumento \e[91mbreakpoint\e[39m contiene errores \e[91m!!!\e[39m' '!!! El argumento breakpoint contiene errores !!!'
						finalizarEjecucion 44
				  fi;;
				-u|--unbreakpoint)
					if [[ -n $2 ]] && [[ ! $2 == -* ]]; then
						tiempo_unbreak=$2
						log 9 "Estableciendo unbreakpoint en \e[44m$tiempo_unbreak" "Estableciendo unbreakpoint en <${tiempo_unbreak}>"
						shift 2
						continue
				  else
						echo 'ERROR: "--unbreakpoint" requiere un argumento válido/no vacio.'
						log 9 '\e[91m!!!\e[39m El argumento \e[91munbreakpoint\e[39m contiene errores \e[91m!!!\e[39m' '!!! El argumento unbreakpoint contiene errores !!!'
						finalizarEjecucion 45
				  fi;;
			-?*)
				log 4 "\e[93m^^^\e[39m Opcíon \e[44m${1}\e[49m desconocida \e[93m^^^\e[39m" "^^^ Opción ${1} desconocida ^^^";;
			*)
		  	break
	  esac
	  shift
	done
	if [[ -n "$filename" ]]; then
		log 3 "Leyendo archivo:" '@'
		leerArchivo
		log 0 "Fin Lectura archivo" '@'
	fi
	if [[ -n "$tmp_mem_tamano" ]]; then
		mem_tamano=$tmp_mem_tamano
		log 3 "Tamaño de memoria asignado a \e[44m$mem_tamano" "Tamaño de memoria asignado a <${mem_tamano}>"
	fi
}

#######################################
#	Lee datos de archivo
#	Globales:
#		filename
#		mem_tamano
#		proc_color
#		proc_color_secuencia
#		proc_count
#		proc_estado
#		proc_id
#		proc_pagina_tamano
#		proc_paginas
#		proc_tamano
#		proc_tiempo_ejecucion
#		proc_tiempo_ejecucion_esperado
#		proc_tiempo_ejecucion_restante
#		proc_tiempo_llegada
#		proc_priori
#		tiempo_final
#	Argumentos:
#		Nada
#	Devuelve:
#		Nada
#######################################

function leerArchivo() {
	j=0; # decenas
	k=1; # unidades
	contProc=0;
	
	local -i i=0
	if [[ ! -f $filename ]]; then
		echo "Archivo \"${filename}\" no válido."
		log 9 '\e[91m!!!\e[39m El archivo no existe \e[91m!!!\e[39m' '!!! El archivo no existe !!!'
		finalizarEjecucion 30
	fi
	IFS=$'\n'; set -f #Establece el valor de separacion como final de linea
	for line in $(<$filename); do
		line=$(echo $line | cut -d '#' -f1 | tr -d ' ' | tr -d '\r') #elimina los espacios (-d) y tr sustituye
		log 0 "Linea leida \e[44m$line" "Linea leida <${line}>"
		if [[ ! $line == +* ]] && [[ -n $line ]]; then #si la linea no empieza por # y + o no es nula entonces...
			
			proc_priori[$i]=$(echo $line | cut -d ';' -f1) #guarda el tamaño, porque va cortando todolo separado por ; y coge la 1ª columna(-f1)
			proc_tamano[$i]=$(echo $line | cut -d ';' -f2) #guarda las paginas
			proc_direcciones[$i]=$(echo $line | cut -d ';' -f3) #guarda el tiempo de llegada
			proc_tiempo_llegada[$i]=$(echo $line | cut -d ';' -f4) #guarda el tiempo de llegada

			proc_id_decenas[$contProc]="P${j}${k}" 

			let "contProc=contProc+1";
			let "k=k+1"
			if [[ $k -eq 9 ]]; then
				let "j=j+1";
				let "k=0";
			fi

			if [[ $i -lt ${#proc_color_secuencia[@]} ]]; then
				proc_color[$i]="48;5;$(echo ${proc_color_secuencia[$i]} | cut -d ',' -f2);38;5;$(echo ${proc_color_secuencia[$i]} | cut -d ',' -f1)"
				proc_f[$i]="48;5;$(echo ${proc_f[$i]} | cut -d ',' -f2);38;5;$(echo ${proc_color_fondo[$i]} | cut -d ',' -f1)"
			else
				proc_color[$i]="48;5;$(shuf -i 0-256 -n 1);38;5;$(shuf -i 0-256 -n 1)"
				proc_f[$i]="48;5;$(shuf -i 0-256 -n 1);38;5;$(shuf -i 0-256 -n 1)"
			fi
			log 0 'Es proceso:'
			log 0 "Tamaño \e[44m${proc_tamano[$i]}" "Tamaño <${proc_tamano[$i]}>"
			log 0 "Secuecia \e[44m${proc_paginas[$i]}" "Secuecia <${proc_paginas[$i]}>"
			log 0 "Llegada \e[44m${proc_tiempo_llegada[$i]}" "Llegada <${proc_tiempo_llegada[$i]}>"
			


			
			
			log 0 "ID \e[44m${proc_id_decenas[$i]}" "ID <${proc_id_decenas[$i]}>"
			if [[ -z ${proc_id_decenas[$i]} ]]; then
				proc_id[$i]="P${i}" #si el proceso no tiene id se le asigna uno por defecto
				log 0 "Nueva ID \e[44m${proc_id_decenas[$i]}" "Nueva ID <${proc_id_decenas[$i]}>"
			fi
			proc_estado[$i]=1
			proc_paginas[$i]=$(convertirDireccion ${proc_direcciones[$i]})
			proc_tiempo_ejecucion_esperado[$i]=$(echo ${proc_paginas[i]} | tr ',' ' ' | wc -w)
			proc_tiempo_ejecucion_restante[$i]=${proc_tiempo_ejecucion_esperado[i]}
			log 3 "Proceso \e[44m${i}\e[49m, con ID \e[44m${proc_id_decenas[$i]}\e[49m, Secuencia \e[44m${proc_paginas[$i]}\e[49m, Marcos \e[44m${proc_tamano[$i]}\e[49m, Llegada \e[44m${proc_tiempo_llegada[$i]}\e[49m" "Proceso <${i}>, con ID <${proc_id_decenas[$i]}>, Secuencia <${proc_paginas[$i]}>, Marcos <${proc_tamano[$i]}>, Llegada <${proc_tiempo_llegada[$i]}>"
			((i++))
		else
			if [[ $line == +* ]]; then
				log 0 'Es opción:' '@'
				case $(echo $line | tr -d '+' | cut -d ':' -f1) in
					"VALOR_MENOR")
						ValorMenor=$(echo $line | cut -d ':' -f2)
						log 0 "de memoria \e[44m$ValorMenor" "de memoria <${ValorMenor}>"
						log 3 "Configuración, marcos de memoria \e[44m$cotaPrimera" "Configuración, marcos de memoria <${cotaPrimera}>";;
					"VALOR_MAYOR")
						ValorMayor=$(echo $line | cut -d ':' -f2)
						log 0 "de memoria \e[44m$cotaSegunda" "de memoria <${ValorMayor}>"
						log 3 "Configuración, marcos de memoria \e[44m$ValorMayor" "Configuración, marcos de memoria <${ValorMayor}>";;

					"DIRECCIONES_TOTALES")
						dir_tot=$(echo $line | cut -d ':' -f2)
						log 0 "de memoria \e[44m$dir_tot" "de memoria <${dir_tot}>"
						log 3 "Configuración, marcos de memoria \e[44m$dir_tot" "Configuración, marcos de memoria <${dir_tot}>";;
					"DIRECCIONES")
						proc_pagina_tamano=$(echo $line | cut -d ':' -f2)
						log 0 "de página \e[44m$proc_pagina_tamano" "de página <${proc_pagina_tamano}>"
						log 3 "Configuración, tamaño de pagina \e[44m$proc_pagina_tamano" "Configuración, tamaño de pagina <${proc_pagina_tamano}>";;
					"PRIORIDAD")
						prioridad=$(echo $line | cut -d ':' -f2)
						log 0 "de memoria \e[44m$prioridad" "de memoria <${prioridad}>"
						log 3 "Configuración, marcos de memoria \e[44m$prioridad" "Configuración, marcos de memoria <${prioridad}>";;

					"COLORES")
						IFS=';' read -r -a proc_color_secuencia <<< "$(echo $line | cut -d ':' -f2)"
						log 0 "de color \e[44m$proc_color_secuencia" "de página <${proc_color_secuencia}>"
						log 3 "Configuración, colores \e[44m$proc_color_secuencia" "Configuración, colores <${proc_color_secuencia}>";;
					*)
						echo 'CONFIGURACIÓN EN FICHERO NO VÁLIDA'
						log 9 "\e[91m!!!\e[39m Configuración en archivo no válida \e[91m!!!\e[39m" "!!! Configuración en archivo no válida !!!"
						finalizarEjecucion 31;;
				esac
			else log 0 'Es comentario' '@'; fi
		fi
	done
	mem_tamano= ${dir_tot}/$proc_pagina_tamano;
	set +f; unset IFS
	if [[ ! $i -eq 0 ]]; then
		proc_count=$i
	fi
}

#######################################
#	Convierte páginas a direcciones
#	Globales:
#		proc_pagina_tamano
#	Argumentos:
#		direcciones
#	Devuelve:
#		paginas
#######################################
function convertirDireccion() {
	local -r secuencia=$1
	local -a direcciones=()
	local paginas
	IFS=',' read -r -a direcciones <<< "$secuencia"
	for direccion in ${direcciones[@]}; do
		paginas+="$((direccion / proc_pagina_tamano)),"
	done
	echo "${paginas::-1}"
}

#######################################
#	Muestra datos por pantalla
#	Globales:
#		linea_tiempo
#		mem_paginas
#		mem_paginas_secuencia
#		mem_proc_id
#		mem_proc_index
#		mem_siguiente_ejecucion
#		out_proc_index
#		proc_color
#		proc_estado
#		proc_id
#		proc_orden
#		proc_paginas
#		proc_posicion
#		proc_tamano
#		proc_tiempo_ejecucion
#		proc_tiempo_ejecucion_esperado
#		proc_tiempo_ejecucion_restante
#		proc_tiempo_espera
#		proc_tiempo_respuesta
#		swp_proc_id
#		swp_proc_index
#		tiempo
#	Argumentos:
#		Nada
#	Devuelve:
#		Nada
#######################################
function salidaEjecucion() {

	local -i i j ultimo_cambio=0 offset
	local -a paginas paginas_color
	local id estado estado_color linea linea_no_esc linea_buffer posicion fallo
	header 2
	linea='\e[38;5;17m\e[39m REF TLL TEj NMA PRI TES TRET TREJ ESTADO             Paginas\e[38;5;17m\e[39m'
	linea_no_esc='\e[38;5;17m\e[39m REF TLL TEj NMA PRI TES TRET TREJ ESTADO             Paginas\e[38;5;17m\e[39m'

	pantalla "$linea"; log 3 "$linea" "$linea_no_esc"
	j=0; #cifra izquierda
	k=0; #cifra derecha
	contMemEjec=0; #cuenta el numero de procesos en memoria o ejecucion
	for i in ${proc_orden[@]}; do


		id=${proc_id[$i]:0:8}
		id_decenas=${proc_id_decenas[$i]:0:8}

		if [[ ${proc_estado[i]} -ge 16 ]]; then
			estado='FINALIZADO       '

		elif [[ ${proc_estado[i]} -ge 8 ]]; then
			anteriorProc=$UltimoEjec;
			procMem[$contMemEjec]=${proc_id_decenas[$i]};
			procColorMem[$contMemEjec]=${proc_color[i]};
			UltimoEjec=${proc_id_decenas[$i]};
			UltimoColorEjec=${proc_color[i]};
			UltimoColor=${proc_color[i]};
			estado='EN EJECUCION     '
			let "contMemEjec=contMemEjec+1"
			

		elif [[ ${proc_estado[i]} -ge 4 ]]; then
			procMem[$contMemEjec]=${proc_id_decenas[$i]};
			procColorMem[$contMemEjec]=${proc_color[i]};

			estado='EN MEMORIA       '
			let "contMemEjec=contMemEjec+1"


		elif [[ ${proc_estado[i]} -ge 2 ]]; then
			estado='EN ESPERA        '

		else

			estado='FUERA DEL SISTEMA'

		fi
		
	
		if [[ $estado != 'FUERA DEL SISTEMA' ]]; then
			linea=$(printf "\e[${proc_color[i]}m\e[49m ${proc_id_decenas[$i]}%3d %3d %3d %3d %3d %3d %3d    %s\e[8m%d\e[49m\e[0m "  "${proc_tiempo_llegada[i]}"     "${proc_tiempo_ejecucion_esperado[i]}"     "${proc_tamano[i]}"  "${proc_priori[i]}"     "${proc_tiempo_espera[i]}"    "${proc_tiempo_respuesta[i]}"     "${proc_tiempo_ejecucion_restante[i]}"       "$estado")

			linea_no_esc=$(printf "\e[49m ${proc_id_decenas[$i]}%3d %3d %3d %3d %3d %3d %3d    %s\e[8m%d\e[49m\e[0m "  "${proc_tiempo_llegada[i]}"     "${proc_tiempo_ejecucion_esperado[i]}"     "${proc_tamano[i]}"  "${proc_priori[i]}"     "${proc_tiempo_espera[i]}"    "${proc_tiempo_respuesta[i]}"     "${proc_tiempo_ejecucion_restante[i]}"       "$estado")
		else

			linea=$(printf "\e[${proc_color[i]}m\e[49m ${proc_id_decenas[$i]}%3d --- %3d %3d --- --- ---    FUERA DEL SISTEMA  " "${proc_tiempo_llegada[i]}"          "${proc_tamano[i]}"  "${proc_priori[i]}"                    )

			linea_no_esc=$(printf "\e[49m ${proc_id_decenas[$i]}%3d --- %3d %3d --- --- ---    FUERA DEL SISTEMA  " "${proc_tiempo_llegada[i]}"          "${proc_tamano[i]}"  "${proc_priori[i]}"                    )


		fi


		if [[ $estado = "EN EJECUCION     " ]]; then
			ProcEnEjecucion=${proc_id_decenas[$i]}; # guarda el proceso que esta siendo ejecutado
			colorEnEjecucion=$(echo "${proc_color[$i]}"|cut -d ";" -f6);

		fi
		
		for (( z=0;z<=${proc_count};z++)); do
			if [[ "$ProcEnEjecucion" = "${proc_id_decenas[$z]}" ]]; then
				numProcEnEjecucion=$z; # Numero del proceso que esta en ejecucion

			fi


		done
		
	let "vecesSubrayar=sacarPaginas[i]"
	veces=`grep -o "," <<< "${proc_direcciones[$i]}" | wc -l`;
	
	if [[ "$estado" = "FINALIZADO       " ]]; then
		vecesSubrayar=`grep -o "," <<< "${proc_direcciones[$i]}" | wc -l`;
		let "sacarPaginas[i]=vecesSubrayar"
	fi

	if [[ "$estado" = "EN EJECUCION     " ]]; then
			let "vecesSubrayar=sacarPaginas[i]+1"
	fi
	
	for ((j=0;j<veces;j++)); do

		let "p=j+1";
		dir=`echo "${proc_direcciones[i]}"|cut -d ',' -f $p`

		pag=$(convertirDireccion ${dir})
		if [[ $vecesSubrayar -gt 0 ]];then
			linea+=$(printf "\e[%sm\e[49m\e[4m%d-%d\e[0m " "${proc_color[i]}" "$dir" "$pag" )
			linea_no_esc+=$(printf "\e[49m\e[4m%d-%d\e[0m "  "$dir" "$pag" )
			let "vecesSubrayar=vecesSubrayar-1"
		else
			linea+=$(printf "\e[%sm\e[49m%d-%d " "${proc_color[i]}" "$dir" "$pag" )
			linea_no_esc+=$(printf "\e[49m%d-%d "  "$dir" "$pag" ) 
		fi
	done
	unset vecesSubrayar;
	unset Aux;
	unset a;


		let "k=k+1"
		if [[ $k -eq 9 ]]; then
			let "j=j+1";
			let "k=0";
		fi
	

	pantalla "$linea"; log 3 "$linea" "$linea_no_esc"

	done



	header 0
	


	cuentaProc=0; #Cuenta los procesos
	cuentaTamano=0; #Va sumando el tamano de cada proceso
	contadorNum=0;
	EstaImpresoCero=0; #indica si ya ha impreso el 0 de la memoria o no	
	Ant=0;
	
	linea='\e[38;5;17m\e[39m'; linea_no_esc='\e[100m'




	contMemEjec=0; #reutilizo la variable

		lineaNombre+="       ";lineaNombre_no_esc+="       ";
		lineaProcesos+="MEMORIA"; lineaProcesos_no_esc+="MEMORIA"; ##inicio de la barra 
		lineaNumeros+="       ";lineaNumeros_no_esc+="       ";




	for i in {0..100}; do

		
		if test $i -eq ${mem_tamano}; then
			break;
		fi
		offset=$(echo ${proc_posicion[mem_paginas[i]]} | cut -d ' ' -f1)
		if [[ -n ${mem_paginas[i]} ]] && [[ ${mem_paginas[i]} -ne $((mem_paginas[i-1])) ]]; then
			ultimo_cambio=0
		fi
		if [[ -n ${mem_paginas[i]} ]] && [[ $i -lt $mem_tamano ]]; then
			if [[ $i -eq $((proc_paginas_apuntador[mem_paginas[i]] + offset)) ]]; then
				linea+="" #"\e[100m\e[${proc_color[${mem_paginas[i]}]}m\e[100m"; linea_no_esc+='\e[100m'
			else
				((++ultimo_cambio))
				id_decenas=$(echo "${proc_id_decenas[mem_paginas[i]]}" )

				tamanoProc=${proc_tamano[mem_paginas[i]]};


				EstaYaImpreso=0;
				u=${#nombresProc[@]};
				for((p=0;p<$u;p++));do
					if test "$id_decenas" = "${nombresProc[$p]}"; then 
						EstaYaImpreso=1;
					fi
					if test -z $id_decenas; then
						EstaYaImpreso=1;
					fi 
				done

					if test $EstaYaImpreso -eq 0; then

						for ((k=0;k<$tamanoProc;k++)); do
							
							if test $k -eq 0; then

								if test $EstaImpresoCero -eq 0; then
									lineaNombre+=$(printf "\e[${procColorMem[$contMemEjec]}m\e[49m${procMem[$contMemEjec]}   ")
									lineaNombre_no_esc+=$(printf "\e[49m${procMem[$contMemEjec]}   ")
									Last=${procMem[$contMemEjec]};
 									let "contMemEjec=contMemEjec+1"
									Anterior=$color;

									lineaNumeros+=$(printf "\e[49m0   \e[0m") lineaNumeros_no_esc+=$(printf "\e[49m0  \e[0m")
									EstaImpresoCero=1;
									
								else
									lineaNombre+=$(printf "   ")
									lineaNombre_no_esc+=$(printf "   ")
									lineaNumeros+='\e[0m   \e[0m'; lineaNumeros_no_esc+='\e[0m    \e[0m';
								fi

	
								let "help=contMemEjec-1"
								#busca el numero del proceso actual de entre todos
								for ((u=0;u<=$proc_count;u++)); do
									if [[ "${procMem[$help]}" = "${proc_id_decenas[$u]}" ]] ; then
										numProcesoActual=$u;
									fi



								done
								#mira si el proceso está en memoria y ha sido expulsado para sacar las paginas ejecutadas ya 
							
								if [[ ${proc_estado[$numProcesoActual]} -ge 4 ]] && [[ ${proc_estado[$numProcesoActual]} -lt 8 ]]; then
									if [[ ${sacarPaginas[$numProcesoActual]} -gt 0 ]]; then
										let "y=sacarPaginas[numProcesoActual]";
										## saca las paginas necesarias según le indica el array sacarPaginas
										for ((j=0;j<$y;j++)); do
											let "p=j+1";
											dir=`echo "${proc_direcciones[$numProcesoActual]}"|cut -d ',' -f $p`
				
											pag=$(convertirDireccion ${dir})
											let "help=contMemEjec-1"
											pintaColor=$(echo "${procColorMem[$help]}"|cut -d ";" -f6)
											lineaProcesos+=$(printf "\e[48;5;${pintaColor}m\e[30m%d  " "$pag" )
											lineaProcesos_no_esc+=$(printf "\e[30m%d  "  "$pag" )
											lineaNumeros+='\e[0m   \e[0m'; lineaNumeros_no_esc+='\e[0m   \e[0m';
											lineaNombre+='\e[0m   \e[0m'; lineaNombre_no_esc+='\e[0m \e[0m';

										done
									fi
								fi






								#si el que va a pintar es el que se está ejecutando
								if [[ "${procMem[$help]}" = "$UltimoEjec" ]] ; then

									let "y=sacarPaginas[numProcEnEjecucion]+1";
									## saca las paginas necesarias según le indica el array sacarPaginas
									for ((j=0;j<$y;j++)); do
										let "p=j+1";
										dir=`echo "${proc_direcciones[$numProcEnEjecucion]}"|cut -d ',' -f $p`
				
										pag=$(convertirDireccion ${dir})
										let "help=contMemEjec-1"
										pintaColor=$(echo "${procColorMem[$help]}"|cut -d ";" -f6)
										lineaProcesos+=$(printf "\e[48;5;${pintaColor}m\e[30m%d  " "$pag" )
										lineaProcesos_no_esc+=$(printf "\e[30m%d  "  "$pag" )
										lineaNumeros+='\e[0m   \e[0m'; lineaNumeros_no_esc+='\e[0m   \e[0m';#AQUI SACA EL BLANCO
										lineaNombre+='\e[0m   \e[0m'; lineaNombre_no_esc+='\e[0m \e[0m';#AQUI SACA EL BLANCO

								done



								#bucle que suma las paginas que se deben sacar dependiendo del tiempo
								for (( s=0;s<${#sacarPaginas[@]};s++ )); do

									if test $s -eq $numProcEnEjecucion; then
	
										if [[ -z $anteriorTime  ]] ; then
											let "Aux=1";
										else
												 
											let "Aux=tiempo-anteriorTiempo+1"


									
										fi
							
 															  
		
										for (( o=0;o<$Aux;o++ )); do
											let "sacarPaginas[numProcEnEjecucion]=sacarPaginas[numProcEnEjecucion]+1"

										done
										
																						
	
									fi
								done 

								let "help=contMemEjec-1"
								pintaColor=$(echo "${procColorMem[$help]}"|cut -d ";" -f6)
								lineaProcesos+=$(printf "\e[48;5;${pintaColor}m   \e[0m"); 
								lineaProcesos_no_esc+=$(printf "   \e[0m");

								
							else
								let "help=contMemEjec-1"
								pintaColor=$(echo "${procColorMem[$help]}"|cut -d ";" -f6)
								lineaProcesos+=$(printf "\e[48;5;${pintaColor}m   \e[0m"); 
								lineaProcesos_no_esc+=$(printf "   \e[0m"); 


							fi
							
							



							else 
							let "help=contMemEjec-1"
							pintaColor=$(echo "${procColorMem[$help]}"|cut -d ";" -f6)
							lineaProcesos+=$(printf "\e[48;5;${pintaColor}m   \e[0m");
							 lineaProcesos_no_esc+=$(printf "   \e[0m");
							lineaNumeros+='\e[0m   \e[0m'; lineaNumeros_no_esc+='\e[0m    \e[0m';#AQUI SACA EL BLANCO
							lineaNombre+='\e[0m   \e[0m'; lineaNombre_no_esc+='\e[0m   \e[0m';#AQUI SACA EL BLANCO
							fi
						done
							let "cuentaTamano=cuentaTamano+tamanoProc"

							id_decenasNext=$(echo "${proc_id_decenas[mem_paginas[cuentaTamano]]}") # | cut -c $(($ultimo_cambio * 3 - 2))-)

							colorNext=${proc_color[mem_paginas[cuentaTamano]]};

															
							lineaNombre+=$(printf " \e[${procColorMem[$contMemEjec]}m\e[49m${procMem[$contMemEjec]}")
							lineaNombre_no_esc+=$(printf " \e[49m${procMem[$contMemEjec]}")

							let "contMemEjec=contMemEjec+1"
							Anterior=$colorNext;
				
						lineaProcesos+=$( printf "\e[94m\e[48;5;${pintaColor}m   |\e[0m"); 
						lineaProcesos_no_esc+=$( printf "\e[94m   |\e[0m"); 

						if [[ $cuentaTamano/10 -ge 1 ]]; then
						lineaNumeros+=$(printf "\e[49m  $cuentaTamano\e[0m") lineaNumeros_no_esc+=$(printf "\e[0m  $cuentaTamano\e[0m")

						else
						lineaNumeros+=$(printf "\e[49m   $cuentaTamano\e[0m") lineaNumeros_no_esc+=$(printf "\e[0m   $cuentaTamano\e[0m")
						fi

						let "contadorNum=contadorNum+1";


						nombresProc[$cuentaProc]="$id_decenas";
						let "cuentaProc=cuentaProc+1"
					fi
					fi

			
	
		fi


	done

		unset contMemEjec;
		unset procMem;
		unset contTamano;
		unset procTamano;
		unset procColorMem;
			cuentaProc=0; #Cuenta los procesos
		contadorNum=0;
		unset nombresProc;
		unset EstaImpresoCero;
		EstaYaImpreso=0;
	pantalla "$lineaNombre"; log 3 "$lineaNombre" "$lineaNombre_no_esc" #numeritos

		let "lim=mem_tamano"


	if test $cuentaTamano -ne $mem_tamano; then
		let "queda=lim-cuentaTamano"
		for(( c=0;c<$queda;c++)); do
				let "help=mem_tamano-c"
				lineaProcesos+='\e[107m   \e[0m'; lineaProcesos_no_esc+='\e[107m    \e[0m';#AQUI SACA EL BLANCO
				lineaNumeros+=$(printf "\e[49m   \e[0m") lineaNumeros_no_esc+=$(printf "\e[49m   \e[0m") 

		done 
		lineaNumeros+=$(printf "\e[49m$mem_tamano\e[0m") lineaNumeros_no_esc+=$(printf "\e[49m$mem_tamano\e[0m") 

	fi



	pantalla "$lineaProcesos"; log 3  "$lineaProcesos" "$lineaProcesos_no_esc" #numeritos
	pantalla "$lineaNumeros"; log 3 "$lineaNumeros" "$lineaNumeros_no_esc" #numeritos
	unset lineaNumeros;
	unset lineaNumeros_no_esc;
	unset lineaProcesos;
	unset linea_Procesos_no_esc;
	unset lineaNombre;
	unset lineaNombre_no_esc;
	header 0
	





################################################## A PARTIR DE AQUI, LINEA DE TIEMPO ###############
	
	
	unset linea_buffer;
	unset linea;
	unset linea_no_esc;

	if [[ -z $IniciarLineaTiempo ]]; then
		lineaIdTime+="       "; lineaIdTime_no_esc+="       ";
		lineaTime+="TIEMPO"; lineaTime_no_esc+="TIEMPO";
		lineaAuxTime+="TIEMPO";
		lineaTime_buffer+="      "; lineaTimebuffer_no_esc+="      ";
		IniciarLineaTiempo="dkjlajñlk"; # nunca más volverá a estar vacia

	fi
	
	#si es la primera vez que sale en ejecucion

	if [[ ${sacarPaginas[numProcEnEjecucion]} -eq 1 ]] && [[ "$UltimoEjec" != "$anteriorProc" ]] || [[ ${sacarPaginas[numProcEnEjecucion]} -ne 1 ]] && [[ "$UltimoEjec" != "$anteriorProc" ]]; then

		
		if [[ -n $anteriorTime ]] ;then 
			let "incremento=tiempo-anteriorTime-2" # le resto dos porque pone dos de más 
			for (( c=0;c<${incremento}; c++ ));do
					
				let "numPaginas[antNumEjec]=numPaginas[antNumEjec]+1"

				let "l=numPaginas[antNumEjec]"
				dir=`echo "${proc_direcciones[$antNumEjec]}"|cut -d ',' -f $l`
				
				pag=$(convertirDireccion ${dir})

			
					lineaIdTime+="\e[49m   "; lineaIdTime_no_esc+="\e[49m   "
					lineaTime+="\e[30;48;5;${auxColor}m$pag  ";
					 lineaTime_no_esc+="$pag  ";
					lineaAuxTime+="\e[30;48;5;${auxColor}m$pag  ";
					lineaTime_buffer+="\e[49m   ";lineaTimebuffer_no_esc+="\e[49m   "


			done
		fi
		auxColor=$(echo "$UltimoColorEjec"|cut -d ";" -f6);
		if [[ $UltimoEjec != $AnteriorPintado ]]; then # si el nombre es distinto del nombre anterior que ha pintado..
			lineaIdTime+="\e[49m\e[${UltimoColorEjec}m\e[49m$UltimoEjec"; lineaIdTime_no_esc+="\e[49m\e[49m$UltimoEjec"
			PintaNombre=1;
		fi
		AnteriorPintado=$UltimoEjec;

		if [[ -n $PintaNombre ]]; then
			let "numPaginas[numProcEnEjecucion]=numPaginas[numProcEnEjecucion]+1"

			let "l=numPaginas[numProcEnEjecucion]"
			dir=`echo "${proc_direcciones[$numProcEnEjecucion]}"|cut -d ',' -f $l`
				
			pag=$(convertirDireccion ${dir})


			lineaTime+="\e[${UltimoColorEjec}m\e[49m|$pag  "; lineaTime_no_esc+="\e[0m|$pag  "
			lineaAuxTime+="|\e[30;48;5;${auxColor}m$pag  ";
			lineaTime_buffer+=" ";lineaTime_buffer_no_esc+=" "; 
			lineaIdTime+=" "; lineaIdTime_no_esc+=" ";

		fi
		

		if test -z $tiempo; then
			tiempo=0;
		fi
		if [[ $tiempo/10 -ge 1 ]]; then
			lineaTime_buffer+="\e[49m\e[${UltimoColorEjec}m\e[49m$tiempo ";lineaTimebuffer_no_esc+="\e[49m\e[49m $tiempo "
		else
			lineaTime_buffer+="\e[49m\e[${UltimoColorEjec}m\e[49m$tiempo  ";lineaTimebuffer_no_esc+="\e[49m\e[49m $tiempo  "
		fi


		
		
		anteriorTime=$tiempo;

	else
					

			auxColor=$(echo "$UltimoColorEjec"|cut -d ";" -f6);
			let "incremento=tiempo-anteriorTime"
			
			for (( c=0;c<${incremento}; c++)); do
				let "numPaginas[numProcEnEjecucion]=numPaginas[numProcEnEjecucion]+1"

				let "l=numPaginas[numProcEnEjecucion]"
				dir=`echo "${proc_direcciones[$numProcEnEjecucion]}"|cut -d ',' -f $l`
				
				pag=$(convertirDireccion ${dir})

			
					lineaIdTime+="\e[49m   "; lineaIdTime_no_esc+="\e[49m   "
					lineaTime+="\e[30;48;5;${auxColor}m$pag  ";
					 lineaTime_no_esc+="$pag  ";
					lineaAuxTime+="\e[30;48;5;${auxColor}m$pag  ";
					lineaTime_buffer+="\e[49m   ";lineaTimebuffer_no_esc+="\e[49m   "


			done
			anteriorTime=$tiempo;

	fi
	unset PintaNombre;
	antNumEjec=$numProcEnEjecucion;

	pantalla "$lineaIdTime"; log 3 "$lineaIdTime" "$lineaIdTime_no_esc"
	pantalla "$lineaTime"; log 3 "$lineaTime" "$lineaTime_no_esc"
	pantalla "$lineaTime_buffer"; log 3 "$lineaTime_buffer" "$lineaTimebuffer_no_esc"

	lineaTime=$lineaAuxTime;

	
	header 0

	header 0
}

#######################################
#	Realiza un paso de tiempo
#	Globales:
#		evento
#		evento_log
#		evento_log_NoEsc
#		mem_proc_id
#		mem_tamano
#		mem_tamano_abreviacions
#		mem_tamano_redondeado
#		mem_usada
#		mem_usada_abreviacion
#		mem_usada_redondeado
#		modo_debug
#		modo_silencio
#		proc_count
#		proc_count_abreviacion
#		proc_count_redondeado
#		swp_proc_id
#		tiempo
#		tiempo_break
#		tiempo_final
#		tiempo_unbreak
#	Argumentos:
#		Nada
#	Devuelve:
#		Nada
#######################################
function step() {
	local -i i
	if [[ $tiempo -le $tiempo_final ]]; then poblarSwap; fi
	if [[ ! ${#swp_proc_id[@]} -eq 0 ]]; then poblarMemoria; fi

	if [[ ${#mem_proc_id[@]} -eq 0 ]]; then
		if [[ ${#swp_proc_id[@]} -eq 0 ]] && [[ $tiempo -gt $tiempo_final ]]; then finalizarEjecucion 0 ; fi #? si ha terminado
		if [[ ${proc_tamano[${swp_proc_index[0]}]} -gt $mem_tamano ]]; then finalizarEjecucion 20 ; fi #? si el tamaño del proceso es mayor que la memoria
		if [[ $tiempo -ge 0 ]]; then linea_tiempo[$tiempo]=-1; fi #? cuando no hay nada en la memria se pone a -1
	else
		calcularEjecucion
	fi

	if [[ -n $tiempo_break ]] && [[ $((tiempo + 1)) -eq $tiempo_break ]]; then
		modo_debug=1
		if [[ -n $modo_silencio ]]; then
			modo_silencio_break=1
			notacionCientifica $mem_tamano "mem_tamano_redondeado" "mem_tamano_abreviacion" #abrevia la memoria
			notacionCientifica $mem_usada "mem_usada_redondeado" "mem_usada_abreviacion"
			notacionCientifica $proc_count "proc_count_redondeado" "proc_count_abreviacion"
			unset modo_silencio
		fi
	fi

	if [[ -n $tiempo_unbreak ]] && [[ $tiempo -eq $tiempo_unbreak ]]; then
		unset modo_debug
		if [[ -n $modo_silencio_break ]]; then
			modo_silencio=1
			unset modo_silencio_break
		fi
	fi

	if [[ -n $evento ]] || [[ -n $modo_debug ]]; then
		salidaEjecucion
	fi

	if [[ -n $evento ]]; then
		for ((i=0; i<${#evento_log[@]}; i++)); do
			if [[ $(echo ${evento_log_NoEsc[$i]} | cut -d ' ' -f2) == 'termina' ]]; then
				log 5 "$(echo ${evento_log[$i]} | cut -d '#' -f1)" "$(echo ${evento_log_NoEsc[$i]} | cut -d '#' -f1)"
				evolucionPaginas $(echo ${evento_log_NoEsc[$i]} | cut -d '#' -f2)
			else
				log 5 "${evento_log[$i]}" "${evento_log_NoEsc[$i]}"
			fi
		done
		pantalla "${evento::-2}"
		evento_log=()
		evento_log_NoEsc=()
	fi

	if [[ -n $evento ]] || [[ -n $modo_debug ]]; then
		log 3
		if [[ -z $modo_silencio ]]; then
			read -p "Presiona cualquier tecla para continuar " -n 1 -r
		fi
	fi
	unset evento

	if [[ ${#mem_proc_id[@]} -gt 0 ]]; then
		ejecucion
	fi

	((tiempo++))

	############!###########
	echo " ##### Paso ######"
	echo ${#proc_id[@]}
	echo ${proc_estado[@]}
	echo ${proc_tamano[@]}
	echo ${mem_proc_id[@]}
	echo $tiempo
	echo $tiempo_final
	echo ${linea_tiempo[@]}
	read -p "#########"
	############!###########
}

#######################################
#	Abrevia número
#	Globales:
#		Nada
#	Argumentos:
#		global abreviacion
#		global redondeado
#		numero
#	Devuelve:
#		Nada
#######################################
function notacionCientifica() {
	local -ri numero=$1 #primer argumento es el numero a redondear
	local -rn redondeado="$2" abreviacion="$3" #la variable donde se guardara la aproximación y la variable donde se guarda la abreviacion
	local -i i=1000
	while [[ -z $redondeado ]]; do
		if [[ $numero -ge $i ]]; then
			i=$((i * 1000))
		else
			case "$i" in
			"1000")
				abreviacion=;;
			"1000000")
				abreviacion="K";;
			"1000000000")
				abreviacion="M";;
			"1000000000000")
				abreviacion="G";;
			"1000000000000000")
				abreviacion="T";;
			*)
				abreviacion="?";;
			esac
			redondeado=$((numero % i / (i / 1000)))
		fi
	done
}

#######################################
#	Mete procesos en swap
#	Globales:
#		evento
#		evento_log
#		evento_log_NoEsc
#		proc_color
#		proc_estado
#		proc_id
#		proc_tiempo_llegada
#		swp_proc_id
#		swp_proc_index
#		tiempo
#	Argumentos:
#		Nada
#	Devuelve:
#		Nada
#######################################
function poblarSwap() {
	local -i i
	for (( i=0 ; i<${#proc_id_decenas[@]}; i++ )); do
		if [[ ${proc_tiempo_llegada[$i]} -eq $tiempo ]]; then
			evento+="\e[${proc_color[$i]}m\e[49m${proc_id_decenas[$i]}\e[49m > \e[93mespera\e[49m, "
			evento_log+=("\e[${proc_color[${i}]}m\e[49m ${proc_id_decenas[$i]}\e[49m entra en swap en instante \e[49m$tiempo")
			evento_log_NoEsc+=("\e[49m ${proc_id_decenas[$i]} entra en swap en instante <${tiempo}>")
			swp_proc_id+=("\e[49m ${proc_id_decenas[$i]}")
			swp_proc_index+=("$i")
			((proc_estado[i]|=2))
		fi
	done
}

#######################################
#	Mete procesos en memoria
#	Globales:
#		evento
#		evento_log
#		evento_log_NoEsc
#		mem_paginas
#		mem_paginas_secuencia
#		mem_proc_id
#		mem_proc_index
#		mem_proc_tamano
#		mem_tamano
#		mem_usada
#		mem_usada_abreviacion
#		mem_usada_redondeado
#		modo_silencio
#		proc_color
#		proc_estado
#		proc_tamano
#		swp_proc_id
#		swp_proc_index
#	Argumentos:
#		Nada
#	Devuelve:
#		Nada
#######################################
function poblarMemoria(){
local -i espacio_valido=1 i j index
	local id
	mem_usada=${#mem_paginas[@]} #memoria usada es igual al numero de paginas
	if [[ -n $swp_proc_id ]]; then #si la swap no es nulo lo que pasara a continuacion te sorprendera...
		until [[ ${proc_tamano[${swp_proc_index[0]}]} -gt $((mem_tamano - mem_usada)) ]] || [[ ${#swp_proc_id[@]} -eq 0 ]] || [[ $espacio_valido -eq 0 ]]; do #mientras el tamaño del primer proceso en el swap sea mayor que la memoria libre o el numero de procesos del swap sea cero hacer...
			for ((i=0 ; i<=$((mem_tamano - proc_tamano[swp_proc_index[0]] )) ; i++ )); do #para i=0 hasta mayor que 500 menos el tamaño del primer proceso incrementar
				espacio_valido=1 #define variable local espacio valido igual a 1
				for ((j=0 ; j<proc_tamano[swp_proc_index[0]] ; j++ )); do #por cada tamaño del proceso
					if [[ -z ${mem_paginas[$(($i + $j))]} ]]; then #si la memoria es nula
						espacio_valido=$((espacio_valido * 1)) #entonces es valido
					else
						i=$((i + j)) #sino pasa al siguiente bloque de memoria
						espacio_valido=0
						break
					fi
				done
				if [[ $espacio_valido -eq 1 ]]; then #si el espacio es valido entonces
					index=${swp_proc_index[0]}
					id=${swp_proc_id[0]}
					evento+="\e[${proc_color[index]}m$id\e[0m > \e[92men memoria\e[0m, "
					evento_log+=("\e[${proc_color[index]}m$id\e[0m entra en memoria en instante \e[44m$tiempo\e[0m, despues de esperar \e[44m$((tiempo - proc_tiempo_llegada[swp_proc_index[0]]))\e[0m")
					evento_log_NoEsc+=("$id entra en memoria en instante <${tiempo}>, despues de esperar <$((tiempo - proc_tiempo_llegada[swp_proc_index[0]]))>")
					mem_proc_id+=("$id") #guarda la id
					mem_proc_index+=("$index") #guarda index
					mem_proc_tamano+=("${proc_tamano[index]}") #guarda tamaño
					((proc_estado[swp_proc_index[0]]|=4))
					mem_usada=$((mem_usada + proc_tamano[swp_proc_index[0]])) #y actualiza la memoria usada

					for ((j=0 ; j<proc_tamano[swp_proc_index[0]] ; j++ )); do #por cada tamaño del proceso
						mem_paginas[$((i + j))]=$index #guarda la index de cada proceso de memoria en el espacio correspondiente
						mem_paginas_secuencia[$((i + j))]=-1
					done

					actualizarPosiciones
					unset swp_proc_id[0] #saca el proceso del swap
					unset swp_proc_index[0]
					swp_proc_id=("${swp_proc_id[@]}") #limpia espacios vacios de la lista
					swp_proc_index=("${swp_proc_index[@]}")
					break
				fi
			done
		done
	fi
	if [[ -n $swp_proc_id ]] && [[ ${proc_tamano[${swp_proc_index[0]}]} -le $((mem_tamano - mem_usada)) ]]; then
		desfragmentarMemoria
		poblarMemoria
	fi
	if [[ -z $modo_silencio ]]; then
		unset mem_usada_redondeado
		notacionCientifica $mem_usada "mem_usada_redondeado" "mem_usada_abreviacion"
	fi 

}

#######################################
#	Saca procesos de memoria
#	Globales:
#		evento
#		evento_log
#		evento_log_NoEsc
#		mem_paginas
#		mem_proc_id
#		mem_proc_index
#		mem_proc_tamano
#		mem_tamano
#		mem_usada
#		mem_usada_abreviacion
#		mem_usada_redondeado
#		modo_silencio
#		proc_color
#		proc_estado
#		proc_posicion
#		proc_tiempo_ejecucion
#		proc_tiempo_espera
#		proc_tiempo_salida
#	Argumentos:
#		Indice de proceso
#		Indice de memoria
#	Devuelve:
#		Nada
#######################################
function eliminarMemoria() {
	local -ri index_objetivo=$1 index_mem_objetivo=$2
	local -i i
	for (( i=0 ; i<mem_tamano ; i++ )); do
		if [[ -n ${mem_paginas[$i]} ]] && [[ ${mem_proc_index[$index_mem_objetivo]} -eq ${mem_paginas[$i]} ]]; then #si la id del proceso es igual a la id del que buscasa entonces...
			unset mem_paginas[$i] #saca procesos de la memoria si
		fi
	done
	i=0
	for index in ${mem_proc_index[@]}; do #por cada indice en memoria hacer...
		if [[ $index_objetivo -eq $index ]]; then #si lo encuentras entonces...
			evento+="\e[${proc_color[${mem_proc_index[$i]}]}m${mem_proc_id[$i]}\e[0m > \e[96mfinaliza\e[0m, "
			proc_tiempo_salida[$index]=$tiempo
			((proc_estado[index]|=16))
			evento_log+=("\e[${proc_color[${index}]}m${mem_proc_id[$i]}\e[0m termina en instante \e[44m$tiempo\e[0m, con tiempo de espera \e[44m${proc_tiempo_espera[$index]}\e[0m y tiempo de ejecución \e[44m${proc_tiempo_ejecucion[${index}]}#$index")
			evento_log_NoEsc+=("${mem_proc_id[$i]} termina en instante <${tiempo}>, con tiempo de espera <${proc_tiempo_espera[$index]}> y tiempo de ejecución <${proc_tiempo_ejecucion[${index}]}>#$index")
			unset mem_proc_index[$i] #saca el indice de memoria
			unset mem_proc_id[$i] #saca el id de memoria
			for pos in ${proc_posicion[$index]}; do #por cada posicion del proceso hacer...
				unset mem_paginas_secuencia[$pos] #saca las paginas
			done
			unset proc_posicion[$index]
			unset mem_proc_tamano[$i] #saca el proceso de tamaño de la memoria
			mem_proc_index=( "${mem_proc_index[@]}" ) #desfragmenta la lista
			mem_proc_id=( "${mem_proc_id[@]}" )
			mem_proc_tamano=( "${mem_proc_tamano[@]}" )
		fi
		((i++))
	done
	if [[ -z $modo_silencio ]]; then
		mem_usada=${#mem_paginas[@]}
		unset mem_usada_redondeado
		notacionCientifica $mem_usada "mem_usada_redondeado" "mem_usada_abreviacion"
	fi
	if [[ ! ${#swp_proc_id[@]} -eq 0 ]]; then poblarMemoria; fi
}

#######################################
#	Agrupa procesos en memoria
#	Globales:
#		evento
#		mem_paginas
#		mem_paginas_secuencia
#		mem_tamano
#		mem_usada
#	Argumentos:
#		Nada
#	Devuelve:
#		Nada
#######################################
function desfragmentarMemoria() {
	local -i i j
	until [[ $((pivot_final + 1)) -eq $mem_usada ]]; do
		local -i pivot=-1 pivot_final=0 count=0
		for ((i=(mem_tamano - 1) ; i>=0 ; i-- )); do
			if [[ -z ${mem_paginas[$i]} ]]; then
				if [[ $pivot -gt 0 ]]; then ((count++)); fi
			else
				if [[ $pivot -lt 0 ]]; then pivot_final=$i; fi
				pivot=$i
			fi
		done
		if [[ ! $((pivot_final + 1)) -eq $mem_usada ]]; then
			for ((j=0 ; j<=count ; j++ )); do # por cada hueco hace...
				for ((i=0 ; i<=pivot_final ; i++ )); do #por cada proceso comprueba si hay un hueco a la izquierda
					if [[ -z ${mem_paginas[$i]} ]] && [[ -n ${mem_paginas[$((i + 1))]} ]]; then #si hay hueco se mueve
						mem_paginas[$i]=${mem_paginas[$((i + 1))]}
						mem_paginas_secuencia[$i]=${mem_paginas_secuencia[$((i + 1))]}
						unset mem_paginas[$((i + 1))]
						unset mem_paginas_secuencia[$((i + 1))]
					fi
				done
			done
		fi
	done
	actualizarPosiciones
	evento+="\e[94mDESFRAGMENTACIÓN\e[0m, "
}

#######################################
#	Ejecuta un proceso en CPU
#	Globales:
#		linea_tiempo
#		mem_proc_index
#		proc_tiempo_ejecucion
#		proc_tiempo_ejecucion_restante
#		proc_tiempo_espera
#		proc_tiempo_respuesta
#	Argumentos:
#		Nada
#	Devuelve:
#		Nada
#######################################
function ejecucion() {
	local -i i
	for index in ${mem_proc_index[@]}; do
		((++proc_tiempo_respuesta[index]))
		if (((proc_estado[index]&8)==8)); then
			((--proc_tiempo_ejecucion_restante[index]))
			((++proc_tiempo_ejecucion[index]))
			linea_tiempo[$tiempo]=$index
			actualizarPaginas $index
			if [[ ${proc_tiempo_ejecucion_restante[$index]} -eq 0 ]]; then
				eliminarMemoria $index $i
			fi
		else
			((++proc_tiempo_espera[index]))
		fi
		((i++))
	done
	for index in ${swp_proc_index[@]}; do
		((++proc_tiempo_espera[index]))
		((++proc_tiempo_respuesta[index]))
	done
}

#######################################
#	Prioridad Mayor/menor de procesos en memoria
#	Globales:
#		mem_proc_index
#		mem_siguiente_ejecucion
#		proc_estado
#		proc_tiempo_ejecucion
#		proc_tiempo_ejecucion_restante
#	Argumentos:
#		Nada
#	Devuelve:
#		Nada
#######################################

function calcularEjecucion() {
	
	local -i min=${proc_tiempo_ejecucion_restante[${mem_proc_index[0]}]} min_index=${mem_proc_index[0]}
	local -i Mm=${proc_priori[0]}

	for index in ${mem_proc_index[@]}; do 

		if [[ $priReal = M ]]; then
			
			if [[ ${proc_priori[index]} -gt $Mm ]]; then

				min_index=$index
				Mm=${proc_priori[index]}
			fi
		fi

		if [[ $priReal = m ]]; then
			if [[ ${proc_priori[index]} -lt $Mm ]];then

				min_index=$index
				Mm=${proc_priori[index]}
			fi
		fi
			((proc_estado[index]&=~8))

	done
		((proc_estado[min_index]|=8))
	
}
#######################################
#	Ordena los proc. por orden de llegada
#	Globales:
#		proc_orden|=
#		proc_tiempo_llegada
#	Argumentos:
#		Nada
#	Devuelve:
#		Nada
#######################################
function ordenarProcesos() {
	local -i i j min_index=0 min=${proc_tiempo_llegada[0]}
	local -a procesos_pendientes
	procesos_pendientes=("${proc_tiempo_llegada[@]}")
	for ((i=0; i<proc_count; i++)); do
		for ((j=0; j<${#procesos_pendientes[@]}; j++)); do
			if [[ ${procesos_pendientes[j]} -lt $min && ${procesos_pendientes[j]} -ge 0 ]] || [[ $min -eq -1 ]]; then
				min=${procesos_pendientes[j]}
				min_index=$j
			fi
		done
		proc_orden[$i]=$min_index
		procesos_pendientes[$min_index]=-1
		min=-1
	done
}

#?######################################
#	Realiza sustitución de páginas
#	Globales:
#		mem_paginas_secuencia
#		proc_tamano
#		proc_posicion
#		proc_paginas_apuntador
#		proc_paginas_fallos
#		proc_paginas
#	Argumentos:
#		Index de proceso
#	Devuelve:
#		Nada
#?######################################
function actualizarPaginas() {
	local -ri index=$1
	local -i fallo i=0 apuntador
	local -a paginas=()
	local posicion posicion_previa

	IFS=',' read -r -a paginas <<< "${proc_paginas[index]}"

	local -r objetivo=${paginas[$((proc_tiempo_ejecucion[index]-1))]}

	for posicion in ${proc_posicion[index]}; do
		if [[ ${mem_paginas_secuencia[posicion]} -eq $objetivo ]]; then fallo=$i; fi
		((++i))
	done

	if [[ -z $fallo ]]; then
		apuntador=${proc_paginas_apuntador[index]}
		mem_paginas_secuencia[$(( $(echo ${proc_posicion[index]} | cut -d ' ' -f1) + apuntador ))]=$objetivo
		for ((i=0; i<proc_tamano[index]; i++)); do
			posicion="$index,$((proc_tiempo_ejecucion[index]-1)),$i"
			posicion_previa="$index,$((proc_tiempo_ejecucion[index]-2)),$i"
			if [[ ${proc_paginas_evolucion["$posicion_previa"]} -ne -1 ]] && [[ $i -lt ${proc_tiempo_ejecucion[index]} ]]; then
				proc_paginas_evolucion["$posicion"]=${proc_paginas_evolucion[$posicion_previa]}
				else
				proc_paginas_evolucion["$posicion"]=-1
			fi
		done
		posicion="${index},$((proc_tiempo_ejecucion[index]-1)),$apuntador"
		proc_paginas_evolucion["$posicion"]=$objetivo
		posicion="${index},$((proc_tiempo_ejecucion[index]-1)),p"
		proc_paginas_evolucion["$posicion"]=$apuntador
		proc_paginas_apuntador[index]=$((++proc_paginas_apuntador[index]%proc_tamano[index]))
		((++proc_paginas_fallos[index]))
	else
		for ((i=0; i<proc_tamano[index]; i++)); do
			posicion="$index,$((proc_tiempo_ejecucion[index]-1)),$i"
			posicion_previa="$index,$((proc_tiempo_ejecucion[index]-2)),$i"
			proc_paginas_evolucion["$posicion"]=${proc_paginas_evolucion[$posicion_previa]}
			posicion="${index},$((proc_tiempo_ejecucion[index]-1)),p"
			proc_paginas_evolucion["$posicion"]=$((-fallo-1))
		done
	fi
}

#######################################
#	Muestra evolución de paginas de proceso
#	Globales:
#		proc_paginas_evolucion
#		proc_tamano
#		proc_tiempo_ejecucion
#	Argumentos:
#		Index de proceso
#	Devuelve:
#		Nada
#######################################
function evolucionPaginas() {
	local -ri index=$1
	local -i i j fallo=0 apuntador
	local linea linea_no_esc linea_buffer posicion pagina
	for ((i=0; i< ${proc_tamano[index]}; i++)); do
		linea+='_____'
		linea_no_esc+='_____'
	done
	linea+='_'; linea_no_esc+='_'
	log 3 "$linea" "$linea_no_esc"
	for ((i=0; i< ${proc_tiempo_ejecucion[index]}; i++)); do
		linea=;linea_no_esc=;fallo=0
		posicion="${index},${i},p"
		apuntador=${proc_paginas_evolucion["$posicion"]}
		for ((j=0; j< ${proc_tamano[index]}; j++)); do
			posicion="${index},${i},${j}"
			pagina=${proc_paginas_evolucion["$posicion"]}
			if [[ $pagina -ne -1 ]]; then
				linea_buffer="$(printf "%2d " "$pagina")"
				if [[ $j -eq $apuntador ]]; then
					linea+="| \e[7;${proc_color[index]}m$linea_buffer\e[0m"
					linea_no_esc+="|>$linea_buffer"
				else
					if [[ $apuntador -lt 0 ]] && [[ $j -eq $((-apuntador-1)) ]]; then
						linea+="| \e[${proc_color[index]}m$linea_buffer\e[0m"
						linea_no_esc+="|-$linea_buffer"
					else
						linea+="| $linea_buffer"
						linea_no_esc+="| $linea_buffer"
					fi
				fi
				fallo=1
			else
				linea+='|    '
				linea_no_esc+='|    '
			fi
		done
		linea+='|'; linea_no_esc+='|'
		log 3 "$linea" "$linea_no_esc"
	done
	linea=;linea_no_esc=
	for ((i=0; i< ${proc_tamano[index]}; i++)); do
		linea+='¯¯¯¯¯'
		linea_no_esc+='¯¯¯¯¯'
	done
	linea+='¯'; linea_no_esc+='¯'
	log 3 "$linea" "$linea_no_esc"
}

#######################################
#	Localiza cada proceso en memoria
#	Globales:
#		mem_paginas
#		mem_proc_index
#		mem_tamano
#		proc_posicion
#	Argumentos:
#		Nada
#	Devuelve:
#		Nada
#######################################
function actualizarPosiciones() {
	echo "Actualizando posiciones"

	local -i p i
	local -a posiciones=()
	local -i inx=${mem_proc_index[p]}

	for ((p=0; p<${#mem_proc_index[@]}; p++ )) ; do
		
		for ((i=0; i<mem_tamano; i++ )); do
			if [[ ${mem_paginas[i]} -eq $inx ]] && [[ -n ${mem_paginas[i]} ]]; then
				posiciones+=("$i")
			fi
		done
		proc_posicion[$inx]=${posiciones[@]}
	done
}

#######################################
#	Calcula última llegada de proceso
#	Globales:
#		proc_tiempo_llegada
#	Argumentos:
#		Nada
#	Devuelve:
#		Último tiempo
#######################################
function ultimoTiempo() {
	local -i tiempo_max=0
	for t in "${proc_tiempo_llegada[@]}"; do
		if [[ $t -gt $tiempo_max ]]; then tiempo_max=$t; fi #coge el tiempo de llegada maximo de todos los tiempos
	done
	echo $tiempo_max
}

#######################################
#	Calcula última llegada de proceso
#	Globales:
#		date
#		linea_tiempo
#		proc_color
#		proc_id
#		proc_paginas_fallos
#		proc_tiempo_ejecucion
#		proc_tiempo_espera
#		proc_tiempo_espera
#		proc_tiempo_llegada
#		proc_tiempo_respuesta
#		proc_tiempo_salida
#		SECONDS
#		tiempo
#	Argumentos:
#		Código de error
#	Devuelve:
#		Nada
#######################################
function finalizarEjecucion() {
	local -ri error=$1
	local -i i j espera_total=0 respuesta_total=0 fallos_total=0 ultimo_cambio buffer_1=0 buffer_2=0
	local id linea linea_no_esc linea_buffer
	if [[ $error -eq 0 ]]; then
		salidaEjecucion
		pantalla
		log 5
		linea="$(printf "%7s%s%8s-  %s  -  %s  -  %s  -  %s  -  %s" " " "ID" " " "	LLEGADA" "	SALIDA" "	ESPERA" "	REPUESTA" "	FALLOS")"
		log 5 "$linea" '@'
		pantalla "$linea"
		for ((i=0; i<proc_count; i++)); do
			id=${proc_id[i]:0:15}
			linea="$(printf "\e[%sm \e[49m       ${proc_id_decenas[i]}	-	%d	-	%d	-	%d	-	%d	-	%d" "${proc_color[i]}"  "${proc_tiempo_llegada[i]}" "${proc_tiempo_salida[i]}" "${proc_tiempo_espera[i]}" "${proc_tiempo_respuesta[i]}" "${proc_paginas_fallos[i]}")"

			linea_no_esc="$(printf "\e[49m ${proc_id_decenas[i]} - %5d     -  %5d   -  %5d   -   %5d    - %5d"  "${proc_tiempo_llegada[i]}" "${proc_tiempo_salida[i]}" "${proc_tiempo_espera[i]}" "${proc_tiempo_respuesta[i]}" "${proc_paginas_fallos[i]}")"
			log 5 "$linea" "$linea_no_esc"
			pantalla "$linea"
			espera_total+=${proc_tiempo_espera[i]}
			respuesta_total+=${proc_tiempo_respuesta[i]}
			fallos_total+=${proc_paginas_fallos[i]}
		done
		linea=;linea_no_esc=
		pantalla
		log 5

		for ((j=0; j< (tiempo+39)/40; j++)); do
			ultimo_cambio=$buffer_1
			for ((i=j*40; i<=j*40+40 && i<tiempo; i++)); do
				if [[ $i -ge 0 ]] && [[ ${linea_tiempo[i]} -ne -1 ]]; then
					if [[ $i -gt 0 ]] && [[ ${linea_tiempo[i]} -eq ${linea_tiempo[((i-1))]} ]]; then
						((++ultimo_cambio))
					else
						ultimo_cambio=0
					fi
					if [[ $ultimo_cambio -eq 0 ]]; then
						linea+="\e[${proc_color[linea_tiempo[i]]}m| "; linea_no_esc+='| '
					elif [[ $((ultimo_cambio * 2 -2)) -lt ${#proc_id[linea_tiempo[i]]} ]]; then
						id=$(echo ${proc_id[linea_tiempo[i]]} | cut -c $(($ultimo_cambio * 2 - 1))-)
						linea+="$(printf "%-2s" "${id:0:2}")"; linea_no_esc+="$(printf "%-2s" "${id:0:2}")"
					else
						linea+='\e[0m  '; linea_no_esc+='  '
					fi
				else
					linea+='\e[0m  '; linea_no_esc+='  '
				fi
			done
			log 3 "$linea" "$linea_no_esc"; linea=''; linea_no_esc=''
			buffer_1=$ultimo_cambio

			for ((i=j*40; i<=j*40+40 && i<tiempo; i++)); do
				if [[ $i -ge 0 ]] && [[ ${linea_tiempo[i]} -ne -1 ]]; then
					linea+="\e[${proc_color[${linea_tiempo[$i]}]}m=="; linea_no_esc+='=='
				else
					linea+='\e[49;38;5;237m--'; linea_no_esc+='--'
				fi
			done
			log 3 "$linea" "$linea_no_esc"; linea=''; linea_no_esc=''

			ultimo_cambio=$buffer_2
			for ((i=j*40; i<=j*40+40 && i<tiempo; i++)); do
				if [[ $i -ge 0 ]] && [[ ${linea_tiempo[i]} -ne -1 ]]; then
					if [[ $i -gt 0 ]] && [[ ${linea_tiempo[i]} -eq ${linea_tiempo[((i-1))]} ]]; then
						((++ultimo_cambio))
					else
						ultimo_cambio=0
					fi
					if [[ $ultimo_cambio -eq 0 ]]; then
						linea+="\e[${proc_color[linea_tiempo[i]]}m| "; linea_no_esc+='| '
					elif [[ $((ultimo_cambio * 2 -2)) -lt ${#i} ]]; then
						id=$(echo $((i-1)) | cut -c $(($ultimo_cambio * 2 - 1))-)
						linea+="$(printf "%-2s" "${id:0:2}")"; linea_no_esc+="$(printf "%-2s" "${id:0:2}")"
					else
						linea+='\e[0m  '; linea_no_esc+='  '
					fi
				else
					linea+='  '; linea_no_esc+='  '
				fi
			done
			log 3 "$linea" "$linea_no_esc"; linea=''; linea_no_esc=''
			buffer_2=$ultimo_cambio
			log 3
		done

		linea_buffer="$((espera_total / proc_count)).$(( (espera_total * 1000 ) / proc_count % 1000))"
		linea="Tiempo de espera medio: \e[44m$linea_buffer"
		linea_no_esc="Tiempo de espera medio: <$linea_buffer>"
		pantalla "$linea"; log 5 "$linea" "$linea_no_esc"

		linea_buffer="$((respuesta_total / proc_count)).$(( (respuesta_total * 1000 ) / proc_count % 1000))"
		linea="Tiempo de respuesta medio: \e[44m$linea_buffer"
		linea_no_esc="Tiempo de respuesta medio: <$linea_buffer>"
		pantalla "$linea"; log 5 "$linea" "$linea_no_esc"

		linea_buffer="$((fallos_total / proc_count)).$(( (fallos_total * 1000 ) / proc_count % 1000))"
		linea="Número de fallos medio: \e[44m$linea_buffer"
		linea_no_esc="Número de fallos medio: <$linea_buffer>"
		pantalla "$linea"; log 5 "$linea" "$linea_no_esc"

		log 5
		log 0 "TIEMPO DE EJECUCIÓN: \e[44m${SECONDS}s" "TIEMPO DE EJECUCIÓN: <${SECONDS}s>"
		log 5 "ÚLTIMO TIEMPO: \e[44m$tiempo" "ÚLTIMO TIEMPO: <$tiempo>"
		pantalla "\nFINAL DE EJECUCIÓN - ÚLTIMO TIEMPO: \e[44m$tiempo\e[0m"
		log 9 "FINAL DE EJECUCIÓN CON FECHA \e[44m$(date)\e[49m" "FINAL DE EJECUCIÓN CON FECHA <$(date)>"
	else
		pantalla "\e[91m!!!\e[39m EXCEPCIÓN \e[91m${error}\e[39m \e[91m!!!\e[39m"
		log 9 "\e[91m!!!\e[39m EXCEPCIÓN \e[91m${error}\e[39m CON FECHA \e[44m$(date)\e[49m \e[91m!!!\e[39m" "!!! EXCEPCIÓN <${error}> CON FECHA <$(date)> !!!"
	fi
	header 0 2
	exit $error
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
		if [[ -n $mensaje ]]; then
			echo -e "[$(colorLog $nivel)${nivel}\e[39m] > ${mensaje}\e[0m" >> salida.txt
		else
			echo >> salida.txt
		fi
		if [[ -n $mensaje_noesc ]]; then
			if [[ $mensaje_noesc == '@' ]]; then
				echo "[${nivel}] > ${mensaje}" >> salidaNoEsc.txt
			else
				echo "[${nivel}] > ${mensaje_noesc}" >> salidaNoEsc.txt
			fi
		else
			echo >> salidaNoEsc.txt
		fi
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
		echo -e "\e[0m$mensaje\e[0m"
	fi
}

#######################################
#	Escribe datos en el archivo de salida
#	Globales:
#		mem_tamano
#		proc_color
#		proc_count
#		proc_id
#		proc_pagina_tamano
#		proc_paginas
#		proc_tamano
#		proc_tiempo_llegada
#	Argumentos:
#		Nada
#	Devuelve:
#		Nada
#######################################
function salidaDatos() {
	local -i i
	local colores=$(for color in ${proc_color[@]}; do echo -n "$(echo $color | cut -d ';' -f6),$(echo $color | cut -d ';' -f3) ; "; done)
	rm salidaEntrada.txt;
	
	echo "+DIRECCIONES_TOTALES: $dir_tot" >> salidaEntrada.txt
	echo "+DIRECCIONES: $proc_pagina_tamano" >> salidaEntrada.txt
	echo "+VALOR_MENOR: $ValorMenor" >> salidaEntrada.txt
	echo "+VALOR_MAYOR: $ValorMayor" >> salidaEntrada.txt
	echo "+PRIORIDAD: $prioridad" >> salidaEntrada.txt
	echo "+COLORES: ${colores::-2}" >> salidaEntrada.txt
	for ((i=0; i<proc_count; i++)); do
		echo "${proc_priori[i]};${proc_tamano[i]} ; ${proc_direcciones[i]} ; ${proc_tiempo_llegada[i]} " >> salidaEntrada.txt
	done
}

#######################################
#	Selecciona color del nivel de log
#	Globales:
#		Nada
#	Argumentos:
#		Nível
#	Devuelve:
#		Color
#######################################
function colorLog() {
	local -ri nivel=$1
	case $nivel in
		1) echo -e "\e[35m";;
		2) echo -e "\e[34m";;
		3) echo -e "\e[36m";;
		4) echo -e "\e[91m";;
		5) echo -e "\e[33m";;
		9) echo -e "\e[32m";;
		*) echo -e "\e[39m";;
	esac
}

#######################################
#	Escribe cabecera de fichero
#	Globales:
#		nivel_log
#	Argumentos:
#		Nada
#	Devuelve:
#		Nada
#######################################
function cabeceraLog() {
	if [[ $nivel_log -le 1 ]]; then
		log 1 'LICENCIA DE USO:' '@'
		header 0 2
		log 1 "\e[38;5;17m#\e[39m$(printf "%98s" " ")\e[38;5;17m#\e[39m" "#$(printf "%98s" " ")#"
		log 1 "\e[38;5;17m#\e[39m                                           MIT License                                            \e[38;5;17m#\e[39m" "#                                           MIT License                                            #"
		log 1 "\e[38;5;17m#\e[39m                          Copyright (c) 2017 Diego González, Rodrigo Díaz                         \e[38;5;17m#\e[39m" "#                          Copyright (c) 2017 Diego González, Rodrigo Díaz                         #"
		log 1 "\e[38;5;17m#\e[39m                      ――――――――――――――――――――――――――――――――――――――――――――――――――――――                      \e[38;5;17m#\e[39m" "#                      ――――――――――――――――――――――――――――――――――――――――――――――――――――――                      #"
		log 1 "\e[38;5;17m#\e[39m                   You may:                                                                       \e[38;5;17m#\e[39m" "#                   You may:                                                                       #"
		log 1 "\e[38;5;17m#\e[39m                     - Use the work commercially                                                  \e[38;5;17m#\e[39m" "#                     - Use the work commercially                                                  #"
		log 1 "\e[38;5;17m#\e[39m                     - Make changes to the work                                                   \e[38;5;17m#\e[39m" "#                     - Make changes to the work                                                   #"
		log 1 "\e[38;5;17m#\e[39m                     - Distribute the compiled code and/or source.                                \e[38;5;17m#\e[39m" "#                     - Distribute the compiled code and/or source.                                #"
		log 1 "\e[38;5;17m#\e[39m                     - Incorporate the work into something that                                   \e[38;5;17m#\e[39m" "#                     - Incorporate the work into something that                                   #"
		log 1 "\e[38;5;17m#\e[39m                       has a more restrictive license.                                            \e[38;5;17m#\e[39m" "#                       has a more restrictive license.                                            #"
		log 1 "\e[38;5;17m#\e[39m                     - Use the work for private use                                               \e[38;5;17m#\e[39m" "#                     - Use the work for private use                                               #"
		log 1 "\e[38;5;17m#\e[39m$(printf "%98s" " ")\e[38;5;17m#\e[39m" "#$(printf "%98s" " ")#"
		log 1 "\e[38;5;17m#\e[39m                   You must:                                                                      \e[38;5;17m#\e[39m" "#                   You must:                                                                      #"
		log 1 "\e[38;5;17m#\e[39m                     - Include the copyright notice in all                                        \e[38;5;17m#\e[39m" "#                     - Include the copyright notice in all                                        #"
		log 1 "\e[38;5;17m#\e[39m                       copies or substantial uses of the work                                     \e[38;5;17m#\e[39m" "#                       copies or substantial uses of the work                                     #"
		log 1 "\e[38;5;17m#\e[39m                     - Include the license notice in all copies                                   \e[38;5;17m#\e[39m" "#                     - Include the license notice in all copies                                   #"
		log 1 "\e[38;5;17m#\e[39m                       or substantial uses of the work                                            \e[38;5;17m#\e[39m" "#                       or substantial uses of the work                                            #"
		log 1 "\e[38;5;17m#\e[39m$(printf "%98s" " ")\e[38;5;17m#\e[39m" "#$(printf "%98s" " ")#"
		log 1 "\e[38;5;17m#\e[39m                   You cannot:                                                                    \e[38;5;17m#\e[39m" "#                   You cannot:                                                                    #"
		log 1 "\e[38;5;17m#\e[39m                     - Hold the author liable. The work is                                        \e[38;5;17m#\e[39m" "#                     - Hold the author liable. The work is                                        #"
		log 1 "\e[38;5;17m#\e[39m                       provided \"as is\".                                                          \e[38;5;17m#\e[39m" "#                       provided \"as is\".                                                          #"
		log 1 "\e[38;5;17m#\e[39m$(printf "%98s" " ")\e[38;5;17m#\e[39m" "#$(printf "%98s" " ")#"
		header 0 2
		log 1
	fi
	if [[ $nivel_log -le 3 ]]; then
		log 1 'CABECERA DEL PROGRAMA:' '@'
		header 0 2
		log 3 "\e[38;5;17m#\e[39m$(printf "%98s" " ")\e[38;5;17m#\e[39m" "#$(printf "%98s" " ")#"
		log 3 "\e[38;5;17m#\e[39m                             \e[48;5;17mSRPT, Paginación, FIFO, Memoria Continua,\e[0m                            \e[38;5;17m#" "#                             SRPT, Paginación, FIFO, Memoria Continua,                            #"
		log 3 "\e[38;5;17m#\e[39m                            \e[48;5;17mFijas e iguales, Primer ajuste y Reubicable\e[0m                           \e[38;5;17m#" "#                            Fijas e iguales, Primer ajuste y Reubicable                           #"
		log 3 "\e[38;5;17m#\e[38;5;20m                      ――――――――――――――――――――――――――――――――――――――――――――――――――――――                      \e[38;5;17m#" "#                      ――――――――――――――――――――――――――――――――――――――――――――――――――――――                      #"
		log 3 "\e[38;5;17m#\e[96m                     Alumnos:                                                                     \e[38;5;17m#" "#                     Alumnos:                                                                     #"
		log 3 "\e[38;5;17m#\e[96m                       - González Román, Diego                                                    \e[38;5;17m#" "#                       - González Román, Diego                                                    #"
		log 3 "\e[38;5;17m#\e[96m                       - Díaz García, Rodrigo                                                     \e[38;5;17m#" "#                       - Díaz García, Rodrigo                                                     #"
		log 3 "\e[38;5;17m#\e[96m                     Sistemas Operativos, Universidad de Burgos                                   \e[38;5;17m#" "#                     Sistemas Operativos, Universidad de Burgos                                   #"
		log 3 "\e[38;5;17m#\e[96m                     Grado en ingeniería informática (2016-2017)                                  \e[38;5;17m#" "#                     Grado en ingeniería informática (2016-2017)                                  #"
		log 3 "\e[38;5;17m#\e[39m$(printf "%98s" " ")\e[38;5;17m#\e[39m" "#$(printf "%98s" " ")#"
		header 0 2
		log 3
	fi
}

#_____________________________________________
# FINAL DE FUNCIONES
#
# COMIENZO DE PROGRAMA PRINCIPAL
#_____________________________________________

SECONDS=0
declare -a proc_id proc_estado proc_tamano proc_paginas proc_direcciones proc_tiempo_llegada proc_tiempo_salida proc_tiempo_ejecucion proc_tiempo_ejecucion_restante proc_tiempo_espera proc_tiempo_respuesta proc_posicion proc_paginas_apuntador proc_paginas_fallos proc_orden mem_paginas mem_proc_id mem_proc_index mem_proc_tamano swp_proc_id swp_proc_index out_proc_index proc_color_secuencia linea_tiempo
declare -A proc_paginas_evolucion
declare -i proc_count mem_tamano mem_usada tiempo mem_tamano_redondeado mem_usada_redondeado proc_count_redondeado nivel_log=3
declare mem_tamano_abreviacion mem_usada_abreviacion proc_count_abreviacion evento evento_log evento_log_NoEsc filename

log 9
log 9 "EJECUCIÓN DE \e[44m${0}\e[49m EN \e[44m$(hostname)\e[49m CON FECHA \e[44m$(date)\e[49m" "EJECUCIÓN DE <${0}> EN <$(hostname)> CON FECHA <$(date)>"
log 9

if [[ $# -gt 0 ]]; then
	log 5 'Argumentos introducidos, obteniendo información:' '@'
	leerArgs "$@"
fi

cabeceraLog
header 1 1; header 0 1
echo "Nota: El siguiente algoritmo es prioridad mayor/menor y se implementa como apropiativo"
if [[ -z $filename ]]; then #si no hay argumento de archivo entonces...
	log 5 'No Argumento filename, comprobando modo de introduccion de datos:' '@'
	read -p 'Introducción de datos por archivo (s/n): ' -n 1 -r ; echo
	log 0 "RESPUESTA INPUT: \e[34m$REPLY\e[39m" "RESPUESTA INPUT: <$REPLY>"
	if [[ $REPLY =~ ^[SsYy]$ ]]; then #si la respuesta es S
		read -p 'Nombre del archivo: ' filename
		log 5 "Por archivo \e[34m${filename}\e[39m" "Por archivo <${filename}>"
		leerArchivo
	else log 5 'Por teclado' '@';	fi
fi

pedirDatos

for(( k=0;k<=${proc_count};k++)); do
	sacarPaginas[$k]=0; # indica el numero de paginas que se deben sacar inicialmente

done

for(( k=0;k<=${proc_count};k++)); do
	numPaginas[$k]=0; # indica el numero de paginas pintadas en la linea de tiempos de cada proceso 
done

salidaDatos
ordenarProcesos

notacionCientifica $mem_tamano "mem_tamano_redondeado" "mem_tamano_abreviacion"
notacionCientifica "$mem_usada" "mem_usada_redondeado" "mem_usada_abreviacion"
notacionCientifica $proc_count "proc_count_redondeado" "proc_count_abreviacion"

while true ; do step ; done
