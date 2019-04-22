FROM python:3
ADD ingester-database/ingester-database.py /ingester-database/
ADD common/ingesterqueueitem.py /common/
ADD common/queuereader.py /common/
ADD common/confighelper.py /common/
RUN pip install boto3
RUN pip install jsonpickle
CMD [ "python", "./ingester-database/ingester-database.py" ]