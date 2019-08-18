# Project Title

ThoughtWorks MediaWiki Deployment

## Getting Started

These instructions will get you a mediawiki website up and running on AWS servers in your account. 

### Prerequisites

Configure your AWS credentials with default region as **ap-south-1**

```
aws configure
```

Initalize terraform in project cloned directory

```
terraform init
```

### Deployment

Following command creates infrastrucute, installs packages and deploys mediawiki web and db servers

```
terraform apply
```
