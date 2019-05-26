FROM python:3-alpine
ADD api-server/api-server.py /api-server/
ADD api-server/favorite.py /api-server/
ADD api-server/favoritesstoredatabase.py /api-server/
ADD api-server/favoritesstoreexception.py /api-server/
ADD api-server/recommendations.py /api-server/
ADD common/confighelper.py /common/
RUN pip install flask
RUN pip install flask_api
RUN pip install gunicorn
RUN pip install pymysql
RUN pip install boto3
EXPOSE 4445
WORKDIR /api-server/
CMD [ "gunicorn", "-b", "0.0.0.0:4445", "--access-logfile", "-", "--error-logfile", "-", "api-server" ]