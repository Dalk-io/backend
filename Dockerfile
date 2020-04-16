## Make a self-contained executable out of the application.
FROM google/dart AS dart-runtime
WORKDIR /app
ADD pubspec.* /app/
ADD common/network_entities /common/network_entities/
RUN pub get
ADD bin /app/bin/
ADD lib /app/lib/
RUN dart2native /app/bin/main.dart -o /app/bin/server

## Build a bare minimum image for serving.
FROM scratch
WORKDIR /app

# Server and server dependencies.
COPY --from=dart-runtime /app/bin/server /app/bin/server

COPY --from=dart-runtime /lib64/ld-linux-x86-64.so.2 /lib64/ld-linux-x86-64.so.2
COPY --from=dart-runtime /lib/x86_64-linux-gnu/libc.so.6 /lib/x86_64-linux-gnu/libc.so.6
COPY --from=dart-runtime /lib/x86_64-linux-gnu/libm.so.6 /lib/x86_64-linux-gnu/libm.so.6
COPY --from=dart-runtime /lib/x86_64-linux-gnu/libpthread.so.0 /lib/x86_64-linux-gnu/libpthread.so.0
COPY --from=dart-runtime /lib/x86_64-linux-gnu/libdl.so.2 /lib/x86_64-linux-gnu/libdl.so.2

## Setup for serving.
ENTRYPOINT ["/app/bin/server"]