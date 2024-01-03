FROM --platform=linux/amd64  swift:5.0 as builder
WORKDIR /root
COPY asm2c .
RUN swift build -c release
COPY . .
RUN ./.build/x86_64-unknown-linux/release/asm2c /root/src/mrboom.asm /root/Resources
#CMD ["./.build/x86_64-unknown-linux/release/asm2c" "/root/src/mrboom.asm" "/root/Resources"]

#FROM swift:slim
#WORKDIR /root
#COPY --from=builder /root .
#COPY . .
#CMD ["./.build/x86_64-unknown-linux/release/asm2c"]
#RUN ./.build/x86_64-unknown-linux/release/asm2c /root/src/mrboom.asm

#docker run -i -t -d  ocr-docker-build bash
#docker build -t ocr-docker-build . --progress=plain
#running /Users/franck/dev/asm2c/.build/debug/asm2c /Users/franck/dev/mrboom-libretro/tools/asm/src/mrboom.asm
