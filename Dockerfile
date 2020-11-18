# Use docker to run tests in a Linux container. (Because I'm developing on Windows.)
# Usage: docker build .
# Clean up: docker container prune -f
# Really clean up: docker system prune -a --volumes -f

FROM google/dart

WORKDIR /lakos

# Install Graphviz dot
RUN apt update
RUN apt install graphviz -y

# Get dependencies
ADD pubspec.* /lakos/
RUN dart pub get
ADD . /lakos
RUN dart pub get --offline

# Run all tests
RUN dart test