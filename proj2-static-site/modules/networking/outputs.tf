output "vpc_id"            { value = aws_vpc.main.id }
output "public_subnet_id"  { value = aws_subnet.public.id }
output "private_subnet_id" { value = aws_subnet.private.id }
output "public_sg_id"      { value = aws_security_group.public_ec2.id }
output "private_sg_id"     { value = aws_security_group.private_ec2.id }
