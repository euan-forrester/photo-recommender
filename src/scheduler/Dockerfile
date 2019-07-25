FROM python:3-alpine
ADD scheduler/scheduler.py /scheduler/
ADD scheduler/usersstoreapiserver.py /scheduler/
ADD scheduler/usersstoreexception.py /scheduler/
ADD common/schedulerqueueitem.py /common/
ADD common/schedulerresponsequeueitem.py /common/
ADD common/queuereader.py /common/
ADD common/queuewriter.py /common/
ADD common/confighelper.py /common/
ADD common/metricshelper.py /common/
ADD common/loop_command.sh /common/
RUN pip install boto3
RUN pip install jsonpickle
RUN pip install mysql-connector-python
RUN pip install requests
RUN pip install pymemcache
WORKDIR scheduler/
CMD [ "../common/loop_command.sh", "./scheduler.py", "2" ]