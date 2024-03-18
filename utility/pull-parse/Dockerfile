# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /usr/src/app

# Copy the current directory contents into the container at /usr/src/app
COPY ./csv_data_parse.py .

# Install any needed packages specified in requirements.txt
RUN pip install --no-cache-dir pandas

# Run cvs_data_parse.py when the container launches, filename will be provided via command line
ENTRYPOINT ["bash"]
