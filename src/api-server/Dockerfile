FROM python:3.7.4-alpine
ADD api-server/api-server.py /api-server/
ADD api-server/photorecommendation.py /api-server/
ADD api-server/favoritesstoredatabase.py /api-server/
ADD api-server/favoritesstoreexception.py /api-server/
ADD common/flickrapiwrapper.py /common/
ADD common/confighelper.py /common/
ADD common/metricshelper.py /common/
ADD common/unhandledexceptionhelper.py /common/
# Take advantage of layer cacheing, so that everything referenced by this file is cached if the file doesn't change:
# https://blog.realkinetic.com/building-minimal-docker-containers-for-python-applications-37d0272c52f3
COPY api-server/requirements.txt /
RUN pip install -r /requirements.txt
EXPOSE 4445
WORKDIR /api-server/
CMD [ "gunicorn", "-b", "0.0.0.0:4445", "--access-logfile", "-", "--error-logfile", "-", "api-server" ]