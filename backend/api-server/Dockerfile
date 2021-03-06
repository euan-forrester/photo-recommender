# https://pythonspeed.com/articles/base-image-python-docker-images/
# slim-buster makes our images approx 100MB larger than alpine
FROM python:3.8.2-alpine
ADD api-server/api-server.py /api-server/
ADD api-server/photorecommendation.py /api-server/
ADD api-server/favoritesstoredatabase.py /api-server/
ADD api-server/favoritesstoreexception.py /api-server/
ADD api-server/userrecommendation.py /api-server/
ADD api-server/flickrauthwrapper.py /api-server/
ADD common/flickrapiwrapper.py /common/
ADD common/confighelper.py /common/
ADD common/metricshelper.py /common/
ADD common/unhandledexceptionhelper.py /common/
ADD common/pullerqueueitem.py /common/
ADD common/queuewriter.py /common/
# Our OAuth lib needs the C compiler to install itself
# https://stackoverflow.com/a/58028091
# Cleanup taken from: https://spectrum.chat/zeit/now/best-dockerfile-for-building-a-python-container-with-compiled-dependencies~308b60c7-77fc-43de-b42a-8d14f9956ccd
RUN apk add --no-cache --virtual .build-deps gcc=9.2.0-r4 musl-dev=1.1.24-r2 libffi-dev=3.2.1-r6 openssl-dev=1.1.1g-r0
# Take advantage of layer cacheing, so that everything referenced by this file is cached if the file doesn't change:
# https://blog.realkinetic.com/building-minimal-docker-containers-for-python-applications-37d0272c52f3
# In practice I don't observe this happening though?
COPY api-server/requirements.txt /
RUN pip install -r /requirements.txt
RUN apk del .build-deps
EXPOSE 4445
WORKDIR /api-server/
CMD [ "gunicorn", "-b", "0.0.0.0:4445", "--access-logfile", "-", "--error-logfile", "-", "api-server" ]