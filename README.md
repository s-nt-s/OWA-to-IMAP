**Problema**: Nos vemos obligados a utilizar una cuenta que permite únicamente acceso por OWA (outlook web access) cuyos servidores tienen deshabilitado el acceso POP y además tampoco funcionan las reglas de reenvió

**Solución 1º**: Usar [davmail](http://davmail.sourceforge.net/serversetup.html) para crear un acceso pop o imap

**Problema de la solucón 1º**:  La cuenta que va a leer desde ese acceso pop nos va a pedir que usemos un certificado SSL no auto firmado y ni queremos pagarlo ni queremos dar acceso a nuestra cuenta sin encriptar

**Solución**: [davmail](http://davmail.sourceforge.net/serversetup.html) + [pop2imap](http://www.linux-france.org/prj/pop2imap/) + cuenta intermedia + nuestra cuenta final

1- Crear directorio para el script e instalar las herramientas necesarias

```console
pi@bot ~ $ mkdir .owa
pi@bot ~ $ cd .owa
pi@bot ~/.owa $ wget http://downloads.sourceforge.net/project/davmail/davmail/4.4.0/davmail-4.4.0-2198.zip
pi@bot ~/.owa $ unzip davmail-*.zip
pi@bot ~/.owa $ rm davmail-*.zip
pi@bot ~/.owa $ aptitude install libmail-pop3client-perl libmail-imapclient-perl libdigest-hmac-perl libemail-simple-perl libdate-manip-perl
pi@bot ~/.owa $ wget http://www.linux-france.org/prj/pop2imap/dist/pop2imap-1.21.tgz
pi@bot ~/.owa $ tar -xzvf pop2imap-*.tgz
pi@bot ~/.owa $ cd pop2imap*
pi@bot ~/.owa/pop2imap-1.21 $ make install
pi@bot ~/.owa/pop2imap-1.21 $ cd ..
pi@bot ~/.owa $ rm -R pop2imap*
pi@bot ~/.owa $ touch owa.sh
pi@bot ~/.owa $ chmod +x owa.sh
```

2- Configurar DavMail (davmail.properties)

```
...
# Modo servidor
davmail.server=true
# Exchange OWA o EWS url
davmail.url=https://mail.ejemplo.com
# Puerto para el acceso POP
davmail.popPort=1110
# El resto de servicios no nos interesan
davmail.caldavPort=
davmail.imapPort=
davmail.ldapPort=
davmail.smtpPort=
# No permitir acceso remoto (solo lo vamos a usar en local)
davmail.allowRemote=false
# Lo dejamos vacio para que escriba el log en la misma carpeta del script
davmail.logFilePath=
...
```

3- Crear ficheros de configuración

input.cnf (cuentas que vamos a leer)

```
LABEL1 usuario1 pass1 https://autodiscover.ejemplo1.com/ews/exchange.asmx
LABEL2 usuario2 pass2 https://webmail.ejemplo2.es/owa/
```

output.cnf (cuenta *espejo*)

```
GMAIL output@gmail.com pass imap.gmail.com 993 owa
```


4- Crear tarea programada
	
```console
pi@bot ~ $ crontab -e
```

```
# Cada hora en horario laboral
0 7-20 * * 1,2,3,4  /bin/bash ~/.owa/owa.sh
0 7-18 * * 5  /bin/bash ~/.owa/owa.sh
# Cada 4 horas fuera de horario laboral y entre semana
0 23,3 * * 1,2,3,4  /bin/bash ~/.owa/owa.sh
# Cada 8 horas en fin de semana
0 */8 * 6,7 /bin/bash ~/.owa/owa.sh
```

5- Configurar nuestra cuenta final

Ahora nuestra cuenta final puede leer vía pop de la cuenta intermedia (que funciona como espejo del owa) sin problemas.

**Nota**: Se podría usar la salida imap que da davmail para [migrar de imap a imap](http://imapsync.lamiral.info/) pero según la documentación de davmail su acceso pop es más eficiente. También se podría pensar en prescindir de la cuenta intermedia y cargarlo todo en la cuenta final pero entonces no se ejecutarían nuestros filtros sobre este correo entrante y además si borrásemos un mail este volvería a aparecer en la próxima sincronización.

