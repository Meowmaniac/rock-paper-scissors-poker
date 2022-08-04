// создаем HTTP-сервер
const httpServer = require('http').createServer();
// подключаем к серверу Socket.IO
const io = require('socket.io')(httpServer, {
    cors: {
        origin: '*'
    }
});

let playersCount = 0;
let players = [];

const onConnection = (socket) => {
    if (playersCount < 2) {
        socket.on('address', (arg) => {
            console.log('Player ' + arg + ' connected');
            players[socket.id] = arg;
            console.log(players);
        });
        playersCount++;
    } else {
        console.log('Room is full');
        console.log(players);
    }
    /*
        // получаем название комнаты из строки запроса "рукопожатия"
        const { roomId } = socket.handshake.query;
        // сохраняем название комнаты в соответствующем свойстве сокета
        socket.roomId = roomId;
        // присоединяемся к комнате (входим в нее)
        socket.join(roomId);
    */

    socket.on('disconnect', () => {
        console.log('Player disconnected');
        playersCount--;
        delete players[socket.id];
        console.log(players);
        //socket.leave(roomId);
    });
}

// обрабатываем подключение
io.on('connection', onConnection);

// запускаем сервер
const PORT = process.env.PORT || 5000;
httpServer.listen(PORT, () => {
    console.log(`Server ready. Port: ${PORT}`);
});