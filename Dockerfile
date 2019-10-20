# -- Base Image --
# Installs application dependencies
FROM python:3.7.2 as base
ENV PYTHONUNBUFFERED 1

# Set up application environment
WORKDIR /app
COPY ./src/requirements.txt ./
RUN pip install -r requirements.txt

# -- Test Image --
# Code to be mounted into /app
FROM base as test

COPY ./src/requirements-test.txt ./
RUN pip install -r requirements-test.txt
ENTRYPOINT ["pytest", "-vv", "--cov=.", "--cov-report=xml:coverage.xml", "--cov-report=term", "--junitxml=tests.xml"]

# -- Formatting helper --
FROM base as tools

WORKDIR /app
COPY tools.ini /root/
RUN pip install black flake8 flake8-bugbear mypy
ENTRYPOINT [ "bash", "-c" ]

# -- Production Image --
# Runs the service
FROM base as prod

COPY ./src .

# Expose any ports
# EXPOSE 5000
ENTRYPOINT ["python3", "app.py"]
