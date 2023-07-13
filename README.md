# Jay's Handy Dandy Tooling Collection

This is a collection of the various scripts, playbooks, inventories, etc that I use to stand up and manage my 
internal homelab environment.

Note that this is all very heavily opinionated and designed for my needs, which are probably not exactly the same 
as your needs. Please use what you find useful, raise issues if you have questions/comments, and give me a PR if you
have suggestions. 

I've written a number of [blog posts](https://jayschmidt.us/series/homelab/) on my setup and how I use it, and there 
will be more to come. These posts document my experience, and you replicate them at your own risk. However, I do try
and ensure that they work properly (since these are my notes as well).

## My Environment

### Virtualization
I'm using [Proxmox](https://www.proxmox.com/en/) as my virtualization platform; it's simple to use, works great, and 
basically stays out of my way. Even better, it is integrated with [Ceph](https://ceph.io) which I use as both a block
and file store. Another advantage is that Proxmox allows you deploy both virtual machines and containers. The later
gives a great performance boost for use cases that don't require a full virtual machine.

The underlying hardware is all commodity based, mostly bought on the secondhand market and is more than sufficient 
for the work that I'm doing. 

### Network Attached Storage
One of my pandemic pastimes was to build out a home NAS system in a gigantic computer case I'd been lugging around for 
the last decade without a good use for. I crammed it full of disk, and installed IX Systems 
[TrueNAS](https://www.truenas.com/). 

This system provides backup targets for all the Apple devices in the house, my windows workstation, and all of the other
data I've been lugging around like a packrat for the last several decades. Because hardware doesn't last forever, I 
run a backup job from my NAS to [Backblaze](https://www.backblaze.com/) using their S3 compatible object store.

I also use the NAS to run a few critical infrastructure related virtual machine with the built-in BHYVE hypervisor
that comes as part of TrueNAS. These are systems such as my PiHoles, Unifi Control System, and log aggregator that
I don't want to be on any of my development systems since I have a nasty habit of breaking things. 

### PFSense Firewall
My internet comes in via both CenturyLink Fiber and T-Mobile 5G; sure it is a bit of overkill but both my wife and I 
work from home and having a failover is almost a necessity when you are regularly doing live sessions with customers
and colleagues. 

This is all managed via a [PFSense](https://www.pfsense.org/) device. In the past, I had always used the Netgate 
branded hardware but I ran into issues with CenturyLink and running PPPoE on the Netgate hardware, so I bought a small
["Micro PC / Firewall Appliance](https://a.co/d/2jZIMQL) and installed PFSense. This has been a rock solid addition
to the infrastructure here, and something I don't really ever need to touch.

### Unifi WAPs
You know, as a tech person, you refer to Wireless Access Points as WAPs. That's just how it's done. Then I find out 
that there is this song out there that is definitely not referring to networking gear. 

That said, I run the Unifi control app via docker on a VM running on my NAS, and have four of the access points covering
my house, garage office, and patio area. Is it overkill? Uh, yeah, but anything worth doing is worth overdoing.

### Raspberry Pies
I have a number of these in the computer room; they run things like my ntopng installation, my internal websites, a few
management tools, and my ADBS receiver for FlightRadar24. I also have Portainer running on top of these systems to make
managing the docker installations remotely a bit easier.
