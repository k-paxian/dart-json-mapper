# Use the official Dart SDK image
FROM dart:latest

# Set the working directory
WORKDIR /app

# Copy the entire repository content into the image
COPY . /app/

# Copy the test script into the image
COPY run_tests.sh /app/run_tests.sh

# Make the test script executable
RUN chmod +x /app/run_tests.sh

# Set the entrypoint to the test script
ENTRYPOINT ["/app/run_tests.sh"]
