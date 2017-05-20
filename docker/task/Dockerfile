FROM alphahydrae/lair:latest

LABEL maintainer="docker@alphahydrae.com"

COPY wait.sh /wait

ENTRYPOINT [ "/wait", "rake" ]
CMD [ "-T" ]
