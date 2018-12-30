# Knesset Data Web UI Kubernetes Chart

## Installation

Create DB secret

```
( export ROOT_USERNAME=`python -c "import binascii,os;print(binascii.hexlify(os.urandom(6)))"` &&\
export ROOT_PASSWORD=`python -c "import binascii,os;print(binascii.hexlify(os.urandom(15)))"` &&\
kubectl create secret generic web-ui-db --from-literal=ROOT_USERNAME="${ROOT_USERNAME}"  \
                                        --from-literal=ROOT_PASSWORD="${ROOT_PASSWORD}" &&\
echo "${ROOT_USERNAME}" / "${ROOT_PASSWORD}" )
```

Create DB Web UI secret

```
( export USERNAME=`python -c "import binascii,os;print(binascii.hexlify(os.urandom(6)))"` &&\
export PASSWORD=`python -c "import binascii,os;print(binascii.hexlify(os.urandom(15)))"` &&\
kubectl create secret generic web-ui-db-ui --from-literal=USERNAME="${USERNAME}"  \
                                           --from-literal=PASSWORD="${PASSWORD}" &&\
echo "${USERNAME}" / "${PASSWORD}" )
```
