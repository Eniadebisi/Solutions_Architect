output "public_instance_id" { value = aws_instance.public.id }
output "public_instance_ip" { value = aws_instance.public.public_ip }
output "public_instance_dns" { value = aws_instance.public.public_dns }
output "private_instance_id" { value = aws_instance.private.id }
