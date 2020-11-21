pragma solidity ^0.4.21;
pragma experimental ABIEncoderV2;

import "./EIP20.sol";

contract Lottery is EIP20{
    
    uint revealDuration = 1 weeks;
    uint purchaseDuration = 1 weeks;
    
    address[] winnerAddress;
    uint winner;    // winner of the current lottery
    uint lotteryCounter = 1;  // number of lottery round
    uint totalMoney = 0;    // total money of the system
    uint totalMoneyLottery = 0; // total money that collected in the current lottery
    uint public purchase_end_time;  // end of purchase time
    uint public reveal_end_time; // end of reveal time


    mapping(address=>Ticket[]) tickets;
    mapping(address=>uint) ticket_order;
    mapping(uint=>address[]) ticketOwner;
    mapping(address=>uint) award_amount; 
    mapping(address=>uint) winnerMultiplier;
    
    function Lottery() public{
        purchase_end_time=now + purchaseDuration;
        winner = 0;
        reveal_end_time = purchase_end_time + revealDuration;
    }
    
    struct Ticket{
        uint lottery_num;
        bytes32 ticket_hash;
        uint N;
        bool isValidTicket;
    }

    function purchase(bytes32 val) public payable{
        if(transfertocase(10)){
            if( block.timestamp < purchase_end_time){
                Ticket memory t;
                t.ticket_hash = val;
                t.lottery_num = lotteryCounter;
                t.isValidTicket = false;
                tickets[msg.sender].push(t);
                totalMoney = totalMoney + 10;
                totalMoneyLottery += 10;
            }
        }else{
            revert();
        }
    }
    // withdraw award if msg.sender has any
    function withdraw() public payable{
        if(award_amount[msg.sender] == 0){
            throw;
        }else{
            uint amount = award_amount[msg.sender];
            transferfromcase(amount,msg.sender);
            totalMoney -= amount;
            award_amount[msg.sender] = 0;
        }
    }
   
   
   // @param: uint N. hashes N with message sender address. 
   // checks if the ticket hash value matches with the message sender's tickets
   // if the value is true, it makes this ticket valid and generates new random winner value.
   function reveal(uint N) public payable {  
            if( block.timestamp > purchase_end_time){
                bytes32 shah = keccak256(N,msg.sender);
                uint len = tickets[msg.sender].length;
                for(uint i=0 ; i<len ; i++){
                    if(tickets[msg.sender][i].ticket_hash == shah && !tickets[msg.sender][i].isValidTicket){
                        tickets[msg.sender][i].isValidTicket = true;
                        tickets[msg.sender].[i].N = N;
                        ticketOwner[N].push(msg.sender);
                        winner = winner ^ N; // creating random number with XOR operation
                    }
                }
            }
   }
   
   // if block.timestamp > reveal_end_time it makes, it is time to revealWinner.
   // until this time, random winner number will be generated. Cheks the N values of tickets
   // and finds winner tickets. it calculates a unit amount according to number of winner tickets.
   // Adds award to winner tickets' owners.
   function revealWinner() public payable{
       if( block.timestamp > reveal_end_time ){
            winnerAddress = ticketOwner[winner];
            Ticket[] memory winnerTicket;
            uint count = 0;
            for(uint i = 0;i<winnerAddress.length;i++){
                for(uint j = 0; j<tickets[winnerAddress[i]].length; j++){
                    if(winner == tickets[winnerAddress[i]][j].N){
                        count += 1;
                        winnerMultiplier[winnerAddress[i]] += 1;
                    }
                }
            }
            uint m = totalMoneyLottery/(2^lotteryCounter);
            uint unit = m+((m/2)%2);
            for(uint k=0 ; k<winnerAddress.length ; k++){
                award_amount[winnerAddress[k]] += winnerMultiplier[winnerAddress[k]]*unit;
                winnerMultiplier[winnerAddress[k]] = 0;
            }
            resetContract() ;
        }
   }
   
   function getLotteryCounter() public view returns (uint){
       return lotteryCounter;
   }

    function getWinnerNumber() public view returns (uint){
        return winner;
    }
    
    function getTicketOwner() public view returns (address[]){
        return ticketOwner[winner];
    }
    
    function getHashValue(uint N,address adr) public view returns(bytes32){
        return keccak256(N,adr);
    }
    function getTotalAmount() public view returns (uint){
        return totalMoney;
    }
    function getPurchaseEndTime()public view returns (uint){ // returns the purchase end time
        return purchase_end_time;
    }
    function getTime()public view returns (uint){   // returns the current time
        return block.timestamp;
    }
    
    function getAwardAmount()public view returns (uint){  // returns the total reward amount of the message sender
        return award_amount[msg.sender];
    }
    function resetContract() public { // this method finishes the lottery and starts a new one at the end of the lottery round
        purchase_end_time = now + purchaseDuration;
        reveal_end_time = purchase_end_time + revealDuration;
        lotteryCounter += 1;
        winner = 0;
        totalMoneyLottery = 0;
    }
}
