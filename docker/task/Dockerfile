FROM alphahydrae/lair:latest

LABEL maintainer="docker@alphahydrae.com"

COPY wait /wait

ENTRYPOINT [ "/wait", "rake" ]
CMD [ "-T" ]
