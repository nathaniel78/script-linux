#!/bin/bash
### SCRIPT PARA MONITORAMENTO DE DISPONIBILIDADE DE INTERNET E AJUSTE DO BIND ###

#---------------------------------------------------------------------------------
# AUTOR: NATHANIEL J. FURTADO
# DATA: 23/05/2022
# DESCRIÇÃO: SCRIPT PARA MONITORAMENTO DE DOIS LINKS E ATUALIZAR ARQUIVO ZONE.
# --------------------------------------------------------------------------------

# DATA ATUAL
DATA_ATUAL=`date +%Y%m%d`

# DATA PERSONALIZADA
DATA_PERS=`date +%Y%m%d%H%M%S`

# CAMINHO DO ARQUIVO DE DNS DO BIND
CAMINHO_ARQZONE="caminho_do_arquivo_dbzone"

# DIRETORIO DO BACKUP
DIRETORIO_BACKUP="/root/backup_zone/bck_db_zone-$DATA_PERS"

# DIRETORIO DO LOG
DIRETORIO_LOG='/root/log_zone/registro_log' 

# CONTADOR
CONTADOR=0

# TIME
TIME_SLEEP=10

# QUANTIDADE DE PING
QTD_PING=10

# MONITORAMENTO LINK
LINK_MONITORAMENTO="0.0.0.0"

# URL PARA MONITORAMENTO
URL="google.com"

# STATUS LINK
STATUS_LINK="UP"

# VALIDAR DIRETÓRIO BACKUP
if [ ! -d /root/backup_zone ]; then

	echo 'Criando diretório de backup'
	
	mkdir /root/backup_zone
	
fi

# VALIDAR DIRETÓRIO LOG
if [ ! -d /root/log_zone ]; then

	echo 'Criando diretório de log'
	
	mkdir /root/log_zone
	
fi

# LOOP PARA MONITORAR PING
while : ; do

		# CASO O PING NÃO RESPONDA PARA LINK 01, VAI PARA DNS ALTERNATIVO
        if ! ping -c $QTD_PING $LINK_MONITORAMENTO >/dev/null && [ "$STATUS_LINK" = "UP" ]; then
		
			# AVISO
			echo "Trocando de servidor LINK 01 -> LINK 02"
			
			# ALTERANDO STATUS
			STATUS_LINK="DOWN"
			
			# CONTADOR
			CONTADOR=0
			
			# BACKUP
			echo "Será realizado o backup do arquivo db.zone original"
			cp $CAMINHO_ARQZONE $DIRETORIO_BACKUP
			
			# REGISTRANDO LOG
			echo "Serviço RNP INATIVO => $(date +"%x => %X")" >> $DIRETORIO_LOG
			
			# ADICIONA ; COMEÇANDO NA LINHA 40 ATÉ 150 -> LINK 01
			sed -i '40,150s/^/;/g' $CAMINHO_ARQZONE

			# REMOVE ; COMEÇANDO NA LINHA 152 ATÉ 200 -> LINK 02
			sed -i '152,200s/;//g' $CAMINHO_ARQZONE
			
			# CAPTURANDO O SERIAL NO ARQUIVO ZONE
			SERIAL=`sed -n '/Serial/{p;q;}' ${CAMINHO_ARQZONE} | awk '{print $1}'`

			# PEGANDO A DATA INICIAL NO SERIAL
			SERIAL_DATA=`echo $SERIAL | cut -c1-8`

			# NOVO SERIAL
			NOVO_SERIAL="${DATA_ATUAL}01"

			# PEGANDO AS DOIS ULTIMOS CARACTERES
			SERIAL_FINAL=`echo $SERIAL | cut -c9-10`

			# NOVO FINAL SERIAL
			NOVO_FINAL=$(($SERIAL_FINAL+1))

			# INCREMENTANDO SERIAL
			INCREMENTANDO_SERIAL="${DATA_ATUAL}0${NOVO_FINAL}"
			
			# VERIFICANDO SERIAL COM DATA ATUAL			
			if [ $DATA_ATUAL -gt $SERIAL_DATA ]; then
			
				echo 'Gerar um novo serial'
				
				# SUBSTITUINDO SERIAL POR NOVO SERIAL
				sed -i "s/$SERIAL/$NOVO_SERIAL/g" $CAMINHO_ARQZONE
				
				# RESTART DO SERVIÇO BIND
				systemctl restart bind9
				
			else
			
				echo 'Incrementar final do serial'
				
				# SUBSTITUINDO SERIAL POR NOVO SERIAL
				sed -i "s/$SERIAL/$INCREMENTANDO_SERIAL/g" $CAMINHO_ARQZONE
				
				# RESTART DO SERVIÇO BIND
				systemctl restart bind9
				
			fi
		
		# CASO O LINK 01 RESPONDA, VOLTA A CONFIGURAÇÃO DNS ORIGINAL
        elif ping -c $QTD_PING $LINK_MONITORAMENTO >/dev/null && [ "$STATUS_LINK" = "DOWN" ]; then
        
			# AVISO
			echo "Trocando de servidor LINK 02 -> LINK 01"

			# ALTERANDO STATUS
			STATUS_LINK="UP"
			
			# CONTADOR
			CONTADOR=0
			
			# REGISTRANDO LOG
			echo "Serviço RNP ATIVO => $(date +"%x => %X")" >> $DIRETORIO_LOG
			
			# ADICIONA ; COMEÇANDO NA LINHA 152 ATÉ 200 -> LINK 01
			sed -i '152,200s/^/;/g' $CAMINHO_ARQZONE

			# REMOVE ; COMEÇANDO NA LINHA 40 ATÉ 150 -> LINK 02
			sed -i '40,150s/;//g' $CAMINHO_ARQZONE
			
			# CAPTURANDO O SERIAL NO ARQUIVO ZONE
			SERIAL=`sed -n '/Serial/{p;q;}' ${CAMINHO_ARQZONE} | awk '{print $1}'`

			# PEGANDO A DATA INICIAL NO SERIAL
			SERIAL_DATA=`echo $SERIAL | cut -c1-8`

			# NOVO SERIAL
			NOVO_SERIAL="${DATA_ATUAL}01"

			# PEGANDO AS DOIS ULTIMOS CARACTERES
			SERIAL_FINAL=`echo $SERIAL | cut -c9-10`

			# NOVO FINAL SERIAL
			NOVO_FINAL=$(($SERIAL_FINAL+1))

			# INCREMENTANDO SERIAL
			INCREMENTANDO_SERIAL="${DATA_ATUAL}0${NOVO_FINAL}"
			
			# VERIFICANDO SERIAL COM DATA ATUAL			
			if [ $DATA_ATUAL -gt $SERIAL_DATA ]; then
			
				echo 'Gerar um novo serial'
				
				# SUBSTITUINDO SERIAL POR NOVO SERIAL
				sed -i "s/$SERIAL/$NOVO_SERIAL/g" $CAMINHO_ARQZONE
				
				# RESTART DO SERVIÇO BIND
				systemctl restart bind9
				
			else
			
				echo 'Incrementar final do serial'
				
				# SUBSTITUINDO SERIAL POR NOVO SERIAL
				sed -i "s/$SERIAL/$INCREMENTANDO_SERIAL/g" $CAMINHO_ARQZONE
				
				# RESTART DO SERVIÇO BIND
				systemctl restart bind9
				
			fi

        else
		
			# INCREMENTANDO CONTADOR
			let CONTADOR=CONTADOR+1
			
			# AVISO
			ping -c 1 $URL|echo "$URL => PING OK: $CONTADOR => $(date +"%x => %X") => $(grep 'PING'| cut -d " " -f3)"
		
        fi

        sleep $TIME_SLEEP
done