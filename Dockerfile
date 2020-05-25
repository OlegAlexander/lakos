# Use docker to run tests in a Linux container. (Because I'm developing on Windows.)
# Usage: docker build .
# Clean up: docker container prune -f

FROM google/dart

WORKDIR /lakos

# Install Graphviz dot
RUN apt update
RUN apt install graphviz -y

# Get dependencies
ADD pubspec.* /lakos/
RUN pub get
ADD . /lakos
RUN pub get --offline

# Run all tests
RUN pub run test