FROM node:4.3.2
MAINTAINER Dan Lynn <docker@danlynn.org>

WORKDIR /myapp

# Install unzip and python headers required by aws cli.
# Install groff and less required by aws help.
RUN \
	apt-get update &&\
	apt-get install unzip &&\
	apt-get install -y python-dev &&\
	apt-get install -y -qq groff &&\
	apt-get install -y -qq less

# install aws cli
# note: pass aws config from project dir to `docker run` containers using:
#   -v "$(pwd)/.aws:/root/.aws"
RUN \
	curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip" &&\
	unzip awscli-bundle.zip &&\
	./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

# install cwtail logging (see: https://github.com/danlynn/cwtail)
RUN \
	npm install -g git+https://github.com/danlynn/cwtail.git

# install claudia.js
RUN \
	npm install claudia@2.11.0 -g

# create install-claudia-app-template command
RUN \
	echo "#!/usr/bin/env bash\necho '2.11.0' > /myapp/.claudia-version && curl -LsS https://github.com/danlynn/claudia-app-template/archive/1.0.1.tar.gz > /usr/local/src/claudia-app-template.tar.gz\ntar -xz --skip-old-files --strip-components=1 --transform=s/README/TEMPLATE-README/ -f /usr/local/src/claudia-app-template.tar.gz -C /myapp" > /usr/local/bin/install-claudia-app-template &&\
	chmod a+x /usr/local/bin/install-claudia-app-template

# create logs command
RUN \
	echo '#!/usr/bin/env bash\nif [ -e "/myapp/claudia.json" ]; then\nlambda_name=$(grep -P -o "(?<=\"name\":\s\").*(?=\")" /myapp/claudia.json | tr -d "\r")\ncwtail -tf "/aws/lambda/$lambda_name"\nelse\necho "ERROR: claudia.json not found. Can not show logs until \"claudia create\" command has deployed lambda."\nfi' > /usr/local/bin/logs &&\
	chmod a+x /usr/local/bin/logs
