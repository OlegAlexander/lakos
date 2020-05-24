# Use docker to run tests in a Linux container. (Because I'm developing on Windows.)
# Usage: docker build .
# Clean up: docker container prune -f

FROM google/dart

WORKDIR /app

# Install Graphviz dot
RUN apt update
RUN apt install graphviz -y

# Get dependencies
ADD pubspec.* /app/
RUN pub get
ADD . /app
RUN pub get --offline

# Run all tests
RUN pub run test