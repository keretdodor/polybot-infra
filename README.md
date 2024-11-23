# The Polybot Project

The Polybot Project is a Telegram bot developed using Python and integrated with a REST API to leverage the YOLOv5 AI model for image and photo analysis. The primary goal of this project is to provide human-readable insights from analyzed images in a seamless and user-friendly manner.

To support its functionality, the project is deployed on AWS using an infrastructure designed with Terraform, organized into modules for clarity and maintainability.

To streamline development and operations, I implemented three distinct CI/CD pipelines that automate the infrastructure setup and development workflows, creating a robust and efficient environment for continuous development.

# The Infrastructure

![alt text](polybot-infra.png)

To ensure high availability, I have created the infrastructure on two different Availability Zones with two different subnets.

# Brief Overview
 
 **1. Telegram Bot (Polybot)**
 * Pulls Telegram token from **AWS Secret Manager**
 * Users upload images through Telegram
 * The Image is being stored in an S3 bucket 
 * A SQS queue is being sent to the YOLOv5 instances with the image details in JSON format.


 **2. YOLOv5** 
 * Pulls the image from the S3 bucket using the SQS queue details.
 * Analyzing the data with the YOLOv5 AI model, storing the analyzed image on s3 bucket and stores the output values in a **DynamoDB Table**

**3. Conta





## The Telegram Bot (Polybot) Instances

I have deployed two instances of the Telegram bot on each subnet with docker. They are not using an Autoscaling Group since most of the proccesses will happen of the YOLOv5 instances. 
The two polybot instances being grouped in the same **target group** that is connected to an **Application Load Balancer** ,  
![alt text](cars.png)
![alt text](cats.png)
