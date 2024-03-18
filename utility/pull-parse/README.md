## Parse Docker Pull Data
This is a rough little python program that is designed to parse the data from the Docker admin portal for hub activity into something a bit more useful.

When run, this program will create two files in the output directory that roll up the number of PUSH/PULLS by username and repo name. It sorts by most to least, and provides the percentage of the total that each line contributes to.

To build and run:

1. Edit the `dockerfile` as desired.
2. Build the image: `docker build -t csv_data_parse:latest .`
3. Run the image `docker run -it --rm -v $(pwd):/usr/src/app csv_data_parse`
4. You will be dropped into a bash shell with your current directory mounted into the image. 
5. Run the process (this assumes you have already put the raw data into your working directory). This can be done with `csv_data_parse.py FILENAME`
6. This will product two output files under `./output`
7. You can now exit the Docker container; it will be removed on exit (provided you use the run command from above).
8. You can now import your parsed files into your spreadsheet program of choice.



