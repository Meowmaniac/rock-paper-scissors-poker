import React, { Component } from "react";
import { io } from "socket.io-client";
import { ethers } from "ethers";

class App extends Component {
  state = {
    player: "",
    balance: "",
    isJoined: false,
  };

  async componentDidMount() {
    const socket = io("http://localhost:5000");

    socket.on("connect", () => {
      console.log("Connected to server");
    });

    const accounts = await window.ethereum.request({
      method: "eth_requestAccounts",
    });
    const address = accounts[0];
    console.log(address);

    socket.emit("address", address);
  }

  render() {
    return (
      <div className="App">
        <header className="App-header">
          <h1>Rock-Paper-Scissors Poker</h1>
        </header>
      </div>
    );
  }
}
/*

function App() {
  const socket = io('http://localhost:5000');

  socket.on("connect", () => {
    console.log('Connected from client');
  });

  return (
    <div className="App">
      <header className="App-header">
        <p>React</p>
      </header>
    </div>
  );
}
*/
export default App;
