FROM python:3-alpine
ADD api-server/api-server.py /api-server/
ADD common/confighelper.py /common/
RUN pip install flask
RUN pip install gunicorn
RUN pip install mysql-connector-python
RUN pip install boto3
EXPOSE 4445
WORKDIR /api-server/
CMD [ "gunicorn", "-b", "0.0.0.0:4445", "--access-logfile", "-", "--error-logfile", "-", "api-server" ]