# Quick Step by Step

Quick steps to run this folder's content, required to open multiple terminals when needed.

-  Check out this repo. 

`git clone git@github.com:stockgeeks/docker-compose.git`

-  Navigate to `kafka-connect-crash-course` directory.

`cd docker-compose/kafka-connect-crash-course`

-  Build the docker images as the connect image is required to build to include connector standalone configurations, we 
could have used a map to provide the files but building it for now.

`docker-compose build`

-  Run the docker containers, it will run Zookeeper, Kafka and the Connector in background.

`docker-compose up -d`

- Check the docker container logs attaching a terminal window to tail/follow them.

`docker-compose logs -f`

- Check the docker images running

`watch docker-compose ps`

- When running the docker-compose in some environments the folder where we will create the file from where the connector
is reading might be created as root user, this is due to how docker-compose and docker are setup and images are built,
change the folder permissions to your current user, in a terminal if necessary: 

`sudo chown $USER: connect-input-file`

-  Run in a new terminal window a command line client attached to the connect destination topic and wait for messages 
for validation as this is a source connector.

`docker exec -it kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:9092 --topic simple-connect --from-beginning`

- This will create a folder connect-input-file in the same level as the docker-compose.yml file where inside the connector
expects to find the file where it will read lines from and publish to kafka, enter this directory and create a file named
`my-source-file.txt`.

`cd connect-input-file && touch my-source-file.txt`

- Open the file with your preferred text editor and add lines to it and notice that the lines are automatically read by
the connector and published to the kafka topic where we have attached our console client every time you save the file,
it relies in a new line / blank line at the end of the file, so make sure to add it in order for it to work properly.
