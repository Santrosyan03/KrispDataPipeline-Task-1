# Krisp Data Pipeline

This project is a data ingestion pipeline designed to process user metrics and store them in a PostgreSQL database. The pipeline is containerized using Docker, ensuring easy deployment and environment isolation.

## Table of Contents

- [Krisp Data Pipeline](#krisp-data-pipeline)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Setup Instructions](#setup-instructions)
  - [Clone the repository](#1-clone-the-repository)
  - [Build and Start the Containers](#2-build-and-start-the-containers)
  - [Check the Logs](#3-check-the-logs)
  - [Run main.py](#4-run-mainpy)
- [DATABASE SCHEMA DOCUMENTATION](#database-schema-documentation)
  - [users table](#users-table)
  - [sessions table](#sessions-table)
  - [timezones table](#timezones-table)
  - [users_session_pivot table](#users_session_pivot-table)
  - [sentiments table](#sentiments-table)
  - [events table](#events-table)


## Prerequisites

Before you begin, ensure you have met the following requirements:

- **Docker Desktop**: Ensure Docker Desktop is installed and running on your machine. You can download it from [Docker Desktop](https://www.docker.com/products/docker-desktop).
- **Python 3.9+**: Installed on your machine for local development (optional).

## Project Structure

```plaintext
KrispDataPipeline/
│
├── app/
│   ├── main.py               # Main script to run the pipeline
│   ├── requirements.txt      # Python dependencies
│   └── Dockerfile            # Dockerfile for the app
│
├── db/
│   ├── init.sql              # SQL script to initialize the database
│   └── Dockerfile            # Dockerfile for custom PostgreSQL setup
│
├── docker-compose.yml        # Docker Compose configuration
└──README.md                 # This README file
```

## Setup Instructions

#### 1) Clone the repository:

```bash
git clone https://github.com/Santrosyan03/KrispDataPipeline-Task-1.git
cd KrispDataPipeline-Task-1
```

#### 2) Build and Start the Containers:
  
```bash
docker-compose up
```

#### 3) Check the Logs: (Optional)

#### Check the logs to ensure everything is running smoothly

```bash
docker-compose logs
```

#### 4) Run main.py:

```bash
python app/main.py
```


## DATABASE SCHEMA DOCUMENTATION

#### users table:
Keeping simple user data, may include some additional columns like region, 
country or native language.
Also, I want to note some ideas outside the task scope, like adding the 
language to the user_sessions table which will indicate the language the user 
talked at a certain timestamp as the languages differ in their parameters like 
amplitudes of voice, frequencies or the general pitch which are parameters that
can and will be used to analyse speakers sentiment of voice.
  
#### sessions table:
Keeping basic information about the session, like start end timestamps, 
I was thinking there can be sessions types, like business meetings, 
or webinars and my thinking is that including such factor may increase the 
accuracy of the models' predictions.

#### timezones table
Table main purpose of which is to give the back end and other clients using
the database to have easier access to the timezones and make it easier for
them to calculate. Using the integer values back end application can easily
transform one timezone to another.

#### users_session_pivot table
Crucial table that defines the whole structure I had in mind. This structure 
which mimics the pivotal structure of many-to-many relationship tables 
decomposition helps to construct very effective way of fulfilling the desired task.
It includes keys from users and sessions table, with each row representing 
additional information like user_id, sessions_id, user_timezone_id, user_connected_timestamp, 
user_disconnected_timestamp, talked_time, microphone_used, speaker_used.
Note, in the design was made keeping in mind that the user will connect to 
the same session once (user sessions key is unique in this table) though this 
structure will perform arguably well even if it is not unique.

#### sentiments table
This table is connected to the user_sessions table id, or equivalently to 
the composite key of user_id and sessions_id from the same table
(Keeping in mind the assumption of the uniqueness of the pair described in the table above)
As user can have multiple voice sentiments during the same session, 
I find that this way of strong the sentiment is the most effective, 
and most accessible from the back end or other applications.

#### events table
Additionally, I wanted to include events table which describe all the 
events that user has in a sessions. It is connected the user_sessions 
table with the same logic as the sentiments and basically keeps log of 
actions that user did, keeping all the timestamps inside, allowing to get 
timeline of users' journey inside a sessions.