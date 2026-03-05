FROM python:3.8.13

ARG DBT_HOME=/home/dbtuser

# Update and install system packages
RUN apt-get update -y && \
  apt-get install --no-install-recommends -y -q \
  git libpq-dev python-dev && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN groupadd -g 999 dbtuser && useradd -r -u 999 -g dbtuser dbtuser
# Home directory
WORKDIR ${DBT_HOME}

RUN chown -R dbtuser:dbtuser ${DBT_HOME}

USER dbtuser

RUN mkdir ${DBT_HOME}/.dbt

# dbt will look for profiles.yml here unless overridden
ENV DBT_PROFILES_DIR=${DBT_HOME}/.dbt

# Project directory expected by the Airflow command: `--project-dir dbt_k8_demo`
RUN mkdir -p ${DBT_HOME}/dbt_k8_demo

# Install DBT
RUN pip install -U pip

ENV VIRTUAL_ENV=${DBT_HOME}/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

RUN pip install dbt-core==1.0.4 dbt-bigquery==1.0.0

COPY --chown=dbtuser:dbtuser ./profiles.yml ${DBT_HOME}/.dbt/profiles.yml
# Copy the dbt project into the directory referenced by `--project-dir dbt_k8_demo`
COPY --chown=dbtuser:dbtuser ./dbtLearn/ ${DBT_HOME}/dbt_k8_demo/

# Default to the project directory (dbt can still be run from elsewhere with --project-dir)
WORKDIR ${DBT_HOME}/dbt_k8_demo