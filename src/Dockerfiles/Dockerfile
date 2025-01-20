# ------ STAGE 1: build dependencies ------
FROM amazonlinux:2 AS build

RUN yum -y update && \
    yum -y install python3 python3-devel zip

RUN python3 -m ensurepip

WORKDIR /app

COPY requirements.txt .

RUN pip3 install --upgrade pip && \
    pip3 install --target ./package -r requirements.txt


# ------ STAGE 2: export dependencies ------
FROM busybox AS export
COPY --from=build /app/package /out