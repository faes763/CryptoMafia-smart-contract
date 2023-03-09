// SPDX-License-Identifier: GPL-3.0  
  
pragma solidity >=0.8.2 <0.9.0;  
  
contract mafia {  
    address[] public players;  
    mapping(address=>uint) public playerWager;  
    mapping(address=>Agent) public playerHUD;  
    mapping(string=>address) infoPlayer;  
    mapping(address=>string) public namePlayer;  
  
    event InformingPlayer(string _human, string _message);  
    event Numb(uint numb);  
  
  
    uint readyPlayers = 0;  
    uint livesPlayer;  
  
  
    struct Agent {  
        string role;  
        address _address;  
        PLAYER status;  
        uint index;  
        bool heal;  
        uint voiting;  
        bool voted;  
        bool[] repeat;  
    }  
    function randomDoctor() private view returns (uint256) {  
        uint256 timeStamp = block.timestamp;  
        return uint256(block.number * timeStamp) / (players.length - 1) % (players.length);  
    }  
  
    function randomMafia() private view returns (uint256) {  
        uint256 timeStamp = block.timestamp;  
        return uint256(block.number * timeStamp* 12- 373) / (players.length - 1) % (players.length);  
    }  
  
    enum PLAYER {  
        REGISTER,  
        WAIT,  
        READY,  
        LIVE,  
        LOSE,  
        WIN  
    }  
    //Cостояние пользователя  
    GAME public game = GAME.START;  
  
    function deposit(string memory _name,uint _value, address _address) public payable {  
        // require(msg.value > 1000,"low bid");  
        registration(_address,_value, _name);  
        namePlayer[_address] = _name;  
    }  
  
    function readyMember() public {  
        // require(msg.sender == _address);  
        require(game==GAME.START, "Game playing");  
        //Если игра у нас ещё на старте, то мы можем менять состояние игрока  
        require(playerHUD[msg.sender].status != PLAYER.READY,"Player is registry");  
          
        playerHUD[msg.sender].status = PLAYER.READY;  
        readyPlayers++;  
        require(players.length > 4,"A few people");  
        if(readyPlayers == players.length) {  
            startGame();  
        }  
    }  
  
    function registration(address _address,uint _bid,string memory _playerName) private {  
        require(game == GAME.START, "Game playing");  
        //Проверка, запущена ли игра, если нет, то мы продолжаем  
        require(createMember(_address, _playerName), "player register");  
        //Функция возращающая создан ли игрок или нет. Если игрок был создан,   
        //то он запишется в массив игроков, вместе с его ставкой  
        playerBid(_address,_bid);  
    }  
      
    function playerBid(address player,uint _bid) private {  
        playerWager[player] = _bid;  
        //Ставка игрока  
    }  
  
    bool[] repPlayer;  
    //Функция для добавления игрока  
    function createMember(address _address,string memory _name) private returns(bool) {  
            if(playerHUD[_address].status == PLAYER.WAIT || playerHUD[_address].status == PLAYER.READY) {  
            //Если у игрока стоит статус WAIT или READY, то функция вернёт false. Тоесть игрок не будет создан  
            return false;  
        }  
        players.push(_address);  
        uint index = players.length - 1;  
        //Индекс игрока, под которым будет храниться  
          
         
        playerHUD[_address] = Agent("",_address,PLAYER.WAIT, index, false, 0,false, repPlayer);  
        infoPlayer[_name] = _address;  
        return true;  
    }  
  
    function lengthPlayerArr() public view returns(uint) { 
        return players.length; 
    } 
    function amountReady() public view returns(uint) { 
        return readyPlayers; 
    } 
    uint winnerPlayer = 0;  
  
  
    function withdraw(address _to) private {  
        uint amount = address(this).balance;  
       (bool success, ) = _to.call{value: amount/winnerPlayer}("");  
       require(success, "Failed to send Ether");  
    }  
  
    //Конец игры  
    function endGame() private {  
        emit Numb(1);  
        for(uint a = 0; a<players.length; a++) {
            if(playerHUD[players[a]].status == PLAYER.WIN) {  
            //   withdraw(players[a]);  
            }  
        }  
        delete players;  
        readyPlayers = 0;  
        game = GAME.START;  
        winnerPlayer=0;  
    }  
  
  
    // function playerLength() public view returns(uint) {  
    //     return players.length; 
    // }  
  
  
    //Cостояние игры  
    enum GAME {  
        START,  
        PLAY,  
        END  
    }  
      
    enum DAY {  
        DAY,  
        NIGHT  
    }  
    DAY setTime = DAY.NIGHT;  
    uint dayTime = 0;  
  
    //Старт игры  
    function startGame() public {  
        game = GAME.PLAY;  
        //Запускаем игру, регистрироваться больше нельзя  
  
        livesPlayer = players.length;  
  
        for(uint i =0;i<players.length;i++) {  
            playerHUD[players[i]].role = "Peaceful";  
  
            playerHUD[players[i]].status = PLAYER.LIVE;  
            //Назначаем всем пользователям мирную роль  
        }  
        playerHUD[players[randomDoctor()]].role = "Doctor";  
        // //Случайному игроку назначаем роль доктора  
        uint256 indexMafia = randomMafia();  
        if(keccak256(abi.encodePacked(playerHUD[players[indexMafia]].role)) == keccak256(abi.encodePacked("Doctor"))) {  
            //Если у нас выпал игрок с ролью доктор, то мы опять вызываем функцию рандома, чтобы другой игрок был мафией  
            playerHUD[players[indexMafia+1]].role = "Mafia";  
        }else {  
            playerHUD[players[indexMafia]].role = "Mafia";  
        }  
    }  
  
  
  
    uint processMafia= 0;  
    uint processDoctor= 0;  
  
    bool killDoctor = false;  
  
  
  
    function killPlayer(string memory _namePlayer) public {  
        require(keccak256(abi.encodePacked(playerHUD[msg.sender].role)) == keccak256(abi.encodePacked("Mafia")),"your role is not mafia");  
        require(setTime==DAY.NIGHT,"You can't do this during the day");  
        require(players[playerHUD[searchPlayer(_namePlayer)].index] != 0x0000000000000000000000000000000000000000,"This player has died");  
        if(!killDoctor) {  
            require(processMafia != processDoctor, "Your move is only after the doctor");  
        }  
        require(processMafia == dayTime, "You can't kill again today");  
        if(playerHUD[searchPlayer(_namePlayer)].heal) {  
            processMafia++;  
            emit InformingPlayer(_namePlayer,"survived");  
            playerHUD[searchPlayer(_namePlayer)].heal = false;  
        } else {  
            removePlayer(_namePlayer);  
            //Удаление игрока  
            emit InformingPlayer(_namePlayer,"death");  
            processMafia++;  
            livesPlayer--;  
            if(keccak256(abi.encodePacked(playerHUD[searchPlayer(_namePlayer)].role)) == keccak256(abi.encodePacked("Doctor"))) {  
                killDoctor = true;  
            }  
        }  
        emit InformingPlayer(playerHUD[searchPlayer(_namePlayer)].role,"The has made his choice");  
        countDay();  
    }  
  
    function healPlayer(string memory _namePlayer) public {  
          
        require(keccak256(abi.encodePacked(playerHUD[msg.sender].role)) == keccak256(abi.encodePacked("Doctor")),"your role is not Doctor");  
        require(setTime==DAY.NIGHT,"You can't do this during the day");  
        require(processDoctor == dayTime, "You can't health again today");  
        playerHUD[searchPlayer(_namePlayer)].heal = true;  
        processDoctor++;  
        emit InformingPlayer(playerHUD[searchPlayer(_namePlayer)].role,"The has made his choice");  
    }  
  
  
    function countDay() private {  
        setTime = DAY.DAY;  
        dayTime++;  
    }  
  
    Agent kickedPlayer;  
  
    uint votedPlayer = 0;  
  
    // mapping(address=>uint)   
  
    function votePlayer(string memory _namePlayer) public {  
        require(playerHUD[msg.sender].voted == false && setTime == DAY.DAY && playerHUD[msg.sender].status != PLAYER.LOSE && playerHUD[searchPlayer(_namePlayer)].status != PLAYER.LOSE);  
        //  && searchPlayer(_namePlayer) != 0x0000000000000000000000000000000000000000  
        playerHUD[msg.sender].voted = true;  
        playerHUD[searchPlayer(_namePlayer)].voiting++;  
        votedPlayer++;  
        if(votedPlayer == livesPlayer) {  
            setTime = DAY.NIGHT;  
            kickedPlayer = Agent("",0x0000000000000000000000000000000000000000,PLAYER.REGISTER, 0, false, 0,false,repPlayer);  
            for(uint i = 0;i<players.length; i++) { 
                if(playerHUD[players[i]].status != PLAYER.LOSE) {  
                    if(kickedPlayer.voiting < playerHUD[players[i]].voiting) {  
                        kickedPlayer = playerHUD[players[i]];  
                        emit Numb(kickedPlayer.voiting);  
                    }   
                    else if(kickedPlayer.voiting == playerHUD[players[i]].voiting && kickedPlayer.voiting != 0) {  
                        uint test = kickedPlayer.voiting;  
                        for(uint y = i;y<players.length; y++) {  
                            if(kickedPlayer.voiting < playerHUD[players[y]].voiting) {  
                                kickedPlayer = playerHUD[players[y]];  
                                emit Numb(kickedPlayer.voiting);  
                            }  
                        }  
                        if(kickedPlayer.voiting == test) {  
                            emit Numb(kickedPlayer.voiting);  
                            emit InformingPlayer("BOT", "Opinions differed");  
                            return;  
                        }  
                    }  
  
                }  
            }  
  
            address kickPlayer = players[kickedPlayer.index];  
            emit InformingPlayer(namePlayer[kickPlayer], playerHUD[kickPlayer].role);  
  
            if(keccak256(abi.encodePacked(playerHUD[kickPlayer].role)) == keccak256(abi.encodePacked("Mafia"))) {  
                for(uint a = 0; a<players.length; a++) {  
                    if(playerHUD[players[a]].status == PLAYER.LIVE) {  
                        playerHUD[players[a]].status = PLAYER.WIN;  
                        winnerPlayer++;  
                    }  
                }  
                endGame();  
            }  
  
            removePlayer(namePlayer[kickPlayer]);  
            //Удаление игрока  
            for(uint b = 0; b<players.length; b++) {  
                playerHUD[players[b]].voted = false;  
                playerHUD[players[b]].voiting = 0;  
            }  
            setTime = DAY.NIGHT;  
        }  
    }  
  
  
  
  
    function removePlayer(string memory _namePlayer) private {  
        playerHUD[searchPlayer(_namePlayer)].status = PLAYER.LOSE;  
        players[playerHUD[searchPlayer(_namePlayer)].index] = 0x0000000000000000000000000000000000000000;  
        infoPlayer[_namePlayer] = 0x0000000000000000000000000000000000000000;  
    }  
  
    //Поиск адреса игрока по его имени  
    function searchPlayer(string memory _namePlayer) private view returns(address) {  
        return infoPlayer[_namePlayer];  
    }  
  
  
    struct Message {  
        string name;  
        string message;  
    }  
  
    Message[] public chat;  
  
    function messages(string memory name, string memory _message) public {  
        chat.push(Message(name, _message));  
    }  
}