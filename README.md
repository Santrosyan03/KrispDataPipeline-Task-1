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
git clone https://github.com/Santrosyan03/Krisp-Data-Pipeline.git
cd Krisp-Data-Pipeline
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