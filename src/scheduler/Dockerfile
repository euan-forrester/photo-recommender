FROM python:3.7.4-alpine
ADD scheduler/scheduler.py /scheduler/
ADD scheduler/usersstoreapiserver.py /scheduler/
ADD scheduler/usersstoreexception.py /scheduler/
ADD common/pullerqueueitem.py /common/
ADD common/pullerresponsequeueitem.py /common/
ADD common/queuereader.py /common/
ADD common/queuewriter.py /common/
ADD common/confighelper.py /common/
ADD common/metricshelper.py /common/
ADD common/unhandledexceptionhelper.py /common/
ADD common/loop_command.sh /common/
# Take advantage of layer cacheing, so that everything referenced by this file is cached if the file doesn't change:
# https://blog.realkinetic.com/building-minimal-docker-containers-for-python-applications-37d0272c52f3
COPY scheduler/requirements.txt /
RUN pip install -r /requirements.txt
WORKDIR scheduler/
CMD [ "../common/loop_command.sh", "./scheduler.py", "2" ]