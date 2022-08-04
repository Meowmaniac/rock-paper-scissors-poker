// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Player.sol";

contract Dealer {
    uint8[] public deck; //private
    uint256[5] public blinds;
    uint8 public round;
    Player[] public players;

    constructor(Player[] memory playersReadyToPlay) {
        players = playersReadyToPlay;
        //init deck
        initDeck();
        //set blinds
        setOpponents();
    }

    // очень ситуативная хренотень для двух игроков
    function setOpponents() private {
        players[0].setOpponent(players[1]);
        players[1].setOpponent(players[0]);
    }

    function reset() public {
        round = 0;
        delete(players);
    }

    // это абсолютно не оптимизированный метод, но работает
    function shuffle(uint8[21] memory currentDeck) public view returns (uint8[21] memory) {
        for (uint256 i = 0; i < currentDeck.length; i++) {
            uint256 n = i + uint256(keccak256(abi.encodePacked(block.timestamp))) % (currentDeck.length - i);
            uint8 temp = currentDeck[n];
            currentDeck[n] = currentDeck[i];
            currentDeck[i] = temp;
        }

        return currentDeck;
    }

    // 0 = rock, 1 = paper, 2 = scissors
    function initDeck() public {
        uint8[21] memory defaultDeck = 
                [1, 1, 1, 1, 1, 1, 1,
                 2, 2, 2, 2, 2, 2, 2,
                 3, 3, 3, 3, 3, 3, 3];
        uint8[21] memory currentDeck = defaultDeck;
        deck = shuffle(currentDeck);
    }

    // раздача карт
    function startRound(Player player1, Player player2) public {
        require(player1.showHand()[0] == 0, "Round is already going");
        require(round <= 5, "Wrong round number");
        require(player1.currentBalance() > 0 && player2.currentBalance() > 0, "Can't start round with 0 balance!");
        if(round == 0) {round = 1;} // старт игры

        // определение очередности ставок игроков нечётный раунд - первый игрок первый делауует ставку, чётный - второй
        // возможно позже сделать рандомный выбор
        if(round % 2 == 0) {
            player2.increaseBetCount();
        } else {
            player1.increaseBetCount();
        }

        initDeck(); // каждый раз новая колода xD
        dealCards(player1);
        dealCards(player2);
        player1.blind(round*10); // тут добавить нормальный расчёт блайндов
        player2.blind(round*10);
    }

    // выполняется в момент когда открыта основная карта
    function endRound(Player player1, Player player2) public {
        require(round <= 5, "Wrong round number");
        //require(player1.currentBalance() > 0 && player2.currentBalance() > 0, "Bankrupt lost the game"); // для случая когда нет денег на следующий блайнд
        require(player1.betCount() > 0 && player2.betCount() > 0, "No bet/check happened");
        require(player1.currentBet() == player2.currentBet() || player1.getBetType() == 5 || player2.getBetType() == 5 || player1.getBetType() == 3 || player1.getBetType() == 3, "Bets are not equal or it's not pass/all-in");
        
        uint256 roundReward = player1.currentBet() + player2.currentBet();

        // где-то тут проверить если кто-то спасовал, то второй автоматически выиграл
        if(player1.getBetType() == 3) {
            player2.getRoundReward(roundReward);
        } else if(player2.getBetType() == 3) {
            player1.getRoundReward(roundReward);
        } else {
            if (selectMainCardWinner(player1, player2) == 0) {
                selectPokerWinner(player1, player2);
            }
        }

        if(round < 5) {
            // где-то тут проверить есть ли у игрока деньги на следующий блайнд
            if(player1.currentBalance() < (round+1)*10) { // тут добавить нормальный расчёт блайндов
                player2.getRoundReward(player1.currentBalance()); // если у игрока нет денег на блайнд в следующем раунде, то он проигрывает всё и игра заканчивается
                player1.bankrupt();
                round = 5;
            } else if(player2.currentBalance() < (round+1)*10) {
                player1.getRoundReward(player2.currentBalance());
                player2.bankrupt();
                round = 5;
            } else {
                round++;
            }
        }
        // очистка состояния игроков для перехода к следующему раунду
        player1.clearPlayerState();
        player2.clearPlayerState();
    }

    function pickCard() public returns (uint8) {
        uint8 card = deck[deck.length - 1];
        deck.pop();
        return card;
    }

    // need to be called for every player
    function dealCards(Player player) public {
        uint8[5] memory playerHand;
        for (uint i=0; i<5; i++) {
            playerHand[i] = deck[deck.length - 1];
            deck.pop();
        }
        player.changeHand(playerHand);
    }

    function exchangeCards(bool[5] memory isChanged, Player player) public {
        uint8[5] memory playerHand = player.showHand();
        for (uint i=0; i<5; i++) {
            if (isChanged[i] == true) {
                playerHand[i] = pickCard();
            }
        }
        player.changeHand(playerHand);
    }

    function showDeck() public view returns (uint8[] memory) {
        return deck;
    }
    
    function selectMainCardWinner(Player player1, Player player2) public returns (uint8) {
        uint8 mainCardOne = player1.showMainCard();
        uint8 mainCardTwo = player2.showMainCard();
        uint256 roundReward = player1.currentBet() + player2.currentBet();
        if (mainCardOne == mainCardTwo) {
            return 0; // ничья
        } else if ((mainCardOne == 1 && mainCardTwo == 3) || 
                    (mainCardOne == 2 && mainCardTwo == 1) ||
                    (mainCardOne == 3 && mainCardTwo == 2)) {
            player1.getRoundReward(roundReward);
            return 1; // player 1 won
        } else if ((mainCardTwo == 1 && mainCardOne == 3) || 
                    (mainCardTwo == 2 && mainCardOne == 1) ||
                    (mainCardTwo == 3 && mainCardOne == 2)) {
            player2.getRoundReward(roundReward);
            return 2; // player 2 won
        }
        return 3;
    }

    function selectPokerWinner(Player player1, Player player2) public returns (uint8) {
        require(player1.showMainCard() == player2.showMainCard(), "Main cards not equal"); // может это и не надо т.к сюда будем попадать только при неудачном результате mainCardWinner
        uint cardsLikeMainOne = 0;
        uint cardsLikeMainTwo = 0;
        uint8[5] memory handOne = player1.showHand();
        uint8[5] memory handTwo = player2.showHand();
        uint8 mainCardOne = player1.showMainCard();
        uint8 mainCardTwo = player2.showMainCard();
        uint256 roundReward = player1.currentBet() + player2.currentBet();

        for (uint i=0; i<5; i++) {
            if (handOne[i] == mainCardOne)
                cardsLikeMainOne++;
            if (handTwo[i] == mainCardTwo)
                cardsLikeMainTwo++;
        }
        if (cardsLikeMainOne == cardsLikeMainTwo) {
            player1.getRoundReward(roundReward/2);
            player2.getRoundReward(roundReward/2);
            return 0; // ничья
        } 
        else if (cardsLikeMainOne > cardsLikeMainTwo) { 
            player1.getRoundReward(roundReward);
            return 1; // player 1 won
        } 
        else { 
            player2.getRoundReward(roundReward);
            return 2; // player 2 won
        } 

    }
}