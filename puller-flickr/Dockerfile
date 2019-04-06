FROM python:3
ADD puller-flickr.py /
ADD flickrapiwrapper.py /
RUN pip install flickrapi
RUN pip install python-memcached
RUN pip install django
RUN pip install boto3
CMD [ "python", "./puller-flickr.py", "-d" ]