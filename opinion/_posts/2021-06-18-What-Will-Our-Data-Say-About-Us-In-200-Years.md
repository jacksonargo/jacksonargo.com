---
title: "What will our data say about us in 200 years?"
layout: post
tags: [data, machine learning]
author: Jackson Argo
---

Just two weeks ago, Russian scientists [published a paper](https://www.cell.com/current-biology/fulltext/S0960-9822(21)00624-2) explaining how they extracted a 24,000 year old living [bdelloid rotifer](https://en.wikipedia.org/wiki/Bdelloidea), a microorganism with exceptional survival skills, from Siberian permafrost. This creature is not only a biological wonder, but comes with a trove of genetic curiosities soon to be studied by biotechnologists. Scientists have found many other creatures preserved in ice, including [Otzi the Iceman](https://www.nationalgeographic.com/history/article/131016-otzi-ice-man-mummy-five-facts), a man naturally preserved in ice for over 5300 years. Unlike the rotifer, Otzi is a human, and even though he nor any of his family can give consent for the research conducted on his remains, he has been the subject of numerous studies. This research does not pose a strong moral dilemma for the same reason it is impossible to get consent, he has been dead for more than five millennia, and it’s hard to imagine what undue harm could affect Otzi or his family. Frameworks such as the [Belmont Report](https://www.hhs.gov/ohrp/regulations-and-policy/belmont-report/read-the-belmont-report/index.html) emphasize the importance of consent from the living, but make no mention of the deceased. However, the dead are not the only ones whose data is at the mercy of researchers. Even with legal and ethical frameworks in place, there are many cases where the personal data of living people is used in studies they might have not consented to.

*A living bdelloid rotifer from 24,000-year-old Arctic permafrost.*

![image](https://user-images.githubusercontent.com/7391437/122631848-ba0fb800-d09c-11eb-8ac1-ba3d720ee02d.png)

It’s not hard to imagine that several hundred years from now, historians will be analyzing the wealth of data collected by today’s technology, regardless of the privacy policies we may or may not have read. Ortiz’s remains only provide a snapshot of his last moments, and this limited information has left scientists many unanswered questions about his life. Similarly, today’s data does not capture a complete picture of our world and some may even be misleading. Historians are no stranger to limited or misleading data, and are constantly filling in the gaps and revising their understanding as new information surfaces. But, what kind of biases will historians face when looking at these massive datasets of personal and private information?

## Missing in Action

To answer this question, we first look for the parts of our world that are not captured or underrepresented in these datasets. Kate Crawford gives us two examples of this in the article [_Hidden Biases in Big Data_](https://hbr.org/2013/04/the-hidden-biases-in-big-data). A study of Twitter and Foursquare data revealed interesting features about New Yorker’s activity during Hurricane Sandy. However this data also revealed it’s inherent bias; the majority of the data was produced in Manhattan and little data was produced in the harder-hit areas. In a similar way, a smartphone app designed to detect potholes will be less effective in lower-income areas where smartphones are not as prevalent.

For some, absence from these datasets is directly built into legal frameworks. GDPR, as one example, gives citizens in the EU the [right to be forgotten](https://gdpr.eu/right-to-be-forgotten/). There are some constraints, but this typically allows an individual to request that a data controller, a company like Google that collects and stores data, should erase that individual’s personal data from the company’s databases. Provided the data controller complies, this individual will no longer be represented in that dataset. We should not expect that the people who exercise this right are evenly distributed in some demographic. Tech savvy and security-conscious individuals may be more likely to fall into this category than others. 

The US has [COPPA](https://www.ftc.gov/tips-advice/business-center/privacy-and-security/children%27s-privacy), the children’s privacy act, which puts heavy restrictions on data that companies can collect from children. Many companies, such as the discussion website Reddit, chose to omit children under 13 entirely in their [user agreements](https://www.redditinc.com/policies/user-agreement) or terms of service. Scrolling through the posts in [r/Spongebob](https://www.reddit.com/r/spongebob/), a subreddit community for the tv show Spongebob Squarepants, might suggest that no one under 13 is talking about Spongebob online.

## Context Clues

For those of us who are collected into the nebulous big data-sphere, how accurately does your data actually represent you? Data collection is getting more and more sophisticated as the years go on. To name just a few sources of your data, virtual reality devices capture your motion data, voice controlled devices capture your speech patterns and intonation, and cameras capture your biometric data like faceprints and fingerprints. There are even now [devices that interface directly with the neurons in primate brains](https://www.youtube.com/watch?v=rsCul1sp4hQ) to detect intended actions and movements. 

Unfortunately, this kind of data collection is not free from contextual biases. When companies like Google and Facebook collect data, they are only collecting data particular to their needs, which is often to inform advertising or product improvements. Data systems are not able to capture all the information that they detect; this is far too ambitious, even for our biggest data centers. A considerable amount of development time is spent deciding what data is important and worth capturing, and the result is never to paint a true picture of history. Systems that capture data are designed to emphasize the important features, and everything else is either greatly simplified or dropped. Certain advertisers may only be interested in whether an individual is heterosexual or not, and nuances like gender and sexuality are heavily simplified in their data. 

Building an indistinguishable robot replica of a person is still science fiction, for now, but several ai based companies are already aiming to [replicate people and their emotions through chatbots](https://www.wired.com/story/replika-open-source/). These kinds of systems learn from our text and chat history from apps like Facebook and Twitter to create a personalized chatbot version of ourselves. Perhaps there will even be a world where historians ask chatbots questions about our history. But therein lies another problem historians are all too familiar with, the meaning of words and phrases we use today can change dramatically in a short amount of time. This is, of course, assuming that we can even agree on the definition of words today.

In the article [_Excavating AI_](https://excavating.ai/), Kate Crawford and Trevor Paglen discuss the political context surrounding data used in machine learning. Many machine learning models are trained using a set of data and corresponding labels to indicate what the data represents. For example, a training dataset might contain thousands of pictures of different birds along with the species of the bird in the picture. This dataset could train a machine learning model to identify species of birds from satellite images. The process begins to break down when the labels are more subjectively defined. A model trained to differentiate planets from other celestial bodies may incorrectly determine that [Pluto](https://www.loc.gov/everyday-mysteries/item/why-is-pluto-no-longer-a-planet/) is a planet if the training data was compiled before 2006. The rapidly evolving nature of culture and politics makes this kind of model training heavily reliant on the context of the dataset’s creation.

*A Venezuelan Troupial in Aruba*

![image](https://user-images.githubusercontent.com/7391437/122631844-aa906f00-d09c-11eb-8630-f60b7dbd1474.png)

## Wrapping Up

200 years from now, historians will undoubtedly have access to massive amounts of data to study, but they will face the same historical biases and misinformation that plague historians today. In the meantime, we can focus on protecting our own online privacy and addressing biases and misinformation in our data to make future historians’ job just a little easier.

Thank you for reading!

## References

* https://www.cell.com/current-biology/fulltext/S0960-9822(21)00624-2
* https://www.nationalgeographic.com/history/article/131016-otzi-ice-man-mummy-five-facts
* https://www.hhs.gov/ohrp/regulations-and-policy/belmont-report/read-the-belmont-report/index.html
* https://hbr.org/2013/04/the-hidden-biases-in-big-data
* https://gdpr.eu/right-to-be-forgotten/
* https://www.ftc.gov/tips-advice/business-center/privacy-and-security/children%27s-privacy
* https://www.wired.com/story/replika-open-source/
* https://excavating.ai/
