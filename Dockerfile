FROM tarantool/tarantool

# install dependencies
RUN apt update && \
  apt install -y git unzip cmake tt

# init tt dir structure, create dir for app, create symlink
RUN tt init && \
  mkdir tt_kv && \
  ln -sfn ${PWD}/tt_kv/ ${PWD}/instances.enabled/tt_kv

# copy cluster configs
COPY tt_kv /opt/tarantool/tt_kv

# build app
RUN tt build tt_kv