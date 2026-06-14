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

## OpenTofu

All variables are named like `TF_VAR_*` and used by `tofu/variables.tf`

Run from the repository root:

```sh
op run --environment 5hfpicsmni2xf56r2dv5gumz5e -- tofu -chdir=homelab/tofu plan
```
