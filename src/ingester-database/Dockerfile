FROM python:3-alpine
ADD ingester-database/ingester-database.py /ingester-database/
ADD ingester-database/databasebatchwriter.py /ingester-database/
ADD common/ingesterqueueitem.py /common/
ADD common/queuereader.py /common/
ADD common/confighelper.py /common/
ADD common/loop_command.sh /common/
RUN pip install boto3
RUN pip install jsonpickle
RUN pip install mysql-connector-python
RUN pip install pymemcache
CMD [ "./common/loop_command.sh", "./ingester-database/ingester-database.py", "2" ]
