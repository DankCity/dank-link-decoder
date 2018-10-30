FROM python:alpine

WORKDIR /app

COPY pkg/ /app

RUN pip install -U pip setuptools \
 && pip install -e .

ENTRYPOINT ["echo"]
CMD ["Hello, World!"]
