provider "aws" {
    region = "us-east-1"   
}

# resources

resource "aws_vpc" "manju-vpc" {
    cidr_block = "17.0.0.0/16"
    tags = {
      Name = "manju-vpc"
    }
}

resource "aws_subnet" "m-public-subnet" {
    vpc_id = aws_vpc.manju-vpc.id
    cidr_block = "17.0.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "m-public-subnet"
    }  
}

resource "aws_subnet" "m-private-subnet" {
    vpc_id = aws_vpc.manju-vpc.id
    cidr_block = "17.0.2.0/24"
    availability_zone = "us-east-1b"
    tags = {
      Name = "m-prvt-subnet"
    }
  
}
resource "aws_security_group" "m-allow-ssh" {
    name_prefix = "m-ssh"
    vpc_id = aws_vpc.manju-vpc.id
    ingress = [{
        from_port = 22
        to_port =  22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    },
    {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ]
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    } 
}


resource "aws_internet_gateway" "m-internet-gateway" {
    vpc_id = aws_vpc.manju-vpc.id
    tags = {
      name = "m-internet-gateway"
    } 
}

# resource "aws_internet_gateway_attachment" "attachment" {
#     internet_gateway_id = aws_internet_gateway.m-internet-gateway.id
#     vpc_id = aws_vpc.manju-vpc.id
# }

resource "aws_route_table" "m-pub-rt" {
    vpc_id = aws_vpc.manju-vpc.id
    
    tags = {
      Name = "m-pub-rt"
    }
}

resource "aws_route" "rt-route" {
    route_table_id =  aws_route_table.m-pub-rt.id
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.m-internet-gateway.id
}

resource "aws_route_table_association" "rt-assign" {
    subnet_id = aws_subnet.m-public-subnet.id
    route_table_id = aws_route_table.m-pub-rt.id  
}

resource "aws_instance" "m-ec2-1" {
    ami = "ami-0a0e5d9c7acc336f1"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.m-public-subnet.id
    security_groups = [aws_security_group.m-allow-ssh.id]
    key_name = "testing"
    associate_public_ip_address = true
    tags = {
      Name = "m-ec2-1"
    }
}

resource "aws_instance" "m-ec2-2" {
    ami = "ami-0a0e5d9c7acc336f1"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.m-private-subnet.id
    security_groups = [aws_security_group.m-allow-ssh.id]
    key_name = "testing"
    tags = {
      Name = "m-ec2-2"
    }
}

resource "aws_lb" "m-lb" {
    name = "m-lb"
    load_balancer_type =  "application"
    security_groups = [aws_security_group.m-allow-ssh.id]
    subnets = [aws_subnet.m-public-subnet.id, aws_subnet.m-private-subnet.id]
    tags = {
      environment = "production"
    }
}

resource "aws_lb_target_group" "m-lb" {
    vpc_id = aws_vpc.manju-vpc.id
    name = "m-alb"
    port = 80
    protocol = "HTTP"  
    target_type = "instance"

}

resource "aws_lb_listener" "lb_listener" {
    load_balancer_arn = aws_lb.m-lb.arn
    port = 80
    protocol = "HTTP"
    default_action {
      type = "forward"
      target_group_arn = aws_lb_target_group.m-lb.arn
    }
}


resource "aws_lb_target_group_attachment" "m-lb-test" {
    target_group_arn =  aws_lb_target_group.m-lb.arn
    target_id = aws_instance.m-ec2-1.id
    port = 80
}

resource "aws_lb_target_group_attachment" "m-lb-test1" {
    target_group_arn =  aws_lb_target_group.m-lb.arn
    target_id = aws_instance.m-ec2-2.id
    port = 80
}


# output 

output "instance_ip_1" {
    value = aws_instance.m-ec2-1.public_ip  
}

output "instance_ip_2" {
    value = aws_instance.m-ec2-2.private_ip  
}

output "load_balancer" {
    value = aws_lb.m-lb.dns_name 
}
