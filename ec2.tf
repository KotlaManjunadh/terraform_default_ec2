# provider 

provider "aws" {
    region = "us-east-1"  
}

# data

data "aws_vpc" "default" {
    default = true
}

# output "vpc_ids" {
#     value = data.aws_vpc.default.id  
# }
data "aws_subnets" "default" {
    filter {
      name = "vpc-id"
      values = [data.aws_vpc.default.id]
    }
}

data "aws_subnet" "default" {
    id = tolist(data.aws_subnets.default.ids)[0]
    # filter {
    #     name = "vpc-id"
    #     values = [data.aws_vpc.default.id]
    # }
}

#resources sg,instance,routetable

resource "aws_security_group" "manju_ssh" {
    name_prefix = "manju_ssh"
    vpc_id = data.aws_vpc.default.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}

resource "aws_instance" "manju_ec2" {
    ami = "ami-0a0e5d9c7acc336f1"
    instance_type = "t2.micro"
    subnet_id = data.aws_subnet.default.id
    security_groups = [aws_security_group.manju_ssh.id]
    key_name = "testing"
    tags = { 
      name = "manju-ec2"
    }
    associate_public_ip_address = true
}


#output to know id of ec2

output "instance_public_ip" {
    value = aws_instance.manju_ec2.public_ip
}

output "instance_id" {
  value = aws_instance.manju_ec2.id
}