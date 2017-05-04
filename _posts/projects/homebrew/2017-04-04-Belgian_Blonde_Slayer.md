---
title: "Belgian Blonde - SWMBO Slayer"
date: 2017-03-23
author: suttonbm
layout: post
categories:
  - projects
tags:
  - homebrew
  - beer
project: homebrew
excerpt: >
  My first partial mash attempt!
---

After a few (6?) batches under my belt using extract and steeped grains, I started feeling the itch to try out some more interesting recipes.  A lot of the cool looking ones out there also happen to be all-grain only.  I'm a bit space constrained in my apartment, so going full all-grain with the three-pot process seemed a bit out of reach for me.  Thus, I decided to try out partial mash with BIAB.  I have one three-gallon pot, and one two-gallon pot to work with.  I'm shooting for a 2.5 gallon batch in the bottle, so the fermentation volume should be ~2.6 gallons to account for trub loss.

For my first recipe I'm going to try a belgian blonde, courtesy of [homebrewtalk](http://www.homebrewtalk.com/showthread.php?t=26599)

### Planning
I'll be using BIAB with single-step mash (no sparge).  Mash thickness will be targeted at 1.7 qt/lb grain.  I'll also be taking advantage of my homemade sous-vide pump to circulate water and maintain temperature throughout the mash.  PID controller was previously auto-tuned to the volume of water and target temperature.

Since this is my first-ever all-grain attempt, I really don't have any idea what efficiency to expect.  I'll be collecting data throughout the process in order to calculate for future batches.

#### The Specifications
**Style:** Belgian Blonde
**Batch Size:** 2.65 gal
**SRM:** 5.2
**IBU:** 19
**OG:** 1.057
**FG:** 1.015

#### Ingredients
| Weight | Ingredient | Type | Pct |
| --- | --- | --- | --- |
| 3 lbs | Pale Malt (2 Row) US (2.0 SRM) | Grain | 50.2 % |
| 2 lbs | Wheat Malt, Bel (2.0 SRM) | Grain | 33.5 % |
| 4.0 oz | Caramel/Crystal Malt - 10L (10.0 SRM) | Grain | 4.2 % |
| 4.0 oz | Wheat, Flaked (1.6 SRM) | Grain | 4.2 % |
| 2.0 oz | Caravienne Malt (22.0 SRM) | Grain | 2.1 % |
| 5.6 oz | Extra Light DME (late addition) | Grain | 5.9% |
| 0.6 oz | Willamette @ 60min | Hops | |
| 1 pkt | Safbrew T-58 | Yeast | |

#### Brew Process
| Mash Step | Description | Temp | Time |
| --- | --- | --- | --- |
| Prep | Measure 9.5qt water in mash pot | | |
| Mash In | Add grain to pot and stir | 164F | |
| Sacch | Hold temp for required time | 152F | 75 min |
| Mash Out | Heat to mash-out temp and Hold | 168F | 10 min |
| Drain | Pull out grain bag and let drain | | |
| Squeeze | Place bag in collander over second pot and squeeze | | |
| Top Up | Target pre-boil 1 qt | | |
| Measure | Collect pre-boil vol, SG | | |

From here, follow boil and hops addition as listed in the ingredients.  Since this is my first AG batch, will need to adjust late extract addition to hit target SG (see below)

### Brew Day Notes
I didn't capture

#### Mash Process
| Mash Step | Temp Tgt. | Temp Act. | Time Tgt. | Time Act. |
| --- | --- | --- | --- | --- |
| Dough In | 164F | 163F | | |
| Sacch | 152F | 155F (avg) | 75min | 75min |
| Heat On | 168F | ---F | 7min | -min |
| Mash Out | 168F | ---F | 10min | --min |

For some reason, I had a bit of trouble with (a) maintaining temp (mash temp ended up being closer to 156F) and (b) keeping the recirculation going.  The pump kept wanting to clog up somehow with the tubes stuck in the pot.  I may need to explore some better options, for e.g. install an outlet at the bottom.  Also a bit tricky dealing with the temp sensor, may want to look into putting that into the pot as well (or install a different one permanently).

Also had some trouble with the burner trying to turn on with the bag on the bottom of the pot.  I think it might really be useful to put in a false bottom or something which supports the bag so that the PID can work without crazy intervention.  Hopefully I didn't burn the bag :(.

Good news - the bag didn't burn, but I forgot the mash-out...

#### Efficiency
| Step | Tgt Vol | Act Vol | Tgt SG | Act SG |
| --- | --- | --- | --- | --- |
| Post-Mash | 2.07 gal | 2.13 gal | 1.067 | 1.055 |
| Post-Boil | 1.65 gal | 1.54 gal | | |
| Top-Up | 1.00 gal | 1.10 gal | | |
| Into Fermenter | 2.65 gal | 2.25 gal | 1.057 | 1.070 |
| Trub Loss | TBD oz | 0 oz | | |

1.048 @ 106F
Based on the above, my achieved mash efficiency was 55.7%.
Calculated boil-off rate was 0.6 gal/hr.

Unfortunately, I was short on top-up water, so hopefully I can get away with topping up later in the fermenter.

#### Adjustments
Based on the mash efficiency, I made the following adjustments for IBU and OG:

Hops:
- Recipe @ 0.6oz
- Actual @ 0.5oz

DME:
- Recipe @ 5.6oz
- Actual @ 12.8oz

#### Fermentation Plan
Acceptable temp range for T-58 is 59-68F.  I'm shooting for 65F ambient temp using a swamp cooler.

#### 4/30/17
Racked to secondary.  FG 1.008.  Calculated ABV 6.67%, apparent attenuation 86%.

Nose: Malty, maybe some slight bananas?  Fairly dry mouthfeel with ever-so-slight residual sweetness.  Almost no noticable bitterness.  Very little alcohol taste.  Noticed that my sample precipitated quite a bit of yeast during cooling, so may need to consider fining or cold clearing this before bottling.

Comments: Clearly this over-attenuated.  There are many factors which may have come into play to cause this.  First, because my mash efficiency was so low, I had to add far more DME than expected.  If the fermentability of the DME was high, then FG should be low.  Second, I used a different yeast than the orignal recipe called for; this yeast may have higher expected attenuation.  I haven't researched it.  I don't think this will end up being a bad beer; I'll just have to wait and see how it turns out after bottling.
