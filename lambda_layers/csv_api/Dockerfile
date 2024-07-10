FROM public.ecr.aws/lambda/python:3.8

RUN yum install -y zip

COPY requirements.txt .

RUN pip install -r requirements.txt

# Create the Lambda layer directory structure
RUN mkdir -p /opt/python/lib/python3.8/site-packages

# Copy installed packages to the layer directory
RUN cp -r /var/lang/lib/python3.8/site-packages/* /opt/python/lib/python3.8/site-packages/

# Create a zip file of the layer
RUN cd /opt && zip -r9 /opt/layer.zip .

WORKDIR /opt
