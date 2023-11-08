# Basic Container
FROM pytorch/pytorch

# Copy relevant requirements to docker
RUN mkdir /.cache
COPY requirements.txt /.cache/requirements.txt

# Install pip requirements
RUN pip install --no-cache-dir -r /.cache/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
RUN apt-get update && apt-get install git

# install ide
WORKDIR /.cache
RUN git clone https://github.com/Duan-JM/dotfiles
WORKDIR /.cache/dotfiles
RUN make zsh_install
RUN make tmux_install

# Expose the port
EXPOSE 22
