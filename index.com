<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Super Mario Diet Game</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            background-color: #87CEEB;
            overflow: hidden;
        }
        #gameCanvas {
            background-color: #f4f4f4;
            display: block;
            margin: 0 auto;
        }
        .info-box {
            position: absolute;
            top: 10px;
            left: 10px;
            color: #fff;
            background-color: rgba(0, 0, 0, 0.5);
            padding: 10px;
            border-radius: 10px;
            font-size: 20px;
        }
        .diet-recommendation {
            position: absolute;
            top: 50px;
            left: 10px;
            color: white;
            font-size: 18px;
            width: 300px;
            background-color: rgba(0, 0, 0, 0.5);
            padding: 10px;
            border-radius: 10px;
        }
        .menu {
            position: absolute;
            top: 150px;
            left: 10px;
            color: white;
            font-size: 18px;
            background-color: rgba(0, 0, 0, 0.5);
            padding: 20px;
            border-radius: 10px;
            width: 300px;
        }
    </style>
</head>
<body>

<canvas id="gameCanvas" width="800" height="600"></canvas>

<div class="info-box" id="infoBox">Press arrow keys to move, space to jump.</div>
<div class="diet-recommendation" id="dietRecommendation"></div>
<div class="menu" id="menu" style="display:none;"></div>

<script>
    const canvas = document.getElementById("gameCanvas");
    const ctx = canvas.getContext("2d");

    let gameStarted = false;
    let currentQuestion = 0;
    let userResponses = {};
    let mario = {
        x: 50,
        y: 500,
        width: 50,
        height: 50,
        speed: 5,
        velocityY: 0,
        gravity: 0.8,
        jumping: false,
        jumpHeight: -15
    };

    const ground = canvas.height - 50;
    const monsters = [];
    const keys = {};

    window.addEventListener("keydown", (e) => { keys[e.key] = true; });
    window.addEventListener("keyup", (e) => { keys[e.key] = false; });

    const questions = [
        { question: "What is your age?", key: "age" },
        { question: "What is your gender? (M/F)", key: "gender" },
        { question: "What is your weight? (kg)", key: "weight" },
        { question: "How often do you exercise? (1-7)", key: "exercise" },
        { question: "Do you prefer high-protein foods? (Y/N)", key: "highProtein" },
        { question: "Do you prefer a low-carb diet? (Y/N)", key: "lowCarb" }
    ];

    function drawMario() {
        ctx.fillStyle = "#ff0000";
        ctx.fillRect(mario.x, mario.y, mario.width, mario.height);
    }

    function handleJump() {
        if (mario.jumping) {
            mario.velocityY += mario.gravity;
            mario.y += mario.velocityY;

            if (mario.y >= ground) {
                mario.y = ground;
                mario.jumping = false;
                mario.velocityY = 0;
            }
        }
    }

    function moveMario() {
        if (keys["ArrowLeft"]) {
            mario.x -= mario.speed;
        }
        if (keys["ArrowRight"]) {
            mario.x += mario.speed;
        }
        if (keys[" "]) {
            if (!mario.jumping) {
                mario.jumping = true;
                mario.velocityY = mario.jumpHeight;
            }
        }
    }

    function spawnMonsters() {
        if (Math.random() < 0.02) {
            let monster = {
                x: canvas.width,
                y: ground - 40,
                width: 40,
                height: 40,
                speed: 3
            };
            monsters.push(monster);
        }
    }

    function moveMonsters() {
        for (let i = 0; i < monsters.length; i++) {
            monsters[i].x -= monsters[i].speed;
        }
    }

    function detectCollisions() {
        for (let i = 0; i < monsters.length; i++) {
            if (
                mario.x < monsters[i].x + monsters[i].width &&
                mario.x + mario.width > monsters[i].x &&
                mario.y < monsters[i].y + monsters[i].height &&
                mario.y + mario.height > monsters[i].y
            ) {
                // Collision detected: Game over or reset
                alert("Game Over! You collided with a monster!");
                resetGame();
            }
        }
    }

    function showDietRecommendation() {
        let recommendation = "Diet recommendation: ";

        if (userResponses.exercise <= 2) {
            recommendation += "Include more physical activity in your routine.";
        } else {
            recommendation += "Maintain a balanced diet and continue regular exercise.";
        }

        if (userResponses.age > 30) {
            recommendation += " Consider foods rich in calcium for bone health.";
        }

        if (userResponses.gender === "F") {
            recommendation += " Make sure to get enough iron.";
        }

        document.getElementById("dietRecommendation").innerText = recommendation;
    }

    function showMenu() {
        let menuText = "Weekly Meal Plan:\n";
        menuText += "Day 1: High-protein breakfast, Salad for lunch, Fish for dinner.\n";
        menuText += "Day 2: Oats with fruits, Chicken for lunch, Veggies for dinner.\n";
        menuText += "Day 3: Eggs and avocado, Beef salad, Grilled chicken.\n";
        menuText += "Day 4: Smoothie bowl, Tofu stir-fry, Baked salmon.\n";
        menuText += "Day 5: Whole grain toast with peanut butter, Turkey lunch, Veggies.\n";
        menuText += "Day 6: Yogurt with granola, Tuna salad, Chicken breast.\n";
        menuText += "Day 7: Protein pancakes, Veggie stir-fry, Steak with vegetables.";

        document.getElementById("menu").innerText = menuText;
        document.getElementById("menu").style.display = "block";
    }

    function showQuestion() {
        if (currentQuestion < questions.length) {
            document.getElementById("infoBox").innerText = questions[currentQuestion].question;
        } else {
            gameStarted = true;
            document.getElementById("infoBox").style.display = "none";
            showDietRecommendation();
            spawnMonsters();
        }
    }

    function handleAnswer(answer) {
        if (currentQuestion < questions.length) {
            userResponses[questions[currentQuestion].key] = answer;
            currentQuestion++;
            showQuestion();
        }
    }

    function draw() {
        ctx.clearRect(0, 0, canvas.width, canvas.height);
        handleJump();
        moveMario();
        drawMario();
        moveMonsters();
        detectCollisions();

        if (gameStarted) {
            monsters.forEach((monster) => {
                ctx.fillStyle = "#00FF00";
                ctx.fillRect(monster.x, monster.y, monster.width, monster.height);
            });
        }

        requestAnimationFrame(draw);
    }

    function startGame() {
        document.addEventListener("keydown", (e) => {
            if (e.key === "Enter" && currentQuestion < questions.length) {
                const answer = prompt(questions[currentQuestion].question);
                handleAnswer(answer);
            }
        });

        draw();
    }

    function resetGame() {
        gameStarted = false;
        currentQuestion = 0;
        userResponses = {};
        monsters.length = 0;
        mario.x = 50;
        mario.y = ground;
        mario.velocityY = 0;
        mario.jumping = false;
        document.getElementById("menu").style.display = "none";
        startGame();
    }

    window.onload = () => {
        startGame();
    };
</script>

</body>
</html>
