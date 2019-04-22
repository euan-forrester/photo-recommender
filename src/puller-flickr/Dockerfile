FROM python:3
ADD puller-flickr/puller-flickr.py /puller-flickr/
ADD puller-flickr/flickrapiwrapper.py /puller-flickr/
ADD common/ingesterqueueitem.py /common/
ADD common/queuewriter.py /common/
ADD common/confighelper.py /common/
RUN pip install flickrapi
RUN pip install python-memcached
RUN pip install django
RUN pip install boto3
RUN pip install jsonpickle
CMD [ "python", "./puller-flickr/puller-flickr.py" ]