The sample configuration scripts that come packaged with OpenVPN tell you to assign the IP 0.0.0.0 to the network interfaces that you want to bridge, assign an IP to the bridge, and then set them to promiscuous mode, but there is no explanation as to why. This has caused me and many others a great amount of confusion and frustration when it came to creating custom scripts for vpn bridging. For this post, I analyze why this certain configuration makes sense.

**Why assign an IP to the bridge and then change eth0 and tap0 to 0.0.0.0?**

This is actually a matter of convenience. We can assign an IP to the bridge interface and use that to talk over eth0 and tap0; eth0 and tap0 don't need their own IP anymore. It is perfectly fine for tap0 and eth0 to keep their IP's, doing it this way just saves you 2 IP addresses.

**What is promiscuous mode?**

Normally, interfaces only care about data that is addressed to it and ignore everything else. But you want your bridged interfaces tap0 and eth0 to care about everything on the network because they have to transport it across the bridge when necessary.
