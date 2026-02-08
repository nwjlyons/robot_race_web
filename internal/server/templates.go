package server

const indexHTML = `<!DOCTYPE html>
<html>
<head>
    <title>Robot Race</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Press Start 2P', cursive;
            background: #1a1a1a;
            color: #d3d3d3;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .container {
            text-align: center;
            padding: 2rem;
        }
        h1 {
            font-size: 2rem;
            margin-bottom: 2rem;
            text-shadow: 0 0 1rem #d3d3d3;
        }
        button {
            background: #444;
            color: #d3d3d3;
            border: 2px solid #d3d3d3;
            padding: 1rem 2rem;
            font-family: inherit;
            font-size: 1rem;
            cursor: pointer;
            text-shadow: 0 0 0.5rem #d3d3d3;
            box-shadow: 0 0 1rem rgba(211, 211, 211, 0.3);
        }
        button:hover {
            background: #555;
            box-shadow: 0 0 1.5rem rgba(211, 211, 211, 0.5);
        }
    </style>
    <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap" rel="stylesheet">
</head>
<body>
    <div class="container">
        <h1>RobotRace</h1>
        <p style="margin-bottom: 2rem;">Phoenix.LiveView racing game. First to the top wins.</p>
        <p style="margin-bottom: 2rem; font-size: 0.8rem;">Now powered by Go!</p>
        <form action="/create" method="POST">
            <button type="submit">Create New Game</button>
        </form>
    </div>
</body>
</html>`

const joinHTML = `<!DOCTYPE html>
<html>
<head>
    <title>Join Game - Robot Race</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: 'Press Start 2P', cursive;
            background: #1a1a1a;
            color: #d3d3d3;
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
        }
        .container {
            text-align: center;
            padding: 2rem;
            max-width: 500px;
        }
        h1 {
            font-size: 1.5rem;
            margin-bottom: 2rem;
            text-shadow: 0 0 1rem #d3d3d3;
        }
        form {
            display: flex;
            flex-direction: column;
            gap: 1rem;
        }
        input {
            background: #2b2b2b;
            color: #d3d3d3;
            border: 2px solid #d3d3d3;
            padding: 1rem;
            font-family: inherit;
            font-size: 0.8rem;
        }
        button {
            background: #444;
            color: #d3d3d3;
            border: 2px solid #d3d3d3;
            padding: 1rem 2rem;
            font-family: inherit;
            font-size: 0.8rem;
            cursor: pointer;
            text-shadow: 0 0 0.5rem #d3d3d3;
            box-shadow: 0 0 1rem rgba(211, 211, 211, 0.3);
        }
        button:hover {
            background: #555;
            box-shadow: 0 0 1.5rem rgba(211, 211, 211, 0.5);
        }
        .info {
            margin-top: 2rem;
            font-size: 0.7rem;
            line-height: 1.5;
        }
    </style>
    <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap" rel="stylesheet">
</head>
<body>
    <div class="container">
        <h1>Join Robot Race</h1>
        <form action="/join-game" method="POST">
            <input type="hidden" name="game_id" value="{{.GameID}}">
            <input type="text" name="name" placeholder="Enter your name" required autofocus maxlength="20">
            <button type="submit">Join Game</button>
        </form>
        <div class="info">
            <p>Players: {{len .Game.Robots}}/{{.Game.MaxRobots}}</p>
        </div>
    </div>
</body>
</html>`

const gameHTML = `<!DOCTYPE html>
<html>
<head>
    <title>Robot Race</title>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        html, body {
            height: 100%;
            overflow: hidden;
        }
        body {
            font-family: 'Press Start 2P', cursive;
            background: #1a1a1a;
            color: #d3d3d3;
        }
        #canvas {
            display: block;
            width: 100%;
            height: 100%;
        }
        .dialog {
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(26, 26, 26, 0.95);
            border: 2px solid #d3d3d3;
            padding: 2rem;
            text-align: center;
            z-index: 1000;
            min-width: 300px;
        }
        .dialog h1 {
            font-size: 2rem;
            margin-bottom: 1rem;
            text-shadow: 0 0 1rem #d3d3d3;
        }
        .dialog p {
            margin-bottom: 1rem;
            font-size: 0.8rem;
        }
        .dialog button {
            background: #444;
            color: #d3d3d3;
            border: 2px solid #d3d3d3;
            padding: 1rem 2rem;
            font-family: inherit;
            font-size: 0.8rem;
            cursor: pointer;
            text-shadow: 0 0 0.5rem #d3d3d3;
            box-shadow: 0 0 1rem rgba(211, 211, 211, 0.3);
            margin: 0.5rem;
        }
        .dialog button:hover {
            background: #555;
            box-shadow: 0 0 1.5rem rgba(211, 211, 211, 0.5);
        }
        .leaderboard {
            margin-top: 1rem;
            font-size: 0.7rem;
        }
        .leaderboard-entry {
            display: flex;
            justify-content: space-between;
            margin: 0.5rem 0;
            gap: 2rem;
        }
        #countdown-text {
            font-size: 5rem;
            text-shadow: 0 0 2rem #d3d3d3;
        }
    </style>
    <link href="https://fonts.googleapis.com/css2?family=Press+Start+2P&display=swap" rel="stylesheet">
</head>
<body>
    <canvas id="canvas"></canvas>
    <div id="dialog" class="dialog" style="display: none;"></div>

    <script>
        const gameID = "{{.Game.ID}}";
        const robotID = "{{.RobotID}}";
        const isAdmin = {{.IsAdmin}};
        const gameURL = "{{.GameURL}}";
        
        let game = null;
        let ws = null;

        // Connect to WebSocket
        function connect() {
            const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
            ws = new WebSocket(protocol + '//' + window.location.host + '/ws');
            
            ws.onopen = function() {
                console.log('Connected to server');
            };
            
            ws.onmessage = function(event) {
                const msg = JSON.parse(event.data);
                if (msg.type === 'game_update') {
                    game = msg.payload.game;
                    updateUI();
                    render();
                }
            };
            
            ws.onclose = function() {
                console.log('Disconnected from server');
                setTimeout(connect, 1000);
            };
        }

        function sendMessage(type, payload = {}) {
            if (ws && ws.readyState === WebSocket.OPEN) {
                ws.send(JSON.stringify({ type, payload }));
            }
        }

        function updateUI() {
            const dialog = document.getElementById('dialog');
            
            if (game.state === 'setup') {
                dialog.style.display = 'block';
                if (isAdmin) {
                    dialog.innerHTML = '<p>Invite players</p><button onclick="copyLink()">Copy invite link</button><button onclick="startCountdown()">Start countdown</button>';
                } else {
                    dialog.innerHTML = '<p>Get ready</p>';
                }
            } else if (game.state === 'counting_down') {
                dialog.style.display = 'block';
                const text = game.countdown > 0 ? game.countdown : 'Go';
                dialog.innerHTML = '<div id="countdown-text">' + text + '</div>';
            } else if (game.state === 'finished') {
                const winner = getWinner();
                const leaderboard = getLeaderboard();
                let html = '<h1>' + winner.name + ' wins!</h1>';
                html += '<div class="leaderboard"><p>Leaderboard</p>';
                leaderboard.forEach(entry => {
                    html += '<div class="leaderboard-entry"><span>' + entry.robot.name + '</span><span>' + entry.win_count + '</span></div>';
                });
                html += '</div>';
                if (isAdmin) {
                    html += '<button onclick="playAgain()">Play again</button>';
                }
                dialog.innerHTML = html;
                dialog.style.display = 'block';
            } else {
                dialog.style.display = 'none';
            }
        }

        function getWinner() {
            if (!game || !game.robots || game.robots.length === 0) return null;
            return game.robots.reduce((max, robot) => robot.score > max.score ? robot : max, game.robots[0]);
        }

        function getLeaderboard() {
            if (!game || !game.robots) return [];
            const winner = getWinner();
            return game.robots.map(robot => {
                let winCount = game.previous_wins[robot.id] || 0;
                if (winner && robot.id === winner.id) {
                    winCount++;
                }
                return { robot, win_count: winCount };
            }).sort((a, b) => b.win_count - a.win_count);
        }

        function copyLink() {
            navigator.clipboard.writeText(window.location.origin + '/join/' + gameID);
            alert('Link copied to clipboard!');
        }

        function startCountdown() {
            sendMessage('start_countdown');
        }

        function playAgain() {
            sendMessage('play_again');
        }

        // Input handling
        window.addEventListener('keyup', function(e) {
            if (e.code === 'Space' && game && game.state === 'playing') {
                sendMessage('score_point');
            }
        });

        window.addEventListener('touchstart', function(e) {
            if (game && game.state === 'playing') {
                sendMessage('score_point');
            }
        });

        // Canvas rendering
        const canvas = document.getElementById('canvas');
        const ctx = canvas.getContext('2d');
        const colors = ['cyan', 'magenta', 'yellow', 'white'];

        function render() {
            if (!game || !game.robots) return;

            const bodyRect = document.body.getBoundingClientRect();
            canvas.width = bodyRect.width;
            canvas.height = bodyRect.height;

            const robotLength = Math.min(canvas.height / 10, canvas.width / 10);
            const columnWidth = canvas.width / game.robots.length;
            const rowHeight = (canvas.height - robotLength) / game.winning_score;

            game.robots.forEach((robot, i) => {
                const x = (i * columnWidth) + (columnWidth / 2) - (robotLength / 2);
                const y = (canvas.height - (rowHeight * robot.score)) - robotLength;
                const color = colors[i % colors.length];
                drawRobot(x, y, robotLength, color, robot.name);
            });
        }

        function drawRobot(x, y, length, color, name) {
            // Body with glow
            ctx.shadowColor = 'white';
            ctx.shadowBlur = 10;
            ctx.fillStyle = color;
            ctx.fillRect(x, y, length, length);
            
            ctx.shadowBlur = 15;
            ctx.fillRect(x, y, length, length);
            
            ctx.shadowBlur = 20;
            ctx.fillRect(x, y, length, length);
            
            ctx.shadowBlur = 40;
            ctx.fillRect(x, y, length, length);

            // Eyes
            const column = length / 11;
            const eyeLength = column * 4;
            const eyeY = y + column * 1.75;
            
            ctx.shadowBlur = 0;
            
            // Left eye
            ctx.fillStyle = '#2b2b2b';
            ctx.fillRect(x + column, eyeY, eyeLength, eyeLength);
            ctx.fillStyle = '#d3d3d3';
            const pupilLength = eyeLength / 2.5;
            const pupilOffset = (eyeLength / 2) - pupilLength / 2;
            ctx.fillRect(x + column + pupilOffset, eyeY + pupilOffset, pupilLength, pupilLength);
            
            // Right eye
            const rightEyeX = ((x + length) - eyeLength) - column;
            ctx.fillStyle = '#2b2b2b';
            ctx.fillRect(rightEyeX, eyeY, eyeLength, eyeLength);
            ctx.fillStyle = '#d3d3d3';
            ctx.fillRect(rightEyeX + pupilOffset, eyeY + pupilOffset, pupilLength, pupilLength);

            // Name
            ctx.fillStyle = '#444';
            ctx.shadowColor = 'white';
            ctx.shadowBlur = 10;
            ctx.textAlign = 'center';
            const fontHeight = length / 6;
            ctx.font = fontHeight + 'px "Press Start 2P"';
            ctx.fillText(name, x + (length / 2), (y + length) - column);
            ctx.shadowBlur = 0;
        }

        window.addEventListener('resize', render);

        // Initialize
        connect();
    </script>
</body>
</html>`
