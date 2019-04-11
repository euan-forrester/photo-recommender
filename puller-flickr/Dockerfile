FROM python:3
ADD puller-flickr.py /puller-flickr/
ADD flickrapiwrapper.py /puller-flickr/
ADD ../common/ingester-queue-item.py /common/
RUN pip install flickrapi
RUN pip install python-memcached
RUN pip install django
RUN pip install boto3
RUN pip install jsonpickle
CMD [ "python", "./puller-flickr/puller-flickr.py" ]