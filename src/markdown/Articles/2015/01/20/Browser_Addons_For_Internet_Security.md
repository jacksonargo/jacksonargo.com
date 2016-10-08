
Typical web browsing exposes our sensitive information and makes us a target for all kinds of malware. There isn’t a cure-all way to protect ourselves from this; if we are going to go out in public, we are putting ourselves at risk. Nonetheless, there are many effective methods to keep our information from just being easy takings for any neighborhood hacker. For this tutorial I will focus on beefing up our most important interface to the web, our web browser.

Choosing a web browser
I chose to use Firefox because it is truly FOSS, has a huge amount of addons available, and provides a level of virus security. Other browsers like Opera are fine too, but please, stop using IE. If your concern is truly internet anonymity, then I would also recomend not using Chrome since Google hasn’t had the best track record for good privacy policies. If you want to try something completely different, there are a huge amount of open source web browsers available; however, these are less likely to have important features and addons available.

Browser addons
Addons can do a lot for our privacy and security. There are plenty more security related addons than the one I’ve listed here, but I consider these the bare-essentials. With firefox, you can sync your extensions and settings from one Firefox installation to any other (helps to maintain sanity). For the serious security aware, this allows you to create a browser security profile that you can use anywhere that you use Firefox.

Adblock Plus
Adblock Plus provides two services: it blocks ads from loading which also prevents ads from droping cookies or malware on your computer. You can also whitelist websites that you trust to support them with ad based revenue. ABP isn’t perfect and will sometimes allow ads to get through, but any ads that get past adblock are not likely to be malicious (in most senses of the word).

Disconnect
Websites like to drop cookies on your computer that store local data such as login credentials so you can stay logged in to a specific website. Not all of the cookies that get placed on your computer are so innocent; some are used to track which websites you’ve visited, what you’ve searched, etc, to create targeted ads (or maybe something more sinister). Disconnect blocks these tracker connections and keeps websites unaware of the other websites you use. The developers also claim that it speeds up your browsing, so there’s that too. On a few occasions it can be annoying because it blocks you using the “sign in with google/facebook/twitter” feature on many websites, but the payoffs are well worth it.

LastPass
LastPass is a password manager, and what I write about it will mostly hold true for any password manager. I use LastPass because it also comes with a very handy phone app and supports several dual-factor authentication methods. As most security specialists will tell you, the weakest link in any security protocol is the password which can be dictionary attacked and cracked much faster than trying to break the encryption algorithm it unlocks. In terms of internet security, when we register for an account on some obscure internet board, we typically have to supply an email address and password. Most people always use the same email password pair for their internet accounts, and when the passwords are leaked from that obscure board, all of those accounts are now vulnerable. A password manager allows you to create a randomly generated “tough” password and store it in a database along with your login info so you don’t have to keep up with it yourself. Using one quickly becomes second nature and you may be surprised just how many accounts you can acquire in a years time.

HTTPS Everywhere
This addon doesn’t do much except request https sites on whatever server you are visiting. Https uses ssl and tls encryption to transmit your internet packets; without it you are sending unencrypted data that a packet sniffer could intercept.

Self-destucting Cookies
Self-destructing Cookies deletes all cookies associate with a website as soon as you navigate away from it. This is really nice to have on hand if you using a public machine as it will keep you from accidentally staying logged on. Otherwise it is an annoying overkill (unless you are seriously security conscious). If you choose to regularly use it, you can combine this with LastPass’s auto login feature to somewhat seamlessly automatically login and out of any website you visit.
