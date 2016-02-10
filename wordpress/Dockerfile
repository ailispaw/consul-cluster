FROM ailispaw/ubuntu-essential
RUN apt-get -q update && \
    apt-get -q -y install --no-install-recommends php5 php5-cli php5-mysql && \
    apt-get clean && rm -rf /var/lib/apt/lists/*
ADD wordpress /code
