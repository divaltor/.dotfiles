## Standarts

When edit any Opentofu or Ansible files ensure it is up to date with other part. Ansible and Terraform are coupled together into single setup layet. Terraform setup Proxmox and resources in it, Ansible setups VMs, LXC and other stuff Opentofu can't.

## Homelab specs

Hardware

- CPU: AMD Ryzen AI 9 HX PRO 370 (12C/24T, Zen 5/5c, AVX-512 VNNI)
- iGPU: Radeon 890M, 16 CU RDNA 3.5, ~5.3 TFLOPS FP16, shares system RAM
- NPU: XDNA 2, 50 TOPS
- RAM: 64 GB total (DDR5 4800 CL40)
- Disks:
- System: 128 GB AirDisk used by Proxmos host
- VMs storage: 500 GB Samsung 970 EVO Plus NVMe
- ZFS Pool (files, archives, media): 4 disks Seagate IronWolf 6 TB in ZFS Z1 raid

Any containers and VMs should provide host CPUs to get maximum performance from modern CPU instructions, not virtualized one.

## Other

For any additional info how to run Opentofu or Ansible read README.md
