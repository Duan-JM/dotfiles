# Basic Container
FROM pytorch/pytorch

# Copy relevant requirements to docker
RUN mkdir /.cache
COPY ./docker_files/dev/requirements.txt /.cache/requirements.txt
COPY . /.cache/dotfiles
COPY . /.cache/dotfiles

# Install pip requirements
RUN apt-get update && apt-get install make --yes
RUN pip install --no-cache-dir -r /.cache/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# install ide
WORKDIR /.cache/dotfiles
RUN make zsh_install
RUN make tmux_install

# ssh
COPY ./docker_files/dev/id_rsa.pub /.cache/
RUN apt-get install openssh-client openssh-server && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys

# Expose the port
EXPOSE 22
