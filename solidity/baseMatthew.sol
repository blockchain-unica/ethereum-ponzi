contract Matthew {
    address owner;
    address public whale;
    uint256 public blockheight;
    uint256 public stake;
    uint256 period = 40; //180 blocks ~ 42 min, 300 blocks ~ 1h 10 min;
    uint constant public DELTA = 0.1 ether;
    uint constant public WINNERTAX_PRECENT = 10;
    uint newPeriod = period;
        
    function Matthew(){
        owner = msg.sender;
        init();
    }
    
    function reset() private {
        stake = this.balance;
        period = newPeriod;
        blockheight = block.number;
        whale = msg.sender;
    }

    function (){  
        if (block.number >= blockheight + period){      
	   whale.send(stake 9 / 10);
	   reset();//reset the game
        }else{ // top the stake
            if (msg.value < stake + DELTA) throw; 
            msg.sender.send(stake); // give back the old stake
            reset(); //reset the game
        }
    }
    
    
    // next round we set a new staking perioud
    function setNewPeriod(uint _newPeriod) onlyOwner{
        newPeriod = _newPeriod;
    }
    

}
