output "dc_public_ip" {
  value = aws_instance.dc_server.public_ip
}

output "web_public_ip" {
  value = aws_instance.web_server.public_ip
}