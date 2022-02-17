FROM nvcr.io/nvidia/tensorrt:21.03-py3
# ------------------------------------------------------------------
WORKDIR /workspace

COPY ["./format_print.sh", "./requirements.sh", "/workspace/" ]
# ------------------------------------------------------------------
# 由於 安裝套件有互動界面會導致報錯 所以先行關閉
ENV DEBIAN_FRONTEND noninteractive  
RUN chmod +x ./requirements.sh \
&& ./requirements.sh \
&& rm ./requirements.sh \
&& rm ./format_print.sh
# ------------------------------------------------------------------
# 寫入進入W
ENTRYPOINT [ "/bin/bash", "-c" ]
