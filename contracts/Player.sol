// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Player {
    uint8[5] public hand; // private
    uint8 public mainCard; // private
    uint256 public currentBet;
    uint256 public betCount;
    uint256 public currentBalance;
    address public playerAddress;
    Player public opponent;

    enum betTypes { None, Raise, Call, Pass, Blind, AllIn }
    betTypes betType;

    constructor(address _address, uint initialBalance) {
        playerAddress = _address;
        currentBalance = initialBalance;
        betCount = 0;
        betType = betTypes.None;
    }

    function setOpponent(Player player) public {
        opponent = player;
    }

    modifier betsTime {
        require(mainCard > 0, "Main card is not selected");
        _;
    }

    modifier yourTurn {
        require(betCount < opponent.betCount(), "It's not your turn!"); // надо потестить
        _;
    }

    function selectMainCard(uint8 index) public {
        require(hand[0] > 0, "Hand is empty");
        mainCard = hand[index];
    }

    function showMainCard() public view returns (uint8) {
        return mainCard;
    }

    // универсальная ставка
    function bet(uint value) private {
        currentBalance -= value;
        currentBet += value;
    }
    
    // блайнд не учитывается в счётчике ставок
    function blind(uint256 value) public {
        bet(value);
        betType = betTypes.Blind;
    }

    // не факт что такая возможность была в оригинальной игре(надо перечитать мангу)
    // можно использовать только после блайндов, если игроки не хотят повышать ставки
    /*
    function check() public betsTime {
        require(betType == betTypes.Blind, "You can check only after blind");
        betCount++;
        betType = betTypes.Check;
    }
    */
    
    function raise(uint value) public betsTime yourTurn {
        require(value <= currentBalance, "Not enough tokens :(");
        bet(value);
        betCount += 2;
        betType = betTypes.Raise;
    }

    function call() public betsTime yourTurn {
        require(opponent.getBetType() == uint(betTypes.Raise), "Nothing to call");
        if (opponent.currentBet() > currentBalance) {
            bet(currentBalance);
            betType = betTypes.AllIn;
        } else {
            bet(opponent.currentBet() - currentBet);
            betType = betTypes.Call;
        }

        betCount++;
    }

    function pass() public betsTime yourTurn {
        betCount++;
        betType = betTypes.Pass;
    }

    function changeHand(uint8[5] memory newHand) public {
        hand = newHand;
    }

    function showHand() public view returns (uint8[5] memory) {
        return hand;
    }

    function clearPlayerState() public {
        betCount = 0;
        currentBet = 0;
        mainCard = 0;
        betType = betTypes.None;
        delete(hand);
    }

    // костыль для установления очередности игроков
    function increaseBetCount() public {
        betCount++;
    }

    function getRoundReward(uint256 value) public {
        currentBalance += value;
    }

    // для проверки у дилера (возможно лишнее)
    function getBetType() public view returns (uint) {
        return uint(betType);
    }

    function bankrupt() public {
        currentBalance = 0;
    }
}