### Class 5.5 Armageddon

**Europe Region:**
- Planning Document: Europe Region
- Machine Type: General-purpose VM (e.g., n1-standard series)
- Image: Ubuntu 20.04 LTS
- VCIDR Range: 10.105.10.0/24
- Requirement: Hosts prototype gaming information on a RFC 1918 Private 10 net.
- Requirement: Not accessible from the Internet.

**Americas Region:**
- Planning Document: Americas Region
- Machine Type: Linux
- Image: [Specify appropriate Linux distribution and version]
- VCIDR Range: 172.16.0.0/24
- Requirement: Two regions with RFC 1918 172.16 based subnets.
- Requirement: Peering with HQ allows viewing the homepage only on port 80.

**Asia Pacific Region:**
- Planning Document: Asia Region
- Machine Type: Windows
- Image: Windows Server 2019
- VCIDR Range: 192.168.2.0/24
- Requirement: RFC 1918 192.168 based subnet.
- Requirement: Can VPN into HQ.
- Requirement: Only port 3389 (RDP) is open to Asia, no 80 or 22.
