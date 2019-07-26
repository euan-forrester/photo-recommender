FROM python:3-alpine
ADD puller-flickr/puller-flickr.py /puller-flickr/
ADD puller-flickr/flickrapiwrapper.py /puller-flickr/
ADD common/ingesterqueueitem.py /common/
ADD common/ingesterqueuebatchitem.py /common/
ADD common/schedulerqueueitem.py /common/
ADD common/schedulerresponsequeueitem.py /common/
ADD common/queuewriter.py /common/
ADD common/queuereader.py /common/
ADD common/confighelper.py /common/
ADD common/loop_command.sh /common/
RUN pip install flickrapi
RUN pip install python-memcached
RUN pip install django
RUN pip install boto3
RUN pip install jsonpickle
RUN pip install pymemcache
CMD [ "./common/loop_command.sh", "./puller-flickr/puller-flickr.py", "2" ]
