#!/bin/bash
#Autores: Santiago Jimenez (780960) y Fernando Gomez ()

#Comprobacion de privilegios de administracion
if [ $UID -ne 0 ]; then
	echo "Este script necesita privilegios de administracion"
	exit 1
fi

op=$1 #Guardo la opcion en una variable para que sea mas legible
#Comprobacion de opcion correcta
if [ $op != "-a" ] && [ $op != "-s" ]; then
	echo "Opcion invalida" >&2
	exit 1
fi

#Comprobacion del numero de parametros
if [ $# -ne 2 ]; then
	echo "Numero incorrecto de parametros"
	exit 1
fi

#Si vamos a borrar, creamos la carpeta destino de los directorios home
if [ $op = "-s" ]; then
	mkdir -p /extra/backup
fi

input_file=$2
n=150

while read line
do
	echo "$n He leido "${line}""
	let "n+=1"

	usr=$(echo "${line}" | cut -d ',' -f1)
	pass=$(echo "${line}" | cut -d ',' -f2)
	complete_name=$(echo "${line}" | cut -d ',' -f3)
	echo "User: ${usr}, password: ${pass}, nomcomp: ${complete_name}."
	
	if [ -z $complete_name ]; then
		echo "wat"
	fi
	
	#Comprobacion si se desea anyadir
	if [ $op = "-a" ]; then
		#Comprobacion de que todos los campos son no vacios
		if [ -z $usr ] || [ -z $pass ] || [ -z $complete_name ]; then
			echo "Campo invalido"
			exit 1
		fi

		#Comprobamos si el usuario existe
		exists=$(grep -c "^${usr}:" /etc/passwd)

		#Si existe, no se hace nada
		if [ $exists -ne 0 ]; then 
			echo "El usuario "${usr}" ya existe"
		
		#Si no existe, hay que anyadirlo
		else

			#Anyadimos al nuevo usuario al grupo
			#Comprobamos si el grupo existe. Sino, lo creamos
			if ! grep -q "^${usr}:" /etc/group ; then
				#echo "No existe un grupo con ese nombre, lo creo"
				groupadd "${usr}"
			fi
	
			#Creamos el usuario con las especificaciones pedidas
			useradd -f 30 -g "$usr" -K UID_MIN=1815 -m -k /etc/skel $usr

			
			#Le cambiamos la contrasenya al usuario
			input="$usr"
			input+=":"
			input+="$pass"
			echo $input | chpasswd

			echo ""${complete_name}" ha sido creado"

		fi		

	else #Si no se desea anyadir, se deseara suprimir
		
		#Comprobamos que al menos, el primer parametro tiene valor
		if [ -z $usr ]; then
			exit 1
		fi	

		#Comprobamos si el usuario a borrar existe
		exists=$(grep -c "^"${usr}":" /etc/passwd)
		#Si el usuario existe, seguimos con el borrado. Sino, no hacemos nada
		if [ $exists -eq 1 ]; then
			#Comprimimos el home
			tar -cvf ${usr}.tar /home/$usr
			ex1=$?
			cp ${usr}.tar /extra/backup
			ex2=$?
			
			#Solo continuaremos si se ha hecho el backup bien
			if [ $ex1 -eq 0 ] && [ $ex2 -eq 0 ]; then
				rm ${usr}.tar #borramos el .tar temporal
				rm -r /home/$usr
			fi

		fi

	fi

done < "$input_file"
 
