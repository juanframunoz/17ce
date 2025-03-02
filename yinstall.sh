ope.interface-7.2
📌 Creando directorio de logs...
📌 Creando archivo de configuración /etc/odoo.conf...
📌 Configurando servicio systemd para Odoo...
📌 Habilitando servicio Odoo...
Created symlink /etc/systemd/system/multi-user.target.wants/odoo.service → /etc/systemd/system/odoo.service.
✅ Odoo 17 está corriendo correctamente en el puerto 8069
root@fichar:/home# sudo journalctl -u odoo --no-pager | tail -n 50
Mar 02 11:57:40 fichar systemd[1]: Started Odoo 17.
Mar 02 11:57:42 fichar python3[21602]: Exception in thread odoo.service.cron.cron0:
Mar 02 11:57:42 fichar python3[21602]: Traceback (most recent call last):
Mar 02 11:57:42 fichar python3[21602]:   File "/usr/lib/python3.10/threading.py", line 1016, in _bootstrap_inner
Mar 02 11:57:42 fichar python3[21602]:     self.run()
Mar 02 11:57:42 fichar python3[21602]:   File "/usr/lib/python3.10/threading.py", line 953, in run
Mar 02 11:57:42 fichar python3[21602]:     self._target(*self._args, **self._kwargs)
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/odoo/service/server.py", line 512, in target
Mar 02 11:57:42 fichar python3[21602]:     self.cron_thread(i)
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/odoo/service/server.py", line 494, in cron_thread
Mar 02 11:57:42 fichar python3[21602]:     with conn.cursor() as cr:
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/odoo/sql_db.py", line 754, in cursor
Mar 02 11:57:42 fichar python3[21602]:     return Cursor(self.__pool, self.__dbname, self.__dsn)
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/odoo/sql_db.py", line 267, in __init__
Mar 02 11:57:42 fichar python3[21602]:     self._cnx = pool.borrow(dsn)
Mar 02 11:57:42 fichar python3[21602]:   File "<decorator-gen-13>", line 2, in borrow
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/odoo/tools/func.py", line 87, in locked
Mar 02 11:57:42 fichar python3[21602]:     return func(inst, *args, **kwargs)
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/odoo/sql_db.py", line 682, in borrow
Mar 02 11:57:42 fichar python3[21602]:     result = psycopg2.connect(
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/venv/lib/python3.10/site-packages/psycopg2/__init__.py", line 122, in connect
Mar 02 11:57:42 fichar python3[21602]:     conn = _connect(dsn, connection_factory=connection_factory, **kwasync)
Mar 02 11:57:42 fichar python3[21602]: psycopg2.OperationalError: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "odoo" does not exist
Mar 02 11:57:42 fichar python3[21602]: Exception in thread odoo.service.cron.cron1:
Mar 02 11:57:42 fichar python3[21602]: Traceback (most recent call last):
Mar 02 11:57:42 fichar python3[21602]:   File "/usr/lib/python3.10/threading.py", line 1016, in _bootstrap_inner
Mar 02 11:57:42 fichar python3[21602]:     self.run()
Mar 02 11:57:42 fichar python3[21602]:   File "/usr/lib/python3.10/threading.py", line 953, in run
Mar 02 11:57:42 fichar python3[21602]:     self._target(*self._args, **self._kwargs)
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/odoo/service/server.py", line 512, in target
Mar 02 11:57:42 fichar python3[21602]:     self.cron_thread(i)
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/odoo/service/server.py", line 494, in cron_thread
Mar 02 11:57:42 fichar python3[21602]:     with conn.cursor() as cr:
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/odoo/sql_db.py", line 754, in cursor
Mar 02 11:57:42 fichar python3[21602]:     return Cursor(self.__pool, self.__dbname, self.__dsn)
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/odoo/sql_db.py", line 267, in __init__
Mar 02 11:57:42 fichar python3[21602]:     self._cnx = pool.borrow(dsn)
Mar 02 11:57:42 fichar python3[21602]:   File "<decorator-gen-13>", line 2, in borrow
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/odoo/tools/func.py", line 87, in locked
Mar 02 11:57:42 fichar python3[21602]:     return func(inst, *args, **kwargs)
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/odoo/sql_db.py", line 682, in borrow
Mar 02 11:57:42 fichar python3[21602]:     result = psycopg2.connect(
Mar 02 11:57:42 fichar python3[21602]:   File "/opt/odoo/odoo-server/venv/lib/python3.10/site-packages/psycopg2/__init__.py", line 122, in connect
Mar 02 11:57:42 fichar python3[21602]:     conn = _connect(dsn, connection_factory=connection_factory, **kwasync)
Mar 02 11:57:42 fichar python3[21602]: psycopg2.OperationalError: connection to server on socket "/var/run/postgresql/.s.PGSQL.5432" failed: FATAL:  role "odoo" does not exist
root@fichar:/home# sudo systemctl status postgresql
● postgresql.service - PostgreSQL RDBMS
     Loaded: loaded (/lib/systemd/system/postgresql.service; enabled; vendor preset: enabled)
     Active: active (exited) since Sun 2025-03-02 11:56:29 UTC; 2min 53s ago
   Main PID: 21172 (code=exited, status=0/SUCCESS)
        CPU: 3ms

Mar 02 11:56:29 fichar systemd[1]: Starting PostgreSQL RDBMS...
Mar 02 11:56:29 fichar systemd[1]: Finished PostgreSQL RDBMS.
root@fichar:/home# sudo systemctl start postgresql
root@fichar:/home# sudo systemctl status postgresql
● postgresql.service - PostgreSQL RDBMS
     Loaded: loaded (/lib/systemd/system/postgresql.service; enabled; vendor preset: enabled)
     Active: active (exited) since Sun 2025-03-02 11:56:29 UTC; 3min 5s ago
   Main PID: 21172 (code=exited, status=0/SUCCESS)
        CPU: 3ms

Mar 02 11:56:29 fichar systemd[1]: Starting PostgreSQL RDBMS...
Mar 02 11:56:29 fichar systemd[1]: Finished PostgreSQL RDBMS.
root@fichar:/home# sudo -u postgres psql -c "\l" | grep odoo
root@fichar:/home# sudo -u postgres psql -c "CREATE DATABASE odoo OWNER odoo;"
ERROR:  role "odoo" does not exist
