FROM --platform=${BUILDPLATFORM} ubuntu:20.04 as ubuntu

ARG TARGETPLATFORM
ARG PUSERNAME=code
ARG PGROUPNAME=code
ARG PUID=9999
ARG PGID=9999
ARG DEBIAN_FRONTEND=noninteractive
ARG APT_MIRROR=au

# Install the required packages from a local mirror
RUN sed --in-place --regexp-extended "s/(\/\/)(archive\.ubuntu)/\1${APT_MIRROR}.\2/" /etc/apt/sources.list && \
    apt-get update && apt-get install --yes \
    curl unzip ca-certificates software-properties-common sudo jq zsh \
    iproute2 less git python3-pip

# Create the code user so things don't run as root
RUN umask 077 && \
    groupadd --force -g ${PGID} ${PGROUPNAME} && \
    useradd -u ${PUID} -m -d /home/${PUSERNAME} -g ${PGROUPNAME} --shell $(which zsh) ${PUSERNAME} && \
    touch /home/${PUSERNAME}/.zshrc && \
    mkdir /home/${PUSERNAME}/.ssh && \
    mkdir /home/${PUSERNAME}/workdir && \
    chown -R ${PUSERNAME}:${PGROUPNAME} /home/${PUSERNAME}

# Install AWS-CLI (v2)
RUN cd /tmp && \
    echo "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -mm).zip" && \
    curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -mm).zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install -i /usr/local/aws-cli -b /usr/local/bin && \
    umask 077 && mkdir /home/${PUSERNAME}/.aws && chown -R ${PUSERNAME}:${PGROUPNAME} /home/${PUSERNAME}/.aws

# Install AWS Vault - note that sudo is required for '--server'
ARG AWS_VAULT_VERSION=6.3.1
RUN case ${TARGETPLATFORM} in \
         "linux/amd64")  TINI_ARCH=amd64  ;; \
         "linux/arm64")  TINI_ARCH=arm64  ;; \
         "linux/arm/v7") TINI_ARCH=armhf  ;; \
         "linux/arm/v6") TINI_ARCH=armel  ;; \
         "linux/386")    TINI_ARCH=i386   ;; \
    esac && \
    cd /tmp && \
    curl -fsSL "https://github.com/99designs/aws-vault/releases/download/v${AWS_VAULT_VERSION}/aws-vault-linux-${TINI_ARCH}" -o "aws-vault" && \
    chmod +x aws-vault && \
    mv aws-vault /usr/local/bin && \
    umask 077 && mkdir /home/${PUSERNAME}/.awsvault && chown -R ${PUSERNAME}:${PGROUPNAME} /home/${PUSERNAME}/.awsvault && \
    echo "${PUSERNAME} ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/code

USER ${PUSERNAME}
ENV AWS_VAULT_BACKEND=file
