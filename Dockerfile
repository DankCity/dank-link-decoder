FROM python:alpine

RUN pip install -U pip setuptools

ENTRYPOINT ["echo"]
CMD ["Hello, World!"]
