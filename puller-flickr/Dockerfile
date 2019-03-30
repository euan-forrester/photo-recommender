FROM python:3
ADD puller-flickr.py /
ADD flickrapiwrapper.py /
ADD config/config.ini /config/
ADD config/secrets.ini /config/
RUN pip install flickrapi
RUN pip install python-memcached
RUN pip install django
CMD [ "python", "./puller-flickr.py", "-o test.html" ]