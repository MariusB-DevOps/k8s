Instructions for EKS deployment on AWS

The working directory is: "aws"
It contains the following files:
.gitignore
terraform.tf
variables.tf
vpc.tf
outputs.tf
eks-cluster.tf
main.tf
backend.tf

The terraform.tf file defines our required providers, their sources, and the required versions we want to use.

The main.tf file defines our provider configurations with a Kubernetes module, and defines the AWS region via a variable. The data block pulls the available availability zones within the set region and creates a data set of these zones. The locals variable cluster_name uses a random string to create a unique EKS cluster name. The random string constraints are defined in the resource block.

The vpc.tf file calls the VPC module from the official Terraform public module registry. We define our CIDR block, availability zones (pulling them from our availability zone data block we created earlier), and public and private subnet CIDRs. We then enable a NAT gateway and DNS hostnames. Lastly we give the public and private subnets tags that reference the local variable we created earlier.

The eks-cluster.tf file calls the EKS module from the official Terraform public module registry. The cluster name is defined using the local variable we created earlier. We can connect the EKS cluster to the VPC and subnets defined earlier by calling the VPC ID and private subnet IDs from the VPC module. We want the cluster to have public access, so set this to true. Define the AMI type using the EKS managed node group defaults argument. Next, define the managed node groups, including the instance types, minimum, maximum, and desired size.

The variables.tf file defines the region variable that we referenced earlier. Change the default region to the one you want to use.

The outputs.tf file defines the outputs we want printed to the CLI.

The backend.tf file defines the backend we will use ( in my case a s3 bucket to store the state ).

The .gitignore file contains a list of files / folders excluded from git.
