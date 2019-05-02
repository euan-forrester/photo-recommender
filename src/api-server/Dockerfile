FROM python:3
ADD api-server/api-server.py /api-server/
ADD common/confighelper.py /common/
RUN pip install flask
RUN pip install mysql-connector-python
RUN pip install boto3
EXPOSE 4445
CMD [ "python", "./api-server/api-server.py" ]