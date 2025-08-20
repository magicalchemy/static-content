# MA DeFi Part

**Magic Alchemy (MA)** is a P&E game with an economy built on classic farming (liquidity mining), NFT staking, and familiar mechanics like harvesting, crafting, and a card game.

## Core Mechanics and Tokens
In Magic Alchemy, there are two types of tokens (all tokens are on-chain):

* **POTION** — the primary token of the game.
* **Game Tokens (10 types)** — level-based tokens earned by progressing through the game, specifically through NFT Alchemist staking and farming in-game pools.

![](defi1.2x.png)
![](defi2.2x.png)
![](defi3.2x.png)

We’ve completely reimagined the liquidity pool structure of decentralized exchanges, presenting it as a cauldron of potion brewing. To brew, you need two ingredients: the main catalyst, POTION, and one of the 10 game potions (tokens). By combining the primary POTION token with each game token, we create 10 in-game liquidity pools (VALA/POTION, MIATA/POTION, etc.).

Players earn game tokens through NFT Alchemist staking and farming in these pools. By burning a portion of rewards and earning experience points (see Alchemist Leveling), players can level up, unlock higher-value pools (to brew more valuable potions), and progress through the game.

![](defi4.2x.png)

Engaging gameplay is driven by competition, seasonal events, and a range of economic strategies for progressing through levels. The game features varied pool settings, guild collaborations, a unique storyline, and stunning visuals paired with original music.

![](defi5.2x.png)

The gameplay’s core value lies in building skills for interacting with DEX (decentralized exchange) smart contracts, liquidity pools, and liquidity provision. Advanced players can also delve into on-chain analytics, tracking other players’ actions to maximize their own profits.

Players can enjoy both DeFi (decentralized finance) and F2P (free-to-play) modes, playing intensively or casually between episodes of their favorite shows. The genre aligns with idle games, making it easy to fit into any schedule.

## DeFi Features of Magic Alchemy (MA)
Access to potion brewing (liquidity actions like buying, selling, and farming in game pools) is granted through staked NFT Alchemists. However, all users have unrestricted access to the main POTION/USDT pool, ensuring everyone can engage with core liquidity regardless of staking status.

To minimize Pay-to-Win mechanics and limit potential Impermanent Loss (IL), farming in game pools has a liquidity cap per player, which is the maximum liquidity eligible for rewards. For instance, a pool limit of $500 means that even if a player supplies liquidity worth $1,000, rewards will only be calculated based on $500.

The liquidity cap per player increases demand for POTION, making it a key utility of the token. For example, with an initial POTION price of $1 in the POTION/USDT pool, if there are 3,000 Alchemists, each needing $500 of liquidity (equal to 500 POTION), a total of 1.5 million POTION would be required across all players. However, the initial circulating supply of POTION among players is only 875,000, a lower amount. Additionally, liquidity mining in the POTION/USDT pool provides daily rewards of at least 5,479 POTION, drawing part of the circulating supply into this pool, further reinforcing POTION’s utility. The anticipated APR for the POTION/USDT pool could be around 150–300%.

As the game progresses, the circulating supply of POTION will increase, but demand will also rise with the influx of new players and as the liquidity caps on game pools are adjusted upward. The game’s tokenomics also ensure a fair DeFi environment, as Alchemists do not need to worry about unlocks from investors or the team, allowing for a balanced competition among DeFi players.

![](defi6.2x.png)

Let’s break down how liquidity rewards work in the main POTION/USDT pool. Imagine POTION is priced at $1, with 5,479 POTION tokens distributed daily among pool farmers.

Player 0notole plans to provide liquidity worth $500. This can be done manually by:

1. Swapping half of the USDT for POTION.
2. Adding 250 USDT and 250 POTION to the liquidity pool.
3. Staking the resulting LP tokens.

Alternatively, all of these steps can be done in one go, with our smart contract handling the entire process in a single transaction. This means 0notole only needs USDT to add liquidity to the main pool, without needing POTION beforehand.

At game launch, 0notole and 99 other players each contribute $500 to the pool, making the total player liquidity $50,000.

Additionally, if the Warchest adds, say, $450,000 in liquidity to the pool, players receive 10% of the daily reward of 5,479 POTION, equating to 547 POTION distributed among them. 0notole would earn 5.47 POTION per day, representing an approximate 400% APR based on his liquidity.

*This is just an example based on assumed conditions.*

Beyond the core utilities of POTION, the token is essential for purchasing in-game characters, boosters, and NFT parts. In Magic Alchemy, POTION is more than just another Web3 token; it’s the backbone of gameplay, driving demand beyond speculative interest seen in most other Web3 games.

Note that access to specific in-game pools requires an Alchemist of the corresponding meta-level (see table).

![](defi7en.2x.png)

An Alchemist of meta-level n can trade in game pools corresponding to meta-levels 1 through n+1, but can only farm in the pool that matches their exact meta-level n.

To maintain a balanced in-game economy, Alchemists also have stamina and power attributes linked to each meta-level, functioning as motivators and constraints, the “carrot and stick” that encourage progress and discourage stagnation.

![](defi8.2x.png)

Stamina represents fatigue, decreasing if an Alchemist remains too long at the same level, making it harder to earn resources. This feature incentivizes players to progress to higher levels rather than “camp” in one pool. Technically, this is a reduction in the Stamina coefficient (Sc) based on tokens earned from the current game pool (see table).

*Table parameters may be adjusted before the game launch.*

![](defi9en.2x.png)

For example, let’s say both a common and a legendary Alchemist have $500 liquidity in the MIATA/POTION game pool. Suppose leveling up requires burning 100 MIATA tokens, meaning 100 MIATA equals 100% of the required tokens for leveling up. If an Alchemist earns 10 tokens per hour with this liquidity, both common and legendary Alchemists will farm at this rate until the common Alchemist reaches 101%, or 101 MIATA.

From 101% to 105% (101 to 105 MIATA), the common Alchemist’s farming rate drops to 50% (Sc=0.5), earning 5 tokens per hour with $500 liquidity, while the legendary Alchemist continues farming at 10 tokens per hour (Sc=1). When the common Alchemist farms MIATA tokens from 110% to 115%, their Sc reduces to 0.2, earning tokens at only 20% of the default rate, or 2 tokens per hour with $500 liquidity. The legendary Alchemist’s farming rate remains at 10 tokens per hour until reaching 115 MIATA.

This reduced farming rate continues until the Alchemist levels up within the meta-level. Upon leveling up, the required tokens for the next level-up increases by 100 MIATA, meaning 100% of the required tokens now equals 200 MIATA. If a common Alchemist has farmed 114% or 114 MIATA by the first level, with an Sc of 0.2, upon leveling up, they are considered to have farmed 114 MIATA out of the new 200 MIATA, bringing them below 101%. This resets their Sc to 1, restoring the farming rate to normal.

So, with each level-up, both fatigue and farming rate are fully restored to their default values.

Thus, rarer Alchemists can gain a greater advantage from progressing through game pools (farming more tokens without a penalty to farming speed). However, this doesn’t impact the speed of game progression, as all Alchemists farm the required 100% of tokens for leveling up with the same Sc coefficient.

From the example above, a legendary Alchemist can farm 140 more MIATA tokens per meta-level without a speed penalty compared to a common Alchemist.

![](defi10.2x.png)

An Alchemist’s power represents their experience and skill in potion brewing (see table). Each Alchemist has a Power coefficient (Pc), which corresponds to their level within a meta-level, increasing from 1 to 1.15 as they level up. When an Alchemist advances from, say, level 19 to 20 — thus moving from meta-level 2 to meta-level 3 — the Pc resets to 1.

![](defi11en.2x.png)

## Reward Calculation Formulas (for the especially curious)
The potential rewards for the i-th Alchemist at k-th meta-level, Mi,k, are determined as follows:

![](defi12.2x.png)

where Sk is the default reward amount for the k-th meta-level, set before the launch of the k-th pool based on the current price of POTION,

Sci,k and Pci,k — accordingly, the Stamina coefficient and Power coefficient of the i-th Alchemist at the k-th meta-level.

The staking rewards for the i-th Alchemist at the k-th meta-level, Msi,k, are determined as follows:

![](defi13.2x.png)

where Nk is the staking reward share for the k-th meta-level.

The farming rewards for the i-th Alchemist at the k-th meta-level, Mfi,k, are determined as follows:

![](defi14.2x.png)

LPi,k — the liquidity of the i-th farmer-Alchemist at the k-th meta-level.;

DLPk — the default maximum allowable liquidity size for the k-th meta-level.

## Alchemist Leveling
Additionally, the DeFi portion of the game includes off-chain mechanics related to growing and collecting ingredients needed for potion crafting.

![](defi15.2x.png)

To level up an Alchemist, players must:

* Burn a certain number of game tokens (on-chain mechanic)
* earn a specific amount of experience points by crafting potions of the required difficulty level (off-chain mechanic)

Tokens for leveling up an Alchemist can be earned through staking and farming or simply purchased on the market.

![](defi16.2x.png)

The economic model includes a mechanism to support previous pools: to level up an Alchemist, players must burn not only the current meta-level token but also the token from the previous level. This ensures that as players progress, they contribute liquidity to earlier game pools, even if the leading players are already operating in the next pool. This design keeps the economy of all game pools active and balanced throughout the game. The table of required tokens for Alchemist level-ups is shown below:

![](defi17en.2x.png)

The off-chain mechanic serves to both reduce Pay2Win elements (where players might only purchase tokens to level up their Alchemist) and to gamify the storyline progression.

Here’s how the off-chain game mechanic works: The Alchemist receives a potion-making quest, requiring them to grow and collect specific plants. To streamline and maximize ingredient collection, they can hire an NFT goblin gardener once all required ingredients are gathered.

![](defi18.2x.png)

In the Laboratory, the Alchemist crafts potions, with potion purity determined by the equipment used, which can vary in condition — such as broken, basic equipment, or NFT equipment. For simplicity, we’ll refer to this equipment as “boosters.” Besides purity, boosters also affect potion brewing speed, which, depending on the combination and condition of boosters, can range from 5 minutes to several days, from fully functional NFT boosters to entirely broken ones. The economy of the F2P part of the game revolves around managing and repairing these boosters.

## The F2P Component of Magic Alchemy (MA)
Both non-NFT and NFT boosters have durability points and break after a certain number of uses. Once a booster is broken, the Alchemist can either purchase a new NFT booster or use NFT parts to repair their existing booster, whether it’s an NFT or non-NFT. While NFT boosters enable faster potion brewing compared to non-NFT boosters, both types require NFT parts for repairs.

![](defi19.2x.png)

NFT parts can only be crafted in the Workshop, using raw materials bought from a trader for silver coins, which are earned by playing the PvP card game. The card game is open to everyone, including free-to-play players. Available NFT repair specialists help players earn silver coins faster for purchasing materials, while NFT workshops speed up part production.

Alchemists leading the charge in potion brewing gain economic bonuses as they transition to new pools. Meanwhile, players working to catch up are motivated to level up faster. Seasonal rewards add further economic incentives for using NFT boosters, creating a dynamic and engaging progression system.

## Subsidization

![](defi20.2x.png)

Additionally, subsidies are available to players using NFT parts to repair NFT boosters. These subsidies make it economically beneficial for Alchemists to purchase parts, effectively broadening the funnel for F2P players and setting off a conversion flywheel that turns F2P players into Alchemists.

Our system is designed to be organic, allowing F2P players to start directly in the Telegram app. For these players, a crypto wallet using account abstraction (AA wallet) is automatically created by the third-party provider, Dynamic (www.dynamic.xyz), making onboarding seamless (https://www.dynamic.xyz/blog/account-abstraction). Once an F2P player earns value in-game, they’ll be able to craft their first NFT part, sell it, and gain real profit. Silver coins and raw materials for NFT parts are managed in the game’s backend, not on the blockchain.

![](defi21.2x.png)

*F2P Card Game (Arcomage ref.)*

## Game Seasons
The entire DeFi component of Magic Alchemy is divided into seasons, during which top Alchemists and guilds are determined, and POTION rewards are distributed from the massive Game Rewards pool. Both newcomers at meta-level 1 and the advanced potion brewers have equal chances to secure top spots in the individual and guild leaderboards.

* **Individual Leaderboard** — Based on points earned for the number and purity of potions brewed. Potion purity depends on NFT boosters, adding a skill element to brewing.
* **Guild Leaderboard** — Calculated from the combined points of a set number of guild members. Initially, only legendary Alchemists will be able to create guilds, with this feature later expanding to epic Alchemists.
* **Completion Leaderboard** — Tracks all Alchemists and their levels by the end of the game. Rankings are based on level and the time taken to achieve it. The game concludes when Alchemists reach level 100.
## Basic Alchemist Auctions
![](defi22.2x.png)

During the Token and NFT Marathon, genesis Alchemists of various rarities are distributed. With the game’s launch and as the player base grows, auctions for basic common Alchemists may be introduced, providing new players access to Magic Alchemy’s DeFi elements.

To address concerns about a potential dump on the secondary NFT market, auctions can only be held if the marketplace Floor Price of common genesis Alchemists exceeds the auction price of a common genesis Alchemist (A1). The price of such an Alchemist at the Marathon will be determined based on the final Marathon results, following this formula:

![](defi23.2x.png)

where Fc and Pc represent the average cost of a common flask over 42 hours of the Marathon and the probability of obtaining a common Alchemist from a common flask, respectively.

## Warchest
![](defi24.2x.png)

In the game’s economic model, the SAFU Fund, or Warchest, plays a vital role by collecting all profits from NFT sales and pool and marketplace fees. The Warchest supports the value of Alchemist rewards, effectively backing the POTION token, ensuring POTION is safeguarded from dropping to zero.

Players benefit from activity and volume in the main and game liquidity pools, NFT marketplace transactions, and an expanding player base, which drives sales of basic Alchemists and auxiliary NFT characters (repair specialists, gardeners, boosters, and parts). It’s important to note that the Warchest is funded exclusively in stable currency, USDT.

## Summary
![](defi25.2x.png)

Through gamified smart contract interactions, Magic Alchemy opens the doors to the decentralized world of blockchain, DeFi, NFTs, and the broader Web3 ecosystem. The opportunity to monetize gameplay and the rich lore of the Magic Alchemy universe serve as additional incentives for users, while an intuitive UX/UI eases them into the game’s core mechanics.

The game’s economic architecture is balanced to appeal to a wide range of users, and the use of the Warchest — accumulating USDT as the project grows in popularity and attracts new players — helps preserve value for players, investors, and token holders alike.

## FAQ
**1. What tokens are available in Magic Alchemy, and what are they used for?**

The game features two types of tokens:

* POTION: The primary game token, used for purchasing in-game characters, boosters, and NFT components. It is also a key element in liquidity mechanics and gameplay progression.
* Game Tokens (10 types): Tier-based tokens earned by staking NFT Alchemists and farming in-game liquidity pools. These tokens are essential for leveling up, burning for experience points, and unlocking access to higher-value pools.
* 
**2. Why are NFT Alchemists important?**

* Access to DeFi Mechanics: Only NFT Alchemist owners can participate in the main DeFi aspects of the game, including staking and farming.
* Unique Art: Every Alchemist has a hand-drawn, unique design, which may attract collectors interested in rare characters.
* Passive Income: After the Token Marathon, players can stake their Alchemists to earn POTION tokens.

**3. How do NFT Alchemists differ?**

The rarity of an NFT Alchemist determines:

* Stamina Level: Legendary Alchemists can farm 14% more tokens without farming speed penalties compared to common Alchemists.
* Guild Creation: Only owners of Legendary Alchemists (and later Epic Alchemists) can establish guilds.
* Increased Rewards: Legendary Alchemists receive additional POTION bonuses if their guilds achieve leaderboard victories.

**5. What is required to access potion brewing and in-game liquidity pools?**

To access potion brewing (buying, selling, and farming), you must stake an NFT Alchemist. However, the main POTION/USDT pool is open to all users without restrictions.

**6. What drives the demand for POTION tokens?**

The demand for POTION is shaped by:

* Liquidity pool limits in in-game mechanics.
* Utility: It is used to purchase in-game characters, boosters, and NFT components.
* Player growth and the increased liquidity limits in advanced pools.