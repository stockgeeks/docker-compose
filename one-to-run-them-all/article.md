# One to run them all

In this Post, we're going to cover running Kafka locally for when we're developing our application, so when you need to run future examples from the posts here or your own application, you know how to do it. 

There are many possible ways to do that:
 
 * downloading Kafka and Zookeeper manually and running them locally, 
 * directly from the command line using Docker, 
 * using a docker-compose file,
 * using the Confluent CLI commands, 
 * running them on the cloud.

and possibly other creative ways. 

From all the possibilities the one I find more intuitive and easy to maintain in development projects is using docker-compose. I have used different VM based solutions in the past but using docker-compose gives a better developer experience. So I will stick to that in my posts here.

> If you don't have docker and docker-compose installed please check out [my previous post](https://dev.to/thegroo/basic-setup-for-some-tutorials-51m) where I point out directions to where to find the proper documentation to install it in your own environment.

Docker compose uses a simple YAML file and can also build from Dockerfiles for some more advanced setups if you need more control of the images you're building in your projects. Compose also enables you to set configuration parameters and share those changes within a repository with other team members and reuse it to run as a [Swarm Cluster](https://docs.docker.com/engine/swarm/) if you so desire, so we're going to cover mostly docker-compose here as it's my preference and I will provide some hints and links to  documentation on how to do it using other approaches. 

> I think important to clarify that I am not advocating to run all your application in docker during development it should be only the dependencies and mocks that you might need, it's very important that you are enabled to run your unit tests and current application you are working on directly from the IDE of your choice so you can have better development experience and quicker development cycles.

## Running Kafka from a docker-compose file

There are many available options, you can also use the Kafka and zookeeper binaries to pack your own docker images but here I'll show two existing available Kafka images from docker-hub.

* wurstmeister Kafka and Zookeeper docker images.
* Confluent Kafka and Zookeeper images.

The source code with the compose files used in this post are available, clone the repository using:

```bash
git clone git@github.com:stockgeeks/docker-compose.git
``` 

Open the cloned project in your favorite IDE. The source code for this post is under the folder one-to-run-them-all. Navigate to this folder in a command prompt to run the docker-compose commands presented next. If you have problems running the commands make sure to have docker and docker-compose installed as explained in the link shared above and check [this compatibility matrix](https://github.com/docker/compose/releases).


### wurstmeister

For this initial example, we're going to use the latest Kafka docker image from [wurstmeister](https://github.com/wurstmeister) which it's available in [docker hub here](https://hub.docker.com/r/wurstmeister/kafka/).

We will not cover components like the schema registry in this post, the idea is to keep it simple and focus on running Kafka while learning some ways to interact with it using docker and docker-compose.

Let's first make it run it in the background, from a shell inside the one-to-run-them-all folder in the project: 

```bash
docker-compose up -d
```

you can then use `docker ps` to check the running containers. If you're comfortable with multiple command line shells you can [watch](https://en.wikipedia.org/wiki/Watch_(Unix)#See_also) the docker containers continuously in one of them while developing, I usually do that: `watch docker ps` and hit the keyboard with `CTRL + C`  when you want to stop watching. 

> If you're using Mac or Windows it's also possible to install watch command and use it.

With zookeeper and Kafka running locally let's issue some commands to test our setup, let's first enter the running Kafka docker container:

```bash
docker exec -it kafka /bin/bash
```

Now you're inside the running Kafka container and can access the Kafka support scripts available in the command line under `/opt/kafka/bin`, let's start creating a topic called client with 1 partition and replication factor 1.

```bash
./kafka-topics.sh --bootstrap-server kafka:9092 --create --topic client --partitions 1 --replication-factor 1
```

let's then list the topics: 

```bash
./kafka-topics.sh --bootstrap-server kafka:9092 --list
```

You should see `client` as this is the topic we just created, but let's get some more details with `describe`: 


```bash
./kafka-topics.sh --bootstrap-server kafka:9092 --topic client --describe
```

Now you should get some more details like Partition, leader, replicas and in sync replicas which in this case are all the same as we've set all to 1 when creating the topic.

> With a small variation of docker command you can execute the same kafka commands from the host directly, all you need to do is prefix the commands with `docker exec -it kafka` so from the host machine and NOT inside the kafka running container, you can run: `docker exec -it kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:9092 --topic client --describe` and should have exactly the same output as before.

Ok, let's now publish a message to the kafka topic using the console-producer from kafka, but would be nice to be sure the message was published immediately so let's start a consumer to be listening from message in that topic and print it out when a new message is sent.

```bash
./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic client --from-beginning
```

and now in another terminal window let's produce messages to the client topic: 

```bash
./kafka-console-producer.sh --broker-list localhost:9092 --topic client
```
Your terminal will be in waiting status, see screenshot below, with a `>`, type in the line and press enter, the message will be produced to Kafka and received by the client in the consumer terminal.

![terminal consumer / producer](https://thepracticaldev.s3.amazonaws.com/i/rjqtzn8b0n6z2jiad1mt.png)

Now that we have kafka running and have produced and consumed a few messages,
let's now check the compose file:  

```yaml
version: '3.2'

services:
  # https://github.com/wurstmeister/zookeeper-docker
  zookeeper:
    container_name: zookeeper
    image: wurstmeister/zookeeper:latest
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
    ports:
    - "2181:2181"

  # https://hub.docker.com/r/confluentinc/cp-kafka/
  kafka:
    container_name: kafka
    image: wurstmeister/kafka:2.12-2.2.1
    environment:
      ## the >- used below infers a value which is a string and properly 
      ## ignore the multiple lines resulting in one long string: 
      ## https://yaml.org/spec/1.2/spec.html
      KAFKA_ADVERTISED_LISTENERS: >- 
        LISTENER_DOCKER_INTERNAL://kafka:19092, 
        LISTENER_DOCKER_EXTERNAL://${DOCKER_HOST_IP:-kafka}:9092

      KAFKA_LISTENERS: >-
        LISTENER_DOCKER_INTERNAL://:19092,
        LISTENER_DOCKER_EXTERNAL://:9092

      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: >- 
        LISTENER_DOCKER_INTERNAL:PLAINTEXT,
        LISTENER_DOCKER_EXTERNAL:PLAINTEXT

      KAFKA_INTER_BROKER_LISTENER_NAME: LISTENER_DOCKER_INTERNAL
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_LOG4J_LOGGERS: >- 
        kafka.controller=INFO,
        kafka.producer.async.DefaultEventHandler=INFO,
        state.change.logger=INFO
        
    ports:
    - 9092:9092
    depends_on:
    - zookeeper
    volumes:
    - /var/run/docker.sock:/var/run/docker.sock

```

### Confluent Kafka and Zookeeper images

Let's now run kafka [confluent docker image](https://hub.docker.com/r/confluentinc/cp-kafka/).
In the project under the folder one-to-run-them-all there's a [second docker-compose](https://github.com/stockgeeks/docker-compose/blob/master/one-to-run-them-all/docker-compose-confluent.yml) file called `docker-compose-confluent.yml` to run it we can issue the same command as before specifying the file name when want to run using the option `-f` , but before we do that please make sure the previous containers are stopped, if not run from the same folder `docker-compose down -v` which will stop the containers we started before in this article. 

```yaml
docker-compose -f docker-compose-confluent.yml up -d

```

Check if the containers are running and put a `watch docker ps` as before to be sure the confluent containers with zookeeper and kafka are running. If yes, let's execute the same commands as before, the main difference is that Confluent Kafka has it's own installation standars so the kafka scripts are under `/usr/bin` which basically gives access to them from everywhere in the shell inside the container, so go ahead and repeat the same commands issued for the previous example to enter the container shell `docker exec -it docker /bin/bash` and the commands to list, publish, consume are almost the same:

Enter the kafka container: 

```bash
docker exec -it kafka /bin/bash
```

Start the consumer

```bash
kafka-console-consumer --bootstrap-server localhost:9092 --topic client
```

Start the producer

```bash
kafka-console-producer --broker-list kafka:9092 --topic client
```

> By default for develoment which this images are meant for, the topic creation happens automatically when a client tries to consume or produce to it, this should be disabled in a production environment.

## Command line using docker images

This option only requires that you have Docker installed, not docker-compose, you'll run the docker images for Kafka and zookeeper from the command line and that's it. Make sure you have Docker installed. The tricky part is to pick the docker image, there are many available. The most populars in my perception(would need further research to confirm) are: 

* wurstmeister
* Confluent Kafka Images

> Please leave a comment if you prefer any other kafka image for development.


## Command line using binaries

This approach is well documented with all required links to download the binaries in the official Apache Kafka Documentation [Quick Start](https://kafka.apache.org/documentation/#quickstart) section.

## Confluent cli tools


## Options for Production

### Managed Kafka Offers In the Cloud

If you have plans to run your kafka Cluster in the Cloud fully automated, there are a few options, the most natural being [Confluent Cloud](https://www.confluent.io/confluent-cloud/) as it's managed by a team with many Kafka core contributtors and it's creators, currently you can deploy Confluent managed Kafka clusters to Google Cloud or AWS.

Other possible options include: 

[IBM Event Streams for IBM Cloud](https://www.ibm.com/cloud/event-streams-for-cloud) is a full, automated Kafka managed service provided by IBM. 

For Azure check their [Quickstart article](https://docs.microsoft.com/en-us/azure/hdinsight/kafka/apache-kafka-get-started) and more [details in this post](https://azure.microsoft.com/en-us/blog/processing-trillions-of-events-per-day-with-apache-kafka-on-azure/) with extra links and detailed information.

For AWS there's the AWS official offer [MSK](https://aws.amazon.com/msk/) but you will also find different options and companies that offer Kafka managed cluster services over AWS.

For Google Cloud it's recommended to use the [Confluent offer](https://console.cloud.google.com/marketplace/details/confluent-saas/confluent-cloud?pli=1) as mentioned above.  

### Kubernetes or Swarm versions

