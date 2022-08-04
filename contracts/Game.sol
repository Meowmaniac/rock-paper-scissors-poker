// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Dealer.sol";
import "./Player.sol";

contract Game {
    mapping(address => uint256) public playersInGame;
    Dealer public dealer;
    Player[] public players;
    Player winner;
    bool isGameOver = true;

    function joinGame() public payable {  // не факт что тут должно быть payable
        require(players.length < 2, "Room is full!");
        require(msg.value >= 200, "Bank is too low!");
        require(playersInGame[msg.sender] == 0, "Player is already in game");

        Player newPlayer = new Player(msg.sender, msg.value);
        players.push(newPlayer);
        playersInGame[msg.sender] = msg.value;
    }

    function getPlayerAddress(uint8 index) public view returns (address) {
        return players[index].playerAddress();
    }
    
    function createGame() public {
        // проверить хватает ли игроков для старта
        require(players.length == 2, "Not enough players!");
        // проверить закинули ли игроки деньги
        for (uint i=0; i<players.length; i++) {
            require(playersInGame[players[i].playerAddress()] > 0, "Player don't have enough balance to start");
            //totalBank += playersInGame[players[i].playerAddress()]; //кажется это бесполезно
        }
        isGameOver = false;
        dealer = new Dealer(players);
        
    }

    // для тестирования
    function removePlayer(uint8 index) public {
        address playerAddress = getPlayerAddress(index);
        payable(playerAddress).transfer(playersInGame[playerAddress]);
        playersInGame[playerAddress] = 0;

        // удаление со сдвигом
        for (uint i = index; i < players.length - 1; i++) {
            players[i] = players[i + 1];
        }
        players.pop();
    }
    
    // придумать как проверять чтобы сумма балансов игроков всегда соответствовала общему банку
    function updatePlayerBalance(Player player) public {
        playersInGame[address(player)] = player.currentBalance();
    }

    function endGame(Player player1, Player player2) public {
        require(dealer.round() == 5, "It's not the end of the game");// require...
        
        playersInGame[player1.playerAddress()] = player1.currentBalance();
        playersInGame[player2.playerAddress()] = player2.currentBalance();

        isGameOver = true;
        dealer.reset();
        delete(players); // удалить массив или очистить так чтобы там не было элементов вообще
    }

    function requestReward() public {
        require(isGameOver == true, "Wait for the end of the game to request reward");
        require(playersInGame[msg.sender] > 0, "You have no reward");
        
        payable(msg.sender).transfer(playersInGame[msg.sender]);
        playersInGame[msg.sender] = 0;
    }
}




// [true, true, false, false, false], 0x6F9f91c61fC5b7c6637e465fBF709824BC56df20
// 0xA38B6e6547B3A10559F6B90B6590439A37696DAe, 0x22c00aB898A04d2728183D81A2445d70b26Ab3f9