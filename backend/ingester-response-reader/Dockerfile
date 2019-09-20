FROM python:3.7.4-alpine
ADD ingester-response-reader/ingester-response-reader.py /ingester-response-reader/
ADD common/usersstoreapiserver.py /common/
ADD common/usersstoreexception.py /common/
ADD common/ingesterresponsequeueitem.py /common/
ADD common/queuereader.py /common/
ADD common/confighelper.py /common/
ADD common/metricshelper.py /common/
ADD common/unhandledexceptionhelper.py /common/
ADD common/loop_command.sh /common/
# Take advantage of layer cacheing, so that everything referenced by this file is cached if the file doesn't change:
# https://blog.realkinetic.com/building-minimal-docker-containers-for-python-applications-37d0272c52f3
COPY ingester-response-reader/requirements.txt /
RUN pip install -r /requirements.txt
WORKDIR ingester-response-reader/
CMD [ "../common/loop_command.sh", "./ingester-response-reader.py", "2" ]