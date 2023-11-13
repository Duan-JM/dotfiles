# Basic Container
FROM pytorch/pytorch
MAINTAINER by Duan-JM (vincent.duan95@gmail.com)

# Copy relevant requirements to docker
RUN mkdir /.cache
COPY ./docker_files/dev/requirements.txt /.cache/requirements.txt
COPY . /.cache/dotfiles

RUN apt-get update \
    && apt-get install make openssh-client openssh-server --yes \
    && apt-get install --reinstall software-properties-common --yes \
    && apt-get autoremove

# RUN pip install --no-cache-dir -r /.cache/requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# install ide
WORKDIR /.cache/dotfiles
# RUN export all_proxy=socks5://host.docker.internal:7890
# RUN make zsh_install
# RUN make tmux_install
# fix add neovim repo problem
# RUN unset all_proxy https_proxy http_proxy && apt-add-repository ppa:neovim-ppa/stable --yes
# RUN export all_proxy=socks5://host.docker.internal:7890 \
#     && make vim_install \
#     && unset all_proxy https_proxy http_proxy

# ssh
COPY ./docker_files/dev/id_rsa.pub /.cache/
RUN sed -i 's/UsePAM yes/UsePAM no/g' /etc/ssh/sshd_config
RUN mkdir ~/.ssh \
    && touch ~/.ssh/authorized_keys \
    && chmod 600 ~/.ssh/authorized_keys \
    && cat /.cache/id_rsa.pub >> ~/.ssh/authorized_keys \
    && mkdir /run/sshd
CMD ["/usr/sbin/sshd", "-D"]

# Expose the port
EXPOSE 22
