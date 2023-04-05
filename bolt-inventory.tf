resource "local_file" "bolt_inventory" {
  content = templatefile("bolt-inventory.tmpl",
    {
      ssh_bastion_host_a_ip   = aws_instance.ssh_bastion_a.*.public_ip,
      ssh_bastion_host_a_name = aws_instance.ssh_bastion_a.*.tags.Name,
      ssh_bastion_host_b_ip   = aws_instance.ssh_bastion_b.*.public_ip,
      ssh_bastion_host_b_name = aws_instance.ssh_bastion_b.*.tags.Name,
    }
  )
  filename = "bolt-inventory.yaml"
}
