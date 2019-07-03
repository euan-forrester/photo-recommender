FROM python:3-alpine
ADD scheduler/scheduler.py /scheduler/
ADD common/schedulerqueueitem.py /common/
ADD common/schedulerresponsequeueitem.py /common/
ADD common/queuereader.py /common/
ADD common/queuewriter.py /common/
ADD common/confighelper.py /common/
RUN pip install boto3
RUN pip install jsonpickle
RUN pip install mysql-connector-python
RUN pip install requests
CMD [ "python", "./scheduler/scheduler.py" ]