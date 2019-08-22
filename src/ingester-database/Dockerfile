FROM python:3.7.4-alpine
ADD ingester-database/ingester-database.py /ingester-database/
ADD ingester-database/databasebatchwriter.py /ingester-database/
ADD common/ingesterqueueitem.py /common/
ADD common/ingesterqueuebatchitem.py /common/
ADD common/queuereader.py /common/
ADD common/confighelper.py /common/
ADD common/metricshelper.py /common/
ADD common/unhandledexceptionhelper.py /common/
ADD common/loop_command.sh /common/
# Take advantage of layer cacheing, so that everything referenced by this file is cached if the file doesn't change:
# https://blog.realkinetic.com/building-minimal-docker-containers-for-python-applications-37d0272c52f3
COPY ingester-database/requirements.txt /
RUN pip install -r /requirements.txt
CMD [ "./common/loop_command.sh", "./ingester-database/ingester-database.py", "2" ]
