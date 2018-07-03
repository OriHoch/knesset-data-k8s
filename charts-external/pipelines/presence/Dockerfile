FROM python:2.7-alpine

RUN mkdir /presence
WORKDIR /presence

COPY requirements.txt .
RUN pip install -r requirements.txt

COPY *.py ./

ENTRYPOINT ["python", "PresenceManager.py"]
