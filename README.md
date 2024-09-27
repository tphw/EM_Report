# **Elephant Money Flaw Report**
## **Summary:**
<p align="justify">
  This is a report about a flaw discovered in a unverified contract (0x6839e295a8f13864A2830fA0dCC0F52e71a82DbF) of the Elephant Money project of the Binance Smart Chain. This flaw has a critical impact on the Trunk token (0xdd325C38b12903B727D16961e61333f4871A70E0), as it depends on the price of Trunk to be exploited, the damage will increase as the price of Trunk increases. For example, on July 21, with Trunk's price at $1.59 per token, direct losses would have been $1,016,968 with Trunk falling from 1.59 to 1.01, a 36 percent. Basically, there is a function (sweep()) in the vulnerable contract with no access control that allows a bad actor to trigger a cascade of swaps, which through flash loans and price manipulation of some assets could seriously harm EM users. I provide POCs using foundry to demonstrate what Im talking about. BUT, It's not all bad news, I have also discovered how to solve it !!! Below a detailed explanation of how this exploit is possible and how to avoid it.
</p>

## **Sweep calls flow:** 
  The sweep() function of the vulnerable contract is complex and it has various steps. Therefore, for ease of understanding, I won't explain each function steps, but rather give you a general idea of ​​how it works: 

  - Get Trunk balance of "Vulnerable contract". _deposit is the Trunk token.
    
  ![Alt text](images/image1.png)

  - Get amount out of Busd if we sell the balance of "Vulnerable contract" in the Trunk/Busd pair.
  
  ![Alt text](images/image2.png)
  
  - If boolean variable stor_6_20_20 is true (this variable at the moment is set to True), the output of getAmountsOut() if we sell the Trunk balance of the vulnerable contract in the Trunk/Busd pool is compared with the balance of the Trunk balance   of the vulnerable contract multiply by 99/100 , because variable _slippageRate is set to 1. MEM[64 + MEM[64]] memory position is the output of getAmountsOut().
  
  ![Alt text](images/image3.png)

  - If v15 is false, the sweep() function will revert because to call redeem() in _reserve contract(0xA70A8dc7BDf000c8f9374C5B4A542B3656EBad79) the msg.sender needs to be whitelisted, so we are safe if v15 is false, so , as long as the       
  getAmountsOut() returns a value less than the balance of Trunk of the "vulnerable contract" we are ok. (remember this because it's important).

  - If v15 is true, Trunk balance of the vulnerable contract will be swapped for BUSD.

  ![Alt text](images/image4.png)


















   
